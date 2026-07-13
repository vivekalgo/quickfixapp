const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, 'database.json');
let useLocalDb = false;

function setUseLocalDb(val) {
  useLocalDb = val;
}

// Helper to read JSON database safely
function readDb() {
  try {
    if (!fs.existsSync(dbPath)) {
      fs.writeFileSync(dbPath, JSON.stringify({}));
    }
    const data = JSON.parse(fs.readFileSync(dbPath, 'utf8'));
    const collections = ['users', 'shops', 'bookings', 'categories', 'reviews', 'professionals', 'banners', 'offers', 'notifications', 'demands', 'promotions', 'specialcards', 'cmssections', 'customsections'];
    let changed = false;
    for (const col of collections) {
      if (!data[col]) {
        data[col] = [];
        changed = true;
      }
    }
    if (changed) {
      fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
    }
    return data;
  } catch (err) {
    console.error('Error reading JSON DB:', err);
    return {};
  }
}

// Helper to write JSON database safely
function writeDb(data) {
  try {
    fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Error writing JSON DB:', err);
  }
}

// Matches query against local object fields (supporting basic MongoDB operators)
function matchesQuery(doc, query) {
  if (!query || Object.keys(query).length === 0) return true;
  for (const [key, val] of Object.entries(query)) {
    if (val && typeof val === 'object' && !Array.isArray(val)) {
      const operators = Object.keys(val);
      for (const op of operators) {
        if (op === '$ne') {
          if (doc[key] === val['$ne']) return false;
        } else if (op === '$in') {
          if (!Array.isArray(val['$in']) || !val['$in'].includes(doc[key])) return false;
        } else if (op === '$nin') {
          if (Array.isArray(val['$nin']) && val['$nin'].includes(doc[key])) return false;
        } else if (op === '$gt') {
          if (!(doc[key] > val['$gt'])) return false;
        } else if (op === '$gte') {
          if (!(doc[key] >= val['$gte'])) return false;
        } else if (op === '$lt') {
          if (!(doc[key] < val['$lt'])) return false;
        } else if (op === '$lte') {
          if (!(doc[key] <= val['$lte'])) return false;
        } else {
          if (JSON.stringify(doc[key]) !== JSON.stringify(val)) return false;
        }
      }
    } else {
      if (doc[key] !== val) return false;
    }
  }
  return true;
}

// Wraps plain JS object with mongoose-like save() and toObject() methods
function wrapDoc(doc, collectionName) {
  if (!doc) return null;
  const wrapped = { ...doc };
  if (!wrapped._id && wrapped.id) {
    wrapped._id = wrapped.id;
  } else if (!wrapped._id) {
    wrapped._id = 'id_' + Math.random().toString(36).substr(2, 9);
  }

  Object.defineProperty(wrapped, 'toObject', {
    value: function() {
      return this;
    },
    writable: true,
    configurable: true
  });

  Object.defineProperty(wrapped, 'save', {
    value: async function() {
      const db = readDb();
      const list = db[collectionName] || [];
      const idx = list.findIndex(d => (d.id && d.id === this.id) || (d._id && d._id === this._id));

      const cleanDoc = {};
      for (const [k, v] of Object.entries(this)) {
        if (typeof v !== 'function') {
          cleanDoc[k] = v;
        }
      }

      if (idx !== -1) {
        cleanDoc.updatedAt = new Date().toISOString();
        list[idx] = cleanDoc;
      } else {
        cleanDoc.createdAt = new Date().toISOString();
        cleanDoc.updatedAt = new Date().toISOString();
        list.push(cleanDoc);
      }
      db[collectionName] = list;
      writeDb(db);
      return this;
    },
    writable: true,
    configurable: true
  });

  return wrapped;
}

// Custom array with mongoose-like sort() capability
function makeResultArray(arr, collectionName) {
  const result = arr.map(doc => wrapDoc(doc, collectionName));
  result.sort = function(sortObj) {
    const key = Object.keys(sortObj)[0];
    const dir = sortObj[key];
    return Array.prototype.sort.call(result, (a, b) => {
      let valA = a[key];
      let valB = b[key];
      if (valA instanceof Date) valA = valA.getTime();
      if (valB instanceof Date) valB = valB.getTime();
      if (typeof valA === 'string' && !isNaN(Date.parse(valA))) valA = new Date(valA).getTime();
      if (typeof valB === 'string' && !isNaN(Date.parse(valB))) valB = new Date(valB).getTime();

      if (valA < valB) return dir === -1 ? 1 : -1;
      if (valA > valB) return dir === -1 ? -1 : 1;
      return 0;
    });
  };
  return result;
}

// Local mock models defaults — NO hardcoded names or fake data
const modelDefaults = {
  User: {
    name: '',
    email: '',
    membership: 'basic',
    walletBalance: 0.0,
    walletTransactions: [],
    savedAddresses: [],
    avatarUrl: '',
    gender: '',
    dob: '',
    alternatePhone: '',
    emergencyContact: '',
    preferredLanguage: 'English',
    isPhoneVerified: true,
    accountStatus: 'active',
    referralCode: '',
    referralCount: 0,
    referralRewardsEarned: 0
  }
};

// Generates a mock model class
function createMockModel(modelName, collectionName) {
  class MockModel {
    constructor(data) {
      const defaults = modelDefaults[modelName] || {};
      Object.assign(this, defaults, data);
      if (!this.id && !this._id) {
        this._id = 'id_' + Math.random().toString(36).substr(2, 9);
      }
      return wrapDoc(this, collectionName);
    }

    static async find(query) {
      const db = readDb();
      const list = db[collectionName] || [];
      const filtered = list.filter(doc => matchesQuery(doc, query));
      return makeResultArray(filtered, collectionName);
    }

    static async findOne(query) {
      const db = readDb();
      const list = db[collectionName] || [];
      const found = list.find(doc => matchesQuery(doc, query));
      return found ? wrapDoc(found, collectionName) : null;
    }

    static async findById(id) {
      const db = readDb();
      const list = db[collectionName] || [];
      const found = list.find(doc => doc._id === id || doc.id === id);
      return found ? wrapDoc(found, collectionName) : null;
    }

    static async countDocuments(query) {
      const db = readDb();
      const list = db[collectionName] || [];
      return list.filter(doc => matchesQuery(doc, query)).length;
    }

    static async create(data) {
      const doc = new MockModel(data);
      await doc.save();
      return doc;
    }

    static async insertMany(arr) {
      const db = readDb();
      const list = db[collectionName] || [];
      const inserted = [];
      for (const item of arr) {
        const doc = {
          ...item,
          _id: item._id || item.id || 'id_' + Math.random().toString(36).substr(2, 9),
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        list.push(doc);
        inserted.push(wrapDoc(doc, collectionName));
      }
      db[collectionName] = list;
      writeDb(db);
      return inserted;
    }

    static async findOneAndUpdate(query, updateData, options) {
      const db = readDb();
      const list = db[collectionName] || [];
      const idx = list.findIndex(doc => matchesQuery(doc, query));
      if (idx === -1) return null;

      const updated = {
        ...list[idx],
        ...updateData,
        updatedAt: new Date().toISOString()
      };
      list[idx] = updated;
      db[collectionName] = list;
      writeDb(db);
      return wrapDoc(updated, collectionName);
    }

    static async findByIdAndUpdate(id, updateData, options) {
      return this.findOneAndUpdate({ _id: id }, updateData, options);
    }

    static async findOneAndDelete(query) {
      const db = readDb();
      const list = db[collectionName] || [];
      const idx = list.findIndex(doc => matchesQuery(doc, query));
      if (idx === -1) return null;
      const deleted = list.splice(idx, 1)[0];
      db[collectionName] = list;
      writeDb(db);
      return wrapDoc(deleted, collectionName);
    }

    static async findByIdAndDelete(id) {
      return this.findOneAndDelete({ _id: id });
    }
  }

  return MockModel;
}

// 1. User Schema (Customer profiles)
const UserSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  membership: { type: String, default: 'basic' },
  walletBalance: { type: Number, default: 0.0 },
  walletTransactions: [{
    id: String,
    title: String,
    amount: Number,
    type: { type: String, enum: ['credit', 'debit'] },
    date: { type: Date, default: Date.now }
  }],
  savedAddresses: {
    type: [{
      id: String,
      label: String,
      address: String,
      latitude: Number,
      longitude: Number,
      isDefault: Boolean
    }],
    default: []
  },
  avatarUrl: { type: String, default: '' },
  gender: { type: String, default: '' },
  dob: { type: String, default: '' },
  alternatePhone: { type: String, default: '' },
  emergencyContact: { type: String, default: '' },
  preferredLanguage: { type: String, default: 'English' },
  isPhoneVerified: { type: Boolean, default: true },
  accountStatus: { type: String, enum: ['active', 'inactive', 'deleted'], default: 'active' },
  referralCode: { type: String, default: '' },
  referralCount: { type: Number, default: 0 },
  referralRewardsEarned: { type: Number, default: 0 },
  memberSince: { type: Date, default: Date.now }
}, { timestamps: true });

// 2. Service Item Schema (sub-document for Shop services)
const ServiceSchema = new mongoose.Schema({
  id: { type: String, required: true },
  title: { type: String, required: true },
  price: { type: Number, required: true },
  originalPrice: { type: Number },
  rating: { type: Number, default: 5.0 },
  reviewsCount: { type: Number, default: 0 },
  durationText: { type: String, default: '1 hr' },
  bulletPoints: [String],
  imageUrl: String,
  pricingType: { type: String, enum: ['fixed', 'starting', 'inspection', 'range'], default: 'fixed' },
  minPrice: { type: Number, default: 0 },
  maxPrice: { type: Number, default: 0 },
  visitingCharges: { type: Number, default: 0 },
  isFreeInspection: { type: Boolean, default: false },
  gst: { type: Number, default: 0 },
  extraCharges: { type: Number, default: 0 },
  extraChargesLabel: { type: String, default: '' },
  allowPriceEdit: { type: Boolean, default: true },
  allowVisitingEdit: { type: Boolean, default: true },
  isAvailable: { type: Boolean, default: true },
  isEnabled: { type: Boolean, default: true }
});

// 3. Shop Schema (Service Provider shop profile)
const ShopSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  shopDisplayId: { type: String, default: '' },
  name: { type: String, required: true },
  ownerName: { type: String, required: true },
  password: { type: String, required: true }, // will be hashed using bcrypt
  tempPassword: { type: String, default: '' },
  phone: { type: String, required: true, unique: true },
  email: { type: String, default: '' },
  latitude: { type: Number, default: 26.4912 },
  longitude: { type: Number, default: 80.3156 },
  address: { type: String, default: '' },
  serviceRadius: { type: Number, default: 5.0 },
  logoPath: { type: String, default: '' },
  logoUrl: { type: String, default: '' },
  categories: { type: [String], default: ["Cleaning"] },
  imagePath: { type: String, default: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300' },
  rating: { type: Number, default: 5.0 },
  reviewsCount: { type: Number, default: 0 },
  deliveryTimeMins: { type: Number, default: 20 },
  estimatedServiceTime: { type: String, default: '20 mins' },
  priceRange: { type: String, default: "₹₹" },
  isOnline: { type: Boolean, default: true },
  timings: { type: String, default: "09:00 AM - 09:00 PM" },
  portfolioImages: [String],
  services: [ServiceSchema],
  status: { type: String, enum: ['active', 'inactive', 'suspended'], default: 'active' },
  isOpen: { type: Boolean, default: true },
  verificationStatus: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'approved' },
  visitingCharges: { type: Number, default: 150.0 },
  technicians: { type: [String], default: [] },
  gst: { type: String, default: '' },
  pan: { type: String, default: '' },
  aadhaar: { type: String, default: '' },
  verificationDocs: { type: [String], default: [] },
  loginDisabled: { type: Boolean, default: false },
  // Provider App extensions
  isFirstLogin: { type: Boolean, default: true },
  ownerPhone: { type: String, default: '' },
  ownerEmail: { type: String, default: '' },
  ownerPhotoUrl: { type: String, default: '' },
  bankAccountNumber: { type: String, default: '' },
  ifscCode: { type: String, default: '' },
  upiId: { type: String, default: '' },
  walletBalance: { type: Number, default: 0.0 },
  walletTransactions: { type: Array, default: [] },
  commissionRate: { type: Number, default: 15.0 }, // 15% commission default
  workingHours: {
    type: Map,
    of: {
      isClosed: { type: Boolean, default: false },
      openTime: { type: String, default: '09:00 AM' },
      closeTime: { type: String, default: '09:00 PM' }
    },
    default: {
      'Monday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
      'Tuesday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
      'Wednesday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
      'Thursday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
      'Friday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
      'Saturday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' },
      'Sunday': { isClosed: false, openTime: '09:00 AM', closeTime: '09:00 PM' }
    }
  },
  holidays: { type: [String], default: [] },
  emergencyAvailable: { type: Boolean, default: false },
  reviewReplies: { type: Map, of: String, default: {} },
  providerLat: { type: Number },
  providerLng: { type: Number },
  fcmToken: { type: String, default: '' }
}, { timestamps: true });

// 4. Booking Schema (Service Orders)
const BookingSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true }, // QF-XXXXXX format
  customerId: { type: String, required: true },
  customerName: { type: String, required: true },
  customerPhone: { type: String, required: true },
  customerAddress: { type: String, required: true }, // complete full address
  approxAddress: { type: String, default: '' }, // e.g. "Swaroop Nagar, Kanpur"
  customerLat: { type: Number, default: 26.4912 },
  customerLng: { type: Number, default: 80.3156 },
  providerLat: { type: Number },
  providerLng: { type: Number },
  shopId: { type: String, required: true },
  title: { type: String, required: true }, // Description of items ordered
  slot: { type: String, required: true },
  date: { type: Date, required: true },
  amount: { type: Number, required: true },
  visitingCharges: { type: Number, default: 150.0 },
  estEarnings: { type: Number, default: 0.0 },
  estDuration: { type: String, default: '1.5 hrs' },
  specialInstructions: { type: String, default: '' },
  customerRating: { type: Number, default: 4.8 },
  pricingType: { type: String, enum: ['fixed', 'starting', 'inspection', 'range'], default: 'fixed' },
  status: { 
    type: String, 
    enum: ['pending', 'accepted', 'navigating', 'arrived', 'quote_sent', 'work_started', 'work_completed', 'payment_completed', 'cancelled', 'closed'], 
    default: 'pending' 
  },
  providerName: { type: String, default: 'Assigning Expert...' },
  quotation: {
    labourCharge: { type: Number, default: 0 },
    spareParts: { type: Number, default: 0 },
    additionalMaterials: { type: Number, default: 0 },
    visitingCharges: { type: Number, default: 0 },
    discount: { type: Number, default: 0 },
    gst: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
    status: { type: String, enum: ['pending', 'accepted', 'rejected', 'modified'], default: 'pending' },
    createdAt: { type: Date },
    updatedAt: { type: Date }
  },
  quotationHistory: { type: Array, default: [] }
}, { timestamps: true });

// 5. Category Schema
const CategorySchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  iconUrl: { type: String, default: '' },
  isActive: { type: Boolean, default: true }
});

// 6. Review Schema (Customer Feedbacks feed)
const ReviewSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  userName: { type: String, required: true },
  userAvatar: { type: String },
  rating: { type: Number, required: true },
  comment: { type: String, required: true },
  serviceName: { type: String },
  locationName: { type: String },
  shopId: { type: String, default: '' },
  reply: { type: String, default: '' },
  providerName: { type: String, default: '' },
  date: { type: String, default: '' },
  verifiedBadge: { type: Boolean, default: true },
  priority: { type: Number, default: 0 },
  status: { type: String, enum: ['approved', 'pending', 'rejected'], default: 'approved' },
  isActive: { type: Boolean, default: true },
  isFeatured: { type: Boolean, default: false }
});

// 7. Professional Schema (Top service experts cards)
const ProfessionalSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  specialty: { type: String, required: true },
  rating: { type: Number, default: 5.0 },
  reviewsCount: { type: Number, default: 0 },
  imageUrl: { type: String },
  shopId: { type: String, default: '' },
  experience: { type: String, default: '' },
  completedJobs: { type: Number, default: 0 },
  location: { type: String, default: '' },
  verifiedBadge: { type: Boolean, default: false },
  availability: { type: Boolean, default: true },
  featuredStatus: { type: String, default: 'Featured' },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
});

// 8. Promo Banner Schema (Carousel Banners)
const BannerSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, default: '' },
  code: { type: String, default: '' },
  percent: { type: String, default: '' },
  imageUrl: { type: String },
  isActive: { type: Boolean, default: true },
  redirectUrl: { type: String, default: '' },
  priority: { type: Number, default: 0 },
  expiryDate: { type: String, default: '' }
});

// 9. Promo Offer Coupon Schema
const OfferSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  isActive: { type: Boolean, default: true },
  minOrderAmount: { type: Number, default: 0 },
  maxDiscount: { type: Number, default: 0 },
  expiryDate: { type: String, default: '' },
  usageLimit: { type: Number, default: 0 },
  usedCount: { type: Number, default: 0 }
});

// 10. Broadcast Alert Notification Schema
const NotificationSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  time: { type: String, default: 'Just now' },
  icon: { type: String, default: 'notifications_active' },
  iconColor: { type: String, default: 'primary' }
}, { timestamps: true });

// 11. Customer Demand Schema
const DemandSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  phone: { type: String, required: true },
  address: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true }
}, { timestamps: true });

// 12. Settings Schema
const SettingsSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true },
  value: { type: mongoose.Schema.Types.Mixed }
});

// 13. Audit Log Schema
const AuditLogSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  adminId: { type: String, default: 'super-admin' },
  action: { type: String, required: true },
  target: { type: String, default: '' },
  details: { type: String, default: '' },
  ip: { type: String, default: '127.0.0.1' }
}, { timestamps: true });

// 14. Promotion Schema (Home Promotions / Festive Ribbon)
const PromotionSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  description: { type: String, default: '' },
  offerPercentage: { type: String, default: '' },
  couponCode: { type: String, default: '' },
  ctaButtonText: { type: String, default: 'Grab Now' },
  ctaButtonAction: { type: String, default: 'No Action' },
  ctaButtonActionValue: { type: String, default: '' },
  bannerImage: { type: String, default: '' },
  backgroundColor: { type: String, default: '#FFF1F0' },
  textColor: { type: String, default: '#000000' },
  buttonColor: { type: String, default: '#FF4D4F' },
  buttonTextColor: { type: String, default: '#FFFFFF' },
  priority: { type: Number, default: 0 },
  startDate: { type: String, default: '' },
  endDate: { type: String, default: '' },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

// 15. Special For You Card Schema
const SpecialCardSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  icon: { type: String, default: 'star' },
  imageUrl: { type: String, default: '' },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  description: { type: String, default: '' },
  backgroundColor: { type: String, default: '#FFFFFF' },
  buttonText: { type: String, default: 'View' },
  ctaAction: { type: String, default: 'No Action' },
  ctaActionValue: { type: String, default: '' },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  startDate: { type: String, default: '' },
  endDate: { type: String, default: '' }
}, { timestamps: true });

// 16. CMS Dynamic Layout Section Schema
const CmsSectionSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  type: { type: String, required: true },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  settings: { type: mongoose.Schema.Types.Mixed, default: {} }
}, { timestamps: true });

// 17. Custom Homepage Section Service Item Schema (sub-document)
const CustomSectionServiceItemSchema = new mongoose.Schema({
  id: { type: String, required: true },
  title: { type: String, required: true },
  imageUrl: { type: String, default: '' },
  rating: { type: Number, default: 4.5 },
  reviewsCount: { type: String, default: '' },
  startingPrice: { type: String, default: '' },
  actionType: { type: String, default: 'Open Shop' },
  actionValue: { type: String, default: '' }
});

// 17. Custom Homepage Section Schema (banner + service card list)
const CustomSectionSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  bannerImageUrl: { type: String, default: '' },
  bannerBadgeText: { type: String, default: '' },
  bannerActionType: { type: String, default: 'Open Category' },
  bannerActionValue: { type: String, default: '' },
  seeAllActionType: { type: String, default: 'Open Category' },
  seeAllActionValue: { type: String, default: '' },
  serviceItems: { type: [CustomSectionServiceItemSchema], default: [] },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

const MongooseModels = {
  User: mongoose.model('User', UserSchema),
  Shop: mongoose.model('Shop', ShopSchema),
  Booking: mongoose.model('Booking', BookingSchema),
  Category: mongoose.model('Category', CategorySchema),
  Review: mongoose.model('Review', ReviewSchema),
  Professional: mongoose.model('Professional', ProfessionalSchema),
  Banner: mongoose.model('Banner', BannerSchema),
  Offer: mongoose.model('Offer', OfferSchema),
  Notification: mongoose.model('Notification', NotificationSchema),
  Demand: mongoose.model('Demand', DemandSchema),
  Settings: mongoose.model('Settings', SettingsSchema),
  AuditLog: mongoose.model('AuditLog', AuditLogSchema),
  Promotion: mongoose.model('Promotion', PromotionSchema),
  SpecialCard: mongoose.model('SpecialCard', SpecialCardSchema),
  CmsSection: mongoose.model('CmsSection', CmsSectionSchema),
  CustomSection: mongoose.model('CustomSection', CustomSectionSchema)
};

const LocalModels = {
  User: createMockModel('User', 'users'),
  Shop: createMockModel('Shop', 'shops'),
  Booking: createMockModel('Booking', 'bookings'),
  Category: createMockModel('Category', 'categories'),
  Review: createMockModel('Review', 'reviews'),
  Professional: createMockModel('Professional', 'professionals'),
  Banner: createMockModel('Banner', 'banners'),
  Offer: createMockModel('Offer', 'offers'),
  Notification: createMockModel('Notification', 'notifications'),
  Demand: createMockModel('Demand', 'demands'),
  Settings: createMockModel('Settings', 'settings'),
  AuditLog: createMockModel('AuditLog', 'auditlogs'),
  Promotion: createMockModel('Promotion', 'promotions'),
  SpecialCard: createMockModel('SpecialCard', 'specialcards'),
  CmsSection: createMockModel('CmsSection', 'cmssections'),
  CustomSection: createMockModel('CustomSection', 'customsections')
};

function makeModelProxy(modelName) {
  const ProxyClass = function(data) {
    if (useLocalDb) {
      return new LocalModels[modelName](data);
    } else {
      return new MongooseModels[modelName](data);
    }
  };

  const staticMethods = [
    'find', 'findOne', 'findById', 'countDocuments', 'create', 'insertMany',
    'findOneAndUpdate', 'findByIdAndUpdate', 'findOneAndDelete', 'findByIdAndDelete'
  ];

  for (const method of staticMethods) {
    ProxyClass[method] = function(...args) {
      if (useLocalDb) {
        return LocalModels[modelName][method](...args);
      } else {
        return MongooseModels[modelName][method](...args);
      }
    };
  }

  return ProxyClass;
}

module.exports = {
  setUseLocalDb,
  User: makeModelProxy('User'),
  Shop: makeModelProxy('Shop'),
  Booking: makeModelProxy('Booking'),
  Category: makeModelProxy('Category'),
  Review: makeModelProxy('Review'),
  Professional: makeModelProxy('Professional'),
  Banner: makeModelProxy('Banner'),
  Offer: makeModelProxy('Offer'),
  Notification: makeModelProxy('Notification'),
  Demand: makeModelProxy('Demand'),
  Settings: makeModelProxy('Settings'),
  AuditLog: makeModelProxy('AuditLog'),
  Promotion: makeModelProxy('Promotion'),
  SpecialCard: makeModelProxy('SpecialCard'),
  CmsSection: makeModelProxy('CmsSection'),
  CustomSection: makeModelProxy('CustomSection')
};
