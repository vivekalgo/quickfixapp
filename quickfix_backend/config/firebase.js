const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

function initFirebase() {
  if (admin.apps.length > 0) return admin;

  const rawEnv = process.env.FIREBASE_SERVICE_ACCOUNT_JSON ? process.env.FIREBASE_SERVICE_ACCOUNT_JSON.trim() : null;
  let serviceAccount = null;

  if (rawEnv) {
    // 1. Direct JSON string format
    if (rawEnv.startsWith('{') || rawEnv.includes('private_key')) {
      try {
        serviceAccount = JSON.parse(rawEnv);
        console.log("[Firebase Config] Parsed service account credentials from raw JSON environment variable.");
      } catch (e) {
        console.error("[Firebase Config] Error parsing raw JSON env var:", e.message);
      }
    }

    // 2. Base64 encoded JSON format
    if (!serviceAccount && !rawEnv.endsWith('.json')) {
      try {
        const decoded = Buffer.from(rawEnv, 'base64').toString('utf8');
        if (decoded.startsWith('{')) {
          serviceAccount = JSON.parse(decoded);
          console.log("[Firebase Config] Parsed service account credentials from Base64 environment variable.");
        }
      } catch (_) {}
    }

    // 3. File path format
    if (!serviceAccount) {
      try {
        const resolvedPath = path.resolve(__dirname, '..', rawEnv);
        if (fs.existsSync(resolvedPath)) {
          serviceAccount = require(resolvedPath);
          console.log(`[Firebase Config] Loaded service account credentials from file path: ${resolvedPath}`);
        }
      } catch (e) {
        console.error(`[Firebase Config] Error reading credentials file from ${rawEnv}:`, e.message);
      }
    }
  }

  // 4. Default fallback: firebase-adminsdk.json in project root
  if (!serviceAccount) {
    try {
      const defaultPath = path.resolve(__dirname, '..', 'firebase-adminsdk.json');
      if (fs.existsSync(defaultPath)) {
        serviceAccount = require(defaultPath);
        console.log(`[Firebase Config] Loaded service account credentials from default file: ${defaultPath}`);
      }
    } catch (_) {}
  }

  if (serviceAccount) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log("✅ Firebase Admin SDK initialized successfully!");
    } catch (e) {
      console.error("❌ Firebase Admin SDK initialization failed:", e.message || e);
    }
  } else {
    console.warn("⚠️ WARNING: FIREBASE_SERVICE_ACCOUNT_JSON not provided and default firebase-adminsdk.json not found. Push notifications will be disabled.");
  }

  return admin;
}

initFirebase();

module.exports = admin;
