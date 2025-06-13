import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../services/pocketbase_service.dart'; // Impor PocketBaseService

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  String _status = 'Testing connection...';
  bool _isLoading = true;
  final List<String> _logs = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _status = 'Testing connection...';
      _isConnected = false;
    });

    try {
      _addLog('Using PocketBase instance from PocketBaseService...');
      final pb = PocketBaseService().pb; // Gunakan instance dari PocketBaseService

      _addLog('Testing health check...');
      final health = await pb.health.check();

      _addLog('Health check result: ${health.toString()}');

      setState(() {
        _status = 'Connection successful!\nPocketBase server is running';
        _isLoading = false;
        _isConnected = true;
      });
      _addLog('✅ All tests passed!');

      // Cek apakah ada data pengguna di PocketBase (opsional)
      final users = await pb.collection('users').getList(page: 1, perPage: 50);
      _addLog('Fetched ${users.items.length} users from PocketBase');
    } catch (e) {
      setState(() {
        _status = 'Connection failed:\n$e';
        _isLoading = false;
        _isConnected = false;
      });
      _addLog('❌ Connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test PocketBase Connection')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _status.contains('successful') ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _status.contains('successful') ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Icon(
                      _status.contains('successful') ? Icons.check_circle : Icons.error,
                      size: 48,
                      color: _status.contains('successful') ? Colors.green : Colors.red,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testConnection,
                child: const Text('Test Again'),
              ),
            ),

            const SizedBox(height: 16),

            // Go to Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnected && !_isLoading
                    ? () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected && !_isLoading ? null : Colors.grey,
                ),
                child: const Text('Go to Login'),
              ),
            ),

            const SizedBox(height: 24),

            // Logs Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Logs:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}