# Deployment and Build Guide

This document describes how to compile, build, and deploy the QuickFix applications.

## 1. Prerequisites

Before building, verify you have the Flutter SDK (minimum 3.12.0) and Dart SDK installed:
```bash
flutter --version
```

---

## 2. Compiling Android Release (APK & App Bundle)

To generate a standalone APK:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

To generate an Android App Bundle (AAB) for Google Play Console:
```bash
flutter build appbundle --release
```

---

## 3. Compiling iOS Release (App Store)

1. Open a terminal and run the compile command:
   ```bash
   flutter build ipa --release
   ```
2. Open Xcode from the `ios/` project folder.
3. Configure **Signing & Capabilities** with your Apple Developer provisioning profiles.
4. Select **Product > Archive** to package the archive for TestFlight distribution.

---

## 4. Optimization Techniques

We pass the following flags to optimize sizes:
- **`--obfuscate`**: Renames Dart symbols to prevent reverse engineering of business logic.
- **`--split-debug-info`**: Extracts debug symbols from release code, shaving 4-5MB off the final APK size.
