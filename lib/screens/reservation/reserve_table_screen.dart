import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cafe_model.dart';
import '../../models/tables_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';

class ReserveTableScreen extends StatefulWidget {
  final Cafe cafe;

  const ReserveTableScreen({super.key, required this.cafe});

  @override
  State<ReserveTableScreen> createState() => _ReserveTableScreenState();
}

class _ReserveTableScreenState extends State<ReserveTableScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _guestCount = 2;
  String? _selectedTable;
  List<CafeTable> _availableTables = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableTables();
  }

  Future<void> _fetchAvailableTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pb = PocketBaseService().pb;
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final formattedTime = _selectedTime.format(context);

      // Fetch tables that are not reserved for the selected date and time
      final tableRecords = await pb.collection('tables').getFullList(
        filter: 'cafe = "${widget.cafe.id}"',
      );

      print('Found ${tableRecords.length} tables for cafe ${widget.cafe.name}');

      if (tableRecords.isEmpty) {
        setState(() {
          _availableTables = [];
          _isLoading = false;
        });
        return;
      }

      // Check for existing reservations
      try {
        final reservations = await pb.collection('reservations').getFullList(
          filter: 'cafe = "${widget.cafe.id}" && date = "$formattedDate" && time_slot = "$formattedTime"',
        );

        print('Found ${reservations.length} reservations for date $formattedDate and time $formattedTime');

        // Get IDs of reserved tables
        final reservedTableIds = reservations.map((r) => r.data['table']).toList();
        print('Reserved table IDs: $reservedTableIds');

        // Filter available tables
        final availableTables = tableRecords.where((record) =>
        !reservedTableIds.contains(record.id)).toList();

        final List<CafeTable> tables = availableTables.map((record) {
          return CafeTable.fromRecord(record);
        }).toList();

        setState(() {
          _availableTables = tables;
          if (_availableTables.isNotEmpty) {
            _selectedTable = _availableTables.first.id;
          } else {
            _selectedTable = null;
          }
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching reservations: $e');
        // If failed to fetch reservations, assume all tables are available
        final List<CafeTable> tables = tableRecords.map((record) {
          return CafeTable.fromRecord(record);
        }).toList();

        setState(() {
          _availableTables = tables;
          if (_availableTables.isNotEmpty) {
            _selectedTable = _availableTables.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching tables: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load available tables: $e')),
      );
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
      _fetchAvailableTables();
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
      _fetchAvailableTables();
    }
  }

  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate() && _selectedTable != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final pb = PocketBaseService().pb;
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

        // Pastikan user sudah login
        if (pb.authStore.model == null) {
          throw Exception('User not logged in');
        }

        // Pastikan _selectedTable tidak null
        if (_selectedTable == null) {
          throw Exception('No table selected');
        }

        // Buat data untuk reservasi
        final data = {
          'cafe': widget.cafe.id,
          'table': _selectedTable,
          'user': pb.authStore.model!.id,
          'date': formattedDate,
          'time_slot': _selectedTime.format(context),
          'guest_count': _guestCount,
          'status': 'pending',
        };

        print('Creating reservation with data: $data');

        // Buat reservasi
        final record = await pb.collection('reservations').create(body: data);

        print('Reservation created successfully: ${record.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation submitted successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error submitting reservation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit reservation: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve a Table'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cafe info card
              Container(
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
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.cafe.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
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

              const SizedBox(height: 24),
              const Text(
                'Select Date & Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Time picker
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Number of Guests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Guest counter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Guests',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _guestCount > 1
                          ? () => setState(() => _guestCount--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Text(
                      _guestCount.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      onPressed: _guestCount < 10
                          ? () => setState(() => _guestCount++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Available Tables',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Table selection
              _availableTables.isEmpty
                  ? const Center(
                child: Text(
                  'No tables available for the selected date and time.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTable,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _availableTables.map((CafeTable table) {
                      return DropdownMenuItem<String>(
                        value: table.id,
                        child: Text('Table ${table.tableNumber} (${table.capacity} seats)'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTable = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _availableTables.isEmpty ? null : _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Reservation',
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
      ),
    );
  }
}
