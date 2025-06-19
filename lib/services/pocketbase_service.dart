import 'dart:convert';
import 'dart:developer';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class PocketBaseService {
  PocketBase? _pb;
  static final PocketBaseService _instance = PocketBaseService._internal();
  bool _isInitialized = false;
  bool _isHandlingAuthChange = false;
  StreamSubscription<AuthStoreEvent>? _authSubscription;

  // Base URL tanpa trailing slash atau /_/
  static const String baseUrl = 'https://locale-samba-crimes-prozac.trycloudflare.com';

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal();

  PocketBase get pb {
    if (_pb == null) {
      throw Exception('PocketBase not initialized. Call init() first.');
    }
    return _pb!;
  }

  Future<void> init() async {
    log('📌 [PocketBaseService] Initialization started');

    if (_isInitialized) {
      log('⚠️ [PocketBaseService] Already initialized, skipping...');
      return;
    }

    try {
      log('🔍 [PocketBaseService] Creating PocketBase instance with URL: $baseUrl');
      _pb = PocketBase(baseUrl);
      log('✅ [PocketBaseService] PocketBase instance created');

      // Test connection dengan endpoint yang benar
      log('🔍 [PocketBaseService] Testing connection...');
      await _testConnection();

      // Load saved auth state
      log('🔍 [PocketBaseService] Loading auth state...');
      await _loadAuthState();

      // Setup auth change listener
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
      log('🔍 [PocketBaseService] Attempting to connect to $baseUrl');

      // Test dengan endpoint yang pasti ada di PocketBase
      final pingResult = await _pingServer();
      if (!pingResult) {
        throw Exception('Network unreachable or server not responding at $baseUrl');
      }

      log('✅ [PocketBaseService] Connection test successful');
    } on SocketException catch (e, stack) {
      log('❌ [PocketBaseService] Network error: $e', stackTrace: stack);
      throw Exception('Network error: $e');
    } on TimeoutException catch (e, stack) {
      log('❌ [PocketBaseService] Connection timed out: $e', stackTrace: stack);
      throw Exception('Connection timed out: $e');
    } on Exception catch (e, stack) {
      log('❌ [PocketBaseService] General connection error: $e', stackTrace: stack);
      throw Exception('Connection error: $e');
    }
  }

  // ✅ PERBAIKAN: Gunakan endpoint yang benar-benar ada
  Future<bool> _pingServer() async {
    try {
      // Test dengan root API endpoint - ini pasti ada di PocketBase
      final response = await http.get(
        Uri.parse('$baseUrl/api/'), // ✅ Root API endpoint
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      log('🔍 [PocketBaseService] Ping response status: ${response.statusCode}');
      log('🔍 [PocketBaseService] Ping response body: ${response.body}');

      // PocketBase API root biasanya return 200 atau 404, tapi server hidup
      return response.statusCode == 200 ||
          response.statusCode == 404 ||
          response.statusCode == 405; // Method not allowed tapi server hidup
    } catch (e) {
      log('⚠️ [PocketBaseService] Ping to $baseUrl failed: $e');

      // Fallback: test dengan collections endpoint
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/collections'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 15));

        log('🔍 [PocketBaseService] Collections endpoint status: ${response.statusCode}');

        // 200 = OK, 401/403 = Unauthorized tapi server hidup
        return [200, 401, 403].contains(response.statusCode);
      } catch (e2) {
        log('⚠️ [PocketBaseService] Collections endpoint also failed: $e2');
        return false;
      }
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

  // ✅ PERBAIKAN: Test connection dengan endpoint yang benar
  Future<bool> testConnection() async {
    if (!_isInitialized || _pb == null) {
      log('❌ [PocketBaseService] Cannot test connection - not initialized');
      return false;
    }

    try {
      log('🔍 [PocketBaseService] Manual connection test started');

      // Test dengan root API endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/'),
      ).timeout(const Duration(seconds: 15));

      final isConnected = [200, 404, 405].contains(response.statusCode);
      log('✅ [PocketBaseService] Manual connection test result: $isConnected (Status: ${response.statusCode})');
      return isConnected;
    } catch (e, stack) {
      log('❌ [PocketBaseService] Manual connection test failed: $e', stackTrace: stack);

      // Fallback test
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/collections'),
        ).timeout(const Duration(seconds: 15));

        final isConnected = [200, 401, 403].contains(response.statusCode);
        log('✅ [PocketBaseService] Fallback connection test result: $isConnected (Status: ${response.statusCode})');
        return isConnected;
      } catch (e2) {
        log('❌ [PocketBaseService] All connection tests failed');
        return false;
      }
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
    final uri = Uri.parse('$baseUrl/api/files/$filePath');
    log('🔗 [PocketBaseService] Generated file URL: $uri');
    return uri.toString();
  }

  void dispose() {
    if (_isInitialized) {
      _authSubscription?.cancel();
      _pb?.authStore.clear();
      _pb = null;
      _isInitialized = false;
      log('🧹 [PocketBaseService] Disposed successfully');
    }
  }

  Future<void> reset() async {
    dispose();
    await init();
  }
}
