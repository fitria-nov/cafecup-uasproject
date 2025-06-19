import 'dart:developer' as developer;
import 'pocketbase_service.dart';

class OrderService {
  final PocketBaseService _pbService = PocketBaseService();

  // Method yang sudah ada - saveOrderFromPayment
  Future<void> saveOrderFromPayment({
    required String orderId,
    required double totalAmount,
    required String customerName,
    required String customerEmail,
    required String paymentStatus,
    String? transactionId,
  }) async {
    try {
      final pb = _pbService.pb;

      // Debug: Check authentication
      final userId = pb.authStore.model?.id;
      developer.log('🔍 OrderService - User ID: $userId');

      if (userId == null) {
        developer.log('⚠️ User not authenticated, skipping order save');
        return;
      }

      // Get or create cafe
      final cafeId = await _getOrCreateDefaultCafe();
      developer.log('🔍 OrderService - Cafe ID: $cafeId');

      // Determine order status based on payment status
      String orderStatus;
      switch (paymentStatus.toLowerCase()) {
        case 'success':
        case 'settlement':
          orderStatus = 'preparing';
          break;
        case 'pending':
          orderStatus = 'pending';
          break;
        default:
          orderStatus = 'pending';
      }

      // Create order notes with payment info
      final notes = 'Payment: midtrans | Customer: $customerName | Email: $customerEmail' +
          (transactionId != null ? ' | TxnID: $transactionId' : '');

      final orderData = {
        'user': userId,
        'cafe': cafeId,
        'total_amount': totalAmount,
        'status': orderStatus,
        'notes': notes,
        'estimatedTime': orderStatus == 'preparing' ? '15-20 minutes' : '',
      };

      developer.log('🔍 OrderService - Creating order: $orderData');

      final record = await pb.collection('orders').create(body: orderData);

      developer.log('✅ Order saved successfully: ${record.id}');

    } catch (e, stackTrace) {
      developer.log('❌ Error saving order: $e');
      developer.log('❌ Stack trace: $stackTrace');
    }
  }

  // TAMBAHKAN METHOD INI - createTestOrder untuk OrdersScreen
  Future<void> createTestOrder() async {
    try {
      final pb = _pbService.pb;

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        developer.log('❌ Test failed: User not authenticated');
        return;
      }

      final cafeId = await _getOrCreateDefaultCafe();

      final testOrderData = {
        'user': userId,
        'cafe': cafeId,
        'total_amount': 25000.0,
        'status': 'pending',
        'notes': 'Test order - Manual creation from OrdersScreen',
        'estimatedTime': '',
      };

      final record = await pb.collection('orders').create(body: testOrderData);
      developer.log('✅ Test order created: ${record.id}');

    } catch (e) {
      developer.log('❌ Test order failed: $e');
    }
  }

  // TAMBAHKAN METHOD INI - testCreateOrder untuk PaymentScreen
  Future<void> testCreateOrder() async {
    try {
      final pb = _pbService.pb;

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        developer.log('❌ Test failed: User not authenticated');
        return;
      }

      final cafeId = await _getOrCreateDefaultCafe();

      final testOrderData = {
        'user': userId,
        'cafe': cafeId,
        'total_amount': 15000.0,
        'status': 'pending',
        'notes': 'Test order - Manual creation from PaymentScreen',
        'estimatedTime': '',
      };

      final record = await pb.collection('orders').create(body: testOrderData);
      developer.log('✅ Test order created from PaymentScreen: ${record.id}');

    } catch (e) {
      developer.log('❌ Test order failed: $e');
    }
  }

  Future<String> _getOrCreateDefaultCafe() async {
    try {
      final pb = _pbService.pb;

      // Try to get existing cafe
      final result = await pb.collection('cafe').getList(
        page: 1,
        perPage: 1,
      );

      if (result.items.isNotEmpty) {
        return result.items.first.id;
      }

      // Create default cafe if none exists
      final cafeData = {
        'name': 'Default Cafe',
        'description': 'Default cafe for orders',
        'address': 'Default Address',
        'phone': '000-000-0000',
        'rating': 4.0,
        'image': '',
      };

      final record = await pb.collection('cafe').create(body: cafeData);
      developer.log('✅ Created default cafe: ${record.id}');
      return record.id;

    } catch (e) {
      developer.log('❌ Error with cafe: $e');
      throw Exception('Failed to get or create cafe: $e');
    }
  }

  // Method lain yang mungkin sudah ada
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentStatus,
    String? transactionId,
    String? estimatedTime,
  }) async {
    try {
      final pb = _pbService.pb;

      final updateData = <String, dynamic>{
        'status': status,
      };

      if (paymentStatus != null) {
        updateData['payment_status'] = paymentStatus;
      }

      if (transactionId != null && transactionId.isNotEmpty) {
        updateData['transaction_id'] = transactionId;
      }

      if (estimatedTime != null) {
        updateData['estimatedTime'] = estimatedTime;
      }

      await pb.collection('orders').update(orderId, body: updateData);

      developer.log('✅ Order status updated: $orderId -> $status');

    } catch (e) {
      developer.log('❌ Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> confirmPayment({
    required String orderId,
    required String transactionId,
    required String paymentStatus,
  }) async {
    try {
      final pb = _pbService.pb;

      String orderStatus;
      switch (paymentStatus.toLowerCase()) {
        case 'settlement':
        case 'success':
          orderStatus = 'preparing';
          break;
        case 'pending':
          orderStatus = 'pending';
          break;
        case 'failed':
        case 'deny':
        case 'expire':
          orderStatus = 'cancelled';
          break;
        case 'cancel':
          orderStatus = 'cancelled';
          break;
        default:
          orderStatus = 'pending';
      }

      await pb.collection('orders').update(orderId, body: {
        'status': orderStatus,
        'payment_status': paymentStatus,
        'transaction_id': transactionId,
        'payment_confirmed_at': DateTime.now().toIso8601String(),
      });

      developer.log('✅ Payment confirmed for order: $orderId');

    } catch (e) {
      developer.log('❌ Error confirming payment: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  Future<void> updateEstimatedTime({
    required String orderId,
    required String estimatedTime,
  }) async {
    try {
      final pb = _pbService.pb;

      await pb.collection('orders').update(orderId, body: {
        'estimatedTime': estimatedTime,
        'status': 'preparing',
      });

      developer.log('✅ Estimated time updated: $orderId -> $estimatedTime');

    } catch (e) {
      developer.log('❌ Error updating estimated time: $e');
      throw Exception('Failed to update estimated time: $e');
    }
  }
}
