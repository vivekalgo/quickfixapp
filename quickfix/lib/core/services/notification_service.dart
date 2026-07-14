import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quickfix/core/router/app_router.dart';
import 'package:quickfix/core/logging/app_logger.dart';
import 'package:quickfix/core/network/api_endpoints.dart';
import 'package:quickfix/core/services/hive_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  
  // Open local notifications Hive box
  await Hive.initFlutter();
  final box = await Hive.openBox('local_notifications');
  
  // Save notification to Hive
  final notificationData = _parseMessage(message);
  await box.put(notificationData['id'], notificationData);
  
  AppLogger.info('Background message received and stored: ${message.messageId}', tag: 'FCM');
}

Map<String, dynamic> _parseMessage(RemoteMessage message) {
  final notification = message.notification;
  final data = message.data;
  final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  return {
    'id': id,
    'title': notification?.title ?? data['title'] ?? 'QuickFix Update',
    'body': notification?.body ?? data['body'] ?? '',
    'time': DateTime.now().toIso8601String(),
    'isRead': false,
    'type': data['type'] ?? 'general',
    'bookingId': data['bookingId'] ?? '',
    'orderId': data['orderId'] ?? '',
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
      await Hive.openBox('local_notifications');

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
              AppLogger.error('Failed to parse notification payload', tag: 'FCM', error: e);
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
        AppLogger.info('Foreground message received: ${message.messageId}', tag: 'FCM');
        
        // Save to Hive
        final notificationData = _parseMessage(message);
        final box = Hive.box('local_notifications');
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
        AppLogger.info('Notification clicked to open app from background: ${message.messageId}', tag: 'FCM');
        handleNotificationClick(message.data);
      });

      // 7. Handle app launch from terminated state via notification click
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App launched from terminated state via notification click: ${initialMessage.messageId}', tag: 'FCM');
        // Give router a slight delay to initialize
        Future.delayed(const Duration(milliseconds: 1000), () {
          handleNotificationClick(initialMessage.data);
        });
      }

      // 8. Auto sync token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        AppLogger.info('FCM Token refreshed: $newToken', tag: 'FCM');
        await syncTokenWithBackend(newToken);
      });

      // Default topic subscription for all customers
      await subscribeToTopic('customers');

    } catch (e, s) {
      AppLogger.error('Failed to initialize NotificationService', tag: 'FCM', error: e, stackTrace: s);
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
      AppLogger.info('Notification permission status: ${settings.authorizationStatus}', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Error requesting notification permissions', tag: 'FCM', error: e);
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', tag: 'FCM', error: e);
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', tag: 'FCM', error: e);
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      AppLogger.info('Fetched FCM Token: $token', tag: 'FCM');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get FCM Token', tag: 'FCM', error: e);
      return null;
    }
  }

  static Future<void> syncTokenWithBackend(String token) async {
    // Only sync if the user is logged in
    final cacheBox = Hive.box('app_cache');
    final authToken = cacheBox.get('auth_token') as String?;
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

      final response = await dioClient.post('/auth/profile/update', data: {
        'fcmToken': token,
      });

      if (response.statusCode == 200) {
        AppLogger.info('Successfully synced FCM Token with backend.', tag: 'FCM');
        // Update cached profile
        final cached = HiveService.getCachedProfile();
        if (cached != null) {
          final updated = Map<String, dynamic>.from(cached);
          updated['fcmToken'] = token;
          await HiveService.saveCachedProfile(updated);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to sync FCM Token with backend', tag: 'FCM', error: e);
    }
  }

  static void handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final bookingId = data['bookingId']?.toString();
    final deepLink = data['deepLink']?.toString();

    AppLogger.info('Handling notification tap: type=$type, bookingId=$bookingId, deepLink=$deepLink', tag: 'FCM');

    if (deepLink != null && deepLink.isNotEmpty) {
      try {
        appRouter.push(deepLink);
        return;
      } catch (_) {}
    }

    switch (type) {
      case 'booking':
      case 'booking_status':
      case 'Booking':
        if (bookingId != null && bookingId.isNotEmpty) {
          appRouter.push('/tracking/$bookingId');
        } else {
          appRouter.push('/orders');
        }
        break;
      case 'offer':
      case 'promotion':
        appRouter.push('/offers');
        break;
      case 'support':
        appRouter.push('/support');
        break;
      case 'general':
      default:
        appRouter.push('/notifications');
        break;
    }
  }
}
