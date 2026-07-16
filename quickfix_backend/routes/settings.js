const express = require('express');
const router = express.Router();
const { requireAuth, requireAdmin } = require('../middleware/auth');
const settingsController = require('../controllers/settingsController');
const settingsValidator = require('../validators/settingsValidator');

// --- DEMAND ENDPOINTS ---
router.post('/demand/submit', settingsValidator.validateDemandSubmit, settingsController.submitDemand);
router.get('/demand', settingsController.getDemands);

// --- CATEGORY ENDPOINTS ---
router.get('/categories', settingsController.getCategories);
router.post('/categories/upload-image', requireAdmin, settingsValidator.validateCategoryUploadImage, settingsController.uploadCategoryImage);
router.post('/categories/create', requireAdmin, settingsValidator.validateCategoryCreate, settingsController.createCategory);
router.post('/categories/update', requireAdmin, settingsValidator.validateCategoryUpdate, settingsController.updateCategory);
router.delete('/categories/:id', requireAdmin, settingsController.deleteCategory);

// --- BANNERS ENDPOINTS ---
router.post('/banners/upload-image', requireAdmin, settingsValidator.validateBannerUploadImage, settingsController.uploadBannerImage);
router.post('/banners/update', settingsController.updateBanner);

// --- OFFERS & COUPONS ENDPOINTS ---
router.post('/offers/update', settingsController.updateOffer);
router.post('/offers/toggle', settingsController.toggleOffer);
router.delete('/offers/:code', settingsController.deleteOffer);
router.post('/coupons/validate', settingsValidator.validateCouponValidate, settingsController.validateCoupon);

// --- PRICING CHECKOUT ENDPOINT ---
router.post('/checkout/calculate', settingsValidator.validateCheckoutCalculate, settingsController.calculateCheckout);

// --- GLOBAL SETTINGS ENDPOINTS ---
router.get('/settings', settingsController.getSettings);
router.post('/settings', settingsController.updateSettings);

// --- AUDIT LOGS ENDPOINTS ---
router.get('/audit-logs', settingsController.getAuditLogs);
router.post('/audit-logs', settingsController.createAuditLog);

// --- REVIEWS FEED ENDPOINTS ---
router.get('/reviews', settingsController.getReviews);
router.get('/admin/reviews', settingsController.getAdminReviews);
router.post('/reviews/approve', settingsController.approveReview);
router.post('/reviews', settingsController.saveReview);
router.delete('/reviews/:id', settingsController.deleteReview);

// --- PROFESSIONALS ENDPOINTS ---
router.get('/professionals', settingsController.getProfessionals);

// --- HOMEPAGE LAYOUTS ENDPOINTS ---
router.get('/homepage/layout', settingsController.getHomepageLayout);
router.get('/homepage/layout/admin', settingsController.getAdminHomepageLayout);
router.post('/homepage/layout/update', settingsController.updateHomepageLayout);
router.post('/homepage/layout/reorder', settingsController.reorderHomepageLayout);

// --- CUSTOM SECTIONS ENDPOINTS ---
router.get('/custom-sections', settingsController.getCustomSections);
router.get('/admin/custom-sections', settingsController.getAdminCustomSections);
router.get('/custom-sections/:id', settingsController.getCustomSectionById);
router.post('/custom-sections', settingsController.saveCustomSection);
router.delete('/custom-sections/:id', settingsController.deleteCustomSection);

// --- ADMIN MANAGEMENT ENDPOINTS ---
router.post('/admin/login', settingsController.adminLogin);
router.get('/admin/stats', requireAdmin, settingsController.getAdminStats);
router.get('/reports/summary', requireAdmin, settingsController.getReportsSummary);

// --- CUSTOMER MANAGEMENT ---
router.get('/users', requireAdmin, settingsController.getUsers);
router.post('/users/wallet-adjust', requireAdmin, settingsValidator.validateWalletAdjust, settingsController.adjustUserWallet);
router.post('/users/toggle-status', settingsController.toggleUserStatus);

module.exports = router;
