import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/dns_bypass_helper.dart';
import 'package:quickfix_provider/core/storage/hive_service.dart';
import 'package:quickfix_provider/core/router/app_router.dart';
import 'package:quickfix_provider/features/bookings/presentation/pages/booking_detail_screen.dart';

// ─── Background Handler ───────────────────────────────────────────────────────

/// **Firebase & Notifications**: Captures background push notifications in a separate isolate.
/// 
/// Runs inside a custom VM isolate when the provider application is closed or in background.
/// Initialized with `@pragma('vm:entry-point')` to prevent code stripping.
/// Updates the local Hive box so the partner can see background alerts history immediately upon reopening.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await Hive.initFlutter();
  final box = await Hive.openBox('provider_notifications');
  final notificationData = _parseMessage(message);
  await box.put(notificationData['id'], notificationData);
  debugPrint('[FCM Background]: Stored: ${message.messageId}');
}

Map<String, dynamic> _parseMessage(RemoteMessage message) {
  final notification = message.notification;
  final data = message.data;
  final id =
      message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  return {
    'id': id,
    'title': notification?.title ?? data['title'] ?? 'QuickFix Partner Update',
    'body': notification?.body ?? data['body'] ?? '',
    'time': DateTime.now().toIso8601String(),
    'isRead': false,
    'type': data['type'] ?? 'general',
    'bookingId': data['bookingId'] ?? '',
    'deepLink': data['deepLink'] ?? '',
    'iconColor': data['iconColor'] ?? 'primary',
  };
}

// ─── NotificationService ─────────────────────────────────────────────────────

/// Enterprise service for managing system push notifications and alerts in the Provider app.
/// 
/// Interfaces with [FirebaseMessaging] to catch incoming job dispatches and other alerts,
/// registering two local notification channels (standard and custom ring alert) using [FlutterLocalNotificationsPlugin].
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Standard high-priority channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'General booking updates, payments, and partner alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Booking alert channel with custom ringtone
  static const AndroidNotificationChannel _bookingChannel =
      AndroidNotificationChannel(
        'booking_alert_channel',
        'Booking Alerts',
        description:
            'Incoming booking requests — plays a custom alert ringtone.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alert_ring'),
        enableVibration: true,
        showBadge: true,
      );

  /// Initializes the messaging events, local alert controllers, and token synchronizers.
  static Future<void> init() async {
    try {
      // 1. Ensure Hive box is open
      if (!Hive.isBoxOpen('provider_notifications')) {
        await Hive.openBox('provider_notifications');
      }

      // 2. Register background handler FIRST
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 3. Request permissions
      await requestPermissions();

      // 4. Initialize flutter_local_notifications
      const AndroidInitializationSettings initAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');
      const InitializationSettings initSettings = InitializationSettings(
        android: initAndroid,
      );
      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final Map<String, dynamic> data = Uri.splitQueryString(payload);
              handleNotificationClick(data);
            } catch (e) {
              debugPrint('[FCM]: Failed to parse notification payload: $e');
            }
          }
        },
      );

      // 5. Create notification channels
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        await androidPlugin.createNotificationChannel(_bookingChannel);
      }

      // 6. Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('[FCM Foreground]: ${message.messageId}');
        final notificationData = _parseMessage(message);
        final box = Hive.box('provider_notifications');
        await box.put(notificationData['id'], notificationData);

        final notification = message.notification;
        if (notification != null && !kIsWeb) {
          final data = message.data;
          final payload = Uri(
            queryParameters: data.map((k, v) => MapEntry(k, v.toString())),
          ).query;

          final type = data['type']?.toString();
          final isBookingRequest =
              type == 'booking' ||
              (notification.title ?? '').toLowerCase().contains('booking');

          final channelId = isBookingRequest ? _bookingChannel.id : _channel.id;
          final channelName = isBookingRequest
              ? _bookingChannel.name
              : _channel.name;
          final channelDesc = isBookingRequest
              ? _bookingChannel.description
              : _channel.description;

          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: channelDesc,
                icon: '@drawable/ic_notification',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                playSound: true,
                sound: isBookingRequest
                    ? const RawResourceAndroidNotificationSound('alert_ring')
                    : null,
                enableVibration: true,
                visibility: NotificationVisibility.public,
                fullScreenIntent: isBookingRequest,
                styleInformation: BigTextStyleInformation(
                  notification.body ?? '',
                  contentTitle: notification.title,
                ),
              ),
            ),
            payload: payload,
          );
        }
      });

      // 7. Background tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Background Click]: ${message.messageId}');
        handleNotificationClick(message.data);
      });

      // 8. Token refresh re-sync
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM Token Refresh]');
        await syncTokenWithBackend(newToken);
      });

      // 9. Startup: terminated state + topic + token sync
      await _initStartup();
    } catch (e) {
      debugPrint('[FCM]: Failed to initialize NotificationService: $e');
    }
  }

  static Future<void> _initStartup() async {
    // Terminated state launch
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM Terminated Click]: ${initialMessage.messageId}');
        Future.delayed(const Duration(milliseconds: 1500), () {
          handleNotificationClick(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('[FCM]: Failed to get initial message: $e');
    }

    // Subscribe to providers topic
    try {
      await subscribeToTopic('providers');
    } catch (e) {
      debugPrint('[FCM]: Failed to subscribe to providers topic: $e');
    }

    // ✅ FIX: Sync token on EVERY startup when provider is logged in
    try {
      final authToken = HiveService.getAuthToken();
      if (authToken != null) {
        final fcmToken = await getToken();
        if (fcmToken != null) {
          await syncTokenWithBackend(fcmToken);
        }
      }
    } catch (e) {
      debugPrint('[FCM]: Failed to sync token on startup: $e');
    }
  }

  static Future<void> requestPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        carPlay: false,
        criticalAlert: false,
      );
      debugPrint('[FCM]: Permission status: ${settings.authorizationStatus}');

      if (Platform.isAndroid) {
        final androidPlugin = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('[FCM]: Error requesting notification permissions: $e');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('[FCM]: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM]: Failed to subscribe to topic: $topic: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('[FCM]: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM]: Failed to unsubscribe from topic: $topic: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM]: Token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('[FCM]: Failed to get token: $e');
      return null;
    }
  }

  /// **API Usage & Firebase**: Updates the server registration token.
  /// 
  /// Appends the partner's JWT authorization header. If the local network has routing restrictions,
  /// it routes requests through the [DnsBypassHelper] with custom certificate overrides.
  /// After a successful synchronization, the token is written to Hive to avoid repetitive requests.
  static Future<void> syncTokenWithBackend(String token) async {
    final authToken = HiveService.getAuthToken();
    if (authToken == null) {
      debugPrint('[FCM]: Skipping token sync — provider not logged in');
      return;
    }

    try {
      final dioClient = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (DnsBypassHelper.shouldBypass(ApiEndpoints.baseUrl)) {
        dioClient.options.baseUrl = DnsBypassHelper.bypassUrl(
          ApiEndpoints.baseUrl,
          dioClient.options.headers,
        );
        ((dioClient.httpClientAdapter) as IOHttpClientAdapter)
            .createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = DnsBypassHelper.verifyCertificate;
          return client;
        };
      }

      final response = await dioClient.post(
        ApiEndpoints.updateFcmToken,
        data: {'fcmToken': token},
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM]: Token synced to backend successfully');
        final cached = HiveService.getShopProfile();
        if (cached != null) {
          final updated = Map<String, dynamic>.from(cached);
          updated['fcmToken'] = token;
          await HiveService.saveShopProfile(updated);
        }
      }
    } catch (e) {
      debugPrint('[FCM]: Failed to sync token to backend: $e');
    }
  }

  /// Call this right after provider login succeeds
  static Future<void> onProviderLoggedIn() async {
    try {
      final fcmToken = await getToken();
      if (fcmToken != null) {
        await syncTokenWithBackend(fcmToken);
      }
      await subscribeToTopic('providers');
    } catch (e) {
      debugPrint('[FCM]: Failed to register FCM after login: $e');
    }
  }

  /// **Important Logic & Routing**: Handles tap actions on provider notifications.
  /// 
  /// If the payload contains a valid `bookingId`, it pushes the [BookingDetailScreen]
  /// directly onto the navigator stack, allowing the provider to accept or reject the job.
  static void handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final bookingId = data['bookingId']?.toString();

    debugPrint('[FCM Tap]: type=$type, bookingId=$bookingId');

    if (bookingId != null && bookingId.isNotEmpty) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: bookingId),
        ),
      );
    }
  }
}
