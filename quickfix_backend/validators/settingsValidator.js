const { validateImageMimeType } = require('../helpers');

function validateDemandSubmit(req, res, next) {
  const { phone, address, latitude, longitude } = req.body;
  if (!phone || !address || isNaN(parseFloat(latitude)) || isNaN(parseFloat(longitude))) {
    return res.status(400).json({ error: 'phone, address, latitude, and longitude are required' });
  }
  next();
}

function validateCategoryUploadImage(req, res, next) {
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

function validateCategoryCreate(req, res, next) {
  const { id, name } = req.body;
  if (!id || !name) {
    return res.status(400).json({ error: 'id and name are required' });
  }
  next();
}

function validateCategoryUpdate(req, res, next) {
  const { id } = req.body;
  if (!id) {
    return res.status(400).json({ error: 'id is required' });
  }
  next();
}

function validateBannerUploadImage(req, res, next) {
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

function validateCouponValidate(req, res, next) {
  const { code } = req.body;
  if (!code) {
    return res.status(400).json({ error: 'Coupon code is required' });
  }
  next();
}

function validateCheckoutCalculate(req, res, next) {
  const { shopId, items } = req.body;
  if (!shopId || !items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'shopId and items are required' });
  }
  next();
}

function validateWalletAdjust(req, res, next) {
  const { userId, amount } = req.body;
  if (!userId || isNaN(amount)) {
    return res.status(400).json({ error: 'userId and valid amount are required' });
  }
  next();
}

module.exports = {
  validateDemandSubmit,
  validateCategoryUploadImage,
  validateCategoryCreate,
  validateCategoryUpdate,
  validateBannerUploadImage,
  validateCouponValidate,
  validateCheckoutCalculate,
  validateWalletAdjust
};
