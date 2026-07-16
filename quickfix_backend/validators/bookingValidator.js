function validateGetBookingDetails(req, res, next) {
  const { bookingId } = req.params;
  if (!bookingId) {
    return res.status(400).json({ error: 'Booking ID is required' });
  }
  next();
}

function validatePlaceBooking(req, res, next) {
  const { title, amount, shopId, paymentMethod, paymentDetails } = req.body;
  if (!title || !amount || !shopId) {
    return res.status(400).json({ error: 'Missing booking details (title, amount, shopId)' });
  }

  if (paymentMethod === 'Razorpay') {
    if (!paymentDetails || !paymentDetails.paymentId || !paymentDetails.signature || !paymentDetails.orderId) {
      return res.status(400).json({ error: 'Missing Razorpay payment details' });
    }
  }
  next();
}

function validateUpdateStatus(req, res, next) {
  const { id, status } = req.body;
  if (!id || !status) {
    return res.status(400).json({ error: 'Booking ID and status are required' });
  }
  next();
}

module.exports = {
  validateGetBookingDetails,
  validatePlaceBooking,
  validateUpdateStatus
};
