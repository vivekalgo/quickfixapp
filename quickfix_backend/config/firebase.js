const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_JSON ? process.env.FIREBASE_SERVICE_ACCOUNT_JSON.trim() : null;

if (serviceAccountPath) {
  try {
    const resolvedPath = path.resolve(__dirname, '..', serviceAccountPath);
    if (fs.existsSync(resolvedPath)) {
      const serviceAccount = require(resolvedPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log("Firebase Admin SDK initialized successfully!");
    } else {
      console.warn(`Firebase credentials file not found at ${resolvedPath}. Notifications may fail.`);
    }
  } catch (e) {
    console.error("Firebase Admin initialization error:", e);
  }
} else {
  console.warn("FIREBASE_SERVICE_ACCOUNT_JSON not set. Firebase Admin SDK not initialized.");
}

module.exports = admin;
