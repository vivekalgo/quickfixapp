# Firebase Core & FCM Push Integration

QuickFix integrates **Firebase** as the backbone of its mobile alerts and authentication pipeline.

## 1. Initialization

On boot, Firebase is initialized asynchronously using platform native config files:
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
```

---

## 2. Firebase Cloud Messaging (FCM)

We use FCM to dispatch real-time events between customers, backend services, and providers:
- **Registration**: On user login, the application retrieves a unique token using `FirebaseMessaging.instance.getToken()`.
- **Syncing**: This token is transmitted to the backend server via `AuthNotifier.syncFcmTokenSilently()` and mapped to the user database record.
- **Topics**: Users are subscribed to specific topics:
  - Customer app subscribes to `customers`.
  - Provider app subscribes to `providers`.

---

## 3. SMS Auth Fallback

The backend server integrates Firebase Admin SDK to verify Firebase Auth tokens for phone verification, ensuring high delivery rates and secure user registrations.
