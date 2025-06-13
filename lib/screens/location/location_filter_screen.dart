import 'package:flutter/material.dart';
import '../../models/location_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';

class LocationFilterScreen extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const LocationFilterScreen({super.key, required this.onLocationSelected});

  @override
  State<LocationFilterScreen> createState() => _LocationFilterScreenState();
}

class _LocationFilterScreenState extends State<LocationFilterScreen> {
  List<Location> _locations = [];
  List<Location> _filteredLocations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final pb = PocketBaseService().pb;
      final records = await pb.collection('locations').getFullList(
        filter: 'city = "Surabaya"',
        sort: 'district',
      );

      // Convert records to Location objects
      final List<Location> locations = records.map((record) {
        return Location.fromRecord(record);
      }).toList();

      setState(() {
        _locations = locations;
        _filteredLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load locations: $e';
        _isLoading = false;
      });
    }
  }

  void _filterLocations(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredLocations = _locations;
      } else {
        _filteredLocations = _locations.where((location) {
          return location.name.toLowerCase().contains(query.toLowerCase()) ||
              location.district.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterLocations,
              decoration: InputDecoration(
                hintText: 'Search locations...',
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

          // Locations list
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
                : _filteredLocations.isEmpty
                ? Center(
              child: _searchQuery.isEmpty
                  ? const Text(
                'No locations available',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              )
                  : Text(
                'No locations matching "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];

                // Group by district
                final bool showDistrictHeader = index == 0 ||
                    _filteredLocations[index].district != _filteredLocations[index - 1].district;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDistrictHeader) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: Text(
                          location.district,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    ListTile(
                      title: Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${location.district}, ${location.city}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textLight,
                      ),
                      onTap: () {
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
