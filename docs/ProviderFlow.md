# Provider Operations and Booking Management

This document describes how service providers receive and process bookings.

## 1. Shop Setup & Management
- Provider configures shop profiles via `ShopManagementScreen`.
- Adds/edits services, prices, and opening hours.
- Toggles active status (Online/Offline) which controls search availability.

---

## 2. Incoming Booking Notification

When a new booking is placed near a provider:
- A high-priority FCM push notification is sent to the provider's device.
- The provider app triggers a local alarm or custom ring notification (similar to a ride-sharing dispatch alert).
- The provider has a set window (e.g., 60 seconds) to accept or decline the request from the booking screen.

---

## 3. Service Lifecycle Management

Once the provider accepts a booking, they transition the service using status update APIs:
1. **Accept**: Status becomes `accepted`. Customer is notified.
2. **Arrived**: Provider taps "Arrived" upon reaching the customer location.
3. **Start**: Provider enters a secure verification OTP (if required) or taps "Start Service".
4. **Complete**: Taps "Complete Service". Funds are debited from the customer's wallet and credited to the provider's balance.
