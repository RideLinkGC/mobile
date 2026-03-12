import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/convex_functions.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final String? tripId;
  final String? bookingId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.tripId,
    this.bookingId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['_creationTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['_creationTime'] as int)
          : null,
      tripId: metadata?['tripId'] as String?,
      bookingId: metadata?['bookingId'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      tripId: tripId,
      bookingId: bookingId,
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}

class NotificationProvider extends ChangeNotifier {
  final ConvexClient? _convex;
  final String _currentUserId;

  SubscriptionHandle? _subscription;

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static final _mockNotifications = [
    const AppNotification(
      id: 'n1',
      type: 'booking_confirmed',
      title: 'Booking Confirmed',
      message:
          'Your ride from Bole to Megenagna has been confirmed for 08:00 AM.',
      isRead: false,
    ),
    const AppNotification(
      id: 'n2',
      type: 'system',
      title: 'Payment Received',
      message: 'You received 45 ETB for your trip.',
      isRead: false,
    ),
    const AppNotification(
      id: 'n3',
      type: 'trip_started',
      title: 'Trip Reminder',
      message: 'Your trip starts in 30 minutes. Be at the pickup point.',
      isRead: true,
    ),
    const AppNotification(
      id: 'n4',
      type: 'booking_request',
      title: 'New Booking Request',
      message: 'Tigist requested a seat on your Bole-Megenagna trip.',
      isRead: true,
    ),
  ];

  NotificationProvider(this._convex, this._currentUserId);

  Future<void> loadNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();

    if (_convex == null) {
      _notifications = _mockNotifications;
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      _subscription?.cancel();
      _subscription = await _convex.subscribe(
        name: ConvexFunctions.getUserNotifications,
        args: {},
        onUpdate: (value) {
          try {
            final list = jsonDecode(value) as List;
            _notifications = list
                .map((e) =>
                    AppNotification.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('Notification parse error: $e');
            _notifications = _mockNotifications;
          }
          _loading = false;
          notifyListeners();
        },
        onError: (message, value) {
          debugPrint('Notifications error: $message');
          _notifications = _mockNotifications;
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to notifications: $e');
      _notifications = _mockNotifications;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await _convex?.mutation(
        name: ConvexFunctions.markNotificationRead,
        args: {'notificationId': notificationId},
      );
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _convex?.mutation(
        name: ConvexFunctions.markAllNotificationsRead,
        args: {},
      );
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
