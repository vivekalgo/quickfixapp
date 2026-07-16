# QuickFix Folder Structure Directory

This document serves as a layout index mapping directories in both Flutter codebases.

## 1. Customer Application (`quickfix`)

```
quickfix/
├── android/                   # Native Android configuration
├── ios/                       # Native iOS configuration
├── test/                      # Unit and Widget tests
│   ├── shop_filter_test.dart  # Business logic tests for shop filters
│   └── widget_test.dart       # smoke test for the main app
├── lib/
│   ├── main.dart              # Entry point initializes Firebase, Hive, Notifications
│   ├── app.dart               # MaterialApp configuration and route bindings
│   ├── core/                  # Shared system components
│   │   ├── config/            # Global timeouts, base URLs, configs
│   │   ├── logging/           # Logger, Crash reporter, Router observers
│   │   ├── network/           # Dio client setup, DNS Bypass, connectivity check
│   │   ├── services/          # Firebase Cloud Messaging & Local Alerts
│   │   ├── storage/           # Hive Local cache & secure credentials store
│   │   ├── theme/             # App typography, custom color styles, themes
│   │   ├── utils/             # Haptic feedback and input sanitizers
│   │   └── widgets/           # Global widgets (Error state, Loader, Section Header)
│   └── features/              # Feature modules (Contain presentation & data layers)
│       ├── auth/              # Mobile login, onboarding, permission screens
│       ├── booking/           # Cart controller, checkouts, and receipts
│       ├── home/              # Location selector, categories, shop lists & details
│       ├── profile/           # User settings, wallets, edit profile, addresses
│       └── tracking/          # Real-time service order progress mapping
```

---

## 2. Provider Application (`quickfix_provider`)

```
quickfix_provider/
├── android/                   # Native Android configuration
├── ios/                       # Native iOS configuration
├── test/                      # Unit and Widget tests
│   └── widget_test.dart       # Smoke test for Provider MaterialApp
├── lib/
│   ├── main.dart              # Main runner initialization
│   ├── core/                  # Core provider components
│   │   ├── network/           # API endpoints, DioClient, DNS Bypass
│   │   ├── router/            # GoRouter configurations and path mapping
│   │   ├── services/          # FCM Push registration and foreground alerts
│   │   ├── storage/           # Hive Service for provider credentials
│   │   ├── theme/             # Dark theme presets and Outfit Google fonts
│   │   ├── utils/             # Formatters, validator functions
│   │   └── widgets/           # Global error states & loading skeletons
│   └── features/              # Feature modules
│       ├── auth/              # Mobile phone login & partner registration
│       ├── bookings/          # Active booking queues, customer details
│       ├── dashboard/         # Service earnings, counts, analytics graphs
│       ├── payments/          # Razorpay payout bank accounts
│       ├── profile/           # Partner status, offline toggle
│       └── shop/              # Service packages, pricing, opening times
```
