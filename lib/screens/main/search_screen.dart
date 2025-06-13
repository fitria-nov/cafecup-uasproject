import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../utils/app_colors.dart';
import '../../models/cafe_model.dart';
import '../../services/pocketbase_service.dart';
import '../cafe/cafe_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Coffee', 'Tea', 'Pastries', 'Breakfast', 'Lunch'];
  String _selectedCategory = 'All';

  List<Cafe> _allCafes = [];
  List<Cafe> _filteredCafes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCafes(); // Ambil data kafe dari PocketBase
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCafes() async {
    try {
      final pb = PocketBaseService().pb;
      final records = await pb.collection('cafe').getFullList(
        sort: 'name',
      );

      final List<Cafe> cafes = records.map((record) {
        return Cafe.fromRecord(record);
      }).toList();

      setState(() {
        _allCafes = cafes;
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

  void _filterCafes() {
    setState(() {
      _filteredCafes = _allCafes.where((cafe) {
        final matchesSearch = cafe.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            cafe.address.toLowerCase().contains(_searchController.text.toLowerCase());

        final matchesCategory = _selectedCategory == 'All' ||
            cafe.specialties.any((specialty) => specialty.toLowerCase().contains(_selectedCategory.toLowerCase()));

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Cafes'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildCategorySection(),
          _buildFilterSection(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterCafes(),
        decoration: InputDecoration(
          hintText: 'Search cafes, locations, or specialties...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _filterCafes();
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _filterCafes();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textLight.withOpacity(0.3),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            '${_filteredCafes.length} cafes found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _showFilterBottomSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: AppColors.textDark),
                  SizedBox(width: 8),
                  Text(
                    'Filter',
                    style: TextStyle(color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredCafes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'No cafes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _filteredCafes.length,
      itemBuilder: (context, index) {
        return _buildCafeCard(_filteredCafes[index]);
      },
    );
  }

  Widget _buildCafeCard(Cafe cafe) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CafeDetailScreen(cafe: cafe),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                  image: NetworkImage(cafe.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cafe.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cafe.isOpen ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cafe.isOpen ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                        cafe.rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${cafe.distance} km',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 4,
                        children: cafe.specialties.take(2).map((specialty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Distance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('< 1 km'),
                  const SizedBox(width: 8),
                  _buildFilterChip('< 2 km'),
                  const SizedBox(width: 8),
                  _buildFilterChip('< 5 km'),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('4.0+'),
                  const SizedBox(width: 8),
                  _buildFilterChip('4.5+'),
                  const SizedBox(width: 8),
                  _buildFilterChip('4.8+'),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('Open Now'),
                  const SizedBox(width: 8),
                  _buildFilterChip('All'),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterCafes();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}