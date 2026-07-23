const paymentService = require('../services/paymentService');
const { logger } = require('../config/logger');

async function createRazorpayOrder(req, res) {
  const { bookingId } = req.body;
  if (!bookingId) {
    return res.status(400).json({ success: false, error: 'bookingId is required to create a payment order' });
  }
  try {
    const orderData = await paymentService.createRazorpayOrder(bookingId, req.user.id);
    res.json({ success: true, ...orderData });
  } catch (e) {
    if (e.message === 'Booking not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    logger.error('Razorpay order creation error:', e);
    res.status(e.statusCode || 500).json({ success: false, error: e.message || 'Failed to create payment order' });
  }
}

async function verifyRazorpayPayment(req, res) {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature, bookingId } = req.body;
  if (!razorpayOrderId || !razorpayPaymentId) {
    return res.status(400).json({ success: false, error: 'razorpayOrderId and razorpayPaymentId are required' });
  }
  try {
    const result = await paymentService.verifyRazorpayPayment(razorpayOrderId, razorpayPaymentId, razorpaySignature, bookingId);
    res.json(result);
  } catch (e) {
    if (e.message === 'Booking associated with payment order not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    logger.error('Razorpay payment verification error:', e);
    res.status(e.statusCode || 500).json({ success: false, error: e.message || 'Failed to verify payment' });
  }
}

async function handleRazorpayWebhook(req, res) {
  try {
    const result = await paymentService.handleRazorpayWebhook(req.headers, req.body);
    res.json(result);
  } catch (e) {
    logger.error('Razorpay webhook processing error:', e);
    res.status(e.statusCode || 500).json({ success: false, error: e.message || 'Webhook processing failed' });
  }
}

async function getLedgerForBooking(req, res) {
  try {
    const ledger = await paymentService.getLedgerForBooking(req.params.bookingId);
    res.json({ success: true, ledger });
  } catch (e) {
    if (e.message === 'No ledger found for this booking') {
      return res.status(404).json({ success: false, error: e.message });
    }
    res.status(500).json({ success: false, error: 'Failed to fetch payment ledger' });
  }
}

async function getLedgerForShop(req, res) {
  const { shopId } = req.params;
  try {
    if (req.user.role !== 'admin' && req.user.shopId !== shopId && req.user.id !== shopId) {
      return res.status(403).json({ success: false, error: "Forbidden: You do not have access to this shop's ledger" });
    }
    const result = await paymentService.getLedgerForShop(shopId, req);
    res.json({ success: true, ...result });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch provider ledger' });
  }
}

async function getAllLedgerEntries(req, res) {
  try {
    const { from, to } = req.query;
    const result = await paymentService.getAllLedgerEntries(req, from, to);
    res.json({ success: true, ...result });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch all ledger entries' });
  }
}

async function confirmCashCollected(req, res) {
  const { bookingId } = req.params;
  try {
    const ledger = await paymentService.confirmCashCollected(bookingId);
    res.json({ success: true, ledger });
  } catch (e) {
    if (e.message === 'Booking not found' || e.message === 'Ledger not found for this booking') {
      return res.status(404).json({ success: false, error: e.message });
    }
    if (e.statusCode === 400) {
      return res.status(400).json({ success: false, error: e.message });
    }
    logger.error('Cash confirm error:', e);
    res.status(500).json({ success: false, error: 'Failed to confirm cash collection' });
  }
}

async function collectCommission(req, res) {
  const { shopId } = req.params;
  const { bookingIds, amount, note } = req.body;
  try {
    await paymentService.collectCommission(shopId, bookingIds, amount, note);
    res.json({ success: true, message: 'Commission marked as collected' });
  } catch (e) {
    if (e.message === 'Shop not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    logger.error('Commission collect error:', e);
    res.status(500).json({ success: false, error: 'Failed to collect commission' });
  }
}

async function getAllSettlements(req, res) {
  try {
    const result = await paymentService.getAllSettlements(req);
    res.json({ success: true, ...result });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch settlements' });
  }
}

async function getSettlementsForShop(req, res) {
  const { shopId } = req.params;
  try {
    if (req.user.role !== 'admin' && req.user.shopId !== shopId && req.user.id !== shopId) {
      return res.status(403).json({ success: false, error: "Forbidden: You do not have access to this shop's settlements" });
    }
    const result = await paymentService.getSettlementsForShop(shopId, req);
    res.json({ success: true, ...result });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch provider settlements' });
  }
}

async function requestSettlement(req, res) {
  const { shopId, amount, bookingIds, settlementType } = req.body;
  if (req.user.role !== 'admin' && req.user.shopId !== shopId && req.user.id !== shopId) {
    return res.status(403).json({ success: false, error: 'Forbidden: You cannot request settlements for another shop' });
  }
  try {
    const settlement = await paymentService.requestSettlement(shopId, amount, bookingIds, settlementType);
    res.json({ success: true, settlement });
  } catch (e) {
    if (e.message === 'Shop not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    if (e.statusCode === 400) {
      return res.status(400).json({ success: false, error: e.message });
    }
    logger.error('Settlement request error:', e);
    res.status(500).json({ success: false, error: 'Failed to create settlement request' });
  }
}

async function approveSettlement(req, res) {
  const { id } = req.params;
  const { adminNote } = req.body;
  try {
    const settlement = await paymentService.approveSettlement(id, adminNote);
    res.json({ success: true, settlement });
  } catch (e) {
    if (e.message === 'Settlement not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    if (e.statusCode === 400) {
      return res.status(400).json({ success: false, error: e.message });
    }
    res.status(500).json({ success: false, error: 'Failed to approve settlement' });
  }
}

async function completeSettlement(req, res) {
  const { id } = req.params;
  const { transactionId, adminNote } = req.body;
  try {
    const settlement = await paymentService.completeSettlement(id, transactionId, adminNote);
    res.json({ success: true, settlement });
  } catch (e) {
    if (e.message === 'Settlement not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    if (e.statusCode === 400) {
      return res.status(400).json({ success: false, error: e.message });
    }
    res.status(500).json({ success: false, error: 'Failed to complete settlement' });
  }
}

async function rejectSettlement(req, res) {
  const { id } = req.params;
  const { adminNote } = req.body;
  try {
    const settlement = await paymentService.rejectSettlement(id, adminNote);
    res.json({ success: true, settlement });
  } catch (e) {
    if (e.message === 'Settlement not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    res.status(500).json({ success: false, error: 'Failed to reject settlement' });
  }
}

async function getPaymentAuditLogs(req, res) {
  try {
    const { bookingId, shopId, eventType } = req.query;
    const logs = await paymentService.getPaymentAuditLogs(bookingId, shopId, eventType);
    res.json({ success: true, logs });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch payment audit logs' });
  }
}

async function getProviderDashboard(req, res) {
  const { shopId } = req.params;
  try {
    if (req.user.role !== 'admin' && req.user.shopId !== shopId && req.user.id !== shopId) {
      return res.status(403).json({ success: false, error: "Forbidden: You do not have access to this shop's dashboard" });
    }
    const stats = await paymentService.getProviderDashboard(shopId);
    res.json(stats);
  } catch (e) {
    if (e.message === 'Shop not found') {
      return res.status(404).json({ success: false, error: e.message });
    }
    logger.error('Provider payment dashboard error:', e);
    res.status(500).json({ success: false, error: 'Failed to fetch provider payment dashboard' });
  }
}

async function getAdminDashboard(req, res) {
  try {
    const stats = await paymentService.getAdminDashboard();
    res.json(stats);
  } catch (e) {
    logger.error('Admin payment dashboard error:', e);
    res.status(500).json({ success: false, error: 'Failed to fetch admin payment dashboard' });
  }
}

async function getCommissionConfig(req, res) {
  try {
    const config = await paymentService.getCommissionConfig();
    res.json(config);
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to fetch commission config' });
  }
}

async function updateCommissionConfig(req, res) {
  const { defaultCommissionRate, commissionType, categoryRates, providerRates } = req.body;
  try {
    await paymentService.updateCommissionConfig(defaultCommissionRate, commissionType, categoryRates, providerRates);
    res.json({ success: true, message: 'Commission configuration updated' });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to update commission config' });
  }
}

async function getDailyReport(req, res) {
  try {
    const { days = 7 } = req.query;
    const report = await paymentService.getDailyReport(days);
    res.json({ success: true, report });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to generate daily report' });
  }
}

async function getCommissionReport(req, res) {
  try {
    const report = await paymentService.getCommissionReport();
    res.json({ success: true, report });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to generate commission report' });
  }
}

async function getProviderReport(req, res) {
  const { shopId } = req.params;
  try {
    if (req.user.role !== 'admin' && req.user.shopId !== shopId && req.user.id !== shopId) {
      return res.status(403).json({ success: false, error: "Forbidden: You do not have access to this shop's reports" });
    }
    const report = await paymentService.getProviderReport(shopId);
    res.json({ success: true, report });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed to generate provider report' });
  }
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
