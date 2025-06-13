import 'package:flutter/material.dart';
import '../../models/cafe_model.dart';
import '../../models/menu_item_model.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';
import 'payment_screen.dart'; // Ubah import ke PaymentScreen.dart
import 'orders_screen.dart'; // Untuk navigasi setelah pembayaran

class CheckoutScreen extends StatefulWidget {
  final Cafe cafe;
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cafe,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'card';
  String _orderType = 'pickup'; // pickup or delivery
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<String> _createOrder() async {
    final pb = PocketBaseService().pb;
    final subtotal = widget.total;
    final deliveryFee = _orderType == 'delivery' ? 2.50 : 0.0;
    final tax = (subtotal + deliveryFee) * 0.1;
    final total = subtotal + deliveryFee + tax;

    final orderData = {
      'order_id': 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
      'cafe_id': widget.cafe.id,
      'user_id': 'USER_ID', // Ganti dengan ID pengguna jika ada autentikasi
      'total_amount': total,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'status': _selectedPaymentMethod == 'cash' ? 'pending' : 'preparing',
      'order_type': _orderType, // pickup or delivery
      'notes': _notesController.text,
      'items': widget.cartItems.map((item) => {
        'item_id': item['item'].id,
        'quantity': item['quantity'],
      }).toList(),
      'orderTime': DateTime.now().toIso8601String(),
      'estimatedTime': DateTime.now()
          .add(Duration(minutes: _orderType == 'pickup' ? 15 : 30))
          .toIso8601String(), // 15 menit untuk pickup, 30 menit untuk delivery
    };

    final record = await pb.collection('orders').create(body: orderData);
    return record.id; // Mengembalikan ID record (bukan order_id)
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simpan pesanan ke PocketBase
      final orderId = await _createOrder();

      if (_selectedPaymentMethod == 'cash') {
        // Untuk metode "cash", langsung anggap pesanan diterima (pending pembayaran di tempat)
        _showSuccessDialog();
      } else {
        // Untuk metode "card" atau "digital_wallet", lanjutkan ke PaymentScreen
        final subtotal = widget.total;
        final deliveryFee = _orderType == 'delivery' ? 2.50 : 0.0;
        final tax = (subtotal + deliveryFee) * 0.1;
        final total = subtotal + deliveryFee + tax;

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
          // Setelah pembayaran selesai, navigasi ke OrdersScreen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _orderType == 'pickup'
                    ? 'Your order will be ready for pickup in 15-20 minutes'
                    : 'Your order will be delivered in 30-45 minutes',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const OrdersScreen()),
                    );
                  },
                  child: const Text('View Orders'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            _buildOrderType(),
            _buildDeliveryInfo(),
            _buildPaymentMethod(),
            _buildSpecialInstructions(),
            _buildPricingBreakdown(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildPlaceOrderButton(),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(
                Icons.local_cafe,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.cafe.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.cartItems.map((cartItem) {
            final MenuItem item = cartItem['item'];
            final int quantity = cartItem['quantity'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
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
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '\$${item.price.toStringAsFixed(2)} x $quantity',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item.price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _buildOrderType() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOrderTypeCard(
                  type: 'pickup',
                  icon: Icons.store,
                  title: 'Pickup',
                  subtitle: 'Ready in 15-20 min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderTypeCard(
                  type: 'delivery',
                  icon: Icons.delivery_dining,
                  title: 'Delivery',
                  subtitle: '30-45 min',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _orderType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _orderType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textLight.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textDark,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    if (_orderType != 'delivery') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
            'Delivery Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '123 Main Street, Apt 4B\nDowntown, Jakarta 12345',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement change address
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 16),
          _buildPaymentOption(
            value: 'card',
            icon: Icons.credit_card,
            title: 'Credit/Debit Card',
            subtitle: '**** **** **** 1234',
          ),
          _buildPaymentOption(
            value: 'digital_wallet',
            icon: Icons.account_balance_wallet,
            title: 'Digital Wallet',
            subtitle: 'GoPay, OVO, DANA',
          ),
          _buildPaymentOption(
            value: 'cash',
            icon: Icons.money,
            title: 'Cash',
            subtitle: _orderType == 'pickup' ? 'Pay at store' : 'Pay on delivery',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == value
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? AppColors.primary
                : AppColors.textLight.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedPaymentMethod == value
                  ? AppColors.primary
                  : AppColors.textLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedPaymentMethod == value
                          ? AppColors.primary
                          : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedPaymentMethod == value)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
            'Special Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add any special requests or notes for your order...',
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    final subtotal = widget.total;
    final deliveryFee = _orderType == 'delivery' ? 2.50 : 0.0;
    final tax = (subtotal + deliveryFee) * 0.1; // 10% tax
    final total = subtotal + deliveryFee + tax;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          _buildPriceRow('Subtotal', subtotal),
          if (_orderType == 'delivery')
            _buildPriceRow('Delivery Fee', deliveryFee),
          _buildPriceRow('Tax', tax),
          const Divider(height: 24),
          _buildPriceRow('Total', total, isTotal: true),
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
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textDark,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isProcessing
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text(
            'Place Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}