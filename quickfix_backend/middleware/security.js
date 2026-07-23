const helmet = require('helmet');
const cors = require('cors');

// 1. Helmet setup
const helmetMiddleware = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://checkout.razorpay.com"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      imgSrc: ["'self'", "data:", "https://res.cloudinary.com", "https://*.razorpay.com"],
      connectSrc: ["'self'", "https://api.razorpay.com", "https://lumberjack.razorpay.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'self'", "https://api.razorpay.com"]
    }
  },
  strictTransportSecurity: {
    maxAge: 31536000, // 1 year
    includeSubDomains: true,
    preload: true
  },
  referrerPolicy: {
    policy: 'strict-origin-when-cross-origin'
  },
  xssFilter: true,
  frameguard: {
    action: 'deny'
  },
  hidePoweredBy: true
});

// 2. CORS Whitelist configuration
function configureCors() {
  const nodeEnv = (process.env.NODE_ENV || 'development').toLowerCase().trim();
  const isDev = nodeEnv === 'development';

  const rawOrigins = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : [];
  const allowedOrigins = rawOrigins.map(o => o.trim()).filter(o => o.length > 0);

  return cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps, curl, postman)
      if (!origin) return callback(null, true);

      // In dev mode, allow localhost origins
      if (isDev && (origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1'))) {
        return callback(null, true);
      }

      // Check configured allowed origins
      if (allowedOrigins.includes(origin) || allowedOrigins.includes('*')) {
        return callback(null, true);
      }

      callback(new Error(`CORS policy violation: Origin '${origin}' is not allowed.`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id', 'X-Requested-With']
  });
}

// 3. Express 5 compatible NoSQL Injection Prevention
function sanitizeObjectInPlace(obj) {
  if (!obj || typeof obj !== 'object') return;
  for (const key of Object.keys(obj)) {
    if (key.startsWith('$') || key.includes('.')) {
      const cleanKey = key.replace(/[\$.]/g, '_');
      obj[cleanKey] = obj[key];
      delete obj[key];
      if (typeof obj[cleanKey] === 'object') {
        sanitizeObjectInPlace(obj[cleanKey]);
      }
    } else if (typeof obj[key] === 'object') {
      sanitizeObjectInPlace(obj[key]);
    }
  }
}

function sanitizeMongo(req, res, next) {
  if (req.body) sanitizeObjectInPlace(req.body);
  if (req.params) sanitizeObjectInPlace(req.params);
  if (req.query) sanitizeObjectInPlace(req.query);
  next();
}

// 4. Express 5 compatible HTTP Parameter Pollution Protection (hpp)
function sanitizeHpp(req, res, next) {
  if (req.query && typeof req.query === 'object') {
    const whitelist = ['category', 'status', 'sort', 'search', 'page', 'limit'];
    for (const key of Object.keys(req.query)) {
      if (Array.isArray(req.query[key]) && !whitelist.includes(key)) {
        req.query[key] = req.query[key][req.query[key].length - 1];
      }
    }
  }
  next();
}

module.exports = {
  helmetMiddleware,
  corsMiddleware: configureCors(),
  sanitizeMongo,
  sanitizeHpp
};
