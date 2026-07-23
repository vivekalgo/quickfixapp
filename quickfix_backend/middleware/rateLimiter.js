const rateLimit = require('express-rate-limit');

// Custom handler for rate limit exceeded
const handleRateLimitExceeded = (req, res, next, options) => {
  res.status(options.statusCode || 429).json({
    success: false,
    error: options.message || 'Too many requests. Please try again later.'
  });
};

// 1. Auth / Login Limiter (10 attempts / 15 mins)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many login attempts. Please try again after 15 minutes.',
  handler: handleRateLimitExceeded
});

// 2. OTP Request Limiter (5 attempts / 15 mins)
const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many OTP requests. Please try again after 15 minutes.',
  handler: handleRateLimitExceeded
});

// 3. Admin Login Limiter (5 attempts / 15 mins)
const adminLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many admin authentication attempts. Account temporarily throttled for security.',
  handler: handleRateLimitExceeded
});

// 4. Booking APIs Limiter (30 requests / 15 mins)
const bookingLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Booking request rate limit exceeded. Please wait a moment before trying again.',
  handler: handleRateLimitExceeded
});

// 5. Provider APIs Limiter (60 requests / 15 mins)
const providerLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Provider API rate limit exceeded. Please slow down requests.',
  handler: handleRateLimitExceeded
});

// 6. Password Reset Limiter (5 requests / 15 mins)
const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many password reset attempts. Please try again after 15 minutes.',
  handler: handleRateLimitExceeded
});

// 7. Public APIs Limiter (100 requests / 15 mins)
const publicLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Public API rate limit exceeded.',
  handler: handleRateLimitExceeded
});

module.exports = {
  authLimiter,
  otpLimiter,
  adminLoginLimiter,
  bookingLimiter,
  providerLimiter,
  passwordResetLimiter,
  publicLimiter
};
