const morgan = require('morgan');
const { crypto } = require('crypto');
const { accessLogger } = require('../config/logger');

function requestIdMiddleware(req, res, next) {
  const existingId = req.headers['x-request-id'];
  const requestId = existingId || (crypto && crypto.randomUUID ? crypto.randomUUID() : `req-${Date.now()}-${Math.floor(Math.random() * 10000)}`);
  req.id = requestId;
  res.setHeader('X-Request-Id', requestId);
  next();
}

morgan.token('id', (req) => req.id || '-');

const morganFormat = ':remote-addr - :remote-user [:date[iso]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent" id=:id :response-time ms';

const httpAccessLogger = morgan(morganFormat, {
  stream: {
    write: (message) => {
      accessLogger.info(message.trim());
    }
  }
});

module.exports = {
  requestIdMiddleware,
  httpAccessLogger
};
