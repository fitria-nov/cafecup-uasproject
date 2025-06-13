import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cafe_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
}

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

      // Check if user is authenticated
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
        expand: 'cafe,table', // Expand cafe and table relations
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
              'Your reservation Orders will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group reservations by status
    final activeReservations = _reservations.where((r) =>
    r.status.toLowerCase() == 'pending' ||
        r.status.toLowerCase() == 'confirmed').toList();

    final pastReservations = _reservations.where((r) =>
    r.status.toLowerCase() == 'completed' ||
        r.status.toLowerCase() == 'cancelled' ||
        r.status.toLowerCase() == 'canceled').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeReservations.isNotEmpty) ...[
          const Text(
            'Active Reservations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...activeReservations.map((reservation) => _buildReservationCard(reservation)),
          const SizedBox(height: 24),
        ],

        if (pastReservations.isNotEmpty) ...[
          const Text(
            'Past Reservations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...pastReservations.map((reservation) => _buildReservationCard(reservation)),
        ],
      ],
    );
  }

  Widget _buildReservationCard(ReservationData reservation) {
    final isActive = reservation.status.toLowerCase() == 'pending' ||
        reservation.status.toLowerCase() == 'confirmed';

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
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reservation.cafeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(reservation.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_seat,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Table ${reservation.tableNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${reservation.guestCount} guests',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  reservation.date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  reservation.timeSlot,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _showCancelConfirmation(reservation);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Reservation'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(ReservationData reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelReservation(reservation.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pb = _pbService.pb;

      await pb.collection('reservations').update(reservationId, body: {
        'status': 'cancelled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled successfully')),
      );

      _fetchReservations();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel reservation: $e')),
      );
    }
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
      case 'completed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case 'cancelled':
      case 'canceled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
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

      // Check if user is authenticated
      final userId = pb.authStore.model?.id;
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
        expand: 'cafe', // Tambahkan ini untuk mengambil data cafe terkait
      );

      if (!mounted) return;

      setState(() {
        _orders = records.map((record) => OrderData.fromRecord(record)).toList();
        _isLoading = false;
      });
    } catch (e) {
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
      return const Center(
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
              'Your order Orders will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group orders by status
    final activeOrders = _orders.where((o) =>
    o.status.toLowerCase() == 'pending' ||
        o.status.toLowerCase() == 'preparing').toList();

    final pastOrders = _orders.where((o) =>
    o.status.toLowerCase() == 'completed' ||
        o.status.toLowerCase() == 'cancelled' ||
        o.status.toLowerCase() == 'canceled').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeOrders.isNotEmpty) ...[
          const Text(
            'Active Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...activeOrders.map((order) => _buildOrderCard(order)),
          const SizedBox(height: 24),
        ],

        if (pastOrders.isNotEmpty) ...[
          const Text(
            'Past Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...pastOrders.map((order) => _buildOrderCard(order)),
        ],
      ],
    );
  }

  Widget _buildOrderCard(OrderData order) {
    final isActive = order.status.toLowerCase() == 'pending' ||
        order.status.toLowerCase() == 'preparing';

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
                Row(
                  children: [
                    const Icon(
                      Icons.local_cafe,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.cafeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${order.orderId}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: Rp${_formatCurrency(order.totalAmount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${order.notes}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Created: ${order.createdAt}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            if (isActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _showCancelConfirmation(order);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Order'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(OrderData order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelOrder(order.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pb = _pbService.pb;

      await pb.collection('orders').update(orderId, body: {
        'status': 'cancelled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );

      _fetchOrders();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order: $e')),
      );
    }
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
      case 'cancelled':
      case 'canceled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
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
    // Safely extract data from PocketBase record
    final data = record.data as Map<String, dynamic>? ?? {};

    // Ambil cafe ID dan user ID
    final cafeId = data['cafe'] ?? '';
    final userId = data['user'] ?? '';

    // Coba ambil nama cafe dari expand jika tersedia
    String cafeName = 'Cafe';
    if (data['expand'] != null && data['expand']['cafe'] != null) {
      cafeName = data['expand']['cafe']['name'] ?? cafeName;
    } else if (cafeId.toString().length >= 6) {
      cafeName = 'Cafe #${cafeId.toString().substring(0, 6)}';
    }

    final id = record.id?.toString() ?? '';
    final orderId = id.isNotEmpty && id.length >= 8 ? id.substring(0, 8) : id;

    return OrderData(
      id: id,
      orderId: orderId,
      cafeName: cafeName,
      totalAmount: _parseAmount(data['total_amount']),
      status: data['status']?.toString() ?? 'pending',
      notes: data['notes']?.toString() ?? '',
      createdAt: _formatDate(record.created?.toString() ?? ''),
    );
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
    // Safely extract data from PocketBase record
    final data = record.data as Map<String, dynamic>? ?? {};

    // Ambil cafe ID dan table ID
    final cafeId = data['cafe'] ?? '';
    final tableId = data['table'] ?? '';

    // Coba ambil nama cafe dari expand jika tersedia
    String cafeName = 'Cafe';
    if (data['expand'] != null && data['expand']['cafe'] != null) {
      cafeName = data['expand']['cafe']['name'] ?? cafeName;
    } else if (cafeId.toString().length >= 6) {
      cafeName = 'Cafe #${cafeId.toString().substring(0, 6)}';
    }

    // Coba ambil nomor meja dari expand jika tersedia
    String tableNumber = 'Unknown';
    if (data['expand'] != null && data['expand']['table'] != null) {
      tableNumber = data['expand']['table']['table_number'] ?? tableNumber;
    } else if (tableId.toString().length >= 6) {
      tableNumber = tableId.toString().substring(0, 6);
    }

    // Format tanggal
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
