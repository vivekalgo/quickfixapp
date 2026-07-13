import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/shared/widgets/bottom_nav_bar.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final isOnHome = currentIndex == 0;

    return PopScope(
      // Allow pop only when already on home tab (to let app close normally)
      canPop: isOnHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isOnHome) {
          // User pressed back on a non-home tab — go back to Home
          ref.read(currentNavIndexProvider.notifier).state = 0;
          context.go('/home');
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: const CustomBottomNavBar(),
      ),
    );
  }
}
