import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cafe_model.dart';
import '../../models/tables_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import 'reserve_table_screen.dart';

class TableAvailabilityScreen extends StatefulWidget {
  const TableAvailabilityScreen({super.key});

  @override
  State<TableAvailabilityScreen> createState() => _TableAvailabilityScreenState();
}

class _TableAvailabilityScreenState extends State<TableAvailabilityScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Cafe> _cafes = [];
  Map<String, List<CafeTable>> _cafeTablesMap = {};
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _fetchCafesAndTables();
  }

  Future<void> _fetchCafesAndTables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pb = PocketBaseService().pb;

      // Fetch all cafes
      final cafeRecords = await pb.collection('cafe').getFullList(
        sort: 'name',
      );

      print('Fetched ${cafeRecords.length} cafes');

      final List<Cafe> cafes = cafeRecords.map((record) {
        return Cafe.fromRecord(record);
      }).toList();

      // Fetch available tables for each cafe
      Map<String, List<CafeTable>> cafeTablesMap = {};
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final formattedTime = _selectedTime.format(context);

      for (var cafe in cafes) {
        try {
          print('Fetching tables for cafe: ${cafe.name} (${cafe.id})');

          // Pertama, cek apakah koleksi tables ada dan berisi data
          final allTables = await pb.collection('tables').getFullList(
            filter: 'cafe = "${cafe.id}"',
          );

          print('Total tables for ${cafe.name}: ${allTables.length}');

          if (allTables.isEmpty) {
            print('No tables found for cafe ${cafe.name}');
            cafeTablesMap[cafe.id] = [];
            continue;
          }

          // Kemudian cek reservasi yang ada
          try {
            final reservations = await pb.collection('reservations').getFullList(
              filter: 'cafe = "${cafe.id}" && date = "$formattedDate" && time_slot = "$formattedTime"',
            );

            print('Found ${reservations.length} reservations for date $formattedDate and time $formattedTime');

            // Ambil ID meja yang sudah direservasi
            final reservedTableIds = reservations.map((r) => r.data['table']).toList();
            print('Reserved table IDs: $reservedTableIds');

            // Filter meja yang tersedia
            final availableTables = allTables.where((table) =>
            !reservedTableIds.contains(table.id)).toList();

            final List<CafeTable> tables = availableTables.map((record) {
              return CafeTable.fromRecord(record);
            }).toList();

            print('Available tables for ${cafe.name}: ${tables.length}');
            cafeTablesMap[cafe.id] = tables;
          } catch (e) {
            print('Error fetching reservations: $e');
            // Jika gagal mengambil reservasi, anggap semua meja tersedia
            final List<CafeTable> tables = allTables.map((record) {
              return CafeTable.fromRecord(record);
            }).toList();
            cafeTablesMap[cafe.id] = tables;
          }
        } catch (e) {
          print('Error fetching tables for cafe ${cafe.name}: $e');
          cafeTablesMap[cafe.id] = [];
        }
      }

      setState(() {
        _cafes = cafes;
        _cafeTablesMap = cafeTablesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchCafesAndTables: $e');
      setState(() {
        _errorMessage = 'Failed to load cafes and tables: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchCafesAndTables();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _fetchCafesAndTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Availability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Column(
        children: [
          // Date and Time Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date & Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Date picker
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time picker
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cafe List with Available Tables
          Expanded(
            child: _cafes.isEmpty
                ? const Center(
              child: Text(
                'No cafes available',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _cafes.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final cafe = _cafes[index];
                final availableTables = _cafeTablesMap[cafe.id] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cafe Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(cafe.imageUrl),
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
                                    cafe.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cafe.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cafe.rating.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: availableTables.isNotEmpty
                                    ? AppColors.success
                                    : AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                availableTables.isNotEmpty
                                    ? '${availableTables.length} Tables'
                                    : 'No Tables',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Available Tables
                      if (availableTables.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Tables',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availableTables.map((table) {
                                  return Chip(
                                    label: Text(
                                      'Table ${table.tableNumber} (${table.capacity} seats)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    backgroundColor: AppColors.surface,
                                    side: const BorderSide(color: AppColors.border),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                      // Reserve Button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: availableTables.isNotEmpty
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReserveTableScreen(
                                    cafe: cafe,
                                  ),
                                ),
                              );
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: AppColors.border,
                            ),
                            child: const Text(
                              'Reserve a Table',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
