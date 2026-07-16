const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const walletController = require('../controllers/walletController');
const walletValidator = require('../validators/walletValidator');

router.post('/add-money', requireAuth, walletValidator.validateAddMoney, walletController.addMoney);

module.exports = router;
