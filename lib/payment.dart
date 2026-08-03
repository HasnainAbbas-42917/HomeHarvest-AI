import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'cart.dart';
import 'order_confirmed.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final List<CartItem> cartItems;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    required this.cartItems,
    this.customerName = '',
    this.customerEmail = '',
    this.customerPhone = '',
    this.deliveryAddress = '',
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  static const String _baseUrl = 'http://localhost:5000';

  double get subtotal => widget.totalAmount - 150.0;

  // ── Save order to database ─────────────────────────────────────────────
  Future<String?> _saveOrderToDatabase() async {
    final itemsList = widget.cartItems
        .map((item) => {
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'imageUrl': item.imageUrl,
              'category': item.category,
            })
        .toList();

    final response = await http
        .post(
          Uri.parse('$_baseUrl/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'customer_name': widget.customerName,
            'customer_email': widget.customerEmail,
            'customer_phone': widget.customerPhone,
            'delivery_address': widget.deliveryAddress,
            'payment_method': 'Stripe',
            'items': itemsList,
            'subtotal': subtotal,
            'shipping': 150.0,
            'total': widget.totalAmount,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201) {
      return responseData['order_number'];
    } else {
      throw Exception(responseData['message'] ?? 'Failed to place order.');
    }
  }

  // ── Pay with Stripe Checkout ───────────────────────────────────────────
  Future<void> _payWithStripe() async {
    setState(() => _isLoading = true);
    try {
      final itemsList = widget.cartItems
          .map((item) => {
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
              })
          .toList();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/create-checkout-session'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': widget.totalAmount,
              'customer_name': widget.customerName,
              'items': itemsList,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['url'] != null) {
        // Save order to DB
        final orderNumber = await _saveOrderToDatabase();

        // Clear cart
        CartStorage().items.clear();

        // Open Stripe Checkout in browser
        final url = Uri.parse(data['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Navigate to order confirmed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmedPage(
              orderNumber: orderNumber ?? 'HH00000',
              customerName: widget.customerName,
              paymentMethod: 'Stripe',
              totalAmount: widget.totalAmount,
            ),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showError(data['message'] ?? 'Failed to create payment session.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().contains('TimeoutException')
            ? 'Request timed out. Please check your connection and try again.'
            : 'Payment error: ${e.toString()}';
        _showError(msg);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFE74C3C),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8)
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Color(0xFF1A2E1A), size: 20),
                        ),
                      ),
                      const Expanded(
                        child: Text('Payment',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2E1A))),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Order Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Order Summary',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A2E1A))),
                              const SizedBox(height: 20),
                              ...widget.cartItems.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: Text(item.name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF6B7280)),
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        Text('x${item.quantity}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF6B7280))),
                                        const SizedBox(width: 12),
                                        Text(
                                            'Rs ${(item.price * item.quantity).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A2E1A))),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF6B7280))),
                                  Text('Rs ${subtotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A2E1A))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Shipping',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF6B7280))),
                                  Text('Rs 150',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A2E1A))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A2E1A))),
                                  Text(
                                      'Rs ${widget.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D5233))),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Stripe Payment Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            children: [
                              // Stripe logo area
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock,
                                        color: Color(0xFF635BFF), size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Powered by',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280))),
                                    const SizedBox(width: 6),
                                    const Text('Stripe',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF635BFF))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'You will be redirected to Stripe\'s secure checkout page to complete your payment.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                    height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              // Accepted cards
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _cardChip('VISA'),
                                  const SizedBox(width: 8),
                                  _cardChip('Mastercard'),
                                  const SizedBox(width: 8),
                                  _cardChip('Amex'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Pay Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _payWithStripe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF635BFF),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF635BFF).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Pay Rs ${widget.totalAmount.toStringAsFixed(0)} with Stripe',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text('256-bit SSL Encrypted',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 134,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF635BFF))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151))),
    );
  }
}







