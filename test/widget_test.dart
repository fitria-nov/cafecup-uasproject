import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitriuas_final/main.dart';
import 'package:fitriuas_final/services/pocketbase_service.dart';
import 'package:mockito/mockito.dart'; // Tambahkan mockito untuk simulasi
import 'package:shared_preferences/shared_preferences.dart';

// Mock untuk PocketBaseService
class MockPocketBaseService extends Mock implements PocketBaseService {}

void main() {
  // Set up mock SharedPreferences
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CafeCupApp loads TestConnectionScreen on successful initialization',
          (WidgetTester tester) async {
        // Simulasikan inisialisasi sukses
        final mockService = MockPocketBaseService();
        when(mockService.init()).thenAnswer((_) async {
          // Simulasikan inisialisasi sukses tanpa error
        });

        // Ganti PocketBaseService dengan mock untuk tes
        // Catatan: Ini memerlukan injeksi dependensi, untuk kesederhanaan kita abaikan ini dan asumsikan inisialisasi sudah selesai
        await tester.pumpWidget(const CafeCupApp(isPocketBaseInitialized: true));

        // Verifikasi bahwa TestConnectionScreen dimuat
        expect(find.text('Test PocketBase Connection'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget); // Loading saat init
        await tester.pumpAndSettle(); // Tunggu hingga state stabil

        // Setelah loading, periksa status koneksi
        expect(find.text('Connection successful!\nPocketBase server is running'), findsOneWidget);
      });

  testWidgets('CafeCupApp shows error screen on failed initialization',
          (WidgetTester tester) async {
        await tester.pumpWidget(const CafeCupApp(isPocketBaseInitialized: false));

        // Verifikasi layar error dimuat
        expect(find.text('Failed to connect to PocketBase'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
      });
}