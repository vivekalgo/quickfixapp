# QuickFix Customer App 🚀

QuickFix is an enterprise-grade, AI-powered hyperlocal service marketplace application built with Flutter. It delivers an Urban Company, Zomato, and Uber-quality premium user interface with animations, offline support, caching, and a robust state architecture.

## 🛠️ Tech Stack & Integrations

- **Frontend Core**: Flutter (Latest Stable channel)
- **State Management**: Flutter Riverpod & Riverpod Notifiers
- **Routing**: GoRouter with shell navigation structures
- **Networking**: Dio with custom request configurations
- **Local Database**: Hive key-value cache (with offline caching)
- **Sensors**: Geolocator (live GPS coords mapping)
- **Maps**: Google Maps Flutter SDK (Arriving experts location tracking)
- **Payments**: Razorpay payment integrations
- **Styling**: Material 3 Design (Light / Dark responsive)
- **Animations**: Flutter Animate & Hero transitions

---

## 📂 Code Architecture

The project is structured around **Clean Architecture** guidelines combined with a **Feature-first** folder layout. Each package encapsulates its own domain, data, and presentation layers:

```
lib/
├── core/
│   ├── theme/          # App color palettes, Outfit/Inter typography, theme modes
│   ├── router/         # GoRouter setups, ShellRoute wrappers
│   ├── network/        # Network clients, API routes, error helpers
│   ├── database/       # Hive local database setups and caching services
│   ├── utils/          # Haptic controllers, validators, formatters
│   └── widgets/        # Universal premium UI elements (Shimmer, Nav Bars, Scaffolds)
└── features/
    ├── auth/           # Splash, walkthrough carousel, OTP input & GPS permissons
    ├── home/           # Landing slivers, search history suggestions, filterable shops
    ├── booking/        # Service packages details, cart states, calendar date slots & checkout
    └── tracking/       # Live road map painter overlays, milestones status & SOS triggers
```

---

## 🚀 Getting Started

### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>= 3.19.0`)
2. Set up Android Studio or VS Code with Flutter extensions.

### Installation
1. Clone the repository into your workspace:
   ```bash
   cd quickfixx
   ```
2. Download and link dependency libraries:
   ```bash
   flutter pub get
   ```
3. Run the code analyzer to verify code quality:
   ```bash
   flutter analyze
   ```
4. Launch the application on a connected device/emulator:
   ```bash
   flutter run
   ```

---

## 🔑 External Integrations Setup

To move from simulation to production, configure the following keys:

### 1. Google Maps
- **Android**: Add your Google Maps API Key to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <meta-data android:name="com.google.android.geo.API_KEY"
             android:value="YOUR_MAPS_KEY_HERE"/>
  ```
- **iOS**: Initialize the maps API in `ios/Runner/AppDelegate.swift`:
  ```swift
  GMSServices.provideAPIKey("YOUR_MAPS_KEY_HERE")
  ```

### 2. Razorpay
- Replace mock triggers in `lib/features/booking/presentation/screens/booking_checkout_screen.dart` with a live Razorpay listener:
  ```dart
  import 'package:razorpay_flutter/razorpay_flutter.dart';
  
  // Initialize Razorpay
  final razorpay = Razorpay();
  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
  ```

### 3. Firebase (Auth, FCM, Crashlytics)
- Run the FlutterFire CLI command at the root to configure automatic platform files:
  ```bash
  flutterfire configure
  ```

---

## 🧪 Verification & Testing
To run standard widget unit tests:
```bash
flutter test
```
