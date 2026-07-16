const { User } = require('../models');

async function addMoneyToWallet(userId, amount) {
  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }
  
  user.walletBalance = (user.walletBalance || 0) + parseFloat(amount);
  user.walletTransactions = user.walletTransactions || [];
  const transaction = {
    id: `TX-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`,
    title: 'Added via UPI Gateway',
    amount: parseFloat(amount),
    type: 'credit',
    date: new Date()
  };
  user.walletTransactions.push(transaction);
  
  await user.save();
  return {
    walletBalance: user.walletBalance,
    walletTransactions: user.walletTransactions
  };
}

module.exports = {
  addMoneyToWallet
};
