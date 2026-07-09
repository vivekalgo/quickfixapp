# QuickFix Provider Partner App 🚀💼

This is the mobile application designed for QuickFix service partners, shops, and professionals. It allows partners to register their hyperlocal shop, manage their portfolio and service catalog prices, switch their real-time availability, and process incoming service requests.

---

## 🛠️ Tech Stack & Integrations

- **Frontend Core**: Flutter (Material 3 UI, Dark Mode Default)
- **State Management**: Flutter Riverpod (managing active sessions, loading orders, and dynamic states)
- **Routing**: GoRouter (managing login redirects and screen paths)
- **Networking**: Dio client (with JSON serialization wrappers)
- **Local Persistence**: Hive (cached local session settings and partner credentials)
- **Typography & Aesthetics**: outfit font, premium dark-mode styling, micro-animations, and haptics

---

## 📂 Code Architecture

The application is built using **Clean Architecture** combined with a **Feature-first** folder layout:

```
lib/
├── core/
│   ├── network/        # Dio client instance and error-handling interceptors
│   ├── router/         # GoRouter setup, login guards, and shell wrappers
│   ├── theme/          # Custom color configurations and Outift typography styles
│   └── utils/          # Haptics, input validation rules, and helpers
└── features/
    ├── auth/           # Partner registration and dashboard login screens
    └── dashboard/      # Primary panel housing Bookings, Catalog management, and Profile tabs
```

---

## 🚀 Getting Started

### Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>= 3.19.0`)
- Set up Android Studio or VS Code with Flutter extensions.

### Installation & Run Steps
1. Navigate to the provider directory:
   ```bash
   cd quickfix_provider
   ```
2. Pull required package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the codebase analysis rules:
   ```bash
   flutter analyze
   ```
4. Start the application on a connected device/emulator:
   ```bash
   flutter run
   ```

---

## 🔑 Core Features & User Flows

1. **Partner Onboarding**: Shop owners register via the central admin panel, then log in to this app using their phone number and password.
2. **Bookings Flow**:
   - Incoming job is shown in `PENDING` state.
   - Partner can accept or reject the job.
   - Upon acceptance, the customer's phone number, address, and live tracking are unlocked.
   - The partner can move the status to `ON THE WAY` and finally `COMPLETED`.
3. **Dynamic Catalog Manager**: Partners can set their custom selling prices for all service packages registered to their shop category.
4. **Profile & Gallery**: Partners can modify operating timings and upload images of their portfolio to showcase their work in the customer app.
