const express = require('express');
const router = express.Router();
const { requireAuth, requireAdmin } = require('../middleware/auth');
const settingsController = require('../controllers/settingsController');
const settingsValidator = require('../validators/settingsValidator');
const { adminLoginLimiter, publicLimiter } = require('../middleware/rateLimiter');

// --- DEMAND ENDPOINTS ---
router.post('/demand/submit', settingsValidator.validateDemandSubmit, settingsController.submitDemand);
router.get('/demand', settingsController.getDemands);

// --- CATEGORY ENDPOINTS ---
router.get('/categories', publicLimiter, settingsController.getCategories);
router.post('/categories/upload-image', requireAdmin, settingsValidator.validateCategoryUploadImage, settingsController.uploadCategoryImage);
router.post('/categories/create', requireAdmin, settingsValidator.validateCategoryCreate, settingsController.createCategory);
router.post('/categories/update', requireAdmin, settingsValidator.validateCategoryUpdate, settingsController.updateCategory);
router.delete('/categories/:id', requireAdmin, settingsController.deleteCategory);

// --- BANNERS ENDPOINTS ---
router.post('/banners/upload-image', requireAdmin, settingsValidator.validateBannerUploadImage, settingsController.uploadBannerImage);
router.post('/banners/update', requireAdmin, settingsController.updateBanner);

// --- OFFERS & COUPONS ENDPOINTS ---
router.post('/offers/update', requireAdmin, settingsController.updateOffer);
router.post('/offers/toggle', requireAdmin, settingsController.toggleOffer);
router.delete('/offers/:code', requireAdmin, settingsController.deleteOffer);
router.post('/coupons/validate', settingsValidator.validateCouponValidate, settingsController.validateCoupon);

// --- PRICING CHECKOUT ENDPOINT ---
router.post('/checkout/calculate', settingsValidator.validateCheckoutCalculate, settingsController.calculateCheckout);

// --- GLOBAL SETTINGS ENDPOINTS ---
router.get('/settings', publicLimiter, settingsController.getSettings);
router.post('/settings', requireAdmin, settingsController.updateSettings);

// --- AUDIT LOGS ENDPOINTS ---
router.get('/audit-logs', requireAdmin, settingsController.getAuditLogs);
router.post('/audit-logs', requireAdmin, settingsController.createAuditLog);

// --- REVIEWS FEED ENDPOINTS ---
router.get('/reviews', publicLimiter, settingsController.getReviews);
router.get('/admin/reviews', requireAdmin, settingsController.getAdminReviews);
router.post('/reviews/approve', requireAdmin, settingsController.approveReview);
router.post('/reviews', requireAuth, settingsController.saveReview);
router.delete('/reviews/:id', requireAdmin, settingsController.deleteReview);

// --- PROFESSIONALS ENDPOINTS ---
router.get('/professionals', publicLimiter, settingsController.getProfessionals);

// --- HOMEPAGE LAYOUTS ENDPOINTS ---
router.get('/homepage/layout', publicLimiter, settingsController.getHomepageLayout);
router.get('/homepage/layout/admin', requireAdmin, settingsController.getAdminHomepageLayout);
router.post('/homepage/layout/update', requireAdmin, settingsController.updateHomepageLayout);
router.post('/homepage/layout/reorder', requireAdmin, settingsController.reorderHomepageLayout);

// --- CUSTOM SECTIONS ENDPOINTS ---
router.get('/custom-sections', publicLimiter, settingsController.getCustomSections);
router.get('/admin/custom-sections', requireAdmin, settingsController.getAdminCustomSections);
router.get('/custom-sections/:id', publicLimiter, settingsController.getCustomSectionById);
router.post('/custom-sections', requireAdmin, settingsController.saveCustomSection);
router.delete('/custom-sections/:id', requireAdmin, settingsController.deleteCustomSection);

// --- ADMIN MANAGEMENT ENDPOINTS ---
router.post('/admin/login', adminLoginLimiter, settingsController.adminLogin);
router.get('/admin/stats', requireAdmin, settingsController.getAdminStats);
router.get('/reports/summary', requireAdmin, settingsController.getReportsSummary);

// --- CUSTOMER MANAGEMENT ---
router.get('/users', requireAdmin, settingsController.getUsers);
router.post('/users/wallet-adjust', requireAdmin, settingsValidator.validateWalletAdjust, settingsController.adjustUserWallet);
router.post('/users/toggle-status', requireAdmin, settingsController.toggleUserStatus);

module.exports = router;
