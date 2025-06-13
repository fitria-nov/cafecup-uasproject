import 'package:flutter/material.dart';
import '../../models/cafe_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/pocketbase_service.dart';
import '../../screens/cafe/payment_screen.dart'; // Pastikan file ini ada

class CheckoutScreen extends StatelessWidget {
  final Cafe cafe;
  final List<Map<String, dynamic>> cartItems; // [{ 'item': MenuItem, 'quantity': int }]
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cafe,
    required this.cartItems,
    required this.total,
  });

  Future<String> _createOrder(BuildContext context) async {
    final pb = PocketBaseService().pb;
    final orderData = {
      'order_id': 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
      'cafe_id': cafe.id,
      'user_id': 'USER_ID', // Ganti dengan ID pengguna jika ada autentikasi
      'total_amount': total,
      'status': 'preparing',
      'items': cartItems.map((item) => {
        'item_id': item['item'].id,
        'quantity': item['quantity'],
      }).toList(),
      'orderTime': DateTime.now().toIso8601String(),
      'estimatedTime': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(), // Estimasi 10 menit
    };
    final record = await pb.collection('orders').create(body: orderData);
    return record.data['order_id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary for ${cafe.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...cartItems.map((item) {
              final menuItem = item['item'] as MenuItem;
              final quantity = item['quantity'] as int;
              return ListTile(
                title: Text(menuItem.name),
                subtitle: Text('Quantity: $quantity'),
                trailing: Text('\$${menuItem.price * quantity}'),
              );
            }).toList(),
            const Divider(),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final orderId = await _createOrder(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          orderId: orderId,
                          amount: (total * 100).toInt(), // Konversi ke rupiah (misalnya, total dalam dollar * 100)
                        ),
                      ),
                    );
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.toString())),
                      );
                      // Navigasi ulang ke OrdersScreen untuk refresh
                      Navigator.pushReplacementNamed(context, '/orders');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating order: $e')),
                    );
                  }
                },
                child: const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}