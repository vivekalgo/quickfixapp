const notificationService = require('../services/notificationService');

async function fetchNotifications(req, res) {
  try {
    const result = await notificationService.getNotifications(req);
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
}

async function triggerNotification(req, res) {
  try {
    const newAlert = await notificationService.sendNotification(req.body);
    res.json({ success: true, alert: newAlert });
  } catch (e) {
    res.status(500).json({ error: 'Failed to send alert notification' });
  }
}

module.exports = {
  fetchNotifications,
  triggerNotification
};
