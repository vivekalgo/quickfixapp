import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickfix_provider/core/router/app_router.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/services/notification_service.dart';
import 'package:quickfix_provider/core/storage/hive_service.dart';

import 'package:quickfix_provider/features/auth/presentation/controllers/auth_provider.dart';
import 'package:quickfix_provider/core/widgets/offline_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await HiveService.init();
  await NotificationService.init();

  runApp(const ProviderScope(child: QuickFixProviderApp()));
}

class QuickFixProviderApp extends ConsumerWidget {
  const QuickFixProviderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        providerRouter.go('/login');
      }
    });

    return MaterialApp.router(
      title: 'QuickFix Partner Portal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to dark premium theme mode
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.primary,
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.primary,
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      routerConfig: providerRouter,
      builder: (context, child) {
        return OfflineOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
