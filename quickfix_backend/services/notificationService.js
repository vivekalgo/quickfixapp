const { Notification } = require('../models');
const { sendFcmTopicNotification, paginate } = require('../helpers');

async function getNotifications(req) {
  return await paginate(Notification, req, ['title', 'body'], { createdAt: -1 });
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
