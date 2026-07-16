const { PaymentLedger, Settlement, PaymentAuditLog, Booking, Shop, Settings } = require('../models');
const { logPaymentEvent, sendFcmNotification, sendFcmTopicNotification, paginate } = require('../helpers');

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
    description: `Commission ₹${collectedAmt} collected from provider ${shopId}. ${note || ''}`,
    actor: 'admin',
    metadata: { bookingIds: bids, note }
  });
}

async function getAllSettlements(req) {
  const result = await paginate(Settlement, req, ['id', 'shopId', 'status'], { requestedAt: -1 });
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
  const result = await paginate(Settlement, req, ['id', 'shopId', 'status'], { requestedAt: -1 });
  if (Array.isArray(result)) {
    return { settlements: result };
  } else {
    return {
      settlements: result.data,
      pagination: result.pagination
    };
  }
}

async function requestSettlement(shopId, amount, bookingIds, settlementType) {
  const shop = await Shop.findOne({ id: shopId });
  if (!shop) {
    throw new Error('Shop not found');
  }

  const requestAmt = parseFloat(amount);
  if (requestAmt <= 0) {
    const err = new Error('Amount must be greater than 0');
    err.statusCode = 400;
    throw err;
  }
  if ((shop.walletBalance || 0) < requestAmt) {
    const err = new Error(`Insufficient wallet balance. Available: ₹${shop.walletBalance || 0}`);
    err.statusCode = 400;
    throw err;
  }

  const settlementId = `SET-${Date.now()}`;
  const settlement = new Settlement({
    id: settlementId,
    shopId: shop.id,
    providerId: shop.id,
    providerName: shop.ownerName || shop.name,
    settlementType: settlementType || 'manual',
    amount: requestAmt,
    bookingIds: bookingIds || [],
    status: 'pending',
    bankAccount: shop.bankAccountNumber || '',
    ifscCode: shop.ifscCode || '',
    upiId: shop.upiId || '',
    requestedAt: new Date()
  });
  await settlement.save();

  if (bookingIds && bookingIds.length > 0) {
    for (const bid of bookingIds) {
      const ledger = await PaymentLedger.findOne({ bookingId: bid });
      if (ledger && ledger.paymentStatus === 'settlement_pending') {
        ledger.settlementId = settlementId;
        await ledger.save();
      }
    }
  }

  await logPaymentEvent('settlement_created', {
    shopId,
    settlementId,
    amount: requestAmt,
    description: `Settlement request ₹${requestAmt} created by provider ${shopId}`,
    actor: 'provider'
  });

  sendFcmTopicNotification('admins', '💰 Settlement Request', `${shop.name} has requested a settlement of ₹${requestAmt}`, {
    type: 'settlement_request',
    settlementId
  }).catch(() => {});

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
    settlementId: id,
    amount: settlement.amount,
    description: `Settlement ${id} approved by admin`,
    actor: 'admin',
    metadata: { adminNote }
  });

  sendFcmNotification(settlement.shopId, '✅ Settlement Approved', `Your settlement of ₹${settlement.amount} has been approved and will be processed soon.`, { type: 'settlement_approved', settlementId: id }, 'partner').catch(() => {});

  return settlement;
}

async function completeSettlement(id, transactionId, adminNote) {
  const settlement = await Settlement.findOne({ id });
  if (!settlement) {
    throw new Error('Settlement not found');
  }
  if (!['approved', 'processing'].includes(settlement.status)) {
    const err = new Error(`Cannot complete settlement in status: ${settlement.status}`);
    err.statusCode = 400;
    throw err;
  }

  settlement.status = 'completed';
  settlement.transactionId = transactionId || '';
  settlement.adminNote = adminNote || settlement.adminNote;
  settlement.completedAt = new Date();
  await settlement.save();

  const shop = await Shop.findOne({ id: settlement.shopId });
  if (shop) {
    shop.walletBalance = Math.max(0, (shop.walletBalance || 0) - settlement.amount);
    if (!shop.walletTransactions) shop.walletTransactions = [];
    shop.walletTransactions.push({
      id: `TX-SET-${Date.now()}`,
      title: `Settlement Paid ${id}${transactionId ? ' | Txn: ' + transactionId : ''}`,
      amount: settlement.amount,
      type: 'debit',
      date: new Date()
    });
    await shop.save();
  }

  for (const bid of (settlement.bookingIds || [])) {
    const ledger = await PaymentLedger.findOne({ bookingId: bid });
    if (ledger) {
      ledger.paymentStatus = 'settled';
      ledger.settlementId = id;
      await ledger.save();
    }
  }

  await logPaymentEvent('settlement_completed', {
    shopId: settlement.shopId,
    settlementId: id,
    amount: settlement.amount,
    description: `Settlement ${id} completed. TxnID: ${transactionId || 'N/A'}`,
    actor: 'admin',
    metadata: { transactionId }
  });

  sendFcmNotification(settlement.shopId, '💸 Settlement Completed', `₹${settlement.amount} has been transferred to your account. Reference: ${transactionId || 'N/A'}`, { type: 'settlement_completed', settlementId: id }, 'partner').catch(() => {});

  return settlement;
}

async function rejectSettlement(id, adminNote) {
  const settlement = await Settlement.findOne({ id });
  if (!settlement) {
    throw new Error('Settlement not found');
  }

  settlement.status = 'rejected';
  settlement.adminNote = adminNote || '';
  settlement.rejectedAt = new Date();
  await settlement.save();

  await logPaymentEvent('settlement_failed', {
    shopId: settlement.shopId,
    settlementId: id,
    amount: settlement.amount,
    description: `Settlement ${id} rejected by admin. Reason: ${adminNote || 'Not specified'}`,
    actor: 'admin'
  });

  sendFcmNotification(settlement.shopId, '❌ Settlement Rejected', `Your settlement request of ₹${settlement.amount} was rejected. Reason: ${adminNote || 'Contact support'}`, { type: 'settlement_rejected', settlementId: id }, 'partner').catch(() => {});

  return settlement;
}

async function getPaymentAuditLogs(bookingId, shopId, eventType) {
  let logs = await PaymentAuditLog.find({});
  if (bookingId) logs = logs.filter(l => l.bookingId === bookingId);
  if (shopId) logs = logs.filter(l => l.shopId === shopId);
  if (eventType) logs = logs.filter(l => l.eventType === eventType);
  logs.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  return logs;
}

async function getProviderDashboard(shopId) {
  const shop = await Shop.findOne({ id: shopId });
  if (!shop) {
    throw new Error('Shop not found');
  }

  const ledgers = await PaymentLedger.find({ shopId });
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todayLedgers = ledgers.filter(l => new Date(l.createdAt) >= today);

  const todayCash = todayLedgers.filter(l => l.paymentMethod === 'cash').reduce((s, l) => s + l.grossAmount, 0);
  const todayOnline = todayLedgers.filter(l => l.paymentMethod !== 'cash').reduce((s, l) => s + l.grossAmount, 0);
  const todayEarnings = todayLedgers.reduce((s, l) => s + l.providerEarnings, 0);
  const todayCommission = todayLedgers.reduce((s, l) => s + l.commissionAmount, 0);

  const totalEarnings = ledgers.reduce((s, l) => s + l.providerEarnings, 0);
  const totalCommission = ledgers.reduce((s, l) => s + l.commissionAmount, 0);

  const commissionDue = ledgers
    .filter(l => l.commissionStatus === 'pending' && l.paymentMethod === 'cash')
    .reduce((s, l) => s + l.commissionAmount, 0);

  const pendingSettlements = await Settlement.find({ shopId, status: 'pending' });
  const pendingSettlementAmount = pendingSettlements.reduce((s, st) => s + st.amount, 0);

  const completedSettlements = await Settlement.find({ shopId, status: 'completed' });
  const totalSettled = completedSettlements.reduce((s, st) => s + st.amount, 0);

  const cashLedgers = ledgers.filter(l => l.paymentMethod === 'cash' && l.paymentStatus === 'cash_collected');
  const onlineLedgers = ledgers.filter(l => l.paymentMethod !== 'cash');

  return {
    walletBalance: shop.walletBalance || 0,
    commissionRate: shop.commissionRate || 20,
    today: {
      totalEarnings: parseFloat(todayEarnings.toFixed(2)),
      cashCollected: parseFloat(todayCash.toFixed(2)),
      onlineEarnings: parseFloat(todayOnline.toFixed(2)),
      commissionDeducted: parseFloat(todayCommission.toFixed(2))
    },
    overall: {
      totalEarnings: parseFloat(totalEarnings.toFixed(2)),
      totalCommission: parseFloat(totalCommission.toFixed(2)),
      commissionDue: parseFloat(commissionDue.toFixed(2)),
      cashJobsCount: cashLedgers.length,
      onlineJobsCount: onlineLedgers.length
    },
    settlement: {
      pendingAmount: parseFloat(pendingSettlementAmount.toFixed(2)),
      pendingCount: pendingSettlements.length,
      totalSettled: parseFloat(totalSettled.toFixed(2)),
      completedCount: completedSettlements.length
    }
  };
}

async function getAdminDashboard() {
  const ledgers = await PaymentLedger.find({});
  const settlements = await Settlement.find({});
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todayLedgers = ledgers.filter(l => new Date(l.createdAt) >= today);

  const totalGross = ledgers.reduce((s, l) => s + l.grossAmount, 0);
  const totalCommission = ledgers.reduce((s, l) => s + l.commissionAmount, 0);
  const totalProviderEarnings = ledgers.reduce((s, l) => s + l.providerEarnings, 0);

  const todayGross = todayLedgers.reduce((s, l) => s + l.grossAmount, 0);
  const todayCommission = todayLedgers.reduce((s, l) => s + l.commissionAmount, 0);

  const cashLedgers = ledgers.filter(l => l.paymentMethod === 'cash');
  const onlineLedgers = ledgers.filter(l => l.paymentMethod !== 'cash');

  const cashCollection = cashLedgers.reduce((s, l) => s + l.grossAmount, 0);
  const onlineCollection = onlineLedgers.reduce((s, l) => s + l.grossAmount, 0);

  const outstandingCommission = ledgers
    .filter(l => l.commissionStatus === 'pending' && l.paymentMethod === 'cash')
    .reduce((s, l) => s + l.commissionAmount, 0);

  const pendingSettlements = settlements.filter(s => s.status === 'pending');
  const completedSettlements = settlements.filter(s => s.status === 'completed');
  const pendingSettlementAmount = pendingSettlements.reduce((s, st) => s + st.amount, 0);
  const totalSettled = completedSettlements.reduce((s, st) => s + st.amount, 0);

  const shops = await Shop.find({});
  const providerWallets = shops.map(s => ({
    shopId: s.id,
    shopName: s.name,
    walletBalance: s.walletBalance || 0,
    commissionRate: s.commissionRate || 20
  }));

  return {
    today: {
      grossRevenue: parseFloat(todayGross.toFixed(2)),
      commissionEarned: parseFloat(todayCommission.toFixed(2)),
      cashCollection: parseFloat(cashLedgers.filter(l => new Date(l.createdAt) >= today).reduce((s, l) => s + l.grossAmount, 0).toFixed(2)),
      onlineCollection: parseFloat(onlineLedgers.filter(l => new Date(l.createdAt) >= today).reduce((s, l) => s + l.grossAmount, 0).toFixed(2))
    },
    overall: {
      totalGrossRevenue: parseFloat(totalGross.toFixed(2)),
      totalCommissionEarned: parseFloat(totalCommission.toFixed(2)),
      totalProviderEarnings: parseFloat(totalProviderEarnings.toFixed(2)),
      cashCollection: parseFloat(cashCollection.toFixed(2)),
      onlineCollection: parseFloat(onlineCollection.toFixed(2)),
      outstandingCommission: parseFloat(outstandingCommission.toFixed(2))
    },
    settlements: {
      pendingCount: pendingSettlements.length,
      pendingAmount: parseFloat(pendingSettlementAmount.toFixed(2)),
      completedCount: completedSettlements.length,
      totalSettled: parseFloat(totalSettled.toFixed(2))
    },
    providerWallets
  };
}

async function getCommissionConfig() {
  const settings = await Settings.find({});
  const config = {};
  settings.forEach(s => { config[s.key] = s.value; });
  return {
    defaultCommissionRate: parseFloat(config.defaultCommissionRate || '20'),
    commissionType: config.commissionType || 'percentage',
    categoryRates: config.categoryRates ? JSON.parse(typeof config.categoryRates === 'string' ? config.categoryRates : JSON.stringify(config.categoryRates)) : {},
    providerRates: config.providerRates ? JSON.parse(typeof config.providerRates === 'string' ? config.providerRates : JSON.stringify(config.providerRates)) : {}
  };
}

async function updateCommissionConfig(defaultCommissionRate, commissionType, categoryRates, providerRates) {
  const updates = [];
  if (defaultCommissionRate !== undefined) updates.push({ key: 'defaultCommissionRate', value: parseFloat(defaultCommissionRate) });
  if (commissionType !== undefined) updates.push({ key: 'commissionType', value: commissionType });
  if (categoryRates !== undefined) updates.push({ key: 'categoryRates', value: categoryRates });
  if (providerRates !== undefined) updates.push({ key: 'providerRates', value: providerRates });

  for (const { key, value } of updates) {
    await Settings.findOneAndUpdate({ key }, { key, value }, { upsert: true });
  }

  await logPaymentEvent('ledger_updated', {
    description: `Commission config updated: rate=${defaultCommissionRate}%, type=${commissionType}`,
    actor: 'admin',
    metadata: { defaultCommissionRate, commissionType }
  });
}

async function getDailyReport(days) {
  const ledgers = await PaymentLedger.find({});
  const report = [];

  for (let i = parseInt(days) - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    d.setHours(0, 0, 0, 0);
    const dEnd = new Date(d);
    dEnd.setHours(23, 59, 59, 999);

    const dayLedgers = ledgers.filter(l => {
      const ld = new Date(l.createdAt);
      return ld >= d && ld <= dEnd;
    });

    report.push({
      date: d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
      dateIso: d.toISOString().split('T')[0],
      grossRevenue: parseFloat(dayLedgers.reduce((s, l) => s + l.grossAmount, 0).toFixed(2)),
      commissionEarned: parseFloat(dayLedgers.reduce((s, l) => s + l.commissionAmount, 0).toFixed(2)),
      providerEarnings: parseFloat(dayLedgers.reduce((s, l) => s + l.providerEarnings, 0).toFixed(2)),
      cashCollection: parseFloat(dayLedgers.filter(l => l.paymentMethod === 'cash').reduce((s, l) => s + l.grossAmount, 0).toFixed(2)),
      onlineCollection: parseFloat(dayLedgers.filter(l => l.paymentMethod !== 'cash').reduce((s, l) => s + l.grossAmount, 0).toFixed(2)),
      bookingsCount: dayLedgers.length
    });
  }

  return report;
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
