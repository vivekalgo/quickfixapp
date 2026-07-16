const { validateImageMimeType } = require('../helpers');

function validateLogin(req, res, next) {
  const { shopId, password } = req.body;
  if (!shopId || !password) {
    return res.status(400).json({ error: 'Shop ID and password are required' });
  }
  next();
}

function validateChangePassword(req, res, next) {
  const { oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) {
    return res.status(400).json({ error: 'Old password and new password are required' });
  }
  next();
}

function validateToggleOnline(req, res, next) {
  const { isOnline } = req.body;
  if (isOnline === undefined) {
    return res.status(400).json({ error: 'isOnline status is required' });
  }
  next();
}

function validateReplyReview(req, res, next) {
  const { reviewId, replyText } = req.body;
  if (!reviewId || replyText === undefined) {
    return res.status(400).json({ error: 'Review ID and reply text are required' });
  }
  next();
}

function validateUpdateLocation(req, res, next) {
  const { latitude, longitude } = req.body;
  if (latitude === undefined || longitude === undefined) {
    return res.status(400).json({ error: 'Latitude and Longitude are required' });
  }
  next();
}

function validateUploadImage(req, res, next) {
  const { base64Image, mimeType } = req.body;
  if (!base64Image) {
    return res.status(400).json({ error: 'base64Image is required' });
  }
  try {
    req.validatedMime = validateImageMimeType(mimeType);
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
  next();
}

function validateDeletePortfolio(req, res, next) {
  const { imageUrl } = req.body;
  if (!imageUrl) {
    return res.status(400).json({ error: 'imageUrl is required' });
  }
  next();
}

module.exports = {
  validateLogin,
  validateChangePassword,
  validateToggleOnline,
  validateReplyReview,
  validateUpdateLocation,
  validateUploadImage,
  validateDeletePortfolio
};
