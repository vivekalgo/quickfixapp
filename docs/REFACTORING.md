# QuickFix Enterprise Refactoring Documentation (Phase 2)

This document details the refactoring, separation of concerns, and architectural upgrades implemented for the QuickFix backend server, customer Flutter app, and partner/provider Flutter app.

---

## 1. Backend Server MVC/Service Restructuring

The monolithic logic formerly embedded directly in `quickfix_backend/routes/` has been decoupled into dedicated layers. All original endpoints, methods, validation checks, and response structures are fully preserved.

### Architectural Blueprint
```
quickfix_backend/
├── routes/              # Mappings of URLs and HTTP methods to Controllers & Validators
├── controllers/         # Handles req/res lifecycles, extracts input parameters
├── services/            # Main core business rules, database queries & helper calls
├── validators/          # Custom validation middleware checking request bodies
├── middleware/          # Security authentication guards (requireAuth)
└── helpers.js           # Distance computations, FCM pushes, and Cloudinary deletions
```

### Decoupled Modules
1. **Auth Module**
   - Routes: `routes/auth.js`
   - Validators: `validators/authValidator.js`
   - Services: `services/authService.js`
   - Controllers: `controllers/authController.js`
2. **Bookings Module**
   - Routes: `routes/bookings.js`
   - Validators: `validators/bookingValidator.js`
   - Services: `services/bookingService.js`
   - Controllers: `controllers/bookingController.js`
3. **Payments Module**
   - Routes: `routes/payments.js`
   - Validators: `validators/paymentValidator.js`
   - Services: `services/paymentService.js`
   - Controllers: `controllers/paymentController.js`
4. **Provider Module**
   - Routes: `routes/provider.js`
   - Validators: `validators/providerValidator.js`
   - Services: `services/providerService.js`
   - Controllers: `controllers/providerController.js`
5. **Settings Module**
   - Routes: `routes/settings.js`
   - Validators: `validators/settingsValidator.js`
   - Services: `services/settingsService.js`
   - Controllers: `controllers/settingsController.js`
6. **Shops Module**
   - Routes: `routes/shops.js`
   - Validators: `validators/shopValidator.js`
   - Services: `services/shopService.js`
   - Controllers: `controllers/shopController.js`
7. **Wallet Module**
   - Routes: `routes/wallet.js`
   - Validators: `validators/walletValidator.js`
   - Services: `services/walletService.js`
   - Controllers: `controllers/walletController.js`

---

## 2. Customer App Clean Refactoring (`quickfix`)

We restructured the customer application features to isolate API operations and split heavy widgets.

### Core Changes
- **Data Layer Separation:** Created `datasources/` and `repositories/` for `booking`, `notifications`, `profile`, and `tracking` features. All REST client requests now go through remote data sources rather than being directly made in pages/screens.
- **Riverpod Injection:** Bound repositories to global providers (e.g. `bookingRepositoryProvider`), which are watched/read by the state notifier controllers.
- **Widget Decomposition:**
  - `shop_details_screen.dart` -> Split into `ShopDetailsHeader` card and `ShopServiceItem` widgets in the widgets directory.
  - `booking_checkout_screen.dart` -> Broken down into smaller card views for slots, address inputs, and pricing details.
  - `quick_booking_screen.dart` -> Extract stepper details and form items into modular widget classes.

---

## 3. Provider App Clean Refactoring (`quickfix_provider`)

The provider/partner mobile application has been fully refactored to align with Clean Architecture practices.

### Core Changes
- **Feature-First Organization:** Reorganized files under `features/` so that every feature (`auth`, `bookings`, `dashboard`, `payments`, `profile`, `shop`) has a distinct presentation and data/repository layer.
- **Controller Decoupling:** Replaced direct `Dio` client invocations in the provider controllers (e.g., `bookings_provider.dart`, `payments_provider.dart`) with repository method calls.
- **Widget Decomposition:**
  - `booking_detail_screen.dart` -> Decomposed into `BookingStatusCard`, `QuotationCard`, and `QuotationDialog`.
  - `first_login_screen.dart` -> Decomposed into individual steps: `PasswordOnboardingStep`, `ContactOnboardingStep`, `BankOnboardingStep`, and `DocumentsOnboardingStep`.
  - `shop_management_screen.dart` -> Decoupled inline modal popups into dedicated `AddServiceDialog` and `EditServiceDialog` files.
