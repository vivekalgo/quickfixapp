const providerService = require('../services/providerService');

async function login(req, res) {
  const { shopId, password } = req.body;
  try {
    const result = await providerService.loginProvider(shopId, password);
    res.json({
      success: true,
      ...result
    });
  } catch (e) {
    if (e.statusCode === 401 || e.statusCode === 403) {
      return res.status(e.statusCode).json({ error: e.message });
    }
    console.error('Provider login error:', e);
    res.status(500).json({ error: 'Internal server login failed' });
  }
}

async function changePassword(req, res) {
  const { oldPassword, newPassword } = req.body;
  try {
    await providerService.changePassword(req.user.id, oldPassword, newPassword);
    res.json({ success: true, message: 'Password updated successfully' });
  } catch (e) {
    if (e.statusCode === 400 || e.statusCode === 404) {
      return res.status(e.statusCode).json({ error: e.message });
    }
    console.error('Change password error:', e);
    res.status(500).json({ error: 'Failed to change password' });
  }
}

async function updateFcm(req, res) {
  const { fcmToken } = req.body;
  try {
    await providerService.updateFcmToken(req.user.id, fcmToken);
    res.json({ success: true, message: 'FCM Token updated successfully' });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Update FCM Token error:', e);
    res.status(500).json({ error: 'Failed to update FCM Token' });
  }
}

async function getDashboard(req, res) {
  const { shopId } = req.params;
  try {
    if (req.user.role !== 'admin' && req.user.shopId !== shopId && String(req.user.id) !== shopId) {
      return res.status(403).json({ error: "Forbidden: You do not have access to this shop's dashboard" });
    }
    const stats = await providerService.getDashboardStats(shopId);
    res.json(stats);
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Dashboard stats error:', e);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
}

async function toggleOnline(req, res) {
  const { isOnline } = req.body;
  try {
    const status = await providerService.toggleOnline(req.user.id, isOnline);
    res.json({ success: true, isOnline: status });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    res.status(500).json({ error: 'Failed to update online status' });
  }
}

async function updateServices(req, res) {
  const { services, customService } = req.body;
  try {
    const updatedServices = await providerService.updateServices(req.user.id, services, customService);
    res.json({ success: true, services: updatedServices });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Update services error:', e);
    res.status(500).json({ error: 'Failed to update shop services' });
  }
}

async function updateHours(req, res) {
  try {
    const shop = await providerService.updateHoursAndDetails(req.user.id, req.body);
    res.json({ success: true, shop });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Update shop hours/details error:', e);
    res.status(500).json({ error: 'Failed to update details' });
  }
}

async function getEarnings(req, res) {
  const { shopId } = req.params;
  try {
    if (req.user.role !== 'admin' && req.user.shopId !== shopId && String(req.user.id) !== shopId) {
      return res.status(403).json({ error: "Forbidden: You do not have access to this shop's earnings" });
    }
    const earnings = await providerService.getEarnings(shopId);
    res.json(earnings);
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    res.status(500).json({ error: 'Failed to fetch earnings' });
  }
}

async function replyReview(req, res) {
  const { reviewId, replyText } = req.body;
  try {
    const review = await providerService.replyToReview(req.user.id, reviewId, replyText);
    res.json({ success: true, review });
  } catch (e) {
    if (e.statusCode === 403 || e.statusCode === 404) {
      return res.status(e.statusCode).json({ error: e.message });
    }
    console.error('Reply review error:', e);
    res.status(500).json({ error: 'Failed to reply to review' });
  }
}

async function updateLocation(req, res) {
  const { latitude, longitude } = req.body;
  try {
    const coords = await providerService.updateLocation(req.user.id, latitude, longitude);
    res.json({ success: true, ...coords });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Update provider location error:', e);
    res.status(500).json({ error: 'Failed to update location' });
  }
}

async function getProfile(req, res) {
  try {
    const shop = await providerService.getProfile(req.user.id);
    res.json({ success: true, shop });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Fetch provider profile error:', e);
    res.status(500).json({ error: 'Failed to fetch provider profile' });
  }
}

async function uploadBanner(req, res) {
  const { base64Image } = req.body;
  try {
    const imagePath = await providerService.uploadBanner(req.user.id, base64Image, req.validatedMime);
    res.json({ success: true, imagePath });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Cloudinary upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload banner: ${e.message || e}` });
  }
}

async function uploadPortfolio(req, res) {
  const { base64Image } = req.body;
  try {
    const portfolioImages = await providerService.uploadPortfolio(req.user.id, base64Image, req.validatedMime);
    res.json({ success: true, portfolioImages });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Cloudinary portfolio upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload portfolio image: ${e.message || e}` });
  }
}

async function deletePortfolio(req, res) {
  const { imageUrl } = req.body;
  try {
    const portfolioImages = await providerService.deletePortfolio(req.user.id, imageUrl);
    res.json({ success: true, portfolioImages });
  } catch (e) {
    if (e.statusCode === 404) {
      return res.status(404).json({ error: e.message });
    }
    console.error('Portfolio delete error:', e.message || e);
    res.status(500).json({ error: `Failed to delete portfolio image: ${e.message || e}` });
  }
}

async function uploadServiceImage(req, res) {
  const { base64Image } = req.body;
  try {
    const imageUrl = await providerService.uploadServiceImage(base64Image, req.validatedMime);
    res.json({ success: true, imageUrl });
  } catch (e) {
    console.error('Cloudinary service image upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload service image: ${e.message || e}` });
  }
}

module.exports = {
  login,
  changePassword,
  updateFcm,
  getDashboard,
  toggleOnline,
  updateServices,
  updateHours,
  getEarnings,
  replyReview,
  updateLocation,
  getProfile,
  uploadBanner,
  uploadPortfolio,
  deletePortfolio,
  uploadServiceImage
};
