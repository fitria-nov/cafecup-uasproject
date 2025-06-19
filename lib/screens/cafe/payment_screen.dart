import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/order_service.dart'; // Updated import

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final int amount;
  final String? customerName;
  final String? customerEmail;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    this.customerName,
    this.customerEmail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _snapToken;

  // Add OrderService instance
  final OrderService _orderService = OrderService();

  // Ganti dengan URL backend Flask Anda
  static const String backendUrl = 'https://midtrans-backend-production-0501.up.railway.app/';

  @override
  void initState() {
    super.initState();
    // Test order creation on init (for debugging)
    _testOrderCreation();
  }

  // Debug method to test order creation
  Future<void> _testOrderCreation() async {
    developer.log('🔍 Testing order creation...');
    await _orderService.testCreateOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        // Add debug button
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testOrderCreation,
            tooltip: 'Test Order Creation',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderCard(),
                      const SizedBox(height: 24),
                      _buildPaymentMethodsCard(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorCard(),
                      ],
                    ],
                  ),
                ),
              ),
              _buildPaymentButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Order ID', widget.orderId),
            _buildDetailRow('Customer', widget.customerName ?? 'Customer'),
            _buildDetailRow('Email', widget.customerEmail ?? 'customer@email.com'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(widget.amount)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Text(': ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Available Payment Methods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodItem(
              Icons.credit_card,
              'Credit/Debit Card',
              'Visa, Mastercard, JCB',
              Colors.blue,
            ),
            _buildPaymentMethodItem(
              Icons.account_balance_wallet,
              'E-Wallet',
              'GoPay, OVO, DANA, LinkAja',
              Colors.green,
            ),
            _buildPaymentMethodItem(
              Icons.account_balance,
              'Bank Transfer',
              'BCA, Mandiri, BNI, BRI',
              Colors.orange,
            ),
            _buildPaymentMethodItem(
              Icons.store,
              'Convenience Store',
              'Indomaret, Alfamart',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Processing Payment...'),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 20),
            const SizedBox(width: 8),
            Text(
              'Pay Rp ${_formatCurrency(widget.amount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('🔄 Starting payment process...');

      // Step 1: Get payment token from your Flask backend
      final token = await _getPaymentToken();

      if (token != null) {
        developer.log('✅ Got payment token: $token');

        // Step 2: Open Midtrans payment page
        final result = await _openMidtransPayment(token);

        if (result != null && mounted) {
          await _handlePaymentResult(result); // Make this async
        }
      }

    } catch (e, stackTrace) {
      developer.log('❌ Payment error: $e');
      developer.log('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Payment failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getPaymentToken() async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/purchase'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'total_price': widget.amount,
          'name': widget.customerName ?? 'Customer',
          'email': widget.customerEmail ?? 'customer@email.com',
        }),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['snap_token'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get payment token');
      }
    } catch (e) {
      developer.log('Error getting payment token: $e');
      throw Exception('Failed to connect to payment server: $e');
    }
  }

  Future<Map<String, dynamic>?> _openMidtransPayment(String snapToken) async {
    return await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MidtransPaymentPage(
          snapToken: snapToken,
          orderId: widget.orderId,
        ),
      ),
    );
  }

  // Modified _handlePaymentResult to be async and add more debugging
  Future<void> _handlePaymentResult(Map<String, dynamic> result) async {
    final status = result['status'] ?? 'unknown';
    final transactionId = result['transaction_id'];

    developer.log('🔍 Payment result: $result');

    // Save order to PocketBase when payment is successful or pending
    if (status == 'success' || status == 'settlement' || status == 'pending') {
      developer.log('🔄 Saving order to PocketBase...');

      await _orderService.saveOrderFromPayment(
        orderId: widget.orderId,
        totalAmount: widget.amount.toDouble(),
        customerName: widget.customerName ?? 'Customer',
        customerEmail: widget.customerEmail ?? 'customer@email.com',
        paymentStatus: status,
        transactionId: transactionId,
      );

      developer.log('✅ Order save attempt completed');
    }

    String message;
    Color backgroundColor;

    switch (status) {
      case 'success':
      case 'settlement':
        message = 'Payment Successful! Check your orders.';
        backgroundColor = Colors.green;
        break;
      case 'pending':
        message = 'Payment Pending. Check your orders.';
        backgroundColor = Colors.orange;
        break;
      case 'failed':
      case 'deny':
      case 'expire':
        message = 'Payment Failed';
        backgroundColor = Colors.red;
        break;
      case 'cancel':
        message = 'Payment Cancelled';
        backgroundColor = Colors.grey;
        break;
      default:
        message = 'Payment Status Unknown';
        backgroundColor = Colors.grey;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );

      if (status == 'success' || status == 'settlement') {
        // Navigate to success page atau kembali ke home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}

// MidtransPaymentPage remains the same
class MidtransPaymentPage extends StatefulWidget {
  final String snapToken;
  final String orderId;

  const MidtransPaymentPage({
    super.key,
    required this.snapToken,
    required this.orderId,
  });

  @override
  State<MidtransPaymentPage> createState() => _MidtransPaymentPageState();
}

class _MidtransPaymentPageState extends State<MidtransPaymentPage> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            developer.log('Page started loading: $url');
          },
          onPageFinished: (String url) {
            developer.log('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            _checkPaymentStatus(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            developer.log('Navigation request: ${request.url}');

            if (request.url.contains('finish') ||
                request.url.contains('success') ||
                request.url.contains('error') ||
                request.url.contains('pending')) {
              _handlePaymentCompletion(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildMidtransHTML());
  }

  String _buildMidtransHTML() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script type="text/javascript"
                src="https://app.sandbox.midtrans.com/snap/snap.js"
                data-client-key="SB-Mid-client-81nm3beH9ygYqr-C"></script>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                margin: 0; 
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                max-width: 400px;
                margin: 0 auto;
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                text-align: center;
            }
            .loading {
                color: #666;
                margin: 20px 0;
            }
            .error {
                color: #e74c3c;
                margin: 20px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h3>Processing Payment...</h3>
            <div class="loading" id="loading">Please wait while we redirect you to payment page</div>
            <div class="error" id="error" style="display: none;"></div>
        </div>
        
        <script type="text/javascript">
            function showError(message) {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('error').style.display = 'block';
                document.getElementById('error').innerHTML = message;
            }
            
            try {
                snap.pay('${widget.snapToken}', {
                    onSuccess: function(result) {
                        console.log('Payment success:', result);
                        window.location.href = 'payment://success?transaction_id=' + result.transaction_id + '&order_id=' + result.order_id + '&status=success';
                    },
                    onPending: function(result) {
                        console.log('Payment pending:', result);
                        window.location.href = 'payment://pending?transaction_id=' + result.transaction_id + '&order_id=' + result.order_id + '&status=pending';
                    },
                    onError: function(result) {
                        console.log('Payment error:', result);
                        window.location.href = 'payment://error?status=failed&message=' + encodeURIComponent(result.status_message || 'Payment failed');
                    },
                    onClose: function() {
                        console.log('Payment popup closed');
                        window.location.href = 'payment://cancel?status=cancel';
                    }
                });
            } catch (error) {
                console.error('Snap error:', error);
                showError('Failed to load payment page: ' + error.message);
            }
        </script>
    </body>
    </html>
    ''';
  }

  void _checkPaymentStatus(String url) {
    if (url.contains('payment://')) {
      _handlePaymentCompletion(url);
    }
  }

  void _handlePaymentCompletion(String url) {
    developer.log('Payment completion URL: $url');

    Map<String, dynamic> result = {};

    if (url.contains('success')) {
      result = {'status': 'success'};
    } else if (url.contains('pending')) {
      result = {'status': 'pending'};
    } else if (url.contains('error') || url.contains('failed')) {
      result = {'status': 'failed'};
    } else if (url.contains('cancel')) {
      result = {'status': 'cancel'};
    }

    Uri uri = Uri.parse(url);
    uri.queryParameters.forEach((key, value) {
      result[key] = value;
    });

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, {'status': 'cancel'});
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment page...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
