import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/network/connectivity_provider.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';
import 'package:quickfix/features/profile/presentation/controllers/profile_providers.dart';
import 'package:quickfix/features/profile/presentation/pages/order_history_screen.dart';

class OfflineOverlay extends ConsumerWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  void _reloadAllAppData(WidgetRef ref) {
    try {
      ref.invalidate(categoriesProvider);
      ref.invalidate(nearbyShopsProvider);
      ref.invalidate(topProfessionalsProvider);
      ref.invalidate(bannersProvider);
      ref.invalidate(promotionsProvider);
      ref.invalidate(specialCardsProvider);
      ref.invalidate(homepageLayoutProvider);
      ref.invalidate(customSectionsProvider);
      ref.invalidate(appSettingsProvider);
      ref.invalidate(customerReviewsProvider);
      ref.invalidate(customerBookingsProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(profileOffersProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for reconnection and automatically refresh app data silently
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value == false) {
        _reloadAllAppData(ref);
      }
    });

    // Directly return child without showing disruptive popup dialogs or overlays
    return child;
  }
}
