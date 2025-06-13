import 'package:flutter/material.dart';
import '../../services/pocketbase_service.dart';
import '../../models/cafe_model.dart';
import '../../models/menu_item_model.dart';
import '../../utils/app_colors.dart';
import 'checkout_screen.dart';

class MenuScreen extends StatefulWidget {
  final Cafe cafe;

  const MenuScreen({
    super.key,
    required this.cafe,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, int> _cart = {};
  List<String> _categories = [];
  Map<String, List<MenuItem>> _menuItems = {};
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
      final records = await pb.collection('menu_items').getFullList(
        filter: 'cafe = "${widget.cafe.id}"', // Filter berdasarkan ID kafe
         sort: 'category,name', // Urutkan berdasarkan kategori dan nama
      );

      // Konversi record menjadi list MenuItem
      final List<MenuItem> items = records.map((record) {
        return MenuItem(
          id: record.id,
          name: record.data['name'] as String,
          description: record.data['description'] as String,
          price: (record.data['price'] as num).toDouble(),
          imageUrl: record.data['imageUrl'] as String,
          category: record.data['category'] as String,
        );
      }).toList();

      // Kelompokkan item berdasarkan kategori
      final Map<String, List<MenuItem>> groupedItems = {};
      final Set<String> categoriesSet = {};

      for (final item in items) {
        final category = item.category;
        categoriesSet.add(category);
        if (!groupedItems.containsKey(category)) {
          groupedItems[category] = [];
        }
        groupedItems[category]!.add(item);
      }

      setState(() {
        _menuItems = groupedItems;
        _categories = categoriesSet.toList()..sort();
        _tabController = TabController(length: _categories.length, vsync: this);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load menu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _cartItemCount {
    return _cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  double get _cartTotal {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = _findItemById(itemId);
      if (item != null) {
        total += item.price * quantity;
      }
    });
    return total;
  }

  MenuItem? _findItemById(String id) {
    for (final category in _menuItems.values) {
      for (final item in category) {
        if (item.id == id) return item;
      }
    }
    return null;
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
        title: Text('${widget.cafe.name} Menu'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return _buildCategoryView(category);
        }).toList(),
      ),
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartSummary() : null,
    );
  }

  Widget _buildCategoryView(String category) {
    final items = _menuItems[category] ?? [];

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items available',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textLight,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildMenuItem(items[index]);
      },
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final quantity = _cart[item.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.imageUrl),
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
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
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
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (quantity == 0)
            GestureDetector(
              onTap: () => _addToCart(item.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: () => _removeFromCart(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _addToCart(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_cartItemCount items',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  '\$${_cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(
                    cafe: widget.cafe,
                    cartItems: _getCartItems(),
                    total: _cartTotal,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCartItems() {
    final items = <Map<String, dynamic>>[];
    _cart.forEach((itemId, quantity) {
      final item = _findItemById(itemId);
      if (item != null) {
        items.add({
          'item': item,
          'quantity': quantity,
        });
      }
    });
    return items;
  }

  void _addToCart(String itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart[itemId] != null) {
        if (_cart[itemId]! > 1) {
          _cart[itemId] = _cart[itemId]! - 1;
        } else {
          _cart.remove(itemId);
        }
      }
    });
  }
}