const authService = require('../services/authService');

function sendOtp(req, res) {
  const { phoneNumber } = req.body;
  const mockOtp = '123456';
  console.log(`[SMS OTP SIMULATION] Sent OTP code "${mockOtp}" to ${phoneNumber}`);
  res.json({ success: true, message: 'OTP sent successfully', otp: mockOtp });
}

async function verifyOtp(req, res) {
  try {
    const { firebaseToken } = req.body;
    const result = await authService.verifyFirebaseOtp(firebaseToken);
    res.json({
      success: true,
      ...result
    });
  } catch (err) {
    if (err.isFirebaseError) {
      console.error('Firebase token verification failed:', err.message);
      return res.status(401).json({ error: `Firebase Authentication Failed: ${err.message}` });
    }
    console.error('OTP verification error:', err);
    res.status(500).json({ error: 'Internal server error during verification' });
  }
}

async function getProfile(req, res) {
  try {
    const profile = await authService.getProfile(req.user.id);
    res.json(profile);
  } catch (err) {
    if (err.message === 'User profile not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
}

async function updateProfile(req, res) {
  try {
    const profile = await authService.updateProfile(req.user.id, req.body);
    res.json({
      success: true,
      profile
    });
  } catch (err) {
    if (err.message === 'User not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to update profile' });
  }
}

async function uploadAvatar(req, res) {
  try {
    const { base64Image } = req.body;
    const avatarUrl = await authService.uploadAvatar(req.user.id, base64Image, req.validatedMime);
    res.json({ success: true, avatarUrl });
  } catch (err) {
    if (err.message === 'User not found') {
      return res.status(404).json({ error: err.message });
    }
    console.error('Cloudinary upload error:', err.message || err);
    res.status(500).json({ error: `Failed to upload avatar: ${err.message || err}` });
  }
}

async function getReferral(req, res) {
  try {
    const refInfo = await authService.getReferralInfo(req.user.id);
    res.json(refInfo);
  } catch (err) {
    if (err.message === 'User not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to fetch referral info' });
  }
}

async function applyReferral(req, res) {
  try {
    const { referralCode } = req.body;
    await authService.applyReferral(req.user.id, referralCode);
    res.json({ success: true, message: 'Referral applied! ₹50 added to your wallet.' });
  } catch (err) {
    if (err.message === 'Invalid referral code') {
      return res.status(404).json({ error: err.message });
    }
    if (err.message === 'User not found') {
      return res.status(404).json({ error: err.message });
    }
    if (err.message === 'Cannot use your own referral code') {
      return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to apply referral code' });
  }
}

async function deleteAccount(req, res) {
  try {
    await authService.deleteAccount(req.user.id);
    res.json({ success: true, message: 'Account has been deactivated.' });
  } catch (err) {
    if (err.message === 'User not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to delete account' });
  }
}

module.exports = {
  sendOtp,
  verifyOtp,
  getProfile,
  updateProfile,
  uploadAvatar,
  getReferral,
  applyReferral,
  deleteAccount
};
