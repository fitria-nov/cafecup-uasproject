import 'dart:convert';
import 'dart:developer';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Untuk SocketException dan HttpClient
import 'dart:async'; // Untuk TimeoutException
import 'package:http/http.dart' as http; // Import http package

class PocketBaseService {
  PocketBase? _pb; // Ubah dari late final ke nullable
  static final PocketBaseService _instance = PocketBaseService._internal();
  bool _isInitialized = false;
  bool _isHandlingAuthChange = false;
  StreamSubscription<AuthStoreEvent>? _authSubscription; // Untuk dispose listener

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal();

  // Getter untuk pb dengan null check
  PocketBase get pb {
    if (_pb == null) {
      throw Exception('PocketBase not initialized. Call init() first.');
    }
    return _pb!;
  }

  Future<void> init() async {
    log('📌 [PocketBaseService] Initialization started');

    // Prevent multiple initialization
    if (_isInitialized) {
      log('⚠️ [PocketBaseService] Already initialized, skipping...');
      return;
    }

    try {
      log('🔍 [PocketBaseService] Creating PocketBase instance with URL: http://10.0.2.2:8090');
      _pb = PocketBase('http://10.0.2.2:8090');
      log('✅ [PocketBaseService] PocketBase instance created');

      // Test connection
      log('🔍 [PocketBaseService] Testing connection...');
      await _testConnection();

      // Load saved auth state
      log('🔍 [PocketBaseService] Loading auth state...');
      await _loadAuthState();

      // Setup auth change listener dengan proper disposal
      log('🔍 [PocketBaseService] Setting up auth change listener...');
      _authSubscription = _pb!.authStore.onChange.listen((event) {
        _handleAuthChange(event);
      });

      _isInitialized = true;
      log('✅ [PocketBaseService] Initialization completed successfully');
    } catch (e, stack) {
      log('❌ [PocketBaseService] Initialization failed: $e', stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _testConnection() async {
    try {
      log('🔍 [PocketBaseService] Attempting to connect to http://10.0.2.2:8090');

      // Coba ping sederhana ke URL untuk memeriksa koneksi dasar
      final pingResult = await _pingServer();
      if (!pingResult) {
        throw Exception('Network unreachable or server not responding at http://10.0.2.2:8090');
      }

      // Uji dengan health check endpoint yang lebih ringan
      log('🔍 [PocketBaseService] Testing health endpoint...');
      await _testHealthEndpoint();

      log('✅ [PocketBaseService] Connection test successful');
    } on SocketException catch (e, stack) {
      log('❌ [PocketBaseService] Network error: $e (Check if server is running or firewall is blocking port 8090)', stackTrace: stack);
      throw Exception('Network error: $e');
    } on TimeoutException catch (e, stack) {
      log('❌ [PocketBaseService] Connection timed out: $e (Server may be slow or unreachable)', stackTrace: stack);
      throw Exception('Connection timed out: $e');
    } on Exception catch (e, stack) {
      log('❌ [PocketBaseService] General connection error: $e (Possible invalid collection or server issue)', stackTrace: stack);
      throw Exception('Connection error: $e');
    }
  }

  // Fungsi ping menggunakan http package yang lebih reliable
  Future<bool> _pingServer() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8090/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      log('🔍 [PocketBaseService] Ping response status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 404; // 404 bisa jadi endpoint tidak ada tapi server hidup
    } catch (e) {
      log('⚠️ [PocketBaseService] Ping to http://10.0.2.2:8090 failed: $e');
      return false;
    }
  }

  // Test endpoint yang lebih spesifik
  Future<void> _testHealthEndpoint() async {
    try {
      // Coba endpoint yang pasti ada di PocketBase
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8090/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        // Jika health endpoint tidak ada, coba dengan collections endpoint
        await _testCollectionsEndpoint();
      }
    } catch (e) {
      // Fallback ke test collections
      await _testCollectionsEndpoint();
    }
  }

  Future<void> _testCollectionsEndpoint() async {
    try {
      // Test dengan endpoint yang pasti ada (meskipun bisa return error jika tidak ada collections)
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8090/api/collections'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      // Status 200, 401, atau 403 berarti server hidup
      if (![200, 401, 403].contains(response.statusCode)) {
        throw Exception('Unexpected response status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TimeoutException || e is SocketException) {
        rethrow;
      }
      // Untuk error lain, anggap server hidup tapi ada masalah konfigurasi
      log('⚠️ [PocketBaseService] Collections endpoint test failed, but server seems responsive: $e');
    }
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pocketbase_token');
      final userJson = prefs.getString('pocketbase_user');

      log('🔍 [PocketBaseService] Loading auth state - Token: ${token != null ? "exists" : "null"}');
      log('🔍 [PocketBaseService] Loading auth state - User: ${userJson != null ? "exists" : "null"}');

      if (token != null && userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          _pb!.authStore.save(token, userData);
          log('✅ [PocketBaseService] Auth state loaded successfully');
        } catch (e, stack) {
          log('❌ [PocketBaseService] Invalid auth data format: $e', stackTrace: stack);
          await _clearAuthData();
        }
      } else {
        log('ℹ️ [PocketBaseService] No auth state to load');
      }
    } catch (e, stack) {
      log('❌ [PocketBaseService] Failed to load auth state: $e', stackTrace: stack);
    }
  }

  Future<void> _handleAuthChange(AuthStoreEvent event) async {
    if (_isHandlingAuthChange) {
      log('⚠️ [PocketBaseService] Auth change already in progress, skipping...');
      return;
    }

    _isHandlingAuthChange = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = event.token;
      final model = event.model;

      log('🔍 [PocketBaseService] Auth change detected - Token: ${token.isNotEmpty}');
      log('🔍 [PocketBaseService] Auth change detected - Model: ${model != null}');

      if (token.isNotEmpty && model != null) {
        await prefs.setString('pocketbase_token', token);
        final userJsonString = jsonEncode(model.toJson());
        await prefs.setString('pocketbase_user', userJsonString);
        log('✅ [PocketBaseService] Auth state saved successfully');
      } else {
        await _clearAuthData();
        log('🧹 [PocketBaseService] Auth state cleared');
      }
    } catch (e, stack) {
      log('❌ [PocketBaseService] Failed to handle auth change: $e', stackTrace: stack);
    } finally {
      _isHandlingAuthChange = false;
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pocketbase_token');
      await prefs.remove('pocketbase_user');
      _pb?.authStore.clear();
      log('🧹 [PocketBaseService] Auth data cleared successfully');
    } catch (e, stack) {
      log('❌ [PocketBaseService] Failed to clear auth data: $e', stackTrace: stack);
    }
  }

  Future<bool> testConnection() async {
    if (!_isInitialized || _pb == null) {
      log('❌ [PocketBaseService] Cannot test connection - not initialized');
      return false;
    }

    try {
      log('🔍 [PocketBaseService] Manual connection test started');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8090/api/health'),
      ).timeout(const Duration(seconds: 5));

      final isConnected = response.statusCode == 200 || response.statusCode == 404;
      log('✅ [PocketBaseService] Manual connection test result: $isConnected');
      return isConnected;
    } catch (e, stack) {
      log('❌ [PocketBaseService] Manual connection test failed: $e', stackTrace: stack);
      return false;
    }
  }

  bool get isAuthenticated => _pb?.authStore.isValid ?? false;
  dynamic get currentUser => _pb?.authStore.model;

  Future<void> logout() async {
    try {
      _pb?.authStore.clear();
      await _clearAuthData();
      log('✅ [PocketBaseService] User logged out successfully');
    } catch (e, stack) {
      log('❌ [PocketBaseService] Logout failed: $e', stackTrace: stack);
      rethrow;
    }
  }

  String getFileUrl(String filePath) {
    final uri = Uri.parse('http://10.0.2.2:8090/api/files/$filePath');
    log('🔗 [PocketBaseService] Generated file URL: $uri');
    return uri.toString();
  }

  void dispose() {
    if (_isInitialized) {
      _authSubscription?.cancel(); // Dispose listener
      _pb?.authStore.clear();
      _pb = null;
      _isInitialized = false;
      log('🧹 [PocketBaseService] Disposed successfully');
    }
  }

  // Method untuk reset dan reinit jika diperlukan
  Future<void> reset() async {
    dispose();
    await init();
  }
}