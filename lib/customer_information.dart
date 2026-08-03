import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cart.dart';
import 'payment.dart';

class CustomerInformationPage extends StatefulWidget {
  const CustomerInformationPage({super.key});

  @override
  State<CustomerInformationPage> createState() =>
      _CustomerInformationPageState();
}

class _CustomerInformationPageState extends State<CustomerInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  // ── Same IP as login.dart ──────────────────────────────────────────────
  static const String _baseUrl = 'http://localhost:5000';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name should only contain letters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Phone number should only contain digits';
    }
    if (cleaned.length < 10 || cleaned.length > 11) {
      return 'Please enter a valid phone number (10-11 digits)';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your delivery address';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address (at least 10 characters)';
    }
    return null;
  }

  // ── Save order to SQL database ────────────────────────────────────────
  Future<String?> _saveOrderToDatabase(String paymentMethod) async {
    final cartItems = CartStorage().items;
    final subtotal =
        cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    const shipping = 150.0;
    final total = subtotal + shipping;

    // Build items list for API
    final itemsList = cartItems
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
            'customer_name': _nameController.text.trim(),
            'customer_email': _emailController.text.trim(),
            'customer_phone': _phoneController.text.trim(),
            'delivery_address': _addressController.text.trim(),
            'payment_method': paymentMethod,
            'items': itemsList,
            'subtotal': subtotal,
            'shipping': shipping,
            'total': total,
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

  // ── Cash on Delivery ──────────────────────────────────────────────────
  Future<void> _handleCashOnDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final orderNumber = await _saveOrderToDatabase('Cash on Delivery');

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Save to local OrderStorage too (for order page display)
      final cartItems = CartStorage().items;
      final subtotal = cartItems.fold(
          0.0, (sum, item) => sum + (item.price * item.quantity));
      final purchasedItems = CartStorage().checkout();
      OrderStorage().addOrder(purchasedItems, subtotal + 150);

      _showSuccessDialog(orderNumber ?? 'HH00000');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to place order: ${e.toString()}');
      }
    }
  }

  // ── Proceed to Payment ────────────────────────────────────────────────
  Future<void> _handleProceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final cartItems = CartStorage().items;
    final total =
        cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) +
            150.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          totalAmount: total,
          cartItems: List<CartItem>.from(cartItems),
          // Pass customer info so payment page can also save to DB
          customerName: _nameController.text.trim(),
          customerEmail: _emailController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E8), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    size: 50, color: Color(0xFF4A7C4A)),
              ),
              const SizedBox(height: 20),
              const Text('Order Placed!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E1A))),
              const SizedBox(height: 8),
              // ── Show order number from database ──────────────────────
              Text(
                'Order #$orderNumber',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A7C4A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your order has been saved successfully.\nYou can track it in the Orders section.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5233),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue Shopping',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
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
                        child: Text(
                          'Customer\nInformation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E1A),
                              height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                            _buildTextField(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              controller: _nameController,
                              validator: _validateName,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Email Address',
                              hint: 'example@email.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Phone Number',
                              hint: '03XXXXXXXXX',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: _validatePhone,
                              icon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Delivery Address',
                              hint: 'House #, Street, Area, City',
                              controller: _addressController,
                              maxLines: 4,
                              validator: _validateAddress,
                              icon: Icons.location_on_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleCashOnDelivery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5233),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF2D5233).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.money, size: 22),
                                    SizedBox(width: 10),
                                    Text('Cash on Delivery',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : _handleProceedToPayment,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D5233),
                            side: const BorderSide(
                                color: Color(0xFF2D5233), width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 22),
                              SizedBox(width: 10),
                              Text('Proceed to Payment',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A7C4A)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF4A7C4A)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2E1A))),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          enabled: !_isLoading,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A2E1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20, vertical: maxLines > 1 ? 20 : 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF2D5233), width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFE74C3C), width: 2)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFE74C3C), width: 2)),
            errorStyle: const TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}









