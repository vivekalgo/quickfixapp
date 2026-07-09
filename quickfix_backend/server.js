require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const cloudinary = require('cloudinary').v2;

// --- CLOUDINARY CONFIGURATION ---
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME ? process.env.CLOUDINARY_CLOUD_NAME.trim() : '',
  api_key: process.env.CLOUDINARY_API_KEY ? process.env.CLOUDINARY_API_KEY.trim() : '',
  api_secret: process.env.CLOUDINARY_API_SECRET ? process.env.CLOUDINARY_API_SECRET.trim() : '',
});

const { 
  User, 
  Shop, 
  Booking, 
  Category, 
  Review, 
  Professional, 
  Banner, 
  Offer, 
  Notification 
} = require('./models');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'quickfix_super_secure_session_key_987654_change_me';

app.use(cors());
app.use(express.json());

// --- FIREBASE ADMIN INITIALIZATION ---
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_JSON ? process.env.FIREBASE_SERVICE_ACCOUNT_JSON.trim() : null;



if (serviceAccountPath) {
  try {
    let serviceAccount;
    if (serviceAccountPath.trim().startsWith('{')) {
      serviceAccount = JSON.parse(serviceAccountPath);
    } else {
      const fs = require('fs');
      const path = require('path');
      const fullPath = path.isAbsolute(serviceAccountPath) ? serviceAccountPath : path.join(__dirname, serviceAccountPath);
      if (fs.existsSync(fullPath)) {
        serviceAccount = require(fullPath);
      }
    }

    if (serviceAccount) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log("Firebase Admin SDK initialized successfully!");
    } else {
      console.warn("Firebase service account credentials file not found. Phone verification OTP auth will fall back to simulation.");
    }
  } catch (err) {
    console.error("Firebase Admin SDK failed to initialize:", err.message);
  }
} else {
  console.log("FIREBASE_SERVICE_ACCOUNT_JSON not set. Verify OTP endpoint will fall back to simulation.");
}

// --- DATABASE CONNECTION ---
const isMongoConfigured = process.env.MONGODB_URI && !process.env.MONGODB_URI.includes('YOUR_MONGODB_ATLAS_CONNECTION_STRING_HERE');
if (!isMongoConfigured) {
  console.warn("==================================================================");
  console.warn("WARNING: MONGODB_URI is not configured in your .env file!");
  console.warn("Please update quickfix_backend/.env with your MongoDB Atlas URI.");
  console.warn("==================================================================");
}

const { setUseLocalDb } = require('./models');

const dbUri = isMongoConfigured ? process.env.MONGODB_URI : 'mongodb://localhost:27017/quickfix';
mongoose.connect(dbUri, { serverSelectionTimeoutMS: 3000 })
  .then(() => {
    console.log("Connected to MongoDB database successfully!");
    seedDatabase();
  })
  .catch(err => {
    console.warn("MongoDB connection failed:", err.message);
    console.warn("Falling back to local JSON database storage (database.json)...");
    setUseLocalDb(true);
    seedDatabase();
  });

// --- HELPER FUNCTION: Haversine distance ---
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return parseFloat((R * c).toFixed(2));
}

// --- JWT MIDDLEWARE ---
async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing token' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
}

// --- ENDPOINTS ---

// 1. Customer Authentication (OTP simulation)
app.post('/api/auth/send-otp', (req, res) => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ error: 'Phone number is required' });
  }
  // Mock SMS OTP code generation
  const mockOtp = '123456';
  console.log(`[SMS OTP SIMULATION] Sent OTP code "${mockOtp}" to ${phoneNumber}`);
  res.json({ success: true, message: 'OTP sent successfully', otp: mockOtp });
});

// Helper to build a full user profile response object (no hardcoded fallbacks)
function buildProfileResponse(user) {
  return {
    id: user._id,
    name: user.name || '',
    email: user.email || '',
    phone: user.phone,
    membership: user.membership || 'basic',
    walletBalance: user.walletBalance || 0,
    avatarUrl: user.avatarUrl || '',
    savedAddresses: user.savedAddresses || [],
    walletTransactions: user.walletTransactions || [],
    gender: user.gender || '',
    dob: user.dob || '',
    alternatePhone: user.alternatePhone || '',
    emergencyContact: user.emergencyContact || '',
    preferredLanguage: user.preferredLanguage || 'English',
    isPhoneVerified: user.isPhoneVerified !== false,
    accountStatus: user.accountStatus || 'active',
    referralCode: user.referralCode || '',
    referralCount: user.referralCount || 0,
    referralRewardsEarned: user.referralRewardsEarned || 0,
    memberSince: user.memberSince || user.createdAt || new Date().toISOString()
  };
}

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phoneNumber, code, firebaseToken } = req.body;

  let phone = phoneNumber;

  if (firebaseToken) {
    try {
      if (!admin.apps.length) {
        throw new Error("Firebase Admin SDK is not initialized. Cannot verify token.");
      }
      const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
      if (!decodedToken.phone_number) {
        throw new Error("Decoded Firebase token does not contain a phone number.");
      }
      // Normalize phone number: e.g. "+919876543210" -> "9876543210"
      phone = decodedToken.phone_number.replace('+91', '').replace(/\s+/g, '');
    } catch (err) {
      console.error('Firebase token verification failed:', err.message);
      return res.status(401).json({ error: `Firebase Authentication Failed: ${err.message}` });
    }
  } else {
    if (!phone || !code) {
      return res.status(400).json({ error: 'Phone number and verification code are required' });
    }
    // Simulated OTP verification
    if (code !== '123456') {
      return res.status(400).json({ error: 'Invalid verification code' });
    }
  }

  try {
    // Find or create customer user profile — NO hardcoded name/email
    let user = await User.findOne({ phone: phone });
    if (!user) {
      // Generate a unique referral code for this new user
      const refCode = 'QFIX' + Math.random().toString(36).substring(2, 8).toUpperCase();
      user = new User({
        phone: phone,
        name: '',
        email: '',
        membership: 'basic',
        walletBalance: 0,
        referralCode: refCode,
        isPhoneVerified: true,
        accountStatus: 'active',
        memberSince: new Date()
      });
      await user.save();
    } else if (!user.referralCode) {
      // Backfill referral code for existing users who don't have one
      user.referralCode = 'QFIX' + Math.random().toString(36).substring(2, 8).toUpperCase();
      await user.save();
    }

    // Generate JWT token
    const token = jwt.sign({ id: user._id, phone: user.phone, role: 'customer' }, JWT_SECRET, { expiresIn: '30d' });

    res.json({
      success: true,
      token,
      profile: buildProfileResponse(user)
    });
  } catch (e) {
    console.error('OTP verification error:', e);
    res.status(500).json({ error: 'Internal server error during verification' });
  }
});

app.get('/api/auth/profile', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User profile not found' });
    }
    res.json(buildProfileResponse(user));
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

app.post('/api/auth/profile/update', requireAuth, async (req, res) => {
  try {
    const allowedFields = [
      'name', 'email', 'avatarUrl', 'gender', 'dob',
      'alternatePhone', 'emergencyContact', 'preferredLanguage',
      'savedAddresses'
    ];
    const updateData = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    }

    const user = await User.findByIdAndUpdate(req.user.id, updateData, { new: true });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({
      success: true,
      profile: buildProfileResponse(user)
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Avatar upload — stores in Cloudinary
app.post('/api/auth/profile/upload-avatar', requireAuth, async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    if (!base64Image) {
      return res.status(400).json({ error: 'base64Image is required' });
    }
    const dataUri = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;
    
    // Upload image to Cloudinary in a custom folder
    const uploadResponse = await cloudinary.uploader.upload(dataUri, {
      folder: 'quickfix_avatars',
      resource_type: 'image',
    });

    const avatarUrl = uploadResponse.secure_url;
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { avatarUrl },
      { new: true }
    );
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ success: true, avatarUrl: user.avatarUrl });
  } catch (e) {
    console.error('Cloudinary upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload avatar: ${e.message || e}` });
  }
});

// Referral info endpoint
app.get('/api/auth/referral', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    // Backfill if missing
    if (!user.referralCode) {
      user.referralCode = 'QFIX' + Math.random().toString(36).substring(2, 8).toUpperCase();
      await user.save();
    }
    res.json({
      referralCode: user.referralCode,
      referralCount: user.referralCount || 0,
      referralRewardsEarned: user.referralRewardsEarned || 0,
      referralLink: `https://quickfix.app/invite/${user.referralCode}`
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch referral info' });
  }
});

// Apply referral code — called when a new user uses someone's code
app.post('/api/auth/referral/apply', requireAuth, async (req, res) => {
  try {
    const { referralCode } = req.body;
    if (!referralCode) {
      return res.status(400).json({ error: 'Referral code is required' });
    }
    const referrer = await User.findOne({ referralCode: referralCode.toUpperCase() });
    if (!referrer) {
      return res.status(404).json({ error: 'Invalid referral code' });
    }
    const currentUser = await User.findById(req.user.id);
    if (!currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }
    if (referrer._id.toString() === currentUser._id.toString()) {
      return res.status(400).json({ error: 'Cannot use your own referral code' });
    }
    // Reward referrer
    referrer.walletBalance = (referrer.walletBalance || 0) + 100;
    referrer.referralCount = (referrer.referralCount || 0) + 1;
    referrer.referralRewardsEarned = (referrer.referralRewardsEarned || 0) + 100;
    referrer.walletTransactions = referrer.walletTransactions || [];
    referrer.walletTransactions.push({
      id: `TX-REF-${Date.now()}`,
      title: `Referral Reward from ${currentUser.phone}`,
      amount: 100,
      type: 'credit',
      date: new Date()
    });
    await referrer.save();
    // Reward new user
    currentUser.walletBalance = (currentUser.walletBalance || 0) + 50;
    currentUser.walletTransactions = currentUser.walletTransactions || [];
    currentUser.walletTransactions.push({
      id: `TX-REF-${Date.now() + 1}`,
      title: 'Referral Signup Bonus',
      amount: 50,
      type: 'credit',
      date: new Date()
    });
    await currentUser.save();
    res.json({ success: true, message: 'Referral applied! ₹50 added to your wallet.' });
  } catch (e) {
    res.status(500).json({ error: 'Failed to apply referral code' });
  }
});

// Delete / Deactivate Account
app.delete('/api/auth/account', requireAuth, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { accountStatus: 'deleted' },
      { new: true }
    );
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ success: true, message: 'Account has been deactivated.' });
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete account' });
  }
});

app.post('/api/wallet/add-money', requireAuth, async (req, res) => {
  const { amount } = req.body;
  if (amount === undefined || isNaN(amount)) {
    return res.status(400).json({ error: 'Valid amount is required' });
  }
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    user.walletBalance = (user.walletBalance || 0) + parseFloat(amount);
    user.walletTransactions = user.walletTransactions || [];
    user.walletTransactions.push({
      id: `TX-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`,
      title: 'Added via UPI Gateway',
      amount: parseFloat(amount),
      type: 'credit',
      date: new Date()
    });
    await user.save();
    res.json({
      success: true,
      walletBalance: user.walletBalance,
      walletTransactions: user.walletTransactions
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to add money to wallet' });
  }
});

// 2. Shop Partners (Registration, Login, Update, Delete)
app.post('/api/shops/register', async (req, res) => {
  const { name, ownerName, password, phone, latitude, longitude, categories, imagePath } = req.body;
  if (!name || !ownerName || !password || !phone) {
    return res.status(400).json({ error: 'All primary fields (name, ownerName, password, phone) are required' });
  }

  try {
    const existing = await Shop.findOne({ phone });
    if (existing) {
      return res.status(400).json({ error: 'Shop with this phone number already registered' });
    }

    const salt = bcrypt.genSaltSync(10);
    const hashedPassword = bcrypt.hashSync(password, salt);

    const newShop = new Shop({
      id: `shop-${Date.now()}`,
      name,
      ownerName,
      password: hashedPassword,
      phone,
      latitude: parseFloat(latitude) || 26.4912,
      longitude: parseFloat(longitude) || 80.3156,
      categories: categories || ["Cleaning"],
      imagePath: imagePath || 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300',
      rating: 5.0,
      deliveryTimeMins: 20,
      priceRange: "₹₹",
      isOnline: true,
      timings: "09:00 AM - 09:00 PM",
      portfolioImages: [],
      services: []
    });

    await newShop.save();
    res.json({ success: true, shop: newShop });
  } catch (e) {
    res.status(500).json({ error: 'Failed to register shop partner' });
  }
});

app.post('/api/shops/login', async (req, res) => {
  const { phone, password } = req.body;
  if (!phone || !password) {
    return res.status(400).json({ error: 'Phone and password are required' });
  }

  try {
    const shop = await Shop.findOne({ phone });
    if (!shop) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    // Support legacy plaintext password or bcrypt hashes
    let isValid = false;
    if (shop.password.startsWith('$2a$') || shop.password.startsWith('$2b$')) {
      isValid = bcrypt.compareSync(password, shop.password);
    } else {
      isValid = (password === shop.password); // fallback logic
    }

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    const token = jwt.sign({ id: shop._id, phone: shop.phone, role: 'partner' }, JWT_SECRET, { expiresIn: '30d' });

    res.json({ success: true, token, shop });
  } catch (e) {
    res.status(500).json({ error: 'Login process failed' });
  }
});

app.post('/api/shops/update', async (req, res) => {
  const { id } = req.body;
  if (!id) {
    return res.status(400).json({ error: 'Shop ID is required' });
  }

  try {
    const updated = await Shop.findOneAndUpdate({ id }, req.body, { new: true });
    if (!updated) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    res.json({ success: true, shop: updated });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update shop details' });
  }
});

app.delete('/api/shops/:id', async (req, res) => {
  const shopId = req.params.id;
  try {
    const deleted = await Shop.findOneAndDelete({ id: shopId });
    if (deleted) {
      res.json({ success: true, shop: deleted });
    } else {
      res.status(404).json({ error: 'Shop not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete shop' });
  }
});

// Nearby shops and listings matching coords
app.get('/api/shops', async (req, res) => {
  try {
    const allShops = await Shop.find({});
    const userLat = parseFloat(req.query.lat);
    const userLng = parseFloat(req.query.lng);

    // Filter and calculate distances dynamically
    const nearbyShops = allShops
      .map(shop => {
        const distance = isNaN(userLat) || isNaN(userLng) ? 1.0 : calculateDistance(userLat, userLng, shop.latitude, shop.longitude);
        const shopObj = shop.toObject();
        shopObj.distanceKm = distance;
        return shopObj;
      })
      .filter(shop => {
        // Must be approved by admin, status active, online toggled
        const isApproved = shop.verificationStatus === 'approved';
        const isActive = shop.status === 'active';
        const isOnline = shop.isOnline !== false;

        if (!isApproved || !isActive || !isOnline) return false;

        // If location is provided, must be within the shop's defined service radius
        if (!isNaN(userLat) && !isNaN(userLng)) {
          const radius = parseFloat(shop.serviceRadius) || 5.0;
          return shop.distanceKm <= radius;
        }

        return true;
      });

    res.json(nearbyShops);
  } catch (e) {
    console.error('Failed to fetch shops:', e);
    res.status(500).json({ error: 'Failed to fetch shops' });
  }
});

// Zomato-style search matching coordinates & service radius
app.get('/api/shops/search', async (req, res) => {
  try {
    const { q, lat, lng } = req.query;
    const userLat = parseFloat(lat);
    const userLng = parseFloat(lng);

    if (q === undefined) {
      return res.json([]);
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

    res.json(matchedShops);
  } catch (e) {
    console.error('Failed to search shops:', e);
    res.status(500).json({ error: 'Search process failed' });
  }
});

// Customer demand endpoints
app.post('/api/demand/submit', async (req, res) => {
  const { phone, address, latitude, longitude } = req.body;
  if (!phone || !address || isNaN(parseFloat(latitude)) || isNaN(parseFloat(longitude))) {
    return res.status(400).json({ error: 'phone, address, latitude, and longitude are required' });
  }
  try {
    const { Demand } = require('./models');
    const newDemand = new Demand({
      id: `dem-${Date.now()}`,
      phone,
      address,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude)
    });
    await newDemand.save();
    res.json({ success: true, demand: newDemand });
  } catch (e) {
    console.error('Failed to save demand:', e);
    res.status(500).json({ error: 'Failed to save demand' });
  }
});

app.get('/api/demand', async (req, res) => {
  try {
    const { Demand } = require('./models');
    const demands = await Demand.find({});
    res.json(demands);
  } catch (e) {
    console.error('Failed to fetch demands:', e);
    res.status(500).json({ error: 'Failed to fetch demands' });
  }
});

// 3. Categories, Reviews, Professionals Listings
app.get('/api/categories', async (req, res) => {
  try {
    const list = await Category.find({});
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load categories' });
  }
});

app.get('/api/reviews', async (req, res) => {
  try {
    const list = await Review.find({});
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load reviews feed' });
  }
});

app.get('/api/professionals', async (req, res) => {
  try {
    const list = await Professional.find({});
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load professionals' });
  }
});

// 4. Promo Coupons, Banners & Offers
app.get('/api/banners', async (req, res) => {
  try {
    const list = await Banner.find({ isActive: true });
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load banners' });
  }
});

app.post('/api/banners', async (req, res) => {
  const { title, code, percent, imageUrl } = req.body;
  try {
    const newBanner = new Banner({
      id: `banner-${Date.now()}`,
      title,
      code,
      percent,
      imageUrl: imageUrl || 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
      isActive: true
    });
    await newBanner.save();
    res.json({ success: true, banner: newBanner });
  } catch (e) {
    res.status(500).json({ error: 'Failed to create banner' });
  }
});

app.post('/api/banners/toggle', async (req, res) => {
  const { id } = req.body;
  try {
    const banner = await Banner.findOne({ id });
    if (banner) {
      banner.isActive = !banner.isActive;
      await banner.save();
      res.json({ success: true, banner });
    } else {
      res.status(404).json({ error: 'Banner not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Toggle banner failed' });
  }
});

app.delete('/api/banners/:id', async (req, res) => {
  try {
    const deleted = await Banner.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true, banner: deleted });
    } else {
      res.status(404).json({ error: 'Banner not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Delete banner failed' });
  }
});

app.get('/api/offers', async (req, res) => {
  try {
    const list = await Offer.find({});
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load offers' });
  }
});

app.post('/api/offers', async (req, res) => {
  const { code, title, description } = req.body;
  try {
    const newOffer = new Offer({
      code: code.toUpperCase(),
      title,
      description,
      isActive: true
    });
    await newOffer.save();
    res.json({ success: true, offer: newOffer });
  } catch (e) {
    res.status(500).json({ error: 'Failed to create offer' });
  }
});

app.post('/api/offers/toggle', async (req, res) => {
  const { code } = req.body;
  try {
    const offer = await Offer.findOne({ code: code.toUpperCase() });
    if (offer) {
      offer.isActive = !offer.isActive;
      await offer.save();
      res.json({ success: true, offer });
    } else {
      res.status(404).json({ error: 'Offer not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Toggle offer failed' });
  }
});

app.delete('/api/offers/:code', async (req, res) => {
  try {
    const deleted = await Offer.findOneAndDelete({ code: req.params.code.toUpperCase() });
    if (deleted) {
      res.json({ success: true, offer: deleted });
    } else {
      res.status(404).json({ error: 'Offer not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Delete offer failed' });
  }
});

app.post('/api/coupons/validate', async (req, res) => {
  const { code, amount } = req.body;
  if (!code) {
    return res.status(400).json({ error: 'Coupon code is required' });
  }
  try {
    const offer = await Offer.findOne({ code: code.toUpperCase(), isActive: true });
    if (!offer) {
      return res.status(404).json({ error: 'Invalid or expired coupon code' });
    }
    
    // Calculate discounts based on coupon code
    let discount = 0.0;
    if (code.toUpperCase() === 'QUICK20') {
      discount = amount * 0.20;
    } else if (code.toUpperCase() === 'FIRST15') {
      discount = amount * 0.15;
    } else {
      discount = 10.0; // Flat discount fallback
    }

    res.json({ success: true, code, discount: discount.toFixed(2) });
  } catch (e) {
    res.status(500).json({ error: 'Coupon validation failed' });
  }
});

// 5. Booking Transactions
app.get('/api/bookings', async (req, res) => {
  const { shopId, customerId } = req.query;
  try {
    const query = {};
    if (shopId) query.shopId = shopId;
    if (customerId) query.customerId = customerId;

    const list = await Booking.find(query).sort({ createdAt: -1 });
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
});

// Handle both standard paths for bookings placement: /api/bookings and /api/bookings/create
const placeBooking = async (req, res) => {
  const { customerId, customerName, customerPhone, customerAddress, shopId, title, slot, date, amount, paymentMethod } = req.body;
  if (!title || !amount || !shopId) {
    return res.status(400).json({ error: 'Missing booking details (title, amount, shopId)' });
  }

  try {
    let user = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, JWT_SECRET);
        user = await User.findById(decoded.id);
      } catch (err) {
        // Silent token fail
      }
    }

    if (paymentMethod === 'Wallet') {
      if (!user) {
        return res.status(401).json({ error: 'Unauthorized: Authentication required for wallet payment' });
      }
      if ((user.walletBalance || 0) < parseFloat(amount)) {
        return res.status(400).json({ error: 'Insufficient wallet balance' });
      }
      user.walletBalance = (user.walletBalance || 0) - parseFloat(amount);
      user.walletTransactions = user.walletTransactions || [];
      user.walletTransactions.push({
        id: `TX-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`,
        title: `Paid for ${title}`,
        amount: parseFloat(amount),
        type: 'debit',
        date: new Date()
      });
      await user.save();
    }

    const bookingId = `QF-${Math.floor(100000 + Math.random() * 900000)}`;
    const newBooking = new Booking({
      id: bookingId,
      customerId: user ? user._id : (customerId || 'cust-123'),
      customerName: user ? user.name : (customerName || 'John Doe'),
      customerPhone: user ? user.phone : (customerPhone || '9999888877'),
      customerAddress: customerAddress || (user && user.savedAddresses && user.savedAddresses[0]) || '113, Swaroop Nagar, Kanpur',
      shopId,
      title,
      slot: slot || '09:00 AM - 10:00 AM',
      date: date ? new Date(date) : new Date(),
      amount: parseFloat(amount),
      status: 'pending',
      providerName: 'Assigning Expert...'
    });

    await newBooking.save();
    res.json({ 
      success: true, 
      bookingId, 
      booking: newBooking,
      walletBalance: user ? user.walletBalance : undefined
    });
  } catch (e) {
    console.error('Booking placement failed:', e);
    res.status(500).json({ error: 'Failed to save booking order' });
  }
};

app.post('/api/bookings', placeBooking);
app.post('/api/bookings/create', placeBooking);

app.post('/api/bookings/update-status', async (req, res) => {
  const { id, status, providerName } = req.body;
  if (!id || !status) {
    return res.status(400).json({ error: 'Booking ID and status are required' });
  }

  try {
    const booking = await Booking.findOne({ id });
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    booking.status = status;
    if (providerName) {
      booking.providerName = providerName;
    }

    await booking.save();
    res.json({ success: true, booking });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update booking status' });
  }
});

app.post('/api/bookings/cancel', async (req, res) => {
  const { id } = req.body;
  try {
    const booking = await Booking.findOne({ id });
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    if (booking.status === 'on_the_way' || booking.status === 'completed') {
      return res.status(400).json({ error: 'Cannot cancel order once it is on the way or completed!' });
    }

    booking.status = 'cancelled';
    await booking.save();
    res.json({ success: true, booking });
  } catch (e) {
    res.status(500).json({ error: 'Failed to cancel booking' });
  }
});

// 6. Push Notifications Broadcasting
app.get('/api/notifications', async (req, res) => {
  try {
    const list = await Notification.find({}).sort({ createdAt: -1 });
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

app.post('/api/notifications/send', async (req, res) => {
  const { title, body, icon, iconColor } = req.body;
  try {
    const newAlert = new Notification({
      id: `alert-${Date.now()}`,
      title,
      body,
      time: 'Just now',
      icon: icon || 'notifications_active',
      iconColor: iconColor || 'primary'
    });
    await newAlert.save();
    res.json({ success: true, alert: newAlert });
  } catch (e) {
    res.status(500).json({ error: 'Failed to send alert notification' });
  }
});

// --- DATABASE AUTO-SEEDER ---
async function seedDatabase() {
  try {
    // 1. Categories
    const catCount = await Category.countDocuments();
    if (catCount === 0) {
      await Category.insertMany([
        { id: 'cleaning', name: 'Cleaning' },
        { id: 'plumbing', name: 'Plumbing' },
        { id: 'electrician', name: 'Electrician' },
        { id: 'appliances', name: 'Appliances Repair' },
        { id: 'carpentry', name: 'Carpentry' }
      ]);
      console.log('Seeded default service categories.');
    }

    // 2. Professionals
    const profCount = await Professional.countDocuments();
    if (profCount === 0) {
      await Professional.insertMany([
        { 
          id: 'p1', 
          name: 'Rohan Sharma', 
          specialty: 'Expert Electrician', 
          rating: 4.9, 
          reviewsCount: 320, 
          imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150' 
        },
        { 
          id: 'p2', 
          name: 'Suresh Kumar', 
          specialty: 'Master Plumber', 
          rating: 4.8, 
          reviewsCount: 240, 
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150' 
        }
      ]);
      console.log('Seeded default professional cards.');
    }

    // 3. Reviews
    const revCount = await Review.countDocuments();
    if (revCount === 0) {
      await Review.insertMany([
        {
          id: 'r1',
          userName: 'Aman Verma',
          userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
          rating: 5.0,
          comment: 'Very quick service! Electrician was very professional and fixed the issue in no time.',
          serviceName: 'Electrician Service',
          locationName: 'Swaroop Nagar'
        },
        {
          id: 'r2',
          userName: 'Neha Singh',
          userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          rating: 5.0,
          comment: 'Booked through QuickFix and got the best plumbing service at a very affordable price.',
          serviceName: 'Plumbing Service',
          locationName: 'Kalyanpur'
        }
      ]);
      console.log('Seeded default customer reviews.');
    }

    // 4. Banners & Offers
    const bannerCount = await Banner.countDocuments();
    if (bannerCount === 0) {
      await Banner.insertMany([
        {
          id: "banner-1",
          title: "Get 20% OFF\non Home Services",
          code: "QUICK20",
          percent: "20% OFF",
          imageUrl: "https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500",
          isActive: true
        },
        {
          id: "banner-2",
          title: "Clean Home,\nPeace of Mind",
          code: "CLEAN30",
          percent: "30% OFF",
          imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500",
          isActive: true
        }
      ]);
      console.log('Seeded default promo banners.');
    }

    const offerCount = await Offer.countDocuments();
    if (offerCount === 0) {
      await Offer.insertMany([
        {
          code: "QUICK20",
          title: "Welcome Discount",
          description: "Flat 20% off on your next booking",
          isActive: true
        },
        {
          code: "FIRST15",
          title: "New User Discount",
          description: "Flat 15% off on your first service",
          isActive: true
        }
      ]);
      console.log('Seeded default discount coupons.');
    }

    // 5. Default Shop Partner
    const shopCount = await Shop.countDocuments();
    if (shopCount === 0) {
      const salt = bcrypt.genSaltSync(10);
      const hashedPassword = bcrypt.hashSync('password123', salt);
      
      await Shop.create({
        id: 'shop-1',
        name: "QuickFix Solutions Hub",
        ownerName: "Amit Sharma",
        password: hashedPassword,
        phone: "9876543210",
        latitude: 26.4912,
        longitude: 80.3156,
        address: "113, Swaroop Nagar, Kanpur, Uttar Pradesh - 208002",
        serviceRadius: 5.0,
        logoPath: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=100",
        categories: ["Cleaning", "Plumbing"],
        imagePath: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300",
        rating: 4.8,
        deliveryTimeMins: 15,
        priceRange: "₹₹",
        isOnline: true,
        timings: "09:00 AM - 08:00 PM",
        status: "active",
        isOpen: true,
        verificationStatus: "approved",
        visitingCharges: 150.0,
        technicians: ["Rohan Sharma", "Suresh Kumar"],
        portfolioImages: [
          "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300"
        ],
        services: [
          {
            id: "srv-1",
            title: "Deep Home Cleaning",
            price: 499,
            originalPrice: 799,
            rating: 4.8,
            reviewsCount: 120,
            durationText: "2 hrs",
            bulletPoints: [
              "Dusting, vacuuming & floor sanitization",
              "Kitchen counter & appliance exterior cleaning",
              "Bathroom tiles deep scrub & wash"
            ],
            imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300"
          }
        ]
      });
      console.log('Seeded default shop partner (phone: 9876543210, password: password123).');
    }

  } catch (e) {
    console.error('Failed to seed database lists:', e.message);
  }
}

app.listen(PORT, () => {
  console.log(`QuickFix Backend Server listening at http://localhost:${PORT}`);
});
