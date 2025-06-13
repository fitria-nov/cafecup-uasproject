import 'package:intl/intl.dart';

class ReservationData {
  final String id;
  final String cafeName;
  final String cafeAddress;
  final String cafePhone;
  final String cafeImageUrl;
  final String tableNumber;
  final int guestCount;
  final String date;
  final String timeSlot;
  String status;
  final String createdAt;
  String paymentStatus;
  String paymentMethod;
  String paymentDate;
  final int reservationFee;

  ReservationData({
    required this.id,
    required this.cafeName,
    required this.tableNumber,
    required this.guestCount,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    this.cafeAddress = '',
    this.cafePhone = '',
    this.cafeImageUrl = '',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = '',
    this.paymentDate = '',
    this.reservationFee = 50000, // Default reservation fee
  });

  factory ReservationData.fromRecord(dynamic record) {
    // Safely extract data from PocketBase record
    final data = record.data as Map<String, dynamic>? ?? {};

    // Ambil cafe ID dan table ID
    final cafeId = data['cafe'] ?? '';
    final tableId = data['table'] ?? '';

    // Coba ambil nama cafe dari expand jika tersedia
    String cafeName = 'Cafe';
    String cafeAddress = '';
    String cafePhone = '';
    String cafeImageUrl = '';

    if (data['expand'] != null && data['expand']['cafe'] != null) {
      final cafeData = data['expand']['cafe'];
      cafeName = cafeData['name'] ?? cafeName;
      cafeAddress = cafeData['address'] ?? '';
      cafePhone = cafeData['phone'] ?? '';
      cafeImageUrl = cafeData['image_url'] ?? '';
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
      cafeAddress: cafeAddress,
      cafePhone: cafePhone,
      cafeImageUrl: cafeImageUrl,
      tableNumber: tableNumber,
      guestCount: data['guest_count'] is num ? (data['guest_count'] as num).toInt() : 0,
      date: formattedDate,
      timeSlot: data['time_slot']?.toString() ?? 'Unknown time',
      status: data['status']?.toString() ?? 'pending',
      createdAt: _formatDate(record.created?.toString() ?? ''),
      paymentStatus: data['payment_status']?.toString() ?? 'unpaid',
      paymentMethod: data['payment_method']?.toString() ?? '',
      paymentDate: data['payment_date']?.toString() ?? '',
      reservationFee: data['reservation_fee'] is num ? (data['reservation_fee'] as num).toInt() : 50000,
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
