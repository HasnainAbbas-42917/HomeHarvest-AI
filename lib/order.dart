import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  final String userEmail;

  const OrderPage({super.key, this.userEmail = ''});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  static const String _baseUrl = 'http://localhost:5000';
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final url = widget.userEmail.isNotEmpty
          ? '$_baseUrl/orders?email=${widget.userEmail}'
          : '$_baseUrl/orders';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allOrders = List<Map<String, dynamic>>.from(data['orders'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') return _allOrders;
    if (_selectedFilter == 'Active') {
      return _allOrders.where((o) => o['status'] == 'Pending' || o['status'] == 'Completed').toList();
    }
    return _allOrders.where((o) => o['status'] == _selectedFilter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered': return const Color(0xFFDBEAFE);
      case 'Completed': return const Color(0xFFD1FAE5);
      case 'Cancelled': return const Color(0xFFFFEBEE);
      default: return const Color(0xFFFFF3CD);
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Delivered': return const Color(0xFF1E40AF);
      case 'Completed': return const Color(0xFF065F46);
      case 'Cancelled': return const Color(0xFFE74C3C);
      default: return const Color(0xFF92400E);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered': return Icons.local_shipping_outlined;
      case 'Completed': return Icons.check_circle_outline;
      case 'Cancelled': return Icons.cancel_outlined;
      default: return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A7C4A)),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Active'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Delivered'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Cancelled'),
                ],
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A7C4A)))
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    color: const Color(0xFF4A7C4A),
                    child: _filteredOrders.isEmpty
                        ? _buildEmptyOrders()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) =>
                                _buildOrderCard(_filteredOrders[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A7C4A) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isSelected ? const Color(0xFF4A7C4A) : const Color(0xFFE0E0E0),
              width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    final items = order['items'] as List? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : null;
    final itemCount = items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order['order_number']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                    const SizedBox(height: 4),
                    Text(order['created_at']?.toString().substring(0, 10) ?? '',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _statusColor(status), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: _statusTextColor(status)),
                      const SizedBox(width: 4),
                      Text(status,
                          style: TextStyle(color: _statusTextColor(status),
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Product Info
            Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: firstItem != null
                        ? Image.network(firstItem['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey, size: 40))
                        : const Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items.length == 1 ? (firstItem?['name'] ?? '') : 'Multiple Items',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)),
                      ),
                      const SizedBox(height: 6),
                      Text('$itemCount ${itemCount == 1 ? 'Item' : 'Items'}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                      if (items.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          items.take(2).map((i) => i['name']).join(', ') + (items.length > 2 ? '...' : ''),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // Total & View Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 4),
                    Text('Rs ${order['total']?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A7C4A))),
                  ],
                ),
                OutlinedButton(
                  onPressed: () => _showOrderDetails(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A7C4A),
                    side: const BorderSide(color: Color(0xFF4A7C4A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                if (status == 'Pending')
                  TextButton(
                    onPressed: () => _cancelOrder(order['id'], order['order_number']),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE74C3C)),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(int orderId, String orderNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        content: Text('Are you sure you want to cancel order #$orderNumber?',
            style: const TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'Cancelled'}),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Color(0xFF4A7C4A)),
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel order'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    final items = order['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order['order_number']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 14, color: _statusTextColor(status)),
                        const SizedBox(width: 4),
                        Text(status, style: TextStyle(color: _statusTextColor(status), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(order['created_at']?.toString().substring(0, 10) ?? '',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(item['image_url'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? '',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                            const SizedBox(height: 4),
                            Text(item['category'] ?? '',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rs ${item['price']?.toStringAsFixed(0) ?? '0'}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A7C4A))),
                                Text('Qty: ${item['quantity']}',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                  Text('Rs ${order['total']?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D5233))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E8), shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long_outlined, size: 60, color: Color(0xFF4A7C4A)),
                ),
                const SizedBox(height: 24),
                const Text('No orders yet',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                const SizedBox(height: 8),
                const Text('Start shopping to create\nyour first order',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF), height: 1.5)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5233),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Start Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


