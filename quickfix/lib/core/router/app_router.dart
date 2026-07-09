import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_scaffold.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/location_permission_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/home/presentation/screens/shops_list_screen.dart';
import '../../features/home/presentation/screens/category_screen.dart';
import '../../features/booking/presentation/screens/service_details_screen.dart';
import '../../features/booking/presentation/screens/booking_checkout_screen.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/quick_booking_screen.dart';
import '../../features/tracking/presentation/screens/live_tracking_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/refer_earn_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/order_history_screen.dart';
import '../../features/profile/presentation/screens/wallet_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/profile/presentation/screens/wishlist_screen.dart';
import '../../features/profile/presentation/screens/offers_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/home/presentation/screens/location_selector_screen.dart';

import '../../features/home/presentation/screens/shop_details_screen.dart';
import '../../features/home/data/models/home_models.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Onboarding & Authentication Flow
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/location',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LocationPermissionScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/location-selector',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LocationSelectorScreen(),
    ),

    // Shell Route for bottom navigation screens
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/offers',
          builder: (context, state) => const OffersScreen(),
        ),
      ],
    ),

    // Full screen routes (outside ShellRoute)
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/shops',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ShopsListScreen(),
    ),
    GoRoute(
      path: '/category/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CategoryScreen(categoryId: id);
      },
    ),
    GoRoute(
      path: '/shop/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final initialShop = state.extra as Shop?;
        return ShopDetailsScreen(shopId: id, initialShop: initialShop);
      },
    ),
    GoRoute(
      path: '/service/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ServiceDetailsScreen(serviceId: id);
      },
    ),
    GoRoute(
      path: '/booking-quick',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const QuickBookingScreen(),
    ),
    GoRoute(
      path: '/checkout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BookingCheckoutScreen(),
    ),
    GoRoute(
      path: '/confirmation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BookingConfirmationScreen(),
    ),
    GoRoute(
      path: '/tracking/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return LiveTrackingScreen(bookingId: id);
      },
    ),
    GoRoute(
      path: '/wallet',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/support',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/refer-earn',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReferEarnScreen(),
    ),
    GoRoute(
      path: '/addresses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddressesScreen(),
    ),
  ],
);
