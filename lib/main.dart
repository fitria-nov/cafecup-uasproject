import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/pocketbase_service.dart';
import 'utils/app_colors.dart';
import 'test_connection.dart';
// Tambahkan impor LoginScreen jika diperlukan

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi PocketBaseService
  bool isPocketBaseInitialized = false;
  try {
    await PocketBaseService().init(); // Gunakan instance singleton
    debugPrint('✅ PocketBase initialized successfully');
    isPocketBaseInitialized = true;
  } catch (e) {
    debugPrint('❌ PocketBase initialization failed: $e');
    isPocketBaseInitialized = false;
  }

  // Jalankan aplikasi berdasarkan status inisialisasi
  runApp(CafeCupApp(isPocketBaseInitialized: isPocketBaseInitialized));
}

class CafeCupApp extends StatelessWidget {
  final bool isPocketBaseInitialized;

  const CafeCupApp({super.key, required this.isPocketBaseInitialized});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'CafeCup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      // Tentukan home berdasarkan status inisialisasi
      home: isPocketBaseInitialized
          ? const TestConnectionScreen()
          : Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to connect to PocketBase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart aplikasi atau coba inisialisasi ulang
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}