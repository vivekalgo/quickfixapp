# State Management with Riverpod

QuickFix uses **Flutter Riverpod** as its unified state management solution.

## 1. Why Riverpod?
- **Compile-Time Safety**: Prevents runtime ProviderNotFoundExceptions common in old Provider codebases.
- **No BuildContext dependency**: Allows reading and updating state outside UI classes (e.g., deep linking handlers).
- **Reactive Dependencies**: Auto-disposes and rebuilds providers when their parameters change.

---

## 2. Core State Management Patterns

### A. StateNotifier and StateNotifierProvider
Used for stateful controllers that handle complex async workflows (e.g., authentication, cart, booking actions):
- **`authProvider`**: Manages `AuthState` object (isAuthenticated, user, isLoading, error).
- **`cartProvider`**: Manages a Map of `CartItem` instances, providing functions like `addItem()`, `removeItem()`, and `clearCart()`.

### B. FutureProvider
Used for fetching static or async network data:
- **`categoriesProvider`**: Fetches the list of active services from the repository.
- **`nearbyShopsProvider`**: Fetches shops matching the active filter and current GPS coordinates. Re-runs automatically when `currentAddressProvider` or `selectedNearbyFilterProvider` changes.

### C. StreamProvider
Used for reactive database watches or server-sent-events:
- **`notificationsProvider`**: Streams local notifications directly from Hive storage. Automatically triggers UI rebuilds when new push notifications are written to the database.

---

## 3. Reactive Dependency Diagram Example

```
[currentAddressProvider]                             --> [nearbyShopsProvider] --> [ShopsListScreen UI]
[selectedNearbyFilter]  /
```
