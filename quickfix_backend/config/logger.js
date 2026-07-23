const path = require('path');
const fs = require('fs');
const winston = require('winston');
require('winston-daily-rotate-file');

const logDir = path.resolve(__dirname, '..', 'logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.printf(({ level, message, timestamp, requestId, stack }) => {
    const reqStr = requestId ? `[req:${requestId}] ` : '';
    const errStack = stack ? `\n${stack}` : '';
    return `${timestamp} ${level}: ${reqStr}${message}${errStack}`;
  })
);

const errorRotateTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logDir, 'error-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  level: 'error',
  maxFiles: '30d',
  maxSize: '20m',
  zippedArchive: true
});

const combinedRotateTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logDir, 'combined-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxFiles: '30d',
  maxSize: '20m',
  zippedArchive: true
});

const accessRotateTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logDir, 'access-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxFiles: '30d',
  maxSize: '20m',
  zippedArchive: true
});

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: customFormat,
  transports: [
    errorRotateTransport,
    combinedRotateTransport
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: consoleFormat
  }));
} else {
  logger.add(new winston.transports.Console({
    format: customFormat
  }));
}

const accessLogger = winston.createLogger({
  format: customFormat,
  transports: [accessRotateTransport]
});

module.exports = {
  logger,
  accessLogger
};
