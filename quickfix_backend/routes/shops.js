const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');
const shopValidator = require('../validators/shopValidator');

// 1. Shop Registration
router.post('/register', shopValidator.validateRegister, shopController.register);

// 2. Shop Login
router.post('/login', shopValidator.validateLogin, shopController.login);

// 3. Shop Update
router.post('/update', shopValidator.validateUpdate, shopController.update);

// 4. Shop Delete
router.delete('/:id', shopController.deleteShop);

// 5. GET nearby shops
router.get('/', shopController.getNearby);

// 6. Search shops
router.get('/search', shopController.search);

// 7. Admin: Get all shops
router.get('/all', shopController.getAll);

// 8. Admin: Approve shop
router.post('/approve', shopValidator.validateApprove, shopController.approve);

// 9. Admin: Suspend shop
router.post('/suspend', shopValidator.validateSuspend, shopController.suspend);

// 10. Admin: Toggle login access
router.post('/toggle-login', shopValidator.validateToggleLogin, shopController.toggleLogin);

// 11. Admin: Reset password
router.post('/reset-password', shopValidator.validateResetPassword, shopController.resetPassword);

module.exports = router;
