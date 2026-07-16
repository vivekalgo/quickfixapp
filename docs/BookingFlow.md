# Booking and Service Flow

The Booking Flow covers selecting services, checkout, placement, and status updates.

## 1. Cart Management
- Users browse professional shops and tap on services.
- The `cartProvider` intercepts:
  - If the cart is empty, adds the item.
  - If items belong to a different provider shop, it prompts the user to clear the previous cart before adding.
  - Keeps track of quantities and prices.

---

## 2. Order Placement

```
1. User taps "Proceed to Booking"
                 │
                 ▼
2. App reads currentAddressProvider (lat, lng, address text)
                 │
                 ▼
3. Call POST /bookings (payload: services list, shopId, address coordinates)
                 │
                 ▼
4. Server creates booking record with status "pending"
                 │
                 ▼
5. Server sends push notification alert to Provider
                 │
                 ▼
6. Navigate customer to live tracking screen
```

---

## 3. Real-time Status Synchronization
The customer tracks status changes via Riverpod stream watches or regular short polling:
- **Pending**: Waiting for provider partner acceptance.
- **Accepted**: Provider is preparing / traveling.
- **Arrived**: Provider has reached the customer's site.
- **Started**: Service is in progress (OTP verification if enabled).
- **Completed**: Service is done. Wallet funds are transferred to the provider.
