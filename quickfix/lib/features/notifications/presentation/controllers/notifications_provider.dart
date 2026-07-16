import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:quickfix/core/storage/hive_service.dart';
import 'package:quickfix/core/network/network_providers.dart';
import 'package:quickfix/features/notifications/datasources/notifications_remote_data_source.dart';
import 'package:quickfix/features/notifications/repositories/notifications_repository.dart';
import 'package:quickfix/features/notifications/repositories/notifications_repository_impl.dart';

final notificationsRemoteDataSourceProvider = Provider<NotificationsRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return NotificationsRemoteDataSource(client);
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final remote = ref.watch(notificationsRemoteDataSourceProvider);
  return NotificationsRepositoryImpl(remote);
});

// Global Notifications Providers
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  final box = Hive.box('local_notifications');

  List<Map<String, dynamic>> getList() {
    final list = box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort((a, b) {
      final timeA =
          DateTime.tryParse(a['time'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final timeB =
          DateTime.tryParse(b['time'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return list;
  }

  yield getList();

  await for (final _ in box.watch()) {
    yield getList();
  }
});

final syncNotificationsProvider = FutureProvider<void>((ref) async {
  try {
    final repository = ref.read(notificationsRepositoryProvider);
    final data = await repository.getNotifications();
    final box = Hive.box('local_notifications');

    final deletedIds = HiveService.getDeletedNotificationIds();
    final readIds = HiveService.getReadNotificationIds();

    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id']?.toString() ?? '';
      if (id.isNotEmpty && !deletedIds.contains(id) && !box.containsKey(id)) {
        final localItem = {
          'id': id,
          'title': map['title'] ?? '',
          'body': map['body'] ?? '',
          'time':
              map['createdAt'] ??
              map['time'] ??
              DateTime.now().toIso8601String(),
          'isRead': readIds.contains(id),
          'type': map['type'] ?? 'general',
          'bookingId': map['bookingId'] ?? '',
          'orderId': map['orderId'] ?? '',
          'deepLink': map['deepLink'] ?? '',
          'iconColor': map['iconColor'] ?? 'primary',
        };
        await box.put(id, localItem);
      }
    }
  } catch (_) {
    // Fail silently
  }
});

class ReadNotificationsNotifier extends StateNotifier<Set<String>> {
  ReadNotificationsNotifier()
    : super(HiveService.getReadNotificationIds().toSet()) {
    _syncWithLocalNotifications();
  }

  void _syncWithLocalNotifications() {
    try {
      final box = Hive.box('local_notifications');
      final readIds = box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((item) => item['isRead'] == true)
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      state = readIds;
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    state = {...state, id};
    HiveService.markNotificationAsRead(id);

    try {
      final box = Hive.box('local_notifications');
      final item = box.get(id);
      if (item != null) {
        final updated = Map<String, dynamic>.from(item as Map);
        updated['isRead'] = true;
        await box.put(id, updated);
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead(List<String> ids) async {
    state = {...state, ...ids};
    for (final id in ids) {
      HiveService.markNotificationAsRead(id);
    }

    try {
      final box = Hive.box('local_notifications');
      for (final id in ids) {
        final item = box.get(id);
        if (item != null) {
          final updated = Map<String, dynamic>.from(item as Map);
          updated['isRead'] = true;
          await box.put(id, updated);
        }
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    state = state.where((item) => item != id).toSet();
    try {
      await HiveService.markNotificationAsDeleted(id);
      final box = Hive.box('local_notifications');
      await box.delete(id);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = {};
    try {
      final box = Hive.box('local_notifications');
      final ids = box.keys.map((e) => e.toString()).toList();
      await HiveService.markMultipleNotificationsAsDeleted(ids);
      await box.clear();
    } catch (_) {}
  }
}

final readNotificationsProvider =
    StateNotifierProvider<ReadNotificationsNotifier, Set<String>>((ref) {
      return ReadNotificationsNotifier();
    });

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (list) {
      return list.where((item) => item['isRead'] != true).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});
