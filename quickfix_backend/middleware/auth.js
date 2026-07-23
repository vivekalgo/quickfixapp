const jwt = require('jsonwebtoken');

function getJwtSecret() {
  return process.env.JWT_SECRET;
}

async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Unauthorized: Missing token' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const secret = getJwtSecret();
    if (!secret) {
      return res.status(500).json({ success: false, error: 'Server authentication configuration error' });
    }
    const decoded = jwt.verify(token, secret);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Unauthorized: Token expired' });
    }
    return res.status(401).json({ success: false, error: 'Unauthorized: Invalid token' });
  }
}

async function requireAdmin(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Unauthorized: Missing admin token' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const secret = getJwtSecret();
    if (!secret) {
      return res.status(500).json({ success: false, error: 'Server authentication configuration error' });
    }
    const decoded = jwt.verify(token, secret);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Forbidden: Admin access required' });
    }
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Unauthorized: Admin session expired' });
    }
    return res.status(401).json({ success: false, error: 'Unauthorized: Invalid admin token' });
  }
}

async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const secret = getJwtSecret();
      if (secret) {
        const decoded = jwt.verify(token, secret);
        req.user = decoded;
      }
    } catch (_) {}
  }
  next();
}

module.exports = {
  requireAuth,
  requireAdmin,
  optionalAuth
};
