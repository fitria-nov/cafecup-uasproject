import 'package:flutter/material.dart';
import '../../models/cafe_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../cafe/payment_screen.dart';

// Updated OrderItem class to match the one from order_now_screen.dart
class OrderItem {
  final MenuItem item;
  int quantity;

  OrderItem({required this.item, required this.quantity});
}

class CheckoutScreen extends StatefulWidget {
  final Cafe cafe;
  final List<OrderItem> cartItems; // Updated to use OrderItem class
  final double totalPrice;

  const CheckoutScreen({
    super.key,
    required this.cafe,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedDeliveryMethod = 'pickup'; // 'pickup' or 'delivery'
  String _selectedPaymentMethod = 'cash'; // 'cash', 'card', 'ewallet'
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isProcessing = false;

  // Delivery fee
  double get _deliveryFee => _selectedDeliveryMethod == 'delivery' ? 5000.0 : 0.0;

  // Service fee (2% of subtotal)
  double get _serviceFee => widget.totalPrice * 0.02;

  // Tax (10% of subtotal)
  double get _tax => widget.totalPrice * 0.1;

  // Final total
  double get _finalTotal => widget.totalPrice + _deliveryFee + _serviceFee + _tax;

  Future<String> _createOrder(BuildContext context) async {
    try {
      final pb = PocketBaseService().pb;
      final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

      // Create main order
      final orderData = {
        'order_id': orderId,
        'cafe': widget.cafe.id, // Use 'cafe' field name to match your schema
        'user_id': pb.authStore.model?.id ?? 'guest', // Handle guest users
        'total_amount': _finalTotal,
        'subtotal': widget.totalPrice,
        'delivery_fee': _deliveryFee,
        'service_fee': _serviceFee,
        'tax': _tax,
        'status': 'pending',
        'delivery_method': _selectedDeliveryMethod,
        'payment_method': _selectedPaymentMethod,
        'delivery_address': _selectedDeliveryMethod == 'delivery' ? _addressController.text : '',
        'notes': _notesController.text,
        'order_time': DateTime.now().toIso8601String(),
        'estimated_time': DateTime.now().add(
            Duration(minutes: _selectedDeliveryMethod == 'pickup' ? 15 : 30)
        ).toIso8601String(),
      };

      final orderRecord = await pb.collection('orders').create(body: orderData);

      // Create order items
      for (var cartItem in widget.cartItems) {
        await pb.collection('order_items').create(body: {
          'order_id': orderRecord.id,
          'menu_item': cartItem.item.id,
          'quantity': cartItem.quantity,
          'price': cartItem.item.price,
          'subtotal': cartItem.item.price * cartItem.quantity,
        });
      }

      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCafeInfo(),
            _buildOrderSummary(),
            _buildDeliveryOptions(),
            _buildPaymentOptions(),
            _buildOrderNotes(),
            _buildPricingBreakdown(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildCafeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(widget.cafe.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cafe.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.cafe.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.cartItems.map((cartItem) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cartItem.item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${cartItem.quantity}x',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rp ${(cartItem.item.price * cartItem.quantity).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            title: const Text('Pickup'),
            subtitle: const Text('Ready in 15 minutes'),
            value: 'pickup',
            groupValue: _selectedDeliveryMethod,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryMethod = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
          RadioListTile<String>(
            title: const Text('Delivery'),
            subtitle: Text('Ready in 30 minutes • Rp ${_deliveryFee.toStringAsFixed(0)}'),
            value: 'delivery',
            groupValue: _selectedDeliveryMethod,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryMethod = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_selectedDeliveryMethod == 'delivery') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Enter your complete address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            title: const Text('Cash'),
            subtitle: const Text('Pay when you pickup/receive'),
            value: 'cash',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
          RadioListTile<String>(
            title: const Text('Credit/Debit Card'),
            subtitle: const Text('Pay now with card'),
            value: 'card',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
          RadioListTile<String>(
            title: const Text('E-Wallet'),
            subtitle: const Text('GoPay, OVO, DANA, etc.'),
            value: 'ewallet',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Any special requests or notes for your order...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', widget.totalPrice),
          if (_deliveryFee > 0) _buildPriceRow('Delivery Fee', _deliveryFee),
          _buildPriceRow('Service Fee', _serviceFee),
          _buildPriceRow('Tax', _tax),
          const Divider(thickness: 1),
          _buildPriceRow('Total', _finalTotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              _selectedPaymentMethod == 'cash'
                  ? 'Place Order - Rp ${_finalTotal.toStringAsFixed(0)}'
                  : 'Pay Now - Rp ${_finalTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    // Validate delivery address if delivery is selected
    if (_selectedDeliveryMethod == 'delivery' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final orderId = await _createOrder(context);

      if (_selectedPaymentMethod == 'cash') {
        // For cash payment, just show success and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate back to home and clear the navigation stack
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // For card/ewallet payment, navigate to payment screen
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                orderId: orderId,
                amount: (_finalTotal * 100).toInt(), // Convert to cents/smallest unit
              ),
            ),
          );

          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.toString()),
                backgroundColor: AppColors.success,
              ),
            );

            // Navigate back to home
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}