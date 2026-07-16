const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const bookingValidator = require('../validators/bookingValidator');

// 1. Get bookings list
router.get('/', bookingController.getBookings);

// 2. Get booking details
router.get('/details/:bookingId', bookingValidator.validateGetBookingDetails, bookingController.getBookingDetails);

// 3. Create Booking Routes
router.post('/', bookingValidator.validatePlaceBooking, bookingController.placeBooking);
router.post('/create', bookingValidator.validatePlaceBooking, bookingController.placeBooking);

// 4. Update status
router.post('/update-status', bookingValidator.validateUpdateStatus, bookingController.updateStatus);

// 5. Cancel Booking
router.post('/cancel', bookingController.cancelBooking);

// 6. Quotation Upload
router.post('/:bookingId/quotation', bookingController.uploadQuotation);

// 7. Quotation Respond
router.post('/:bookingId/quotation/respond', bookingController.respondToQuotation);

module.exports = router;
