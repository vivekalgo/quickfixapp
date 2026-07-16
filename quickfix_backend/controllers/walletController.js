const walletService = require('../services/walletService');

async function addMoney(req, res) {
  try {
    const { amount } = req.body;
    const result = await walletService.addMoneyToWallet(req.user.id, amount);
    res.json({
      success: true,
      ...result
    });
  } catch (e) {
    if (e.message === 'User not found') {
      return res.status(404).json({ error: e.message });
    }
    res.status(500).json({ error: 'Failed to add money to wallet' });
  }
}

module.exports = {
  addMoney
};
