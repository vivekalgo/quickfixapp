const { Notification } = require('../models');
const { sendFcmTopicNotification, paginate } = require('../helpers');

async function getNotifications(req) {
  let targetUserId = req.query.userId || (req.user && req.user.role !== 'partner' ? req.user.id : '');
  let targetShopId = req.query.shopId || (req.user && req.user.role === 'partner' ? (req.user.shopId || req.user.id) : '');

  const query = {};
  if (targetUserId || targetShopId) {
    const conditions = [
      { userId: '', shopId: '' },
      { userId: { $exists: false } }
    ];
    if (targetUserId) {
      conditions.push({ userId: String(targetUserId) });
    }
    if (targetShopId) {
      conditions.push({ shopId: String(targetShopId) });
    }
    query.$or = conditions;
  }

  return await Notification.find(query).sort({ createdAt: -1 });
}

async function sendNotification(data) {
  const { title, body, icon, iconColor, audience } = data;
  const newAlert = new Notification({
    id: `alert-${Date.now()}`,
    title,
    body,
    time: 'Just now',
    icon: icon || 'notifications_active',
    iconColor: iconColor || 'primary'
  });
  await newAlert.save();

  const payload = {
    type: 'broadcast',
    icon: icon || 'notifications_active',
    iconColor: iconColor || 'primary'
  };

  if (audience === 'shops') {
    sendFcmTopicNotification('providers', title, body, payload);
  } else if (audience === 'all') {
    sendFcmTopicNotification('customers', title, body, payload);
    sendFcmTopicNotification('providers', title, body, payload);
  } else {
    sendFcmTopicNotification('customers', title, body, payload);
  }

  return newAlert;
}

module.exports = {
  getNotifications,
  sendNotification
};
