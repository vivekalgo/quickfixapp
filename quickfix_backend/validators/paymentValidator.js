function validateGetLedgerForBooking(req, res, next) {
  if (!req.params.bookingId) {
    return res.status(400).json({ error: 'Booking ID is required' });
  }
  next();
}

function validateGetLedgerForShop(req, res, next) {
  if (!req.params.shopId) {
    return res.status(400).json({ error: 'Shop ID is required' });
  }
  next();
}

function validateCashConfirm(req, res, next) {
  if (!req.params.bookingId) {
    return res.status(400).json({ error: 'Booking ID is required' });
  }
  next();
}

function validateCommissionCollect(req, res, next) {
  if (!req.params.shopId) {
    return res.status(400).json({ error: 'Shop ID is required' });
  }
  next();
}

function validateSettlementRequest(req, res, next) {
  const { shopId, amount } = req.body;
  if (!shopId || !amount) {
    return res.status(400).json({ error: 'shopId and amount are required' });
  }
  next();
}

function validateSettlementAction(req, res, next) {
  if (!req.params.id) {
    return res.status(400).json({ error: 'Settlement ID is required' });
  }
  next();
}

module.exports = {
  validateGetLedgerForBooking,
  validateGetLedgerForShop,
  validateCashConfirm,
  validateCommissionCollect,
  validateSettlementRequest,
  validateSettlementAction
};
