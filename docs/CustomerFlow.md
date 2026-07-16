# Customer App Journey Map

This document highlights the user path in the customer mobile application.

## 1. Onboarding and Authentication
- The app checks for stored credentials in Hive.
- If none exist, displays onboarding screen followed by phone number input.
- User requests OTP code, receives it via SMS (or fallback console simulator), and logs in.
- The app requests GPS location permissions using Geolocator.

---

## 2. Find and Filter Services
- **GPS Coordinates**: The homepage fetches user coordinates, reverses them to address text using OpenStreetMap (Nominatim), and displays the header.
- **Nearby Filter**: The homepage lists nearby shops sorted by distance.
- **Search**: User queries using search bars; results filter dynamically.

---

## 3. Ordering and Reviewing
- Customer selects package items and goes through checkout.
- Selects payment method (Wallet or Direct Gateway).
- Once order is fulfilled, customer rates the service (1-5 stars) and submits feedback which updates the provider's rating in the backend database.
