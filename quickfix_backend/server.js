const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

// Select and load environment config profile
const nodeEnv = process.env.NODE_ENV ? process.env.NODE_ENV.toLowerCase().trim() : 'development';
let envFile = '.env.dev';
if (nodeEnv === 'production') envFile = '.env.production';
else if (nodeEnv === 'staging') envFile = '.env.staging';

const envPath = path.resolve(__dirname, envFile);
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
  console.log(`[Config] Loaded environment configuration profile: ${envFile}`);
} else {
  dotenv.config(); // fallback to standard .env
  console.warn(`[Config] Profile file ${envFile} not found. Fallback to default .env`);
}

// Generate fallback secrets if missing for dev/testing
if (!process.env.JWT_SECRET) {
  if (nodeEnv === 'production') {
    console.error("FATAL ERROR: JWT_SECRET environment variable is missing in production!");
    process.exit(1);
  } else {
    const crypto = require('crypto');
    process.env.JWT_SECRET = crypto.randomBytes(32).toString('hex');
    console.warn("⚠️ Warning: JWT_SECRET was missing. Generated a dynamic key for testing/dev.");
  }
}

if (!process.env.ADMIN_PASSWORD) {
  if (nodeEnv === 'production') {
    console.error("FATAL ERROR: ADMIN_PASSWORD environment variable is missing in production!");
    process.exit(1);
  } else {
    process.env.ADMIN_PASSWORD = 'quickfix_admin_secret_9988_dev_fallback';
    console.warn("⚠️ Warning: ADMIN_PASSWORD was missing. Set default admin fallback password.");
  }
}

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');

// Initialize Firebase Admin SDK
require('./config/firebase');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS
app.use(cors());

// Parse requests
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

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

// --- REGISTER MODULAR ROUTES ---
app.use('/api/auth', require('./routes/auth'));
app.use('/api/wallet', require('./routes/wallet'));
app.use('/api/provider', require('./routes/provider'));
app.use('/api/shops', require('./routes/shops'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api', require('./routes/settings')); // handles various general paths

// --- DATABASE AUTO-SEEDER ---
async function seedDatabase() {
  // Seeding is disabled to allow starting with a 100% fresh database
  return;
}

// Start Server
app.listen(PORT, () => {
  console.log(`QuickFix Backend Server listening at http://localhost:${PORT}`);
});
