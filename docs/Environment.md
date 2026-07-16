# Configuration and Local Caching

QuickFix applications utilize environmental variables for configuration and local storage databases for persistence.

## 1. System Configurations

Configuration values are declared in `lib/core/config/app_config.dart` (Customer app) and `lib/core/network/api_endpoints.dart` (Provider app):
- **Base URL**: Gateway pointing to Backend APIs (defaults to local Node server `http://localhost:3000/api` or staging URL).
- **Connect Timeout**: Time limit (e.g., 10 seconds) before Dio cancels network handshake.
- **Receive Timeout**: Time limit (e.g., 15 seconds) before cancellation during server data streaming.

---

## 2. Local Database Cache (Hive)

We use **Hive** for ultra-fast, local caching. Hive reads and writes directly to files in binary format.

### Boxes Opened in Customer App
- **`app_settings`**: Stores application metadata, theme settings (dark/light mode), and user addresses.
- **`app_cache`**: Caches customer profiles and service categories to enable offline start support.
- **`local_notifications`**: Serves as local database for notifications, backing the `notificationsProvider` stream.

### Boxes Opened in Provider App
- **`provider_settings`**: Stores partner credentials, active profile stats, and selected theme.
- **Encrypted Storage**: The provider app opens Hive boxes using an AES encryption cipher (`HiveAesCipher`) initialized with a secure key stored in Android KeyStore/iOS Keychain via **FlutterSecureStorage**.

---

## 3. Secure Token Storage

Authentication JWT tokens are stored securely to prevent token leakage:
- On initialization, we read the token via `SecureTokenManager`.
- Tokens are cached locally in memory for instant API inclusion and persisted using platform secure storage API wrappers.
