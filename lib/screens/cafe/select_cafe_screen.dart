import 'package:flutter/material.dart';
import '../../models/cafe_model.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../cafe/cafe_detail_screen.dart';

class SelectCafeScreen extends StatefulWidget {
  final Cafe? cafe; // Optional - if coming from search with pre-selected cafe

  const SelectCafeScreen({
    super.key,
    this.cafe,
  });

  @override
  State<SelectCafeScreen> createState() => _SelectCafeScreenState();
}

class _SelectCafeScreenState extends State<SelectCafeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Cafe> _allCafes = [];
  List<Cafe> _filteredCafes = [];
  Cafe? _selectedCafe;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCafe = widget.cafe; // Pre-select if cafe was passed
    _fetchCafes();
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
        final searchTerm = _searchController.text.toLowerCase();
        return cafe.name.toLowerCase().contains(searchTerm) ||
            cafe.address.toLowerCase().contains(searchTerm) ||
            cafe.specialties.any((specialty) =>
                specialty.toLowerCase().contains(searchTerm));
      }).toList();
    });
  }

  void _selectCafe(Cafe cafe) {
    setState(() {
      _selectedCafe = cafe;
    });
  }

  void _viewCafeDetails(Cafe cafe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CafeDetailScreen(cafe: cafe),
      ),
    );
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
        appBar: AppBar(
          title: const Text('Select Cafe'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchCafes();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cafe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          if (_selectedCafe != null) _buildSelectedCafeInfo(),
          Expanded(
            child: _buildCafeList(),
          ),
        ],
      ),
      bottomNavigationBar: _selectedCafe != null ? _buildBottomAction() : null,
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterCafes(),
        decoration: InputDecoration(
          hintText: 'Search cafes...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textLight),
            onPressed: () {
              _searchController.clear();
              _filterCafes();
            },
          )
              : null,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSelectedCafeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(_selectedCafe!.imageUrl),
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
                  _selectedCafe!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
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
                      _selectedCafe!.rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedCafe!.distance} km away',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCafeList() {
    if (_filteredCafes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No cafes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'No cafes available'
                  : 'Try adjusting your search terms',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredCafes.length,
      itemBuilder: (context, index) {
        return _buildCafeCard(_filteredCafes[index]);
      },
    );
  }

  Widget _buildCafeCard(Cafe cafe) {
    final isSelected = _selectedCafe?.id == cafe.id;

    return Column(
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textDark,
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
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                ),
            ],
          ),
          onTap: () => _selectCafe(cafe),
          tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _viewCafeDetails(_selectedCafe!),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'View Cafe Details',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}