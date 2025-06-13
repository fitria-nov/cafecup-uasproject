import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_data.dart';
import '../../utils/app_colors.dart';
import 'payment_screen.dart';
import '../../services/pocketbase_service.dart';

class ReservationDetailScreen extends StatefulWidget {
  final ReservationData reservation;

  const ReservationDetailScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  final PocketBaseService _pbService = PocketBaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReservationCard(),
            const SizedBox(height: 24),
            _buildCafeInfoCard(),
            const SizedBox(height: 24),
            _buildPaymentCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildReservationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reservation Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                _buildStatusBadge(widget.reservation.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Reservation ID', widget.reservation.id.substring(0, 8)),
            _buildDetailRow('Date', widget.reservation.date),
            _buildDetailRow('Time', widget.reservation.timeSlot),
            _buildDetailRow('Table', 'Table ${widget.reservation.tableNumber}'),
            _buildDetailRow('Guests', '${widget.reservation.guestCount} people'),
            _buildDetailRow('Created', widget.reservation.createdAt),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cafe Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(widget.reservation.cafeImageUrl.isNotEmpty
                          ? widget.reservation.cafeImageUrl
                          : 'https://via.placeholder.com/80'),
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
                        widget.reservation.cafeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.reservation.cafeAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.reservation.cafePhone.isNotEmpty
                                ? widget.reservation.cafePhone
                                : 'Not available',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final isUnpaid = widget.reservation.paymentStatus.toLowerCase() == 'unpaid';
    final isPaid = widget.reservation.paymentStatus.toLowerCase() == 'paid';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'UNPAID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Reservation Fee', 'Rp ${_formatCurrency(widget.reservation.reservationFee)}'),
            _buildDetailRow('Payment Method', widget.reservation.paymentMethod.isNotEmpty ? widget.reservation.paymentMethod : 'Not paid yet'),
            if (widget.reservation.paymentDate.isNotEmpty)
              _buildDetailRow('Payment Date', widget.reservation.paymentDate),
            if (isUnpaid) ...[
              const SizedBox(height: 16),
              const Text(
                'Please complete your payment to confirm your reservation.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textLight)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isActive = widget.reservation.status.toLowerCase() == 'pending' ||
        widget.reservation.status.toLowerCase() == 'confirmed';
    final isUnpaid = widget.reservation.paymentStatus.toLowerCase() == 'unpaid';

    if (!isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showCancelConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Reservation'),
            ),
          ),
          if (isUnpaid) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _proceedToPayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Pay Now'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelConfirmation() {
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
              _cancelReservation();
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

  Future<void> _cancelReservation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pb = _pbService.pb;

      await pb.collection('reservations').update(widget.reservation.id, body: {
        'status': 'cancelled',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh is needed
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to cancel reservation: $e';
      });
    }
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderId: 'RES-${widget.reservation.id.substring(0, 8)}',
          amount: widget.reservation.reservationFee,
          customerName: 'Customer', // Ideally get from user profile
          customerEmail: 'customer@example.com', // Ideally get from user profile
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Payment successful, refresh the page
        setState(() {
          // Update payment status
          widget.reservation.paymentStatus = 'paid';
          widget.reservation.paymentMethod = 'Midtrans';
          widget.reservation.paymentDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
        });
      }
    });
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
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}
