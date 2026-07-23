const Razorpay = require('razorpay');
const crypto = require('crypto');
const { PaymentLedger, Settlement, PaymentAuditLog, Booking, Shop, Settings } = require('../models');
const { logPaymentEvent, sendFcmNotification, sendFcmTopicNotification, paginate } = require('../helpers');
const { logger } = require('../config/logger');

function getRazorpayInstance() {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;
  if (!key_id || !key_secret) {
    return null;
  }
  return new Razorpay({ key_id, key_secret });
}

async function createRazorpayOrder(bookingId, userId) {
  let booking = await Booking.findOne({ id: bookingId });
  if (!booking) {
    try { booking = await Booking.findById(bookingId); } catch (_) {}
  }
  if (!booking) {
    throw new Error('Booking not found');
  }

  // Calculate amount strictly from booking record (never trust client amount!)
  const totalAmount = parseFloat(booking.totalPrice || booking.amount || 0);
  if (totalAmount <= 0) {
    const err = new Error('Invalid booking total amount for payment order creation');
    err.statusCode = 400;
    throw err;
  }

  const amountInPaise = Math.round(totalAmount * 100);
  const razorpay = getRazorpayInstance();

  if (razorpay) {
    const options = {
      amount: amountInPaise,
      currency: 'INR',
      receipt: booking.id || booking._id.toString(),
      notes: {
        bookingId: booking.id || booking._id.toString(),
        userId: userId || booking.userId || ''
      }
    };
    const order = await razorpay.orders.create(options);
    booking.razorpayOrderId = order.id;
    await booking.save();
    return {
      orderId: order.id,
      amount: totalAmount,
      amountInPaise,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID
    };
  } else {
    logger.warn('RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET missing. Generating fallback order token.');
    const fallbackOrderId = `order_dev_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    booking.razorpayOrderId = fallbackOrderId;
    await booking.save();
    return {
      orderId: fallbackOrderId,
      amount: totalAmount,
      amountInPaise,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder'
    };
  }
}

async function verifyRazorpayPayment(razorpayOrderId, razorpayPaymentId, razorpaySignature, bookingId) {
  let booking = null;
  if (bookingId) {
    booking = await Booking.findOne({ id: bookingId });
    if (!booking) try { booking = await Booking.findById(bookingId); } catch (_) {}
  }
  if (!booking && razorpayOrderId) {
    booking = await Booking.findOne({ razorpayOrderId });
  }

  if (!booking) {
    throw new Error('Booking associated with payment order not found');
  }

  // Prevent duplicate payments (idempotency check)
  if (booking.paymentStatus === 'paid') {
    return {
      success: true,
      message: 'Payment has already been processed and verified',
      booking
    };
  }

  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (secret) {
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(razorpayOrderId + '|' + razorpayPaymentId)
      .digest('hex');

    if (expectedSignature !== razorpaySignature) {
      const err = new Error('Razorpay cryptographic signature verification failed');
      err.statusCode = 400;
      throw err;
    }
  } else {
    logger.warn('RAZORPAY_KEY_SECRET missing. Payment signature verification bypassed in dev mode.');
  }

  booking.paymentStatus = 'paid';
  booking.razorpayPaymentId = razorpayPaymentId;
  booking.razorpaySignature = razorpaySignature;
  await booking.save();

  await logPaymentEvent('razorpay_verified', {
    bookingId: booking.id || booking._id,
    shopId: booking.shopId,
    amount: booking.totalPrice || booking.amount,
    description: `Razorpay payment verified: ${razorpayPaymentId} for Order ${razorpayOrderId}`,
    actor: 'customer',
    metadata: { razorpayOrderId, razorpayPaymentId }
  });

  return {
    success: true,
    message: 'Payment verified successfully',
    booking
  };
}

async function handleRazorpayWebhook(headers, rawBody) {
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  const signature = headers['x-razorpay-signature'];

  if (webhookSecret) {
    if (!signature) {
      const err = new Error('Missing Razorpay webhook signature header');
      err.statusCode = 400;
      throw err;
    }
    const bodyStr = typeof rawBody === 'string' ? rawBody : JSON.stringify(rawBody);
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(bodyStr)
      .digest('hex');

    if (expectedSignature !== signature) {
      const err = new Error('Invalid Razorpay webhook signature');
      err.statusCode = 400;
      throw err;
    }
  } else {
    logger.warn('RAZORPAY_WEBHOOK_SECRET missing. Webhook signature validation skipped in dev mode.');
  }

  const event = typeof rawBody === 'string' ? JSON.parse(rawBody) : rawBody;
  const eventType = event.event;

  if (eventType === 'payment.captured') {
    const payment = event.payload.payment.entity;
    const razorpayOrderId = payment.order_id;
    const razorpayPaymentId = payment.id;

    const booking = await Booking.findOne({ razorpayOrderId });
    if (booking && booking.paymentStatus !== 'paid') {
      booking.paymentStatus = 'paid';
      booking.razorpayPaymentId = razorpayPaymentId;
      await booking.save();

      await logPaymentEvent('webhook_payment_captured', {
        bookingId: booking.id || booking._id,
        shopId: booking.shopId,
        amount: payment.amount / 100,
        description: `Webhook payment.captured for Order ${razorpayOrderId}`,
        actor: 'razorpay_webhook',
        metadata: { razorpayOrderId, razorpayPaymentId }
      });
    }
  } else if (eventType === 'payment.failed') {
    const payment = event.payload.payment.entity;
    const razorpayOrderId = payment.order_id;

    const booking = await Booking.findOne({ razorpayOrderId });
    if (booking && booking.paymentStatus !== 'paid') {
      booking.paymentStatus = 'failed';
      await booking.save();

      await logPaymentEvent('webhook_payment_failed', {
        bookingId: booking.id || booking._id,
        shopId: booking.shopId,
        amount: payment.amount / 100,
        description: `Webhook payment.failed for Order ${razorpayOrderId}`,
        actor: 'razorpay_webhook',
        metadata: { razorpayOrderId, error: payment.error_description }
      });
    }
  }

  return { status: 'ok' };
}

async function getLedgerForBooking(bookingId) {
  const ledger = await PaymentLedger.findOne({ bookingId });
  if (!ledger) {
    throw new Error('No ledger found for this booking');
  }
  return ledger;
}

async function getLedgerForShop(shopId, req) {
  req.query.shopId = shopId;
  const result = await paginate(PaymentLedger, req, ['bookingId', 'shopId', 'customerId', 'customerName', 'providerName', 'serviceTitle'], { createdAt: -1 });
  if (Array.isArray(result)) {
    return { ledgers: result };
  } else {
    return {
      ledgers: result.data,
      pagination: result.pagination
    };
  }
}

async function getAllLedgerEntries(req, from, to) {
  if (from || to) {
    const createdAt = {};
    if (from) createdAt.$gte = new Date(from);
    if (to) createdAt.$lte = new Date(to);
    req.query.createdAt = createdAt;
  }
  delete req.query.from;
  delete req.query.to;

  const result = await paginate(PaymentLedger, req, ['bookingId', 'shopId', 'customerId', 'customerName', 'providerName', 'serviceTitle'], { createdAt: -1 });
  if (Array.isArray(result)) {
    return { ledgers: result };
  } else {
    return {
      ledgers: result.data,
      pagination: result.pagination
    };
  }
}

async function confirmCashCollected(bookingId) {
  const booking = await Booking.findOne({ id: bookingId });
  if (!booking) {
    throw new Error('Booking not found');
  }

  const ledger = await PaymentLedger.findOne({ bookingId });
  if (!ledger) {
    throw new Error('Ledger not found for this booking');
  }

  if (ledger.paymentStatus !== 'cash_pending' && ledger.paymentStatus !== 'commission_pending') {
    const err = new Error(`Cannot confirm cash for ledger in status: ${ledger.paymentStatus}`);
    err.statusCode = 400;
    throw err;
  }

  ledger.paymentStatus = 'cash_collected';
  await ledger.save();

  await logPaymentEvent('cash_confirmed', {
    bookingId,
    ledgerId: ledger.id,
    shopId: ledger.shopId,
    amount: ledger.grossAmount,
    description: `Cash of ₹${ledger.grossAmount} confirmed collected for booking ${bookingId}`,
    actor: 'provider'
  });

  return ledger;
}

async function collectCommission(shopId, bookingIds, amount, note) {
  const shop = await Shop.findOne({ id: shopId });
  if (!shop) {
    throw new Error('Shop not found');
  }

  const bids = bookingIds || [];
  for (const bid of bids) {
    const ledger = await PaymentLedger.findOne({ bookingId: bid });
    if (ledger) {
      ledger.commissionStatus = 'paid';
      ledger.paymentStatus = 'settled';
      await ledger.save();
    }
  }

  const collectedAmt = parseFloat(amount) || 0;
  if (collectedAmt > 0) {
    shop.walletBalance = (shop.walletBalance || 0) + collectedAmt;
    if (!shop.walletTransactions) shop.walletTransactions = [];
    shop.walletTransactions.push({
      id: `TX-COMM-COLL-${Date.now()}`,
      title: `Commission Collected by Admin${note ? ': ' + note : ''}`,
      amount: collectedAmt,
      type: 'credit',
      date: new Date()
    });
    await shop.save();
  }

  await logPaymentEvent('commission_collected', {
    shopId,
    amount: collectedAmt,
    description: `Commission collected from shop ${shopId}. Bookings: ${bids.join(', ')}`,
    actor: 'admin',
    metadata: { bookingIds: bids, note }
  });
}

async function getAllSettlements(req) {
  const result = await paginate(Settlement, req, ['id', 'shopId', 'providerName', 'status', 'bankDetails.accountNumber'], { requestedAt: -1 });
  if (Array.isArray(result)) {
    return { settlements: result };
  } else {
    return {
      settlements: result.data,
      pagination: result.pagination
    };
  }
}

async function getSettlementsForShop(shopId, req) {
  req.query.shopId = shopId;
  const result = await paginate(Settlement, req, ['id', 'shopId', 'providerName', 'status'], { requestedAt: -1 });
  if (Array.isArray(result)) {
    return { settlements: result };
  } else {
    return {
      settlements: result.data,
      pagination: result.pagination
    };
  }
}

async function requestSettlement(shopId, amount, bookingIds, settlementType = 'manual') {
  const shop = await Shop.findOne({ id: shopId });
  if (!shop) {
    throw new Error('Shop not found');
  }

  const reqAmt = parseFloat(amount);
  if (isNaN(reqAmt) || reqAmt <= 0) {
    const err = new Error('Invalid settlement amount');
    err.statusCode = 400;
    throw err;
  }

  const pendingSettlement = await Settlement.findOne({ shopId, status: 'pending' });
  if (pendingSettlement) {
    const err = new Error('You already have a pending settlement request');
    err.statusCode = 400;
    throw err;
  }

  const settlement = new Settlement({
    id: `SETTLE-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    shopId,
    providerName: shop.name || shop.ownerName || 'Provider',
    amount: reqAmt,
    settlementType,
    status: 'pending',
    bookingIds: bookingIds || [],
    requestedAt: new Date(),
    bankDetails: shop.bankDetails || {}
  });

  await settlement.save();

  await logPaymentEvent('settlement_requested', {
    shopId,
    amount: reqAmt,
    description: `Settlement request of ₹${reqAmt} submitted by shop ${shopId}`,
    actor: 'provider',
    metadata: { settlementId: settlement.id }
  });

  return settlement;
}

async function approveSettlement(id, adminNote) {
  const settlement = await Settlement.findOne({ id });
  if (!settlement) {
    throw new Error('Settlement not found');
  }

  if (settlement.status !== 'pending') {
    const err = new Error(`Cannot approve settlement in status: ${settlement.status}`);
    err.statusCode = 400;
    throw err;
  }

  settlement.status = 'approved';
  settlement.adminNote = adminNote || '';
  settlement.approvedAt = new Date();
  await settlement.save();

  await logPaymentEvent('settlement_approved', {
    shopId: settlement.shopId,
    amount: settlement.amount,
    description: `Settlement ${id} approved by admin`,
    actor: 'admin',
    metadata: { settlementId: id, adminNote }
  });

  return settlement;
}

async function completeSettlement(id, transactionId, adminNote) {
  const settlement = await Settlement.findOne({ id });
  if (!settlement) {
    throw new Error('Settlement not found');
  }

  if (settlement.status !== 'approved' && settlement.status !== 'pending') {
    const err = new Error(`Cannot complete settlement in status: ${settlement.status}`);
    err.statusCode = 400;
    throw err;
  }

  settlement.status = 'completed';
  settlement.transactionId = transactionId || `TX-BANK-${Date.now()}`;
  settlement.adminNote = adminNote || settlement.adminNote || '';
  settlement.completedAt = new Date();
  await settlement.save();

  const bids = settlement.bookingIds || [];
  for (const bid of bids) {
    const ledger = await PaymentLedger.findOne({ bookingId: bid });
    if (ledger) {
      ledger.settlementStatus = 'settled';
      ledger.settlementId = settlement.id;
      await ledger.save();
    }
  }

  await logPaymentEvent('settlement_completed', {
    shopId: settlement.shopId,
    amount: settlement.amount,
    description: `Settlement ${id} completed. Transferred ₹${settlement.amount} via ${settlement.transactionId}`,
    actor: 'admin',
    metadata: { settlementId: id, transactionId }
  });

  return settlement;
}

async function rejectSettlement(id, adminNote) {
  const settlement = await Settlement.findOne({ id });
  if (!settlement) {
    throw new Error('Settlement not found');
  }

  settlement.status = 'rejected';
  settlement.adminNote = adminNote || '';
  await settlement.save();

  await logPaymentEvent('settlement_rejected', {
    shopId: settlement.shopId,
    amount: settlement.amount,
    description: `Settlement ${id} rejected by admin: ${adminNote}`,
    actor: 'admin',
    metadata: { settlementId: id, adminNote }
  });

  return settlement;
}

async function getPaymentAuditLogs(bookingId, shopId, eventType) {
  const query = {};
  if (bookingId) query.bookingId = bookingId;
  if (shopId) query.shopId = shopId;
  if (eventType) query.eventType = eventType;

  return await PaymentAuditLog.find(query).sort({ createdAt: -1 }).limit(100);
}

async function getProviderDashboard(shopId) {
  const shop = await Shop.findOne({ id: shopId });
  if (!shop) {
    throw new Error('Shop not found');
  }

  const ledgers = await PaymentLedger.find({ shopId });
  const settlements = await Settlement.find({ shopId });

  const totalEarnings = ledgers.reduce((sum, l) => sum + (l.providerEarnings || 0), 0);
  const pendingSettlementAmount = settlements
    .filter(s => s.status === 'pending' || s.status === 'approved')
    .reduce((sum, s) => sum + (s.amount || 0), 0);
  const completedSettlementAmount = settlements
    .filter(s => s.status === 'completed')
    .reduce((sum, s) => sum + (s.amount || 0), 0);
  const availableForSettlement = Math.max(0, totalEarnings - pendingSettlementAmount - completedSettlementAmount);

  return {
    shopId,
    totalEarnings: parseFloat(totalEarnings.toFixed(2)),
    availableForSettlement: parseFloat(availableForSettlement.toFixed(2)),
    pendingSettlements: parseFloat(pendingSettlementAmount.toFixed(2)),
    completedSettlements: parseFloat(completedSettlementAmount.toFixed(2)),
    totalJobsCount: ledgers.length,
    recentLedgers: ledgers.slice(-5).reverse(),
    recentSettlements: settlements.slice(-5).reverse()
  };
}

async function getAdminDashboard() {
  const ledgers = await PaymentLedger.find({});
  const settlements = await Settlement.find({});

  const totalGrossVolume = ledgers.reduce((s, l) => s + (l.grossAmount || 0), 0);
  const totalCommissionEarned = ledgers.reduce((s, l) => s + (l.commissionAmount || 0), 0);
  const totalProviderPayouts = ledgers.reduce((s, l) => s + (l.providerEarnings || 0), 0);
  const pendingSettlementsCount = settlements.filter(s => s.status === 'pending').length;

  return {
    totalGrossVolume: parseFloat(totalGrossVolume.toFixed(2)),
    totalCommissionEarned: parseFloat(totalCommissionEarned.toFixed(2)),
    totalProviderPayouts: parseFloat(totalProviderPayouts.toFixed(2)),
    pendingSettlementsCount,
    totalLedgerEntries: ledgers.length,
    totalSettlementRequests: settlements.length
  };
}

async function getCommissionConfig() {
  let settings = await Settings.findOne({});
  if (!settings) {
    settings = { defaultCommissionRate: 10, commissionType: 'percentage' };
  }
  return {
    defaultCommissionRate: settings.defaultCommissionRate || 10,
    commissionType: settings.commissionType || 'percentage',
    categoryRates: settings.categoryRates || {},
    providerRates: settings.providerRates || {}
  };
}

async function updateCommissionConfig(defaultCommissionRate, commissionType, categoryRates, providerRates) {
  let settings = await Settings.findOne({});
  if (!settings) {
    settings = new Settings({});
  }
  if (defaultCommissionRate !== undefined) settings.defaultCommissionRate = defaultCommissionRate;
  if (commissionType !== undefined) settings.commissionType = commissionType;
  if (categoryRates !== undefined) settings.categoryRates = categoryRates;
  if (providerRates !== undefined) settings.providerRates = providerRates;

  await settings.save();
}

async function getDailyReport(days = 7) {
  const numDays = parseInt(days, 10) || 7;
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - numDays);

  const ledgers = await PaymentLedger.find({ createdAt: { $gte: cutoff } });
  
  const dailyMap = {};
  ledgers.forEach(l => {
    const dateStr = new Date(l.createdAt).toISOString().split('T')[0];
    if (!dailyMap[dateStr]) {
      dailyMap[dateStr] = { date: dateStr, gross: 0, commission: 0, earnings: 0, jobs: 0 };
    }
    dailyMap[dateStr].gross += l.grossAmount || 0;
    dailyMap[dateStr].commission += l.commissionAmount || 0;
    dailyMap[dateStr].earnings += l.providerEarnings || 0;
    dailyMap[dateStr].jobs += 1;
  });

  return Object.values(dailyMap).sort((a, b) => a.date.localeCompare(b.date));
}

async function getCommissionReport() {
  const ledgers = await PaymentLedger.find({});
  const byProvider = {};

  ledgers.forEach(l => {
    if (!byProvider[l.shopId]) {
      byProvider[l.shopId] = {
        shopId: l.shopId,
        providerName: l.providerName,
        totalGross: 0,
        totalCommission: 0,
        commissionPaid: 0,
        commissionPending: 0,
        jobCount: 0
      };
    }
    byProvider[l.shopId].totalGross += l.grossAmount;
    byProvider[l.shopId].totalCommission += l.commissionAmount;
    byProvider[l.shopId].jobCount += 1;
    if (l.commissionStatus === 'paid') {
      byProvider[l.shopId].commissionPaid += l.commissionAmount;
    } else {
      byProvider[l.shopId].commissionPending += l.commissionAmount;
    }
  });

  return Object.values(byProvider).map(p => ({
    ...p,
    totalGross: parseFloat(p.totalGross.toFixed(2)),
    totalCommission: parseFloat(p.totalCommission.toFixed(2)),
    commissionPaid: parseFloat(p.commissionPaid.toFixed(2)),
    commissionPending: parseFloat(p.commissionPending.toFixed(2))
  }));
}

async function getProviderReport(shopId) {
  const ledgers = await PaymentLedger.find({ shopId });
  const settlements = await Settlement.find({ shopId });

  return {
    shopId,
    totalJobsDone: ledgers.length,
    totalGrossBilling: parseFloat(ledgers.reduce((s, l) => s + l.grossAmount, 0).toFixed(2)),
    totalEarnings: parseFloat(ledgers.reduce((s, l) => s + l.providerEarnings, 0).toFixed(2)),
    totalCommissionPaid: parseFloat(ledgers.filter(l => l.commissionStatus === 'paid').reduce((s, l) => s + l.commissionAmount, 0).toFixed(2)),
    totalCommissionPending: parseFloat(ledgers.filter(l => l.commissionStatus === 'pending').reduce((s, l) => s + l.commissionAmount, 0).toFixed(2)),
    cashJobs: ledgers.filter(l => l.paymentMethod === 'cash').length,
    onlineJobs: ledgers.filter(l => l.paymentMethod !== 'cash').length,
    totalSettled: parseFloat(settlements.filter(s => s.status === 'completed').reduce((s, st) => s + st.amount, 0).toFixed(2)),
    pendingSettlements: settlements.filter(s => s.status === 'pending').length,
    ledgers: ledgers.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)),
    settlements: settlements.sort((a, b) => new Date(b.requestedAt || b.createdAt) - new Date(a.requestedAt || a.createdAt))
  };
}

module.exports = {
  createRazorpayOrder,
  verifyRazorpayPayment,
  handleRazorpayWebhook,
  getLedgerForBooking,
  getLedgerForShop,
  getAllLedgerEntries,
  confirmCashCollected,
  collectCommission,
  getAllSettlements,
  getSettlementsForShop,
  requestSettlement,
  approveSettlement,
  completeSettlement,
  rejectSettlement,
  getPaymentAuditLogs,
  getProviderDashboard,
  getAdminDashboard,
  getCommissionConfig,
  updateCommissionConfig,
  getDailyReport,
  getCommissionReport,
  getProviderReport
};
