# Razorpay Integration and Wallet Flow

QuickFix integrates **Razorpay** to process service bookings and wallet top-ups.

## 1. Razorpay Payment Architecture

```
Customer App               Backend Server             Razorpay SDK / API
    │                            │                            │
    │─── 1. Initiate Top Up ────>│                            │
    │    (Amount)                │─── 2. Create Order ───────>│
    │                            │<── 3. Return Order ID ─────│
    │<── 4. Receive Order ID ────│                            │
    │                            │                            │
    │─── 5. Launch Checkout ─────────────────────────────────>│
    │    (Razorpay Payment Screen)                            │
    │<── 6. Return Signature & Payment ID ────────────────────│
    │                            │                            │
    │─── 7. Verify Signature ───>│                            │
    │    & Complete Wallet Add   │─── 8. Validate ───────────>│
    │                            │<── 9. Confirmed ───────────│
    │<── 10. Success UI ─────────│                            │
```

---

## 2. Secure Webhook Validation

To prevent fraudulent transaction overrides (e.g. injecting mock payment IDs):
- The client app sends the payment payload to the server containing `razorpay_payment_id`, `razorpay_order_id`, and `razorpay_signature`.
- The server validates these parameters using the SHA-256 HMAC algorithm with the secure Razorpay Secret Key.
- Wallet balances are updated in the database *only* after verification succeeds.
