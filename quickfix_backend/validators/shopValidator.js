function validateRegister(req, res, next) {
  const { name, ownerName, phone } = req.body;
  if (!name || !ownerName || !phone) {
    return res.status(400).json({ error: 'Shop name, Owner name, and Phone number are required' });
  }
  next();
}

function validateLogin(req, res, next) {
  const { phone, password, shopId } = req.body;
  if ((!phone && !shopId) || !password) {
    return res.status(400).json({ error: 'Phone/Shop ID and password are required' });
  }
  next();
}

function validateUpdate(req, res, next) {
  const { id } = req.body;
  if (!id) {
    return res.status(400).json({ error: 'Shop ID is required' });
  }
  next();
}

function validateApprove(req, res, next) {
  const { id, verificationStatus } = req.body;
  if (!id || !verificationStatus) {
    return res.status(400).json({ error: 'Shop ID and verificationStatus are required' });
  }
  next();
}

function validateSuspend(req, res, next) {
  const { id, suspend } = req.body;
  if (!id || suspend === undefined) {
    return res.status(400).json({ error: 'Shop ID and suspend status are required' });
  }
  next();
}

function validateToggleLogin(req, res, next) {
  const { id, loginDisabled } = req.body;
  if (!id || loginDisabled === undefined) {
    return res.status(400).json({ error: 'Shop ID and loginDisabled status are required' });
  }
  next();
}

function validateResetPassword(req, res, next) {
  const { id } = req.body;
  if (!id) {
    return res.status(400).json({ error: 'Shop ID is required' });
  }
  next();
}

module.exports = {
  validateRegister,
  validateLogin,
  validateUpdate,
  validateApprove,
  validateSuspend,
  validateToggleLogin,
  validateResetPassword
};
