const express = require('express');
const router = express.Router();
const { requireAuth, requireAdmin } = require('../middleware/auth');
const paymentController = require('../controllers/paymentController');
const paymentValidator = require('../validators/paymentValidator');

// --- PAYMENT LEDGER ROUTES ---

// Get ledger entry for a specific booking
router.get('/ledger/:bookingId', requireAuth, paymentValidator.validateGetLedgerForBooking, paymentController.getLedgerForBooking);

// Get all ledger entries for a provider
router.get('/ledger/shop/:shopId', requireAuth, paymentValidator.validateGetLedgerForShop, paymentController.getLedgerForShop);

// Admin: get all ledger entries (with optional filters)
router.get('/ledger', requireAdmin, paymentController.getAllLedgerEntries);

// Provider: confirm cash collected (marks ledger as cash_collected)
router.post('/cash-confirm/:bookingId', requireAuth, paymentValidator.validateCashConfirm, paymentController.confirmCashCollected);

// Admin: mark commission collected from provider (for cash bookings)
router.post('/commission-collect/:shopId', requireAdmin, paymentValidator.validateCommissionCollect, paymentController.collectCommission);


// --- SETTLEMENT ROUTES ---

// Admin: get all settlements
router.get('/settlements', requireAdmin, paymentController.getAllSettlements);

// Provider: get their settlements
router.get('/settlements/shop/:shopId', requireAuth, paymentValidator.validateGetLedgerForShop, paymentController.getSettlementsForShop);

// Provider: request a settlement
router.post('/settlements/request', requireAuth, paymentValidator.validateSettlementRequest, paymentController.requestSettlement);

// Admin: approve a settlement
router.post('/settlements/:id/approve', requireAdmin, paymentValidator.validateSettlementAction, paymentController.approveSettlement);

// Admin: complete a settlement (money transferred)
router.post('/settlements/:id/complete', requireAdmin, paymentValidator.validateSettlementAction, paymentController.completeSettlement);

// Admin: reject/fail a settlement
router.post('/settlements/:id/reject', requireAdmin, paymentValidator.validateSettlementAction, paymentController.rejectSettlement);


// --- PAYMENT AUDIT LOG ROUTES ---

router.get('/audit-logs', requireAdmin, paymentController.getPaymentAuditLogs);


// --- PAYMENT DASHBOARD ROUTES ---

// Provider payment dashboard stats
router.get('/dashboard/provider/:shopId', requireAuth, paymentValidator.validateGetLedgerForShop, paymentController.getProviderDashboard);

// Admin payment dashboard stats
router.get('/dashboard/admin', requireAdmin, paymentController.getAdminDashboard);


// --- COMMISSION CONFIG ROUTES ---

router.get('/commission-config', requireAdmin, paymentController.getCommissionConfig);
router.post('/commission-config', requireAdmin, paymentController.updateCommissionConfig);


// --- PAYMENT REPORTS ---

router.get('/reports/daily', requireAdmin, paymentController.getDailyReport);
router.get('/reports/commission', requireAdmin, paymentController.getCommissionReport);
router.get('/reports/provider/:shopId', requireAuth, paymentValidator.validateGetLedgerForShop, paymentController.getProviderReport);

module.exports = router;
