class OrderData {
  final String id;
  final String orderId;
  final String cafeName;
  final double totalAmount;
  final String status;
  final String notes;
  final String estimatedTime;
  final String createdAt;
  final List<Map<String, dynamic>> orderItems;
  final String paymentMethod;
  final String transactionId;
  final String paymentStatus;

  OrderData({
    required this.id,
    required this.orderId,
    required this.cafeName,
    required this.totalAmount,
    required this.status,
    required this.notes,
    required this.estimatedTime,
    required this.createdAt,
    required this.orderItems,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentStatus,
  });

  factory OrderData.fromRecord(dynamic record) {
    final data = record.data as Map<String, dynamic>? ?? {};
    final cafeId = data['cafe'] ?? '';
    final userId = data['user'] ?? '';

    // Get cafe name from expand if available
    String cafeName = 'Cafe';
    if (data['expand'] != null && data['expand']['cafe'] != null) {
      cafeName = data['expand']['cafe']['name'] ?? cafeName;
    } else if (cafeId.toString().length >= 6) {
      cafeName = 'Cafe #${cafeId.toString().substring(0, 6)}';
    }

    final id = record.id?.toString() ?? '';
    final orderId = id.isNotEmpty && id.length >= 8 ? id.substring(0, 8) : id;

    final notes = data['notes']?.toString() ?? '';

    // Extract payment info from notes using helper methods
    final paymentInfo = _extractPaymentInfo(notes);
    final orderItems = _extractOrderItems(notes);

    return OrderData(
      id: id,
      orderId: orderId,
      cafeName: cafeName,
      totalAmount: _parseAmount(data['total_amount']),
      status: data['status']?.toString() ?? 'pending',
      notes: _cleanNotes(notes), // Clean notes from payment info for display
      estimatedTime: data['estimatedTime']?.toString() ?? '',
      createdAt: _formatDate(record.created?.toString() ?? ''),
      orderItems: orderItems,
      paymentMethod: paymentInfo['payment_method'] ?? 'unknown',
      transactionId: paymentInfo['transaction_id'] ?? '',
      paymentStatus: paymentInfo['payment_status'] ?? '',
    );
  }

  static Map<String, String> _extractPaymentInfo(String notes) {
    final paymentInfo = <String, String>{};

    // Extract transaction ID
    final txnMatch = RegExp(r'TxnID: ([^|]+)').firstMatch(notes);
    if (txnMatch != null) {
      paymentInfo['transaction_id'] = txnMatch.group(1)?.trim() ?? '';
    }

    // Extract payment method
    final paymentMatch = RegExp(r'Payment: ([^|]+)').firstMatch(notes);
    if (paymentMatch != null) {
      paymentInfo['payment_method'] = paymentMatch.group(1)?.trim() ?? '';
    }

    // Extract payment status
    final statusMatch = RegExp(r'PaymentStatus: ([^|]+)').firstMatch(notes);
    if (statusMatch != null) {
      paymentInfo['payment_status'] = statusMatch.group(1)?.trim() ?? '';
    }

    return paymentInfo;
  }

  static List<Map<String, dynamic>> _extractOrderItems(String notes) {
    final items = <Map<String, dynamic>>[];

    final itemsMatch = RegExp(r'Items: ([^|]+)').firstMatch(notes);
    if (itemsMatch != null) {
      final itemsText = itemsMatch.group(1)?.trim() ?? '';
      final itemParts = itemsText.split(', ');

      for (final itemPart in itemParts) {
        final match = RegExp(r'(.+) x(\d+) - Rp(\d+)').firstMatch(itemPart);
        if (match != null) {
          items.add({
            'name': match.group(1)?.trim() ?? '',
            'quantity': int.tryParse(match.group(2) ?? '0') ?? 0,
            'price': int.tryParse(match.group(3) ?? '0') ?? 0,
          });
        }
      }
    }

    return items;
  }

  static String _cleanNotes(String notes) {
    // Remove payment-related info from notes for clean display
    String cleanNotes = notes;

    // Remove payment info patterns
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*Payment: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*Items: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*TxnID: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*PaymentStatus: [^|]+'), '');
    cleanNotes = cleanNotes.replaceAll(RegExp(r'\s*\|\s*Confirmed: [^|]+'), '');

    // Clean up multiple pipes and trim
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
