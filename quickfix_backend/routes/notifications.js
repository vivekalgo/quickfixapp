const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const notificationValidator = require('../validators/notificationValidator');
const { optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, notificationController.fetchNotifications);
router.post('/send', notificationValidator.validateSendNotification, notificationController.triggerNotification);

module.exports = router;
