import 'package:flutter/material.dart';
import '../../models/cafe_model.dart';
import '../../models/location_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';

class SelectCafeScreen extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const SelectCafeScreen({super.key, required this.onLocationSelected});

  @override
  State<SelectCafeScreen> createState() => _SelectCafeScreenState();
}

class _SelectCafeScreenState extends State<SelectCafeScreen> {
  List<Cafe> _cafes = [];
  List<Cafe> _filteredCafes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCafes();
  }

  Future<void> _fetchCafes() async {
    try {
      final pb = PocketBaseService().pb;
      final records = await pb.collection('cafe').getFullList(
        sort: 'name',
      );

      // Convert records to Cafe objects
      final List<Cafe> cafes = records.map((record) {
        return Cafe.fromRecord(record);
      }).toList();

      setState(() {
        _cafes = cafes;
        _filteredCafes = cafes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cafes: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCafes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCafes = _cafes;
      } else {
        _filteredCafes = _cafes.where((cafe) {
          return cafe.name.toLowerCase().contains(query.toLowerCase()) ||
              cafe.address.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Fungsi untuk mengkonversi Cafe ke Location
  Location _createLocationFromCafe(Cafe cafe) {
    // Ambil data lokasi dari PocketBase berdasarkan district cafe
    // Ini hanya contoh, Anda perlu menyesuaikan dengan struktur data Anda
    return Location(
      id: cafe.id,
      name: cafe.name,
      district: cafe.address.split(',')[0].trim(), // Ambil district dari address
      city: "Surabaya", // Default city
      province: "Jawa Timur", // Default province
      latitude: 0.0, // Default latitude
      longitude: 0.0, // Default longitude
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cafe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterCafes,
              decoration: InputDecoration(
                hintText: 'Search cafes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Cafes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
            )
                : _filteredCafes.isEmpty
                ? Center(
              child: _searchQuery.isEmpty
                  ? const Text(
                'No cafes available',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              )
                  : Text(
                'No cafes matching "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _filteredCafes.length,
              itemBuilder: (context, index) {
                final cafe = _filteredCafes[index];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(cafe.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        cafe.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        cafe.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cafe.rating.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                      onTap: () {
                        // Konversi cafe ke location dan kirim ke callback
                        final location = _createLocationFromCafe(cafe);
                        widget.onLocationSelected(location);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1, indent: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
