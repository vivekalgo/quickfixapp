function validateAddMoney(req, res, next) {
  const { amount } = req.body;
  if (amount === undefined || isNaN(amount) || parseFloat(amount) <= 0) {
    return res.status(400).json({ error: 'Valid amount is required' });
  }
  next();
}

module.exports = {
  validateAddMoney
};
