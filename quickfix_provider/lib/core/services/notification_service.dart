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
import '../network/api_endpoints.dart';
import '../storage/hive_service.dart';
import '../router/app_router.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  
  // Open local notifications Hive box
  await Hive.initFlutter();
  final box = await Hive.openBox('provider_notifications');
  
  // Save notification to Hive
  final notificationData = _parseMessage(message);
  await box.put(notificationData['id'], notificationData);
  
  debugPrint('[FCM Background]: Message received and stored: ${message.messageId}');
}

Map<String, dynamic> _parseMessage(RemoteMessage message) {
  final notification = message.notification;
  final data = message.data;
  final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  
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

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for booking updates, payments, and emergency alerts.', // description
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static Future<void> init() async {
    try {
      // 1. Initialize local notifications Hive box
      await Hive.openBox('provider_notifications');

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Configure local notifications settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              // Convert payload back to map
              final Map<String, dynamic> data = Uri.splitQueryString(payload);
              handleNotificationClick(data);
            } catch (e) {
              debugPrint('[FCM]: Failed to parse notification payload: $e');
            }
          }
        },
      );

      // 4. Create the high importance channel
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('[FCM Foreground]: Message received: ${message.messageId}');
        
        // Save to Hive
        final notificationData = _parseMessage(message);
        final box = Hive.box('provider_notifications');
        await box.put(notificationData['id'], notificationData);
        
        // Trigger notification sound / pop up in foreground using flutter_local_notifications
        final notification = message.notification;

        if (notification != null && !kIsWeb) {
          // Build payload string
          final data = message.data;
          final payload = Uri(queryParameters: data.map((key, value) => MapEntry(key, value.toString()))).query;
          
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@drawable/ic_notification',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                playSound: true,
                enableVibration: true,
                visibility: NotificationVisibility.public,
              ),
            ),
            payload: payload,
          );
        }
      });

      // 6. Handle app resume from background notification click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Background Click]: App opened: ${message.messageId}');
        handleNotificationClick(message.data);
      });

      // 7. Auto sync token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM Token Refresh]: $newToken');
        await syncTokenWithBackend(newToken);
      });

      // 8. Handle app launch and subscribe to topics asynchronously
      _initTerminatedStateAndTopic();

      // Request permissions immediately on startup
      requestPermissions().then((_) async {
        final token = HiveService.getAuthToken();
        if (token != null) {
          final fcmToken = await getToken();
          if (fcmToken != null) {
            await syncTokenWithBackend(fcmToken);
          }
        }
      });

    } catch (e) {
      debugPrint('[FCM]: Failed to initialize NotificationService: $e');
    }
  }

  static Future<void> _initTerminatedStateAndTopic() async {
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM Terminated Click]: App launched via notification click: ${initialMessage.messageId}');
        // Give router/navigation stack a slight delay to initialize
        Future.delayed(const Duration(milliseconds: 1500), () {
          handleNotificationClick(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('[FCM]: Failed to get initial message: $e');
    }

    try {
      await subscribeToTopic('providers');
    } catch (e) {
      debugPrint('[FCM]: Failed to auto-subscribe to providers topic: $e');
    }
  }

  static Future<void> requestPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM]: Notification permission status: ${settings.authorizationStatus}');
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
      debugPrint('[FCM]: Fetched Token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM]: Failed to get token: $e');
      return null;
    }
  }

  static Future<void> syncTokenWithBackend(String token) async {
    // Only sync if the provider is logged in
    final authToken = HiveService.getAuthToken();
    if (authToken == null) return;

    try {
      final dioClient = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ));

      // Operator-Block Bypass (Jio / Airtel)
      const String railwayEdgeIp = '69.46.46.69';
      const String railwayDomain = 'up.railway.app';
      if (ApiEndpoints.baseUrl.contains(railwayDomain)) {
        final originalHost = Uri.parse(ApiEndpoints.baseUrl).host;
        dioClient.options.headers['Host'] = originalHost;
        dioClient.options.baseUrl = ApiEndpoints.baseUrl.replaceFirst(originalHost, railwayEdgeIp);
        
        ((dioClient.httpClientAdapter) as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) {
            return (host == railwayEdgeIp || host.endsWith(railwayDomain)) &&
                (cert.subject.contains('CN=*.up.railway.app') || cert.subject.contains('CN=up.railway.app'));
          };
          return client;
        };
      }

      final response = await dioClient.post(ApiEndpoints.updateFcmToken, data: {
        'fcmToken': token,
      });

      if (response.statusCode == 200) {
        debugPrint('[FCM]: Successfully synced FCM Token with backend.');
        // Update cached profile
        final cached = HiveService.getShopProfile();
        if (cached != null) {
          final updated = Map<String, dynamic>.from(cached);
          updated['fcmToken'] = token;
          await HiveService.saveShopProfile(updated);
        }
      }
    } catch (e) {
      debugPrint('[FCM]: Failed to sync FCM Token with backend: $e');
    }
  }

  static void handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final bookingId = data['bookingId']?.toString();

    debugPrint('[FCM Tap]: Handling notification tap: type=$type, bookingId=$bookingId');

    if (bookingId != null && bookingId.isNotEmpty) {
      // Navigate to Booking Detail Screen
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: bookingId),
        ),
      );
    }
  }
}
