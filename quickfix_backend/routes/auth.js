const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const authController = require('../controllers/authController');
const authValidator = require('../validators/authValidator');
const { otpLimiter, authLimiter } = require('../middleware/rateLimiter');

// 1. Customer Authentication (Firebase Phone Auth)
router.post('/send-otp', otpLimiter, authValidator.validateSendOtp, authController.sendOtp);
router.post('/verify-otp', authLimiter, authValidator.validateVerifyOtp, authController.verifyOtp);

router.get('/profile', requireAuth, authController.getProfile);
router.post('/profile/update', requireAuth, authController.updateProfile);
router.post('/profile/upload-avatar', requireAuth, authValidator.validateUploadAvatar, authController.uploadAvatar);

router.get('/referral', requireAuth, authController.getReferral);
router.post('/referral/apply', requireAuth, authValidator.validateApplyReferral, authController.applyReferral);

router.delete('/account', requireAuth, authController.deleteAccount);

module.exports = router;
