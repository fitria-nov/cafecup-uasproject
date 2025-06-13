class ApiConfig {

  // Atau jika menggunakan Railway
  static const String railwayUrl = 'https://midtrans-backend-production-0501.up.railway.app';

  // Untuk testing lokal
  static const String localUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String localUrl = 'http://localhost:5000'; // iOS simulator

  // Pilih environment
  static const bool isProduction = false; // Set true untuk production

  static String get apiUrl {
    if (isProduction) {
      return railwayUrl; // atau baseUrl
    } else {
      return localUrl;
    }
  }

  static String get createTransactionEndpoint => '$apiUrl/create-transaction';
}
