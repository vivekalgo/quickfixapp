const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const providerController = require('../controllers/providerController');
const providerValidator = require('../validators/providerValidator');

// 1. Provider Login
router.post('/login', providerValidator.validateLogin, providerController.login);

// 2. Change Password
router.post('/change-password', requireAuth, providerValidator.validateChangePassword, providerController.changePassword);

// 3. Update Provider FCM Token
router.post('/update-fcm', requireAuth, providerController.updateFcm);

// 4. Provider Dashboard Stats
router.get('/dashboard/:shopId', requireAuth, providerController.getDashboard);

// 5. Toggle Online/Offline
router.post('/toggle-online', requireAuth, providerValidator.validateToggleOnline, providerController.toggleOnline);

// 6. Update Shop Services
router.post('/update-services', requireAuth, providerController.updateServices);

// 7. Update Shop Hours & Timing details
router.post('/update-hours', requireAuth, providerController.updateHours);

// 8. Get Provider Earnings
router.get('/earnings/:shopId', requireAuth, providerController.getEarnings);

// 9. Reply to Review
router.post('/reply-review', requireAuth, providerValidator.validateReplyReview, providerController.replyReview);

// 10. Provider Live Location Coordinates Updates
router.post('/update-location', requireAuth, providerValidator.validateUpdateLocation, providerController.updateLocation);

// 11. Fetch provider profile directly (single source of truth)
router.get('/profile', requireAuth, providerController.getProfile);

// 12. Shop banner image upload — stores in Cloudinary
router.post('/upload-banner', requireAuth, providerValidator.validateUploadImage, providerController.uploadBanner);

// 13. Shop portfolio image upload — stores in Cloudinary and appends to portfolioImages
router.post('/upload-portfolio', requireAuth, providerValidator.validateUploadImage, providerController.uploadPortfolio);

// 14. Shop portfolio image delete
router.post('/delete-portfolio', requireAuth, providerValidator.validateDeletePortfolio, providerController.deletePortfolio);

// 15. Service image upload — stores in Cloudinary and returns imageUrl
router.post('/upload-service-image', requireAuth, providerValidator.validateUploadImage, providerController.uploadServiceImage);

module.exports = router;
