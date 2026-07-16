# Push Notification Pipeline

This document describes the flow of push notifications from generation to user display.

## 1. Architecture Flow

```
1. Booking Status Changes / Alert Triggered (Backend)
                 │
                 ▼
2. Backend generates notification Payload
                 │
                 ▼
3. Backend calls FCM REST API
                 │
                 ▼
4. FCM pushes to Google Play Services / APNs (Apple)
                 │
                 ▼
5. Mobile Device receives message payload
                 │
      ┌──────────┴──────────┐
      ▼                     ▼
Background Mode        Foreground Mode
(FCM System Alert)     (NotificationService intercept)
                            │
                            ▼
                       Display local banner
                       via flutter_local_notifications
```

---

## 2. Foreground Alert Display

By default, iOS and Android do not display push notification banners when the app is in the foreground.
To resolve this:
1. `NotificationService` listens to incoming FCM messages via `FirebaseMessaging.onMessage.listen`.
2. When a payload arrives, it is processed.
3. `NotificationService` displays a local banner using the **`flutter_local_notifications`** plugin.
4. The message details are saved to the Hive `local_notifications` box, updating the stream in real-time.

---

## 3. Deep Linking via Notifications

Payloads include a data field (e.g., `{"click_action": "FLUTTER_NOTIFICATION_CLICK", "type": "booking", "bookingId": "123"}`).
When the user taps the notification banner:
- GoRouter intercepts the click and parses the data payload.
- Navigates the user directly to the corresponding detail page (e.g. `context.go('/booking/123')`).
