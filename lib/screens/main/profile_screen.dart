import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../auth/login_screen.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  late final UserService _userService;
  UserModel? userData;
  bool isLoading = true;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _userService = UserService(_pbService);
    _loadUserData();
  }

  // Memuat data pengguna dari PocketBase
  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });

      print('🔍 === STARTING USER DATA LOAD ===');
      print('🔍 PocketBase authenticated: ${_pbService.isAuthenticated}');

      // Periksa apakah layanan sudah diinisialisasi dan pengguna sudah login
      if (!_pbService.isAuthenticated) {
        print('❌ User not authenticated');
        throw Exception('Pengguna belum terautentikasi');
      }

      print('✅ User is authenticated, getting current user...');

      // Dapatkan pengguna saat ini menggunakan UserService
      final user = await _userService.getCurrentUser();

      print('🔍 UserService returned: $user');

      if (user == null) {
        print('❌ No user data returned from UserService');
        throw Exception('Data pengguna tidak tersedia');
      }

      print('✅ User data retrieved successfully:');
      print('  - Name: ${user.name}');
      print('  - Email: ${user.email}');
      print('  - User Type: ${user.userType}');

      // Dapatkan gambar profil jika tersedia
      String? imageUrl;
      if (user.avatar != null && user.avatar!.isNotEmpty) {
        // Use your existing getFileUrl method
        imageUrl = _pbService.getFileUrl('users/${user.id}/${user.avatar}');
        print('🖼️ Avatar URL: $imageUrl');
      }

      setState(() {
        userData = user;
        profileImageUrl = imageUrl;
        isLoading = false;
      });

      print('✅ UI updated with user data');
      print('🔍 === USER DATA LOAD COMPLETE ===');
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
      // Tampilkan snackbar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigasi ke halaman edit profil
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    userData: userData,
                    userService: _userService,
                  ),
                ),
              ).then((result) {
                // Refresh data setelah kembali dari halaman edit
                if (result == true) {
                  _loadUserData();
                }
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildSimplifiedMenuSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: profileImageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
            )
                : const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData?.name ?? 'Pengguna',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userData?.email ?? 'Tidak ada email',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userData?.userType ?? 'Pengguna',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedMenuSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Pengaturan Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Informasi Pribadi',
            onTap: () {
              // Navigasi ke informasi pribadi
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalInformationScreen(userData: userData),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.password_outlined,
            title: 'Ubah Kata Sandi',
            onTap: () {
              // Navigasi ke ubah kata sandi
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Keluar',
            isDestructive: true,
            onTap: () {
              _showSignOutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.textDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? AppColors.error : AppColors.textDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _pbService.logout();
                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal keluar: ${e.toString()}')),
                  );
                }
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Enhanced EditProfileScreen with UserService
class EditProfileScreen extends StatelessWidget {
  final UserModel? userData;
  final UserService userService;

  const EditProfileScreen({
    super.key,
    this.userData,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Center(
          child: Text('Halaman Edit Profil untuk ${userData?.name ?? "Pengguna"}')
      ),
    );
  }
}

// Stub for PersonalInformationScreen with userData parameter
class PersonalInformationScreen extends StatelessWidget {
  final UserModel? userData;

  const PersonalInformationScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Pribadi')),
      body: Center(
          child: Text('Halaman Informasi Pribadi untuk ${userData?.name ?? "Pengguna"}')
      ),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Kata Sandi')),
      body: const Center(child: Text('Halaman Ubah Kata Sandi')),
    );
  }
}
