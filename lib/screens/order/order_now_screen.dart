import 'package:flutter/material.dart';
import '../../models/cafe_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';

class OrderNowScreen extends StatefulWidget {
  final Cafe cafe;

  const OrderNowScreen({super.key, required this.cafe});

  @override
  State<OrderNowScreen> createState() => _OrderNowScreenState();
}

class _OrderNowScreenState extends State<OrderNowScreen> {
  List<MenuItem> _menuItems = [];
  List<OrderItem> _cartItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    try {
      final pb = PocketBaseService().pb;
      final cafeId = widget.cafe.id;

      print("Fetching menu items for cafe ID: $cafeId"); // Tambahkan log

      // Gunakan nama field yang benar: 'cafe' bukan 'cafe_id'
      final records = await pb.collection('menu_items').getFullList(
        filter: 'cafe="$cafeId"',
        sort: 'category',
      );

      print("Fetched ${records.length} menu items"); // Tambahkan log

      setState(() {
        _menuItems = records.map((record) => MenuItem.fromRecord(record)).toList();
        _isLoading = false; // Pastikan loading indicator berhenti
      });
    } catch (e) {
      print('Error fetching menu items: $e');
      setState(() {
        _errorMessage = 'Failed to load menu items: $e';
        _isLoading = false; // Pastikan loading indicator berhenti
      });
    }
  }

  void _addToCart(MenuItem item) {
    setState(() {
      // Check if item already exists in cart
      final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.item.id == item.id);

      if (existingIndex >= 0) {
        // Increment quantity if item already in cart
        _cartItems[existingIndex].quantity++;
      } else {
        // Add new item to cart
        _cartItems.add(OrderItem(item: item, quantity: 1));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  double get _totalPrice {
    return _cartItems.fold(0, (total, item) => total + (item.item.price * item.quantity));
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pb = PocketBaseService().pb;


      // Create order record
      final order = await pb.collection('orders').create(
          body: {
            'cafe_id': widget.cafe.id,
            'user_id': pb.authStore.model?.id,
            'total_amount': _totalPrice,
            'status': 'pending',
          }
      );

      // Create order items
      for (var item in _cartItems) {
        await pb.collection('order_items').create(
            body: {
              'orders_id': order.id,
              'menu_id': item.item.id,
              'quantity': item.quantity,
              'prices': item.item.price,
            }
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );

        // Clear cart and navigate back
        setState(() {
          _cartItems = [];
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Now'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cafe.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Cafe info
          Container(
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(widget.cafe.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cafe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cafe.address,
                        style: const TextStyle(
                          fontSize: 14,
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
          ),

          // Menu items
          Expanded(
            child: _menuItems.isEmpty
                ? const Center(
              child: Text(
                'No menu items available',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];

                // Add category header if this is the first item or category changed
                final bool showCategoryHeader = index == 0 ||
                    _menuItems[index].category != _menuItems[index - 1].category;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCategoryHeader) ...[
                      if (index > 0) const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (item.imageUrl.isNotEmpty)
                            Container(
                              width: 70,
                              height: 70,
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp ${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _addToCart(item),
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Cart summary
          if (_cartItems.isNotEmpty)
            Container(
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_cartItems.length} items',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Rp ${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Cart details bottom sheet
      floatingActionButton: _cartItems.isNotEmpty
          ? FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Your Cart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _cartItems.clear();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = _cartItems[index];
                        return ListTile(
                          title: Text(
                            cartItem.item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Rp ${cartItem.item.price.toStringAsFixed(0)} x ${cartItem.quantity}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  _removeFromCart(index);
                                  if (_cartItems.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    _cartItems[index].quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Rp ${_totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _placeOrder();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart),
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _cartItems.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }
}

class OrderItem {
  final MenuItem item;
  int quantity;

  OrderItem({required this.item, required this.quantity});
}
