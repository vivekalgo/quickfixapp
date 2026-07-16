function validateSendNotification(req, res, next) {
  const { title, body } = req.body;
  if (!title || !body) {
    return res.status(400).json({ error: 'Title and body are required' });
  }
  next();
}

module.exports = {
  validateSendNotification
};
