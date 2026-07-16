# QuickFix REST API Documentation

QuickFix mobile applications communicate with the backend using a structured REST API client.

## 1. HTTP Client (`DioClient`)

We use the `dio` library to manage HTTP requests. Key features include:
- **DNS Bypass Helper**: Automatically overrides connection handshakes if a direct endpoint connection fails, avoiding local network restrictions.
- **Interceptors**: Automatically appends the authentication JWT token (`Authorization: Bearer <token>`) to headers using `HiveService` storage.
- **Global Error Interceptor**: Automatically parses network timeouts, connection drops, and HTTP bad responses into standardized exceptions using the `ErrorHandler`.

---

## 2. Endpoint Dictionary

All API requests are routed to the backend path specified in `lib/core/network/api_endpoints.dart`.

### Authentication Endpoints
- **POST** `/auth/send-code`: Sends OTP code to mobile phone.
- **POST** `/auth/verify-code`: Verifies OTP and returns JWT token & user profile.
- **GET** `/auth/profile`: Returns details of the logged-in user.
- **PUT** `/auth/profile`: Updates user fields (name, email, FCM token, addresses).
- **POST** `/auth/avatar`: Uploads base64 profile picture.

### Customer Dashboard Endpoints
- **GET** `/categories`: Fetches categories of services.
- **GET** `/shops/nearby`: Fetches nearby service providers filtering by distance/category.
- **GET** `/shops/:id`: Details of a specific shop including list of services and ratings.
- **GET** `/promotions`: Banners and discount coupons.
- **GET** `/reviews`: Latest customer reviews and testimonials.

### Booking & Payment Endpoints
- **POST** `/bookings`: Submits a booking order (cart packages, location coordinates).
- **GET** `/bookings`: Fetches booking order histories.
- **POST** `/payments/razorpay/order`: Generates Razorpay transaction ID.
- **POST** `/payments/wallet/add`: Verifies Razorpay transaction and tops up wallet.

### Provider Endpoints
- **GET** `/provider/stats`: Dashboard statistics (earnings, reviews, bookings).
- **GET** `/provider/bookings`: Bookings assigned to this partner.
- **PUT** `/provider/bookings/:id/status`: Updates status (Accept, Arrived, In-Progress, Completed).
- **PUT** `/provider/shop`: Updates shop timings, location, and services.
- **POST** `/provider/payout`: Withdraws money to a linked bank account.
