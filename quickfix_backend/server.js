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
  Notification,
  Settings,
  AuditLog,
  Promotion,
  SpecialCard,
  CmsSection,
  CustomSection
} = require('./models');
const { calculateCheckoutPriceInternal } = require('./pricingCalculator');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'quickfix_super_secure_session_key_987654_change_me';

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

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

// --- FCM PUSH NOTIFICATION DISPATCH HELPERS ---
async function sendFcmNotification(targetId, title, body, data = {}, targetType = 'user') {
  try {
    if (!admin.apps.length) {
      console.warn("FCM NOT SENT: Firebase Admin SDK is not initialized.");
      return false;
    }

    let token = '';
    if (targetType === 'user') {
      const user = await User.findById(targetId);
      token = user ? user.fcmToken : '';
    } else {
      const shop = await Shop.findOne({ id: targetId });
      token = shop ? shop.fcmToken : '';
    }

    if (!token) {
      console.log(`FCM NOT SENT: No token registered for ${targetType} ${targetId}`);
      return false;
    }

    const message = {
      notification: {
        title,
        body,
      },
      token: token,
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          channelId: 'high_importance_channel',
          icon: 'ic_notification'
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent FCM message: ${response} to ${targetType} ${targetId}`);
    return true;
  } catch (error) {
    console.error(`Error sending FCM notification to ${targetType} ${targetId}:`, error.message || error);
    return false;
  }
}

async function sendFcmTopicNotification(topic, title, body, data = {}) {
  try {
    if (!admin.apps.length) {
      console.warn("FCM TOPIC NOT SENT: Firebase Admin SDK is not initialized.");
      return false;
    }

    const message = {
      notification: {
        title,
        body,
      },
      topic: topic,
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          channelId: 'high_importance_channel',
          icon: 'ic_notification'
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent FCM topic message: ${response} to topic ${topic}`);
    return true;
  } catch (error) {
    console.error(`Error sending FCM topic notification to topic ${topic}:`, error.message || error);
    return false;
  }
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
    memberSince: user.memberSince || user.createdAt || new Date().toISOString(),
    fcmToken: user.fcmToken || ''
  };
}

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phoneNumber, code, firebaseToken } = req.body;

  let phone = phoneNumber;

  if (!firebaseToken) {
    return res.status(401).json({ 
      error: 'Firebase authentication token is required. Please verify your phone number via SMS OTP.' 
    });
  }

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
      'savedAddresses', 'fcmToken'
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
  const { name, ownerName, password, phone, latitude, longitude, categories, imagePath, email, gst, pan, aadhaar, verificationDocs, visitingCharges, serviceRadius, timings, verificationStatus, estimatedServiceTime, priceRange } = req.body;
  if (!name || !ownerName || !phone) {
    return res.status(400).json({ error: 'Shop name, Owner name, and Phone number are required' });
  }

  const phoneStr = String(phone).trim();

  try {
    const existing = await Shop.findOne({ phone: phoneStr });
    if (existing) {
      return res.status(400).json({ error: 'Shop with this phone number already registered' });
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
      loginDisabled: false
    });

    await newShop.save();
    res.json({ success: true, shop: newShop });
  } catch (e) {
    console.error('Register shop error:', e);
    res.status(500).json({ error: 'Failed to register shop partner' });
  }
});

app.post('/api/shops/login', async (req, res) => {
  const { phone, password, shopId } = req.body;
  if ((!phone && !shopId) || !password) {
    return res.status(400).json({ error: 'Phone/Shop ID and password are required' });
  }

  try {
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
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    if (shop.loginDisabled) {
      return res.status(403).json({ error: 'Login has been disabled for this shop' });
    }

    if (shop.status === 'suspended') {
      return res.status(403).json({ error: 'This shop has been suspended' });
    }

    // Support legacy plaintext password or bcrypt hashes
    let isValid = false;
    try {
      isValid = bcrypt.compareSync(password, shop.password);
    } catch (e) {
      isValid = (password === shop.password); // fallback logic
    }

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: shop._id, phone: shop.phone, role: 'partner' }, JWT_SECRET, { expiresIn: '30d' });

    res.json({ success: true, token, shop });
  } catch (e) {
    console.error('Login process failed:', e);
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

// ==========================================================
// PROVIDER PARTNER API ENDPOINTS
// ==========================================================

// Helper to sanitize booking customer info for privacy before accepting
function sanitizeBookingForPrivacy(booking) {
  const bookingObj = booking.toObject ? booking.toObject() : { ...booking };
  if (bookingObj.status === 'pending' || bookingObj.status === 'rejected') {
    bookingObj.customerName = 'Customer (Privacy Protected)';
    bookingObj.customerPhone = 'Hidden until accepted';
    bookingObj.customerAddress = bookingObj.approxAddress || 'Swaroop Nagar, Kanpur';
    bookingObj.customerLat = undefined;
    bookingObj.customerLng = undefined;
    bookingObj.landmark = undefined;
    bookingObj.houseNumber = undefined;
    bookingObj.pinCode = undefined;
    bookingObj.alternatePhone = undefined;
  }
  return bookingObj;
}

// 1. Provider Login
app.post('/api/provider/login', async (req, res) => {
  const { shopId, password } = req.body;
  if (!shopId || !password) {
    return res.status(400).json({ error: 'Shop ID and password are required' });
  }

  try {
    const upperShopId = shopId.toUpperCase();
    let shop = await Shop.findOne({ shopDisplayId: upperShopId });
    if (!shop) {
      shop = await Shop.findOne({ id: shopId });
    }
    if (!shop) {
      shop = await Shop.findOne({ phone: shopId }); // fallback to phone
    }

    if (!shop) {
      return res.status(401).json({ error: 'Invalid Shop ID or password' });
    }

    if (shop.loginDisabled) {
      return res.status(403).json({ error: 'Login has been disabled for this account' });
    }

    if (shop.status === 'suspended') {
      return res.status(403).json({ error: 'This provider account has been suspended' });
    }

    if (shop.verificationStatus !== 'approved') {
      return res.status(403).json({ error: 'Your account is pending admin approval' });
    }

    let isValid = false;
    try {
      isValid = bcrypt.compareSync(password, shop.password);
    } catch (e) {
      isValid = (password === shop.password);
    }

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid Shop ID or password' });
    }

    const token = jwt.sign(
      { id: shop._id, shopId: shop.id, phone: shop.phone, role: 'partner' },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      shop
    });
  } catch (e) {
    console.error('Provider login error:', e);
    res.status(500).json({ error: 'Internal server login failed' });
  }
});

// 2. Change Password
app.post('/api/provider/change-password', requireAuth, async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) {
    return res.status(400).json({ error: 'Old password and new password are required' });
  }

  try {
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Provider account not found' });
    }

    let isValid = false;
    try {
      isValid = bcrypt.compareSync(oldPassword, shop.password);
    } catch (e) {
      isValid = (oldPassword === shop.password);
    }

    if (!isValid) {
      return res.status(400).json({ error: 'Incorrect old password' });
    }

    const salt = bcrypt.genSaltSync(10);
    shop.password = bcrypt.hashSync(newPassword, salt);
    shop.isFirstLogin = false;
    if (shop.tempPassword) shop.tempPassword = '';

    await shop.save();
    res.json({ success: true, message: 'Password updated successfully' });
  } catch (e) {
    console.error('Change password error:', e);
    res.status(500).json({ error: 'Failed to change password' });
  }
});

// 3. Provider Dashboard Stats
app.get('/api/provider/dashboard/:shopId', requireAuth, async (req, res) => {
  const { shopId } = req.params;
  try {
    const shop = await Shop.findOne({ id: shopId });
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    const bookings = await Booking.find({ shopId });
    const today = new Date().toDateString();

    let todayOrders = 0;
    let pendingOrders = 0;
    let acceptedOrders = 0;
    let completedOrders = 0;
    let cancelledOrders = 0;
    let totalRevenue = 0.0;
    let todayRevenue = 0.0;

    for (const b of bookings) {
      const bDateStr = new Date(b.date).toDateString();
      const isToday = bDateStr === today;

      if (isToday) todayOrders++;

      if (b.status === 'pending') pendingOrders++;
      else if (b.status === 'accepted' || b.status === 'navigating' || b.status === 'arrived' || b.status === 'work_started') acceptedOrders++;
      else if (b.status === 'completed' || b.status === 'closed') {
        completedOrders++;
        totalRevenue += b.amount;
        if (isToday) todayRevenue += b.amount;
      }
      else if (b.status === 'cancelled') cancelledOrders++;
    }

    const reviews = await Review.find({ shopId: shop.id });
    const reviewsCount = reviews.length;
    const avgRating = reviewsCount > 0 
      ? parseFloat((reviews.reduce((sum, r) => sum + r.rating, 0) / reviewsCount).toFixed(1)) 
      : shop.rating || 5.0;

    res.json({
      todayOrders,
      pendingOrders,
      acceptedOrders,
      completedOrders,
      cancelledOrders,
      revenue: todayRevenue,
      totalRevenue,
      walletBalance: shop.walletBalance || 0.0,
      rating: avgRating,
      reviewsCount,
      isOnline: shop.isOnline !== false
    });
  } catch (e) {
    console.error('Dashboard stats error:', e);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

// 4. Toggle Online/Offline
app.post('/api/provider/toggle-online', requireAuth, async (req, res) => {
  const { isOnline } = req.body;
  if (isOnline === undefined) {
    return res.status(400).json({ error: 'isOnline status is required' });
  }

  try {
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    shop.isOnline = isOnline;
    await shop.save();
    res.json({ success: true, isOnline: shop.isOnline });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update online status' });
  }
});

// 5. Update Shop Services
app.post('/api/provider/update-services', requireAuth, async (req, res) => {
  const { services, customService } = req.body;
  try {
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    if (services) {
      shop.services = services;
    }

    if (customService) {
      const newService = {
        id: `srv-custom-${Date.now()}`,
        title: customService.title,
        price: parseFloat(customService.price) || 0,
        originalPrice: customService.originalPrice ? parseFloat(customService.originalPrice) : undefined,
        rating: 5.0,
        reviewsCount: 0,
        durationText: customService.durationText || '1 hr',
        bulletPoints: customService.bulletPoints || [],
        imageUrl: customService.imageUrl || 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300',
        pricingType: customService.pricingType || 'fixed',
        minPrice: parseFloat(customService.minPrice) || 0,
        maxPrice: parseFloat(customService.maxPrice) || 0,
        visitingCharges: parseFloat(customService.visitingCharges) || 0,
        isFreeInspection: customService.isFreeInspection === true,
        gst: parseFloat(customService.gst) || 0,
        extraCharges: parseFloat(customService.extraCharges) || 0,
        extraChargesLabel: customService.extraChargesLabel || '',
        isAvailable: customService.isAvailable !== false,
        isEnabled: customService.isEnabled !== false
      };
      shop.services.push(newService);
    }

    await shop.save();
    res.json({ success: true, services: shop.services });
  } catch (e) {
    console.error('Update services error:', e);
    res.status(500).json({ error: 'Failed to update shop services' });
  }
});

app.post('/api/provider/update-hours', requireAuth, async (req, res) => {
  const { workingHours, holidays, serviceRadius, visitingCharges, emergencyAvailable, estimatedServiceTime, priceRange } = req.body;
  try {
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    if (workingHours) shop.workingHours = workingHours;
    if (holidays) shop.holidays = holidays;
    if (serviceRadius !== undefined) shop.serviceRadius = parseFloat(serviceRadius);
    if (visitingCharges !== undefined) shop.visitingCharges = parseFloat(visitingCharges);
    if (emergencyAvailable !== undefined) shop.emergencyAvailable = emergencyAvailable;
    if (estimatedServiceTime !== undefined) shop.estimatedServiceTime = estimatedServiceTime;
    if (priceRange !== undefined) shop.priceRange = priceRange;

    await shop.save();
    res.json({ success: true, shop });
  } catch (e) {
    console.error('Update shop hours/details error:', e);
    res.status(500).json({ error: 'Failed to update details' });
  }
});

// 7. Get Provider Earnings
app.get('/api/provider/earnings/:shopId', requireAuth, async (req, res) => {
  const { shopId } = req.params;
  try {
    const shop = await Shop.findOne({ id: shopId });
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    res.json({
      walletBalance: shop.walletBalance || 0.0,
      commissionRate: shop.commissionRate || 15.0,
      walletTransactions: shop.walletTransactions || []
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch earnings' });
  }
});

// 8. Reply to Review
app.post('/api/provider/reply-review', requireAuth, async (req, res) => {
  const { reviewId, replyText } = req.body;
  if (!reviewId || replyText === undefined) {
    return res.status(400).json({ error: 'Review ID and reply text are required' });
  }

  try {
    const review = await Review.findOne({ id: reviewId });
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    review.reply = replyText;
    await review.save();

    // Also track in shop replies map
    const shop = await Shop.findById(req.user.id);
    if (shop) {
      if (!shop.reviewReplies) shop.reviewReplies = {};
      shop.reviewReplies.set(reviewId, replyText);
      await shop.save();
    }

    res.json({ success: true, review });
  } catch (e) {
    console.error('Reply review error:', e);
    res.status(500).json({ error: 'Failed to reply to review' });
  }
});

// 9. Get Shop Reviews
app.get('/api/reviews/shop/:shopId', async (req, res) => {
  const { shopId } = req.params;
  try {
    const reviews = await Review.find({ shopId });
    res.json(reviews);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load shop reviews' });
  }
});

// 10. Provider Live Location Coordinates Updates
app.post('/api/provider/update-location', requireAuth, async (req, res) => {
  const { latitude, longitude } = req.body;
  if (latitude === undefined || longitude === undefined) {
    return res.status(400).json({ error: 'Latitude and Longitude are required' });
  }

  try {
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    shop.providerLat = parseFloat(latitude);
    shop.providerLng = parseFloat(longitude);
    await shop.save();

    // Also update any active bookings that are currently in 'navigating' status
    await Booking.findOneAndUpdate(
      { shopId: shop.id, status: 'navigating' },
      { providerLat: parseFloat(latitude), providerLng: parseFloat(longitude) }
    );

    res.json({ success: true, providerLat: shop.providerLat, providerLng: shop.providerLng });
  } catch (e) {
    console.error('Update provider location error:', e);
    res.status(500).json({ error: 'Failed to update location' });
  }
});

// 10b. Fetch provider profile directly (single source of truth)
app.get('/api/provider/profile', requireAuth, async (req, res) => {
  try {
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Provider account not found' });
    }
    res.json({ success: true, shop });
  } catch (e) {
    console.error('Fetch provider profile error:', e);
    res.status(500).json({ error: 'Failed to fetch provider profile' });
  }
});

// 10c. Shop banner image upload — stores in Cloudinary
app.post('/api/provider/upload-banner', requireAuth, async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    if (!base64Image) {
      return res.status(400).json({ error: 'base64Image is required' });
    }
    const dataUri = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;
    
    const uploadResponse = await cloudinary.uploader.upload(dataUri, {
      folder: 'quickfix_banners',
      resource_type: 'image',
    });

    const imageUrl = uploadResponse.secure_url;
    const shop = await Shop.findByIdAndUpdate(
      req.user.id,
      { imagePath: imageUrl },
      { new: true }
    );
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    res.json({ success: true, imagePath: shop.imagePath });
  } catch (e) {
    console.error('Cloudinary upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload banner: ${e.message || e}` });
  }
});

// 10d. Shop portfolio image upload — stores in Cloudinary and appends to portfolioImages
app.post('/api/provider/upload-portfolio', requireAuth, async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    if (!base64Image) {
      return res.status(400).json({ error: 'base64Image is required' });
    }
    const dataUri = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;
    
    const uploadResponse = await cloudinary.uploader.upload(dataUri, {
      folder: 'quickfix_portfolios',
      resource_type: 'image',
    });

    const imageUrl = uploadResponse.secure_url;
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    
    if (!shop.portfolioImages) {
      shop.portfolioImages = [];
    }
    shop.portfolioImages.push(imageUrl);
    await shop.save();
    
    res.json({ success: true, portfolioImages: shop.portfolioImages });
  } catch (e) {
    console.error('Cloudinary portfolio upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload portfolio image: ${e.message || e}` });
  }
});

// 10e. Shop portfolio image delete
app.post('/api/provider/delete-portfolio', requireAuth, async (req, res) => {
  try {
    const { imageUrl } = req.body;
    if (!imageUrl) {
      return res.status(400).json({ error: 'imageUrl is required' });
    }
    const shop = await Shop.findById(req.user.id);
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    
    if (shop.portfolioImages) {
      shop.portfolioImages = shop.portfolioImages.filter(img => img !== imageUrl);
      await shop.save();
    }
    
    res.json({ success: true, portfolioImages: shop.portfolioImages });
  } catch (e) {
    console.error('Portfolio delete error:', e.message || e);
    res.status(500).json({ error: `Failed to delete portfolio image: ${e.message || e}` });
  }
});

// 10f. Service image upload — stores in Cloudinary and returns imageUrl
app.post('/api/provider/upload-service-image', requireAuth, async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    if (!base64Image) {
      return res.status(400).json({ error: 'base64Image is required' });
    }
    const dataUri = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;
    
    const uploadResponse = await cloudinary.uploader.upload(dataUri, {
      folder: 'quickfix_services',
      resource_type: 'image',
    });

    const imageUrl = uploadResponse.secure_url;
    res.json({ success: true, imageUrl });
  } catch (e) {
    console.error('Cloudinary service image upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload service image: ${e.message || e}` });
  }
});

// 11. Booking details (sanitized for privacy before accepted)
app.get('/api/bookings/details/:bookingId', async (req, res) => {
  const { bookingId } = req.params;
  try {
    const booking = await Booking.findOne({ id: bookingId });
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Apply privacy filter
    const sanitized = sanitizeBookingForPrivacy(booking);
    res.json(sanitized);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch booking details' });
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
    let list = await Review.find({ status: 'approved', isActive: { $ne: false } });
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load reviews feed' });
  }
});

app.get('/api/admin/reviews', async (req, res) => {
  try {
    const list = await Review.find({});
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load admin reviews' });
  }
});

app.post('/api/reviews/approve', async (req, res) => {
  const { id, status } = req.body;
  try {
    const review = await Review.findOneAndUpdate({ id }, { status }, { new: true });
    if (!review) return res.status(404).json({ error: 'Review not found' });
    res.json({ success: true, review });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update review approval status' });
  }
});

app.post('/api/reviews', async (req, res) => {
  const { id, userName, userAvatar, rating, comment, serviceName, locationName, shopId, reply, providerName, date, verifiedBadge, priority, status, isActive, isFeatured } = req.body;
  try {
    let review;
    if (id) {
      review = await Review.findOneAndUpdate(
        { id },
        { 
          userName, 
          userAvatar, 
          rating: parseFloat(rating) || 5.0, 
          comment, 
          serviceName, 
          locationName, 
          shopId, 
          reply, 
          providerName, 
          date, 
          verifiedBadge: verifiedBadge !== false, 
          priority: parseInt(priority) || 0, 
          status: status || 'approved', 
          isActive: isActive !== false, 
          isFeatured: isFeatured === true 
        },
        { new: true }
      );
      if (!review) return res.status(404).json({ error: 'Review not found' });
    } else {
      review = new Review({
        id: `rev-${Date.now()}`,
        userName,
        userAvatar: userAvatar || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        rating: parseFloat(rating) || 5.0,
        comment,
        serviceName: serviceName || 'General Service',
        locationName: locationName || 'Kanpur',
        shopId: shopId || '',
        reply: reply || '',
        providerName: providerName || '',
        date: date || new Date().toISOString().split('T')[0],
        verifiedBadge: verifiedBadge !== false,
        priority: parseInt(priority) || 0,
        status: status || 'approved',
        isActive: isActive !== false,
        isFeatured: isFeatured === true
      });
      await review.save();
    }
    res.json({ success: true, review });
  } catch (e) {
    console.error('Error saving review:', e);
    res.status(500).json({ error: 'Failed to save review details' });
  }
});

app.delete('/api/reviews/:id', async (req, res) => {
  try {
    const deleted = await Review.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true, review: deleted });
    } else {
      res.status(404).json({ error: 'Review not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete review' });
  }
});

app.get('/api/professionals', async (req, res) => {
  const { sort, lat, lng } = req.query;
  try {
    let list = await Professional.find({ isActive: { $ne: false } });

    const syncedList = await Promise.all(list.map(async (prof) => {
      const p = prof.toObject ? prof.toObject() : { ...prof };
      if (p.shopId) {
        const shop = await Shop.findOne({ id: p.shopId });
        if (shop) {
          p.name = shop.ownerName || shop.name || p.name;
          p.imageUrl = shop.ownerPhotoUrl || shop.imagePath || p.imageUrl;
          p.specialty = (shop.categories && shop.categories.length > 0) ? shop.categories[0] : p.specialty;
          p.rating = shop.rating !== undefined ? shop.rating : p.rating;
          p.availability = shop.isOnline !== undefined ? shop.isOnline : p.availability;
          p.verifiedBadge = shop.verificationStatus === 'approved';
          p.lat = shop.latitude;
          p.lng = shop.longitude;
          p.reviewsCount = shop.services ? shop.services.reduce((acc, s) => acc + (s.reviewsCount || 0), 0) : p.reviewsCount;
        }
      }
      return p;
    }));

    if (sort === 'rating') {
      syncedList.sort((a, b) => (b.rating || 0) - (a.rating || 0));
    } else if (sort === 'bookings') {
      syncedList.sort((a, b) => (b.completedJobs || b.reviewsCount || 0) - (a.completedJobs || a.reviewsCount || 0));
    } else if (sort === 'nearest' && lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      syncedList.sort((a, b) => {
        const distA = (a.lat !== undefined && a.lng !== undefined) ? calculateDistance(userLat, userLng, a.lat, a.lng) : 99999;
        const distB = (b.lat !== undefined && b.lng !== undefined) ? calculateDistance(userLat, userLng, b.lat, b.lng) : 99999;
        return distA - distB;
      });
    } else if (sort === 'recently_added') {
      syncedList.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    } else {
      syncedList.sort((a, b) => {
        const prioDiff = (a.priority || 0) - (b.priority || 0);
        if (prioDiff !== 0) return prioDiff;
        return (b.rating || 0) - (a.rating || 0);
      });
    }

    res.json(syncedList);
  } catch (e) {
    console.error('Error loading professionals:', e);
    res.status(500).json({ error: 'Failed to load professionals' });
  }
});

app.get('/api/admin/professionals', async (req, res) => {
  try {
    const list = await Professional.find({});
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load admin professionals list' });
  }
});

app.post('/api/professionals', async (req, res) => {
  const { id, name, specialty, rating, reviewsCount, imageUrl, shopId, experience, completedJobs, location, verifiedBadge, availability, featuredStatus, priority, isActive } = req.body;
  try {
    let expert;
    if (id) {
      expert = await Professional.findOneAndUpdate(
        { id },
        { 
          name, 
          specialty, 
          rating: parseFloat(rating) || 5.0, 
          reviewsCount: parseInt(reviewsCount) || 0, 
          imageUrl, 
          shopId, 
          experience, 
          completedJobs: parseInt(completedJobs) || 0, 
          location, 
          verifiedBadge: verifiedBadge === true, 
          availability: availability === true, 
          featuredStatus: featuredStatus || 'Featured', 
          priority: parseInt(priority) || 0, 
          isActive: isActive !== false 
        },
        { new: true }
      );
      if (!expert) return res.status(404).json({ error: 'Expert not found' });
    } else {
      expert = new Professional({
        id: `expert-${Date.now()}`,
        name,
        specialty,
        rating: parseFloat(rating) || 5.0,
        reviewsCount: parseInt(reviewsCount) || 0,
        imageUrl: imageUrl || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        shopId: shopId || '',
        experience: experience || '',
        completedJobs: parseInt(completedJobs) || 0,
        location: location || '',
        verifiedBadge: verifiedBadge === true,
        availability: availability === true,
        featuredStatus: featuredStatus || 'Featured',
        priority: parseInt(priority) || 0,
        isActive: isActive !== false
      });
      await expert.save();
    }
    res.json({ success: true, professional: expert });
  } catch (e) {
    console.error('Error saving expert:', e);
    res.status(500).json({ error: 'Failed to save expert details' });
  }
});

app.delete('/api/professionals/:id', async (req, res) => {
  try {
    const deleted = await Professional.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true, professional: deleted });
    } else {
      res.status(404).json({ error: 'Expert not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete expert' });
  }
});

// Dynamic Home Promotions API
app.get('/api/promotions', async (req, res) => {
  try {
    const nowStr = new Date().toISOString();
    let list = await Promotion.find({ isActive: true });

    const validPromotions = list.filter(promo => {
      if (promo.startDate && promo.startDate > nowStr) return false;
      if (promo.endDate && promo.endDate < nowStr) return false;
      return true;
    });

    validPromotions.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(validPromotions);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load promotions' });
  }
});

app.get('/api/admin/promotions', async (req, res) => {
  try {
    const list = await Promotion.find({});
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load all promotions' });
  }
});

app.post('/api/promotions', async (req, res) => {
  const { id, title, subtitle, description, offerPercentage, couponCode, ctaButtonText, ctaButtonAction, ctaButtonActionValue, bannerImage, backgroundColor, textColor, buttonColor, buttonTextColor, priority, startDate, endDate, isActive } = req.body;
  try {
    let promo;
    if (id) {
      promo = await Promotion.findOneAndUpdate(
        { id },
        { 
          title, 
          subtitle, 
          description, 
          offerPercentage, 
          couponCode, 
          ctaButtonText, 
          ctaButtonAction: ctaButtonAction || 'No Action', 
          ctaButtonActionValue, 
          bannerImage, 
          backgroundColor: backgroundColor || '#FFF1F0', 
          textColor: textColor || '#000000', 
          buttonColor: buttonColor || '#FF4D4F', 
          buttonTextColor: buttonTextColor || '#FFFFFF', 
          priority: parseInt(priority) || 0, 
          startDate: startDate || '', 
          endDate: endDate || '', 
          isActive: isActive !== false 
        },
        { new: true }
      );
      if (!promo) return res.status(404).json({ error: 'Promotion not found' });
    } else {
      promo = new Promotion({
        id: `promo-${Date.now()}`,
        title,
        subtitle,
        description,
        offerPercentage,
        couponCode,
        ctaButtonText,
        ctaButtonAction: ctaButtonAction || 'No Action',
        ctaButtonActionValue,
        bannerImage,
        backgroundColor: backgroundColor || '#FFF1F0',
        textColor: textColor || '#000000',
        buttonColor: buttonColor || '#FF4D4F',
        buttonTextColor: buttonTextColor || '#FFFFFF',
        priority: parseInt(priority) || 0,
        startDate: startDate || '',
        endDate: endDate || '',
        isActive: isActive !== false
      });
      await promo.save();
    }
    res.json({ success: true, promotion: promo });
  } catch (e) {
    console.error('Error saving promotion:', e);
    res.status(500).json({ error: 'Failed to save promotion details' });
  }
});

app.delete('/api/promotions/:id', async (req, res) => {
  try {
    const deleted = await Promotion.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true, promotion: deleted });
    } else {
      res.status(404).json({ error: 'Promotion not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Delete promotion failed' });
  }
});

// Special For You Section Cards API
app.get('/api/special-cards', async (req, res) => {
  try {
    const nowStr = new Date().toISOString();
    let list = await SpecialCard.find({ isActive: true });

    const validCards = list.filter(card => {
      if (card.startDate && card.startDate > nowStr) return false;
      if (card.endDate && card.endDate < nowStr) return false;
      return true;
    });

    validCards.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(validCards);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load special cards' });
  }
});

app.get('/api/admin/special-cards', async (req, res) => {
  try {
    const list = await SpecialCard.find({});
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load all special cards' });
  }
});

app.post('/api/special-cards', async (req, res) => {
  const { id, icon, imageUrl, title, subtitle, description, backgroundColor, buttonText, ctaAction, ctaActionValue, priority, isActive, startDate, endDate } = req.body;
  try {
    let card;
    if (id) {
      card = await SpecialCard.findOneAndUpdate(
        { id },
        { 
          icon: icon || 'star', 
          imageUrl, 
          title, 
          subtitle, 
          description, 
          backgroundColor: backgroundColor || '#FFFFFF', 
          buttonText: buttonText || 'View', 
          ctaAction: ctaAction || 'No Action', 
          ctaActionValue, 
          priority: parseInt(priority) || 0, 
          isActive: isActive !== false, 
          startDate: startDate || '', 
          endDate: endDate || '' 
        },
        { new: true }
      );
      if (!card) return res.status(404).json({ error: 'Special card not found' });
    } else {
      card = new SpecialCard({
        id: `special-${Date.now()}`,
        icon: icon || 'star',
        imageUrl,
        title,
        subtitle,
        description,
        backgroundColor: backgroundColor || '#FFFFFF',
        buttonText: buttonText || 'View',
        ctaAction: ctaAction || 'No Action',
        ctaActionValue: ctaActionValue || '',
        priority: parseInt(priority) || 0,
        isActive: isActive !== false,
        startDate: startDate || '',
        endDate: endDate || ''
      });
      await card.save();
    }
    res.json({ success: true, card });
  } catch (e) {
    res.status(500).json({ error: 'Failed to save special card details' });
  }
});

app.post('/api/special-cards/reorder', async (req, res) => {
  const { orderList } = req.body;
  try {
    const promises = orderList.map(item => {
      return SpecialCard.findOneAndUpdate({ id: item.id }, { priority: item.priority });
    });
    await Promise.all(promises);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to reorder special cards' });
  }
});

app.delete('/api/special-cards/:id', async (req, res) => {
  try {
    const deleted = await SpecialCard.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true, card: deleted });
    } else {
      res.status(404).json({ error: 'Special card not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Delete special card failed' });
  }
});

// Dynamic CMS Layout Sections
app.get('/api/homepage/layout', async (req, res) => {
  try {
    let list = await CmsSection.find({ isActive: true });
    
    if (list.length === 0) {
      const defaultSections = [
        { id: 'banner_carousel', title: 'Limited Time Offers', type: 'banner_carousel', priority: 0, isActive: true },
        { id: 'grid_categories', title: 'All Services', type: 'grid_categories', priority: 1, isActive: true },
        { id: 'home_promotions', title: 'Festive Offer Ribbon', type: 'home_promotions', priority: 2, isActive: true },
        { id: 'nearby_shops', title: 'Nearby Top Shops', type: 'nearby_shops', priority: 3, isActive: true },
        { id: 'quickfix_plus', title: 'QuickFix Plus Banner', type: 'quickfix_plus', priority: 4, isActive: true },
        { id: 'trust_badges', title: 'Trust Badges', type: 'trust_badges', priority: 5, isActive: true },
        { id: 'referral_offers', title: 'Referrals & Promos', type: 'referral_offers', priority: 6, isActive: true },
        { id: 'how_it_works', title: 'How QuickFix Works', type: 'how_it_works', priority: 7, isActive: true },
        { id: 'special_for_you', title: 'Special For You 🔥', type: 'special_for_you', priority: 8, isActive: true },
        { id: 'top_experts', title: 'Top Rated Experts', type: 'top_experts', priority: 9, isActive: true },
        { id: 'customer_reviews', title: 'What Our Customers Say', type: 'customer_reviews', priority: 10, isActive: true },
        { id: 'brand_logos', title: 'Brand Marquee Logos', type: 'brand_logos', priority: 11, isActive: true },
        { id: 'support_card', title: 'Need Help Support Card', type: 'support_card', priority: 12, isActive: true }
      ];
      await CmsSection.insertMany(defaultSections);
      list = await CmsSection.find({ isActive: true });
    }
    
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    console.error('CMS Fetch Error:', e);
    res.status(500).json({ error: 'Failed to load homepage layout' });
  }
});

app.get('/api/admin/homepage/layout', async (req, res) => {
  try {
    let list = await CmsSection.find({});
    if (list.length === 0) {
      const defaultSections = [
        { id: 'banner_carousel', title: 'Limited Time Offers', type: 'banner_carousel', priority: 0, isActive: true },
        { id: 'grid_categories', title: 'All Services', type: 'grid_categories', priority: 1, isActive: true },
        { id: 'home_promotions', title: 'Festive Offer Ribbon', type: 'home_promotions', priority: 2, isActive: true },
        { id: 'nearby_shops', title: 'Nearby Top Shops', type: 'nearby_shops', priority: 3, isActive: true },
        { id: 'quickfix_plus', title: 'QuickFix Plus Banner', type: 'quickfix_plus', priority: 4, isActive: true },
        { id: 'trust_badges', title: 'Trust Badges', type: 'trust_badges', priority: 5, isActive: true },
        { id: 'referral_offers', title: 'Referrals & Promos', type: 'referral_offers', priority: 6, isActive: true },
        { id: 'how_it_works', title: 'How QuickFix Works', type: 'how_it_works', priority: 7, isActive: true },
        { id: 'special_for_you', title: 'Special For You 🔥', type: 'special_for_you', priority: 8, isActive: true },
        { id: 'top_experts', title: 'Top Rated Experts', type: 'top_experts', priority: 9, isActive: true },
        { id: 'customer_reviews', title: 'What Our Customers Say', type: 'customer_reviews', priority: 10, isActive: true },
        { id: 'brand_logos', title: 'Brand Marquee Logos', type: 'brand_logos', priority: 11, isActive: true },
        { id: 'support_card', title: 'Need Help Support Card', type: 'support_card', priority: 12, isActive: true }
      ];
      await CmsSection.insertMany(defaultSections);
      list = await CmsSection.find({});
    }
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load layout admin view' });
  }
});

app.post('/api/homepage/layout/update', async (req, res) => {
  const { id, title, isActive, priority, settings } = req.body;
  try {
    const updateFields = {};
    if (title !== undefined) updateFields.title = title;
    if (isActive !== undefined) updateFields.isActive = isActive;
    if (priority !== undefined) updateFields.priority = parseInt(priority);
    if (settings !== undefined) updateFields.settings = settings;

    const section = await CmsSection.findOneAndUpdate({ id }, updateFields, { new: true });
    if (!section) return res.status(404).json({ error: 'Layout section not found' });
    res.json({ success: true, section });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update layout section' });
  }
});

app.post('/api/homepage/layout/reorder', async (req, res) => {
  const { orderList } = req.body;
  try {
    const promises = orderList.map(item => {
      return CmsSection.findOneAndUpdate({ id: item.id }, { priority: item.priority });
    });
    await Promise.all(promises);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to reorder layout' });
  }
});

// --- Custom Homepage Sections API ---
app.get('/api/custom-sections', async (req, res) => {
  try {
    let list = await CustomSection.find({ isActive: true });
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load custom sections' });
  }
});

app.get('/api/admin/custom-sections', async (req, res) => {
  try {
    let list = await CustomSection.find({});
    list.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load all custom sections' });
  }
});

app.get('/api/custom-sections/:id', async (req, res) => {
  try {
    const section = await CustomSection.findOne({ id: req.params.id });
    if (!section) return res.status(404).json({ error: 'Custom section not found' });
    res.json(section);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch custom section' });
  }
});

app.post('/api/custom-sections', async (req, res) => {
  const { id, title, subtitle, bannerImageUrl, bannerBadgeText, bannerActionType, bannerActionValue, seeAllActionType, seeAllActionValue, serviceItems, priority, isActive } = req.body;
  try {
    let section;
    if (id) {
      section = await CustomSection.findOneAndUpdate(
        { id },
        { title, subtitle, bannerImageUrl, bannerBadgeText, bannerActionType: bannerActionType || 'No Action', bannerActionValue, seeAllActionType: seeAllActionType || 'No Action', seeAllActionValue, serviceItems: serviceItems || [], priority: parseInt(priority) || 0, isActive: isActive !== false },
        { new: true }
      );
      if (!section) return res.status(404).json({ error: 'Custom section not found' });
      // Also update the matching CmsSection title/isActive
      await CmsSection.findOneAndUpdate({ id }, { title, isActive: isActive !== false, priority: parseInt(priority) || 0 });
    } else {
      const newId = `custom-section-${Date.now()}`;
      // Create the CmsSection layout entry so it appears in homepage layout
      const allSections = await CmsSection.find({});
      const newPriority = allSections.length;
      const layoutSection = new CmsSection({
        id: newId,
        title: title,
        type: 'custom_section',
        priority: newPriority,
        isActive: isActive !== false
      });
      await layoutSection.save();
      section = new CustomSection({
        id: newId,
        title, subtitle, bannerImageUrl, bannerBadgeText,
        bannerActionType: bannerActionType || 'No Action',
        bannerActionValue,
        seeAllActionType: seeAllActionType || 'No Action',
        seeAllActionValue,
        serviceItems: serviceItems || [],
        priority: parseInt(priority) || newPriority,
        isActive: isActive !== false
      });
      await section.save();
    }
    res.json({ success: true, section });
  } catch (e) {
    console.error('Error saving custom section:', e);
    res.status(500).json({ error: 'Failed to save custom section' });
  }
});

app.delete('/api/custom-sections/:id', async (req, res) => {
  try {
    const deleted = await CustomSection.findOneAndDelete({ id: req.params.id });
    // Also remove from CmsSection layout
    await CmsSection.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true, section: deleted });
    } else {
      res.status(404).json({ error: 'Custom section not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Delete custom section failed' });
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
  const { title, code, percent, imageUrl, redirectUrl, priority, expiryDate } = req.body;
  try {
    const newBanner = new Banner({
      id: `banner-${Date.now()}`,
      title: title || '',
      code: code || '',
      percent: percent || '',
      imageUrl: imageUrl || 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
      redirectUrl: redirectUrl || '',
      priority: parseInt(priority) || 0,
      expiryDate: expiryDate || '',
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

app.post('/api/checkout/calculate', async (req, res) => {
  const { shopId, items, couponCode } = req.body;
  if (!shopId || !items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'shopId and items are required' });
  }
  try {
    const shop = await Shop.findOne({ id: shopId });
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }
    const result = await calculateCheckoutPriceInternal(shop, items, couponCode);
    res.json({ success: true, ...result });
  } catch (e) {
    console.error('Calculate pricing failed:', e);
    res.status(500).json({ error: 'Failed to calculate pricing' });
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
    
    // Apply privacy masking for providers if fetching shop's bookings
    const sanitizedList = list.map(b => {
      if (shopId) {
        return sanitizeBookingForPrivacy(b);
      }
      return b;
    });

    res.json(sanitizedList);
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

    const shop = await Shop.findOne({ id: shopId });
    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    // Recalculate amount using backend pricing engine
    let parsedAmount = parseFloat(amount);
    let visitingCharges = shop.visitingCharges || 150.0;
    let bookingPricingType = req.body.pricingType || 'fixed';

    if (req.body.items && Array.isArray(req.body.items) && req.body.items.length > 0) {
      const calc = await calculateCheckoutPriceInternal(shop, req.body.items, req.body.couponCode);
      parsedAmount = calc.grandTotal;
      visitingCharges = calc.visitingCharge;
      bookingPricingType = calc.pricingType;
    }

    if (paymentMethod === 'Wallet') {
      if (!user) {
        return res.status(401).json({ error: 'Unauthorized: Authentication required for wallet payment' });
      }
      if ((user.walletBalance || 0) < parsedAmount) {
        return res.status(400).json({ error: 'Insufficient wallet balance' });
      }
      user.walletBalance = (user.walletBalance || 0) - parsedAmount;
      user.walletTransactions = user.walletTransactions || [];
      user.walletTransactions.push({
        id: `TX-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`,
        title: `Paid for ${title}`,
        amount: parsedAmount,
        type: 'debit',
        date: new Date()
      });
      await user.save();
    }

    const bookingId = `QF-${Math.floor(100000 + Math.random() * 900000)}`;
    const commissionRate = shop.commissionRate || 15.0;
    const providerName = shop.ownerName || 'Assigning Expert...';
    const estEarnings = parseFloat((parsedAmount * (1 - commissionRate / 100)).toFixed(2));
    
    const addr = customerAddress || (user && user.savedAddresses && user.savedAddresses[0]) || '113, Swaroop Nagar, Kanpur';
    const addrParts = addr.split(',');
    const approxAddress = addrParts.length > 1 
      ? `${addrParts[addrParts.length - 2].trim()}, ${addrParts[addrParts.length - 1].trim()}`
      : addr;

    const newBooking = new Booking({
      id: bookingId,
      customerId: user ? user._id : (customerId || 'cust-123'),
      customerName: user ? user.name : (customerName || 'John Doe'),
      customerPhone: user ? user.phone : (customerPhone || '9999888877'),
      customerAddress: addr,
      approxAddress: approxAddress,
      customerLat: req.body.latitude || (user && user.savedAddresses && user.savedAddresses[0] && user.savedAddresses[0].latitude) || 26.4912,
      customerLng: req.body.longitude || (user && user.savedAddresses && user.savedAddresses[0] && user.savedAddresses[0].longitude) || 80.3156,
      shopId,
      title,
      slot: slot || '09:00 AM - 10:00 AM',
      date: date ? new Date(date) : new Date(),
      amount: parsedAmount,
      visitingCharges,
      estEarnings,
      estDuration: req.body.durationText || '1.5 hrs',
      specialInstructions: req.body.specialInstructions || '',
      status: 'pending',
      providerName: providerName,
      pricingType: bookingPricingType
    });

    await newBooking.save();

    // Send Booking Created push notification to customer
    sendFcmNotification(
      newBooking.customerId,
      'Booking Created 🎉',
      `Your booking QF-${bookingId} for "${title}" has been successfully created.`,
      {
        type: 'booking',
        bookingId: bookingId,
        iconColor: 'success'
      }
    );

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

    const oldStatus = booking.status;
    booking.status = status;
    if (providerName) {
      booking.providerName = providerName;
    }

    await booking.save();

    // Send FCM push notification depending on new status
    let fcmTitle = '';
    let fcmBody = '';
    let fcmIconColor = 'primary';

    switch (status) {
      case 'accepted':
        fcmTitle = 'Booking Accepted 🛠️';
        fcmBody = `Your booking for "${booking.title}" has been accepted by ${booking.providerName || 'our expert'}.`;
        fcmIconColor = 'success';
        break;
      case 'navigating':
      case 'on_the_way':
        fcmTitle = 'Provider En Route 🛵';
        fcmBody = `Your provider ${booking.providerName || 'expert'} has started traveling to your location.`;
        fcmIconColor = 'info';
        break;
      case 'arrived':
        fcmTitle = 'Provider Arrived 📍';
        fcmBody = `Your provider ${booking.providerName || 'expert'} has arrived at your location.`;
        fcmIconColor = 'success';
        break;
      case 'work_started':
        fcmTitle = 'Service Started ⚙️';
        fcmBody = `Work has successfully started for "${booking.title}".`;
        fcmIconColor = 'info';
        break;
      case 'completed':
      case 'work_completed':
        fcmTitle = 'Service Completed ✅';
        fcmBody = `Your service for "${booking.title}" is complete. Please verify and pay.`;
        fcmIconColor = 'success';
        break;
      case 'payment_completed':
        fcmTitle = 'Payment Successful 💳';
        fcmBody = `Payment of ₹${booking.amount} has been successfully processed. Thank you!`;
        fcmIconColor = 'success';
        break;
      case 'cancelled':
        fcmTitle = 'Booking Cancelled ❌';
        fcmBody = `Your booking for "${booking.title}" has been cancelled.`;
        fcmIconColor = 'error';
        break;
      default:
        break;
    }

    if (fcmTitle && fcmBody) {
      sendFcmNotification(booking.customerId, fcmTitle, fcmBody, {
        type: 'booking_status',
        bookingId: booking.id,
        iconColor: fcmIconColor
      });
    }

    // Credit provider's wallet if transitioned to completed or closed
    if ((status === 'completed' || status === 'closed' || status === 'payment_completed') && 
        (oldStatus !== 'completed' && oldStatus !== 'closed' && oldStatus !== 'payment_completed')) {
      const shop = await Shop.findOne({ id: booking.shopId });
      if (shop) {
        const earnings = booking.estEarnings || (booking.amount * 0.85);
        shop.walletBalance = (shop.walletBalance || 0.0) + earnings;
        if (!shop.walletTransactions) shop.walletTransactions = [];
        shop.walletTransactions.push({
          id: `TX-EARN-${Date.now()}`,
          title: `Earnings for ${booking.title}`,
          amount: parseFloat(earnings.toFixed(2)),
          type: 'credit',
          date: new Date()
        });
        await shop.save();
      }
    }

    res.json({ success: true, booking });
  } catch (e) {
    console.error('Update status error:', e);
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

    if (['on_the_way', 'navigating', 'arrived', 'work_started', 'work_completed', 'payment_completed', 'completed', 'closed'].includes(booking.status)) {
      return res.status(400).json({ error: 'Cannot cancel order once provider has started travel or work is in progress!' });
    }

    booking.status = 'cancelled';
    await booking.save();

    // Notify customer
    sendFcmNotification(
      booking.customerId,
      'Booking Cancelled ❌',
      `Your booking QF-${id} for "${booking.title}" has been cancelled.`,
      {
        type: 'booking_status',
        bookingId: id,
        iconColor: 'error'
      }
    );

    res.json({ success: true, booking });
  } catch (e) {
    res.status(500).json({ error: 'Failed to cancel booking' });
  }
});

// Quotation Upload & Respond Endpoints
app.post('/api/bookings/:bookingId/quotation', async (req, res) => {
  const { bookingId } = req.params;
  const { labourCharge, spareParts, additionalMaterials, visitingCharges, discount, gst } = req.body;
  try {
    const booking = await Booking.findOne({ id: bookingId });
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const lC = parseFloat(labourCharge) || 0.0;
    const sP = parseFloat(spareParts) || 0.0;
    const aM = parseFloat(additionalMaterials) || 0.0;
    const vC = parseFloat(visitingCharges) || 0.0;
    const disc = parseFloat(discount) || 0.0;
    const gstPct = parseFloat(gst) || 0.0;

    const subtotal = lC + sP + aM + vC - disc;
    const gstAmt = parseFloat((subtotal * (gstPct / 100)).toFixed(2));
    const totalAmount = subtotal + gstAmt;

    booking.quotation = {
      labourCharge: lC,
      spareParts: sP,
      additionalMaterials: aM,
      visitingCharges: vC,
      discount: disc,
      gst: gstAmt,
      totalAmount: parseFloat(totalAmount.toFixed(2)),
      status: 'pending',
      updatedAt: new Date(),
      createdAt: booking.quotation && booking.quotation.createdAt ? booking.quotation.createdAt : new Date()
    };

    booking.status = 'quote_sent';
    
    if (!booking.quotationHistory) {
      booking.quotationHistory = [];
    }
    booking.quotationHistory.push({
      ...booking.quotation,
      date: new Date()
    });

    await booking.save();

    // Notify customer
    sendFcmNotification(
      booking.customerId,
      'New Quotation Received 📋',
      `A new quotation of ₹${totalAmount.toFixed(2)} has been sent for "${booking.title}".`,
      {
        type: 'booking_status',
        bookingId: bookingId,
        iconColor: 'info'
      }
    );

    res.json({ success: true, booking });
  } catch (e) {
    console.error('Quotation upload failed:', e);
    res.status(500).json({ error: 'Failed to upload quotation' });
  }
});

app.post('/api/bookings/:bookingId/quotation/respond', async (req, res) => {
  const { bookingId } = req.params;
  const { response, comment } = req.body;
  try {
    const booking = await Booking.findOne({ id: bookingId });
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    if (!booking.quotation) {
      return res.status(400).json({ error: 'No quotation found to respond to' });
    }

    booking.quotation.status = response;
    booking.quotation.updatedAt = new Date();

    if (!booking.quotationHistory) {
      booking.quotationHistory = [];
    }
    booking.quotationHistory.push({
      action: `respond_${response}`,
      comment: comment || '',
      date: new Date()
    });

    if (response === 'accepted') {
      booking.status = 'work_started';
      booking.amount = booking.quotation.totalAmount;
      
      const shop = await Shop.findOne({ id: booking.shopId });
      const commissionRate = shop ? (shop.commissionRate || 15.0) : 15.0;
      booking.estEarnings = parseFloat((booking.amount * (1 - commissionRate / 100)).toFixed(2));
    } else if (response === 'rejected') {
      booking.status = 'cancelled';
    } else if (response === 'modify') {
      booking.status = 'arrived';
      booking.quotation.status = 'modified';
    }

    await booking.save();
    res.json({ success: true, booking });
  } catch (e) {
    console.error('Quotation response failed:', e);
    res.status(500).json({ error: 'Failed to respond to quotation' });
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
  const { title, body, icon, iconColor, audience, channel } = req.body;
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

    // Dispatch FCM Push Notification to topic based on audience selection
    if (audience === 'shops') {
      sendFcmTopicNotification('providers', title, body, {
        type: 'broadcast',
        icon: icon || 'notifications_active',
        iconColor: iconColor || 'primary'
      });
    } else if (audience === 'all') {
      sendFcmTopicNotification('customers', title, body, {
        type: 'broadcast',
        icon: icon || 'notifications_active',
        iconColor: iconColor || 'primary'
      });
      sendFcmTopicNotification('providers', title, body, {
        type: 'broadcast',
        icon: icon || 'notifications_active',
        iconColor: iconColor || 'primary'
      });
    } else {
      // Default: customers topic
      sendFcmTopicNotification('customers', title, body, {
        type: 'broadcast',
        icon: icon || 'notifications_active',
        iconColor: iconColor || 'primary'
      });
    }

    res.json({ success: true, alert: newAlert });
  } catch (e) {
    res.status(500).json({ error: 'Failed to send alert notification' });
  }
});

// --- ADMIN AND ENTERPRISE MANAGEMENT SYSTEM ENDPOINTS ---

// Admin system stats
app.get('/api/admin/stats', async (req, res) => {
  try {
    const users = await User.find({});
    const shops = await Shop.find({});
    const bookings = await Booking.find({});
    const offers = await Offer.find({});
    const alerts = await Notification.find({});

    const totalCustomers = users.filter(u => u.accountStatus !== 'deleted').length;
    const totalShops = shops.length;
    const totalProviders = shops.filter(s => s.verificationStatus === 'approved').length;

    const pendingBookings = bookings.filter(b => b.status === 'pending').length;
    const activeBookings = bookings.filter(b => b.status === 'accepted' || b.status === 'on_the_way').length;
    const completedBookings = bookings.filter(b => b.status === 'completed').length;
    const cancelledBookings = bookings.filter(b => b.status === 'cancelled').length;

    let revenue = 0;
    bookings.forEach(b => {
      if (b.status === 'completed') {
        revenue += (parseFloat(b.amount) || 0);
      }
    });

    let walletBalance = 0;
    users.forEach(u => {
      walletBalance += (parseFloat(u.walletBalance) || 0);
    });

    const onlineShops = shops.filter(s => s.isOnline && s.verificationStatus === 'approved' && s.status === 'active').length;
    const offlineShops = totalShops - onlineShops;

    let totalServices = 0;
    shops.forEach(s => {
      if (s.services) {
        totalServices += s.services.length;
      }
    });

    const activeCoupons = offers.filter(o => o.isActive).length;
    const notificationsSent = alerts.length;

    // Today's orders
    const today = new Date();
    today.setHours(0,0,0,0);
    const todaysOrders = bookings.filter(b => {
      const bDate = new Date(b.createdAt || b.date);
      return bDate >= today;
    }).length;

    res.json({
      totalCustomers,
      totalShops,
      totalProviders,
      activeBookings,
      pendingBookings,
      completedBookings,
      cancelledBookings,
      revenue: parseFloat(revenue.toFixed(2)),
      walletBalance: parseFloat(walletBalance.toFixed(2)),
      onlineShops,
      offlineShops,
      totalServices,
      activeCoupons,
      notificationsSent,
      todaysOrders
    });
  } catch (e) {
    console.error('Stats error:', e);
    res.status(500).json({ error: 'Failed to load system stats' });
  }
});

// Reports summary API for Chart.js
app.get('/api/reports/summary', async (req, res) => {
  try {
    const bookings = await Booking.find({});
    const daily = {};
    const last7Days = [];
    
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
      last7Days.push(dateStr);
      daily[dateStr] = { revenue: 0, count: 0 };
    }

    bookings.forEach(b => {
      const bDate = new Date(b.createdAt || b.date);
      const dateStr = bDate.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
      if (daily[dateStr]) {
        daily[dateStr].count += 1;
        if (b.status === 'completed') {
          daily[dateStr].revenue += (parseFloat(b.amount) || 0);
        }
      }
    });

    const dailyData = last7Days.map(day => ({
      date: day,
      revenue: parseFloat(daily[day].revenue.toFixed(2)),
      bookings: daily[day].count
    }));

    const categoryStats = {};
    const shops = await Shop.find({});
    const shopCategoryMap = {};
    shops.forEach(s => {
      shopCategoryMap[s.id] = s.categories || [];
    });

    bookings.forEach(b => {
      const cats = shopCategoryMap[b.shopId] || ['General'];
      cats.forEach(c => {
        if (!categoryStats[c]) {
          categoryStats[c] = { revenue: 0, count: 0 };
        }
        categoryStats[c].count += 1;
        if (b.status === 'completed') {
          categoryStats[c].revenue += (parseFloat(b.amount) || 0);
        }
      });
    });

    res.json({
      daily: dailyData,
      categories: Object.entries(categoryStats).map(([name, val]) => ({
        name,
        revenue: parseFloat(val.revenue.toFixed(2)),
        bookings: val.count
      }))
    });
  } catch (e) {
    console.error('Reports summary error:', e);
    res.status(500).json({ error: 'Failed to load report data' });
  }
});

// Customer management
app.get('/api/users', async (req, res) => {
  try {
    const list = await User.find({});
    res.json(list.filter(u => u.accountStatus !== 'deleted'));
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

app.post('/api/users/wallet-adjust', async (req, res) => {
  const { userId, amount, type, title } = req.body;
  if (!userId || isNaN(amount)) {
    return res.status(400).json({ error: 'userId and valid amount are required' });
  }
  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    const val = parseFloat(amount);
    if (type === 'credit') {
      user.walletBalance = (user.walletBalance || 0) + val;
    } else {
      user.walletBalance = Math.max(0, (user.walletBalance || 0) - val);
    }
    user.walletTransactions = user.walletTransactions || [];
    user.walletTransactions.push({
      id: `TX-ADJ-${Date.now()}`,
      title: title || `Adjusted by Admin`,
      amount: val,
      type: type || 'credit',
      date: new Date()
    });
    await user.save();

    // Notify customer
    sendFcmNotification(
      user._id,
      type === 'credit' ? 'Wallet Credited 💰' : 'Wallet Debited 💸',
      type === 'credit' 
        ? `Your wallet has been credited with ₹${val.toFixed(2)}: ${title || 'Adjusted by Admin'}.`
        : `Your wallet has been debited by ₹${val.toFixed(2)}: ${title || 'Adjusted by Admin'}.`,
      {
        type: 'wallet_update',
        iconColor: type === 'credit' ? 'success' : 'warning'
      }
    );

    res.json({ success: true, walletBalance: user.walletBalance });
  } catch (e) {
    res.status(500).json({ error: 'Failed to adjust wallet' });
  }
});

app.post('/api/users/toggle-status', async (req, res) => {
  const { userId } = req.body;
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.accountStatus = user.accountStatus === 'active' ? 'inactive' : 'active';
    await user.save();
    res.json({ success: true, status: user.accountStatus });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update user status' });
  }
});

// Admin-facing list of all shops
app.get('/api/shops/all', async (req, res) => {
  try {
    const list = await Shop.find({});
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch all shops' });
  }
});

// Shop Verification Status management
app.post('/api/shops/approve', async (req, res) => {
  const { id, verificationStatus } = req.body;
  try {
    const shop = await Shop.findOne({ id });
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    shop.verificationStatus = verificationStatus;
    await shop.save();
    res.json({ success: true, shop });
  } catch (e) {
    res.status(500).json({ error: 'Failed to verify shop' });
  }
});

// Suspend Shop management
app.post('/api/shops/suspend', async (req, res) => {
  const { id, suspend } = req.body;
  try {
    const shop = await Shop.findOne({ id });
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    shop.status = suspend ? 'suspended' : 'active';
    await shop.save();
    res.json({ success: true, shop });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update shop suspend state' });
  }
});

// Disable Login management
app.post('/api/shops/toggle-login', async (req, res) => {
  const { id, loginDisabled } = req.body;
  try {
    const shop = await Shop.findOne({ id });
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    shop.loginDisabled = loginDisabled;
    await shop.save();
    res.json({ success: true, shop });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update login status' });
  }
});

// Reset Password management
app.post('/api/shops/reset-password', async (req, res) => {
  const { id } = req.body;
  try {
    const shop = await Shop.findOne({ id });
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    const tempPassword = 'QF@' + Math.floor(10000 + Math.random() * 90000);
    const salt = bcrypt.genSaltSync(10);
    shop.password = bcrypt.hashSync(tempPassword, salt);
    shop.tempPassword = tempPassword;
    await shop.save();
    res.json({ success: true, tempPassword, shop });
  } catch (e) {
    res.status(500).json({ error: 'Failed to reset password' });
  }
});

// Banners & Coupons Updates
app.post('/api/banners/update', async (req, res) => {
  const { id, title, code, percent, imageUrl, redirectUrl, priority, expiryDate } = req.body;
  try {
    const banner = await Banner.findOneAndUpdate(
      { id },
      { title, code, percent, imageUrl, redirectUrl, priority: parseInt(priority) || 0, expiryDate },
      { new: true }
    );
    if (!banner) return res.status(404).json({ error: 'Banner not found' });
    res.json({ success: true, banner });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update banner' });
  }
});

app.post('/api/offers/update', async (req, res) => {
  const { code, title, description, minOrderAmount, maxDiscount, expiryDate, usageLimit } = req.body;
  try {
    const offer = await Offer.findOneAndUpdate(
      { code: code.toUpperCase() },
      { 
        title, 
        description, 
        minOrderAmount: parseFloat(minOrderAmount) || 0, 
        maxDiscount: parseFloat(maxDiscount) || 0, 
        expiryDate, 
        usageLimit: parseInt(usageLimit) || 0 
      },
      { new: true }
    );
    if (!offer) return res.status(404).json({ error: 'Offer not found' });
    res.json({ success: true, offer });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update offer' });
  }
});

// Global settings
app.get('/api/settings', async (req, res) => {
  try {
    const settingsList = await Settings.find({});
    const settingsObj = {};
    settingsList.forEach(s => {
      settingsObj[s.key] = s.value;
    });
    res.json({
      taxRate: settingsObj.taxRate !== undefined ? settingsObj.taxRate : 5.0,
      commission: settingsObj.commission !== undefined ? settingsObj.commission : 10.0,
      visitingCharges: settingsObj.visitingCharges !== undefined ? settingsObj.visitingCharges : 150.0,
      supportNumber: settingsObj.supportNumber !== undefined ? settingsObj.supportNumber : '9876543210',
      terms: settingsObj.terms !== undefined ? settingsObj.terms : 'Standard Terms & Conditions apply.',
      privacy: settingsObj.privacy !== undefined ? settingsObj.privacy : 'Standard Privacy Policy applies.',
      emergencyContact: settingsObj.emergencyContact !== undefined ? settingsObj.emergencyContact : '100',
      appVersion: settingsObj.appVersion !== undefined ? settingsObj.appVersion : '1.0.0',
      maintenanceMode: settingsObj.maintenanceMode !== undefined ? settingsObj.maintenanceMode : false
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load app settings' });
  }
});

app.post('/api/settings', async (req, res) => {
  try {
    const updatePromises = Object.entries(req.body).map(async ([key, value]) => {
      return Settings.findOneAndUpdate(
        { key },
        { key, value },
        { upsert: true, new: true }
      );
    });
    await Promise.all(updatePromises);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

// Audit Logs
app.get('/api/audit-logs', async (req, res) => {
  try {
    const logs = await AuditLog.find({}).sort({ createdAt: -1 });
    res.json(logs);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load audit logs' });
  }
});

app.post('/api/audit-logs', async (req, res) => {
  const { action, target, details } = req.body;
  try {
    const log = new AuditLog({
      id: `log-${Date.now()}`,
      action,
      target,
      details,
      ip: req.ip || '127.0.0.1'
    });
    await log.save();
    res.json({ success: true, log });
  } catch (e) {
    res.status(500).json({ error: 'Failed to create audit log' });
  }
});

// Category image upload — stores in Cloudinary and returns imageUrl
app.post('/api/categories/upload-image', async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    if (!base64Image) {
      return res.status(400).json({ error: 'base64Image is required' });
    }
    const dataUri = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;
    
    const uploadResponse = await cloudinary.uploader.upload(dataUri, {
      folder: 'quickfix_categories',
      resource_type: 'image',
    });

    const imageUrl = uploadResponse.secure_url;
    res.json({ success: true, imageUrl });
  } catch (e) {
    console.error('Cloudinary category image upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload category image: ${e.message || e}` });
  }
});

// Banner image upload — stores in Cloudinary and returns imageUrl
app.post('/api/banners/upload-image', async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    if (!base64Image) {
      return res.status(400).json({ error: 'base64Image is required' });
    }
    const dataUri = `data:${mimeType || 'image/jpeg'};base64,${base64Image}`;
    
    const uploadResponse = await cloudinary.uploader.upload(dataUri, {
      folder: 'quickfix_banners',
      resource_type: 'image',
    });

    const imageUrl = uploadResponse.secure_url;
    res.json({ success: true, imageUrl });
  } catch (e) {
    console.error('Cloudinary banner image upload error:', e.message || e);
    res.status(500).json({ error: `Failed to upload banner image: ${e.message || e}` });
  }
});

// Category creation & deletion
app.post('/api/categories/create', async (req, res) => {
  const { id, name, iconUrl } = req.body;
  if (!id || !name) return res.status(400).json({ error: 'id and name are required' });
  try {
    const cat = new Category({ id: id.toLowerCase(), name, iconUrl: iconUrl || '', isActive: true });
    await cat.save();
    res.json({ success: true, category: cat });
  } catch (e) {
    res.status(500).json({ error: 'Failed to create category' });
  }
});

app.post('/api/categories/update', async (req, res) => {
  const { id, name, iconUrl } = req.body;
  if (!id) return res.status(400).json({ error: 'id is required' });
  try {
    const cat = await Category.findOneAndUpdate(
      { id: id.toLowerCase() },
      { name, iconUrl },
      { new: true }
    );
    if (!cat) return res.status(404).json({ error: 'Category not found' });
    res.json({ success: true, category: cat });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update category' });
  }
});

app.delete('/api/categories/:id', async (req, res) => {
  try {
    const deleted = await Category.findOneAndDelete({ id: req.params.id });
    if (deleted) {
      res.json({ success: true });
    } else {
      res.status(404).json({ error: 'Category not found' });
    }
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete category' });
  }
});

// --- DATABASE AUTO-SEEDER ---
async function seedDatabase() {
  return; // Auto-seeding disabled to allow starting with a 100% fresh database
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
      const hashedPassword = bcrypt.hashSync('QF@49321', salt);
      
      await Shop.create({
        id: 'shop-1',
        shopDisplayId: 'QFS000135',
        name: "QuickFix Solutions Hub",
        ownerName: "Amit Sharma",
        password: hashedPassword,
        phone: "9876543210",
        email: "amit@quickfix.com",
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
        isFirstLogin: true,
        ownerPhone: "9876543210",
        ownerEmail: "amit@quickfix.com",
        walletBalance: 2450.0,
        walletTransactions: [
          {
            id: 'TX-INIT',
            title: 'Initial Wallet Balance',
            amount: 2450.0,
            type: 'credit',
            date: new Date()
          }
        ],
        workingHours: {
          'Monday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
          'Tuesday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
          'Wednesday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
          'Thursday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
          'Friday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
          'Saturday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
          'Sunday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' }
        },
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
      console.log('Seeded default shop partner (ID: QFS000135, password: QF@49321).');
    }

  } catch (e) {
    console.error('Failed to seed database lists:', e.message);
  }
}

app.listen(PORT, () => {
  console.log(`QuickFix Backend Server listening at http://localhost:${PORT}`);
});
