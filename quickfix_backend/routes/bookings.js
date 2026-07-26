const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const bookingValidator = require('../validators/bookingValidator');
const { bookingLimiter } = require('../middleware/rateLimiter');

// 1. Get bookings list (Unthrottled for smooth UI navigation)
router.get('/', bookingController.getBookings);

// 2. Get booking details (Unthrottled for smooth UI navigation)
router.get('/details/:bookingId', bookingValidator.validateGetBookingDetails, bookingController.getBookingDetails);

// 3. Create Booking Routes
router.post('/', bookingLimiter, bookingValidator.validatePlaceBooking, bookingController.placeBooking);
router.post('/create', bookingLimiter, bookingValidator.validatePlaceBooking, bookingController.placeBooking);

// 4. Update status & Assign provider
router.post('/update-status', bookingLimiter, bookingValidator.validateUpdateStatus, bookingController.updateStatus);
router.post('/assign-provider', bookingLimiter, bookingController.assignProvider);


// 5. Cancel Booking
router.post('/cancel', bookingLimiter, bookingController.cancelBooking);

// 6. Quotation Upload
router.post('/:bookingId/quotation', bookingLimiter, bookingController.uploadQuotation);

// 7. Quotation Respond
router.post('/:bookingId/quotation/respond', bookingLimiter, bookingController.respondToQuotation);

module.exports = router;
