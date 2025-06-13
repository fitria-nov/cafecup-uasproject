import 'package:pocketbase/pocketbase.dart';

class CafeTable {
  final String id;
  final String cafeId;
  final String tableNumber;
  final int capacity;
  final bool isAvailable;
  final String location;

  CafeTable({
    required this.id,
    required this.cafeId,
    required this.tableNumber,
    required this.capacity,
    required this.isAvailable,
    required this.location,
  });

  factory CafeTable.fromRecord(RecordModel record) {
    return CafeTable(
      id: record.id,
      cafeId: record.data['cafe'] ?? '',
      tableNumber: record.data['table_number'] ?? '',
      capacity: record.data['capacity'] ?? 2,
      isAvailable: record.data['is_available'] ?? true,
      location: record.data['location'] ?? 'indoor',
    );
  }
}
