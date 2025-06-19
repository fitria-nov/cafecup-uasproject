import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../services/pocketbase_service.dart';
import '../../services/order_service.dart'; // Update import
import '../../utils/app_colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentTab,
          ),
          // Debug button - sekarang method sudah ada
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              developer.log('🔄 Creating test order...');
              await _orderService.createTestOrder(); // Method ini sekarang ada
              _refreshCurrentTab();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test order created! Pull to refresh.')),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.event_seat),
              text: 'Reservations',
            ),
            Tab(
              icon: Icon(Icons.restaurant_menu),
              text: 'Food Orders',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReservationsTab(),
          OrdersTab(),
        ],
      ),
    );
  }

  void _refreshCurrentTab() {
    setState(() {
      // This will rebuild the TabBarView and refresh the current tab
    });
  }
}

// Sisanya sama seperti sebelumnya...
class ReservationsTab extends StatefulWidget {
  const ReservationsTab({super.key});

  @override
  State<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<ReservationsTab> {
  final PocketBaseService _pbService = PocketBaseService();
  List<ReservationData> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pb = _pbService.pb;

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'You need to be logged in to view reservations';
          _isLoading = false;
        });
        return;
      }

      final records = await pb.collection('reservations').getFullList(
        sort: '-date,-created',
        filter: 'user = "$userId"',
        expand: 'cafe,table',
      );

      if (!mounted) return;

      setState(() {
        _reservations = records.map((record) => ReservationData.fromRecord(record)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error fetching reservations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchReservations,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReservations,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No reservations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your reservation orders will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Your Reservations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        ..._reservations.map((reservation) => _buildReservationCard(reservation)),
      ],
    );
  }

  Widget _buildReservationCard(ReservationData reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reservation.cafeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                _buildStatusBadge(reservation.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Table ${reservation.tableNumber} • ${reservation.guestCount} guests'),
            Text('${reservation.date} at ${reservation.timeSlot}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final PocketBaseService _pbService = PocketBaseService();
  List<OrderData> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pb = _pbService.pb;

      final userId = pb.authStore.model?.id;
      developer.log('🔍 OrdersScreen - User ID: $userId');

      if (userId == null) {
        setState(() {
          _errorMessage = 'You need to be logged in to view orders';
          _isLoading = false;
        });
        return;
      }

      final records = await pb.collection('orders').getFullList(
        sort: '-created',
        filter: 'user = "$userId"',
        expand: 'cafe',
      );

      developer.log('🔍 OrdersScreen - Found ${records.length} orders');

      if (!mounted) return;

      setState(() {
        _orders = records.map((record) => OrderData.fromRecord(record)).toList();
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ OrdersScreen - Error: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error fetching orders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your food orders will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Your Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        ..._orders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildOrderCard(OrderData order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.cafeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Order #${order.orderId}'),
            Text('Total: Rp${_formatCurrency(order.totalAmount)}'),
            if (order.notes.isNotEmpty) Text('Notes: ${order.notes}'),
            Text('Created: ${order.createdAt}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case 'preparing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}

// Data classes
class OrderData {
  final String id;
  final String orderId;
  final String cafeName;
  final double totalAmount;
  final String status;
  final String notes;
  final String createdAt;

  OrderData({
    required this.id,
    required this.orderId,
    required this.cafeName,
    required this.totalAmount,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory OrderData.fromRecord(dynamic record) {
    final data = record.data as Map<String, dynamic>? ?? {};

    final cafeId = data['cafe'] ?? '';

    String cafeName = 'Default Cafe';
    if (data['expand'] != null && data['expand']['cafe'] != null) {
      cafeName = data['expand']['cafe']['name'] ?? cafeName;
    } else if (cafeId.toString().length >= 6) {
      cafeName = 'Cafe #${cafeId.toString().substring(0, 6)}';
    }

    final id = record.id?.toString() ?? '';
    final orderId = id.isNotEmpty && id.length >= 8 ? id.substring(0, 8) : id;

    String displayNotes = data['notes']?.toString() ?? '';
    displayNotes = _cleanNotesForDisplay(displayNotes);

    return OrderData(
      id: id,
      orderId: orderId,
      cafeName: cafeName,
      totalAmount: _parseAmount(data['total_amount']),
      status: data['status']?.toString() ?? 'pending',
      notes: displayNotes,
      createdAt: _formatDate(record.created?.toString() ?? ''),
    );
  }

  static String _cleanNotesForDisplay(String notes) {
    String cleanNotes = notes;
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*Payment: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*Customer: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*Email: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*TxnID: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*\|\s*'), ' | ');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'^\s*\|\s*'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*$'), '');
    return cleanNotes.trim();
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      try {
        return double.parse(amount);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown date';
    }
  }
}

class ReservationData {
  final String id;
  final String cafeName;
  final String tableNumber;
  final int guestCount;
  final String date;
  final String timeSlot;
  final String status;
  final String createdAt;

  ReservationData({
    required this.id,
    required this.cafeName,
    required this.tableNumber,
    required this.guestCount,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
  });

  factory ReservationData.fromRecord(dynamic record) {
    final data = record.data as Map<String, dynamic>? ?? {};

    final cafeId = data['cafe'] ?? '';
    final tableId = data['table'] ?? '';

    String cafeName = 'Cafe';
    if (data['expand'] != null && data['expand']['cafe'] != null) {
      cafeName = data['expand']['cafe']['name'] ?? cafeName;
    } else if (cafeId.toString().length >= 6) {
      cafeName = 'Cafe #${cafeId.toString().substring(0, 6)}';
    }

    String tableNumber = 'Unknown';
    if (data['expand'] != null && data['expand']['table'] != null) {
      tableNumber = data['expand']['table']['table_number'] ?? tableNumber;
    } else if (tableId.toString().length >= 6) {
      tableNumber = tableId.toString().substring(0, 6);
    }

    String formattedDate = 'Unknown date';
    try {
      final date = DateTime.parse(data['date'] ?? '');
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {}

    return ReservationData(
      id: record.id?.toString() ?? '',
      cafeName: cafeName,
      tableNumber: tableNumber,
      guestCount: data['guest_count'] is num ? (data['guest_count'] as num).toInt() : 0,
      date: formattedDate,
      timeSlot: data['time_slot']?.toString() ?? 'Unknown time',
      status: data['status']?.toString() ?? 'pending',
      createdAt: _formatDate(record.created?.toString() ?? ''),
    );
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown date';
    }
  }
}
