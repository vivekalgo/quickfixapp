const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Shop } = require('../models');
const { calculateDistance, deleteFromCloudinary, paginate } = require('../helpers');

const JWT_SECRET = process.env.JWT_SECRET;

async function registerShop(body) {
  const { 
    name, ownerName, password, phone, latitude, longitude, categories, 
    imagePath, email, gst, pan, aadhaar, verificationDocs, visitingCharges, 
    serviceRadius, timings, verificationStatus, estimatedServiceTime, priceRange,
    bankAccountNumber, ifscCode, upiId, ownerPhone, ownerEmail, commissionRate, walletBalance
  } = body;

  const phoneStr = String(phone).trim();
  const existing = await Shop.findOne({ phone: phoneStr });
  if (existing) {
    const err = new Error('Shop with this phone number already registered');
    err.statusCode = 400;
    throw err;
  }

  // Auto-generate Shop Display ID (QFS000001, QFS000002...)
  const allShops = await Shop.find({});
  let maxIdNum = 0;
  allShops.forEach(s => {
    if (s.shopDisplayId && s.shopDisplayId.startsWith('QFS')) {
      const numPart = parseInt(s.shopDisplayId.replace('QFS', ''), 10);
      if (!isNaN(numPart) && numPart > maxIdNum) {
        maxIdNum = numPart;
      }
    }
  });
  const nextNum = maxIdNum + 1;
  const shopDisplayId = 'QFS' + String(nextNum).padStart(6, '0');

  // Auto-generate temporary password if not provided
  const tempPassword = password || ('QF@' + Math.floor(10000 + Math.random() * 90000));

  const salt = bcrypt.genSaltSync(10);
  const hashedPassword = bcrypt.hashSync(tempPassword, salt);

  const newShop = new Shop({
    id: `shop-${Date.now()}`,
    shopDisplayId,
    name,
    ownerName,
    password: hashedPassword,
    tempPassword,
    phone: phoneStr,
    email: email || '',
    latitude: parseFloat(latitude) || 26.4912,
    longitude: parseFloat(longitude) || 80.3156,
    categories: categories || ["Cleaning"],
    imagePath: imagePath || 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300',
    rating: 5.0,
    deliveryTimeMins: 20,
    estimatedServiceTime: estimatedServiceTime || '20 mins',
    priceRange: priceRange || '₹₹',
    isOnline: true,
    timings: timings || "09:00 AM - 09:00 PM",
    portfolioImages: [],
    services: [],
    status: 'active',
    isOpen: true,
    verificationStatus: verificationStatus || 'approved',
    visitingCharges: parseFloat(visitingCharges) || 150.0,
    serviceRadius: parseFloat(serviceRadius) || 5.0,
    gst: gst || '',
    pan: pan || '',
    aadhaar: aadhaar || '',
    verificationDocs: verificationDocs || [],
    loginDisabled: false,
    bankAccountNumber: bankAccountNumber || '',
    ifscCode: ifscCode || '',
    upiId: upiId || '',
    ownerPhone: ownerPhone || '',
    ownerEmail: ownerEmail || '',
    commissionRate: parseFloat(commissionRate) || 15.0,
    walletBalance: parseFloat(walletBalance) || 0.0
  });

  await newShop.save();
  return newShop;
}

async function loginShop(phone, password, shopId) {
  let shop;
  if (shopId) {
    const upperShopId = shopId.toUpperCase();
    shop = await Shop.findOne({ shopDisplayId: upperShopId });
    if (!shop) {
      shop = await Shop.findOne({ id: shopId });
    }
  } else {
    shop = await Shop.findOne({ phone });
  }

  if (!shop) {
    const err = new Error('Invalid credentials');
    err.statusCode = 401;
    throw err;
  }

  if (shop.loginDisabled) {
    const err = new Error('Login has been disabled for this shop');
    err.statusCode = 403;
    throw err;
  }

  if (shop.status === 'suspended') {
    const err = new Error('This shop has been suspended');
    err.statusCode = 403;
    throw err;
  }

  let isValid = false;
  try {
    isValid = bcrypt.compareSync(password, shop.password);
  } catch (e) {
    isValid = (password === shop.password);
  }

  if (!isValid) {
    const err = new Error('Invalid credentials');
    err.statusCode = 401;
    throw err;
  }

  const token = jwt.sign({ id: shop._id, phone: shop.phone, role: 'partner' }, JWT_SECRET, { expiresIn: '30d' });
  return { token, shop };
}

async function updateShop(id, updateData) {
  const updated = await Shop.findOneAndUpdate({ id }, updateData, { new: true });
  if (!updated) {
    throw new Error('Shop not found');
  }
  return updated;
}

async function deleteShop(id) {
  const deleted = await Shop.findOneAndDelete({ id });
  if (deleted) {
    if (deleted.imagePath) {
      deleteFromCloudinary(deleted.imagePath);
    }
    if (deleted.portfolioImages && Array.isArray(deleted.portfolioImages)) {
      deleted.portfolioImages.forEach(img => {
        if (img) deleteFromCloudinary(img);
      });
    }
  }
  return deleted;
}

async function getNearbyShops(userLat, userLng, page, limit) {
  const allShops = await Shop.find({});

  const nearbyShops = allShops
    .map(shop => {
      const distance = isNaN(userLat) || isNaN(userLng) ? 1.0 : calculateDistance(userLat, userLng, shop.latitude, shop.longitude);
      const shopObj = shop.toObject();
      shopObj.distanceKm = distance;
      return shopObj;
    })
    .filter(shop => {
      const isApproved = shop.verificationStatus === 'approved';
      const isActive = shop.status === 'active';
      const isOnline = shop.isOnline !== false;

      if (!isApproved || !isActive || !isOnline) return false;

      if (!isNaN(userLat) && !isNaN(userLng)) {
        const radius = parseFloat(shop.serviceRadius) || 5.0;
        return shop.distanceKm <= radius;
      }

      return true;
    });

  const pageNum = parseInt(page, 10);
  const limitNum = parseInt(limit, 10);
  if (isNaN(pageNum) && isNaN(limitNum)) {
    return nearbyShops;
  } else {
    const activePage = pageNum > 0 ? pageNum : 1;
    const activeLimit = limitNum > 0 ? limitNum : 10;
    const skip = (activePage - 1) * activeLimit;
    const total = nearbyShops.length;
    const data = nearbyShops.slice(skip, skip + activeLimit);
    return {
      success: true,
      data,
      pagination: {
        total,
        page: activePage,
        limit: activeLimit,
        pages: Math.ceil(total / activeLimit)
      }
    };
  }
}

async function searchShops(q, userLat, userLng, page, limit) {
  if (q === undefined) {
    return [];
  }

  const allShops = await Shop.find({});
  const cleanQuery = q.toLowerCase().trim();

  const matchedShops = allShops
    .map(shop => {
      const distance = isNaN(userLat) || isNaN(userLng) ? 1.0 : calculateDistance(userLat, userLng, shop.latitude, shop.longitude);
      const shopObj = shop.toObject();
      shopObj.distanceKm = distance;
      return shopObj;
    })
    .filter(shop => {
      const isApproved = shop.verificationStatus === 'approved';
      const isActive = shop.status === 'active';
      const isOnline = shop.isOnline !== false;

      if (!isApproved || !isActive || !isOnline) return false;

      if (!isNaN(userLat) && !isNaN(userLng)) {
        const radius = parseFloat(shop.serviceRadius) || 5.0;
        if (shop.distanceKm > radius) return false;
      }

      if (cleanQuery.length === 0) return true;

      const nameMatch = shop.name.toLowerCase().includes(cleanQuery);
      const categoryMatch = shop.categories.some(c => c.toLowerCase().includes(cleanQuery));
      const serviceMatch = shop.services && shop.services.some(s => 
        s.title.toLowerCase().includes(cleanQuery) || 
        (s.bulletPoints && s.bulletPoints.some(bp => bp.toLowerCase().includes(cleanQuery)))
      );

      return nameMatch || categoryMatch || serviceMatch;
    });

  const pageNum = parseInt(page, 10);
  const limitNum = parseInt(limit, 10);
  if (isNaN(pageNum) && isNaN(limitNum)) {
    return matchedShops;
  } else {
    const activePage = pageNum > 0 ? pageNum : 1;
    const activeLimit = limitNum > 0 ? limitNum : 10;
    const skip = (activePage - 1) * activeLimit;
    const total = matchedShops.length;
    const data = matchedShops.slice(skip, skip + activeLimit);
    return {
      success: true,
      data,
      pagination: {
        total,
        page: activePage,
        limit: activeLimit,
        pages: Math.ceil(total / activeLimit)
      }
    };
  }
}

async function getAllShops(req) {
  return paginate(Shop, req, ['name', 'ownerName', 'phone', 'email', 'shopDisplayId', 'categories'], { createdAt: -1 });
}

async function approveShop(id, verificationStatus) {
  const shop = await Shop.findOne({ id });
  if (!shop) {
    throw new Error('Shop not found');
  }
  shop.verificationStatus = verificationStatus;
  await shop.save();
  return shop;
}

async function suspendShop(id, suspend) {
  const shop = await Shop.findOne({ id });
  if (!shop) {
    throw new Error('Shop not found');
  }
  shop.status = suspend ? 'suspended' : 'active';
  await shop.save();
  return shop;
}

async function toggleLogin(id, loginDisabled) {
  const shop = await Shop.findOne({ id });
  if (!shop) {
    throw new Error('Shop not found');
  }
  shop.loginDisabled = loginDisabled;
  await shop.save();
  return shop;
}

async function resetPassword(id) {
  const shop = await Shop.findOne({ id });
  if (!shop) {
    throw new Error('Shop not found');
  }
  const tempPassword = 'QF@' + Math.floor(10000 + Math.random() * 90000);
  const salt = bcrypt.genSaltSync(10);
  shop.password = bcrypt.hashSync(tempPassword, salt);
  shop.tempPassword = tempPassword;
  await shop.save();
  return { tempPassword, shop };
}

module.exports = {
  registerShop,
  loginShop,
  updateShop,
  deleteShop,
  getNearbyShops,
  searchShops,
  getAllShops,
  approveShop,
  suspendShop,
  toggleLogin,
  resetPassword
};
