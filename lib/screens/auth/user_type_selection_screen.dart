import 'package:flutter/material.dart';
import '../main/main_screen.dart';
import '../../utils/app_colors.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final Map<String, String> userData;

  const UserTypeSelectionScreen({
    super.key,
    required this.userData,
  });

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedUserType;
  bool _isLoading = false;

  Future<void> _completeRegistration() async {
    if (_selectedUserType != null) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call to complete registration
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement PocketBase user creation with user type
      // Save user data including user type to database

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you like to use CafeCup?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your role to get the best experience',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
                    _buildUserTypeCard(
                      type: 'customer',
                      title: 'Customer',
                      description: 'I want to discover cafes, browse menus, and place orders',
                      icon: Icons.person,
                      features: [
                        'Find nearby cafes',
                        'Browse menus and prices',
                        'Make reservations',
                        'Order food and drinks',
                        'Rate and review cafes',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildUserTypeCard(
                      type: 'artist',
                      title: 'Barista/Artist',
                      description: 'I work at a cafe and want to manage orders and showcase my skills',
                      icon: Icons.coffee,
                      features: [
                        'Manage cafe profile',
                        'Update menu items',
                        'Handle customer orders',
                        'Showcase coffee art',
                        'Interact with customers',
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUserType != null && !_isLoading ? _completeRegistration : null,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Complete Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required List<String> features,
  }) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textLight.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.textLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.textLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isSelected ? AppColors.primary : AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
