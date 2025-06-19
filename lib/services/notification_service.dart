import '../services/pocketbase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> createOrderNotification({
    required String userId,
    required String orderId,
    required String cafeId,
    required String status,
    String? cafeName,
  }) async {
    try {
      final pb = PocketBaseService().pb;

      final notificationData = _getNotificationData(status, cafeName ?? 'Cafe');

      await pb.collection('notifications').create(body: {
        'user_id': userId,
        'order_id': orderId,
        'cafe_id': cafeId,
        'title': notificationData['title'],
        'message': notificationData['message'],
        'type': notificationData['type'],
        'is_read': false,
      });

      print('Notification created for order $orderId with status $status');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> createReservationNotification({
    required String userId,
    required String reservationId,
    required String cafeId,
    required String status,
    String? cafeName,
  }) async {
    try {
      final pb = PocketBaseService().pb;

      final notificationData = _getReservationNotificationData(status, cafeName ?? 'Cafe');

      await pb.collection('notifications').create(body: {
        'user_id': userId,
        'reservation_id': reservationId,
        'cafe_id': cafeId,
        'title': notificationData['title'],
        'message': notificationData['message'],
        'type': notificationData['type'],
        'is_read': false,
      });

      print('Reservation notification created for $reservationId with status $status');
    } catch (e) {
      print('Error creating reservation notification: $e');
    }
  }

  Map<String, String> _getNotificationData(String status, String cafeName) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return {
          'title': 'Order Confirmed! 🎉',
          'message': 'Your order from $cafeName has been confirmed and is being prepared.',
          'type': 'order_confirmed',
        };
      case 'preparing':
        return {
          'title': 'Order Being Prepared 👨‍🍳',
          'message': 'Your order from $cafeName is now being prepared by our chefs.',
          'type': 'order_preparing',
        };
      case 'ready':
        return {
          'title': 'Order Ready! ☕',
          'message': 'Your order from $cafeName is ready for pickup/delivery.',
          'type': 'order_ready',
        };
      case 'delivered':
      case 'completed':
        return {
          'title': 'Order Delivered! ✅',
          'message': 'Your order from $cafeName has been successfully delivered. Enjoy!',
          'type': 'order_delivered',
        };
      case 'cancelled':
        return {
          'title': 'Order Cancelled ❌',
          'message': 'Your order from $cafeName has been cancelled. Please contact support if needed.',
          'type': 'order_cancelled',
        };
      default:
        return {
          'title': 'Order Update',
          'message': 'Your order from $cafeName has been updated.',
          'type': 'order_update',
        };
    }
  }

  Map<String, String> _getReservationNotificationData(String status, String cafeName) {
    switch (status) {
      case 'confirmed':
        return {
          'title': 'Reservation Confirmed! 🪑',
          'message': 'Your table reservation at $cafeName has been confirmed.',
          'type': 'reservation_confirmed',
        };
      case 'reminder':
        return {
          'title': 'Reservation Reminder ⏰',
          'message': 'Don\'t forget your reservation at $cafeName in 1 hour!',
          'type': 'reservation_reminder',
        };
      case 'cancelled':
        return {
          'title': 'Reservation Cancelled ❌',
          'message': 'Your reservation at $cafeName has been cancelled.',
          'type': 'reservation_cancelled',
        };
      default:
        return {
          'title': 'Reservation Update',
          'message': 'Your reservation at $cafeName has been updated.',
          'type': 'reservation_update',
        };
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final pb = PocketBaseService().pb;
      final records = await pb.collection('notifications').getFullList(
        filter: 'user_id = "$userId" && is_read = false',
      );
      return records.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }
}