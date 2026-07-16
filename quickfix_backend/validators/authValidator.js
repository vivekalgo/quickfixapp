const { validateImageMimeType } = require('../helpers');

function validateSendOtp(req, res, next) {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ error: 'Phone number is required' });
  }
  next();
}

function validateVerifyOtp(req, res, next) {
  const { firebaseToken } = req.body;
  if (!firebaseToken) {
    return res.status(401).json({ 
      error: 'Firebase authentication token is required. Please verify your phone number via SMS OTP.' 
    });
  }
  next();
}

function validateUploadAvatar(req, res, next) {
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

function validateApplyReferral(req, res, next) {
  const { referralCode } = req.body;
  if (!referralCode) {
    return res.status(400).json({ error: 'Referral code is required' });
  }
  next();
}

module.exports = {
  validateSendOtp,
  validateVerifyOtp,
  validateUploadAvatar,
  validateApplyReferral
};
