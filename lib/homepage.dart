import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'profile.dart';
import 'order.dart';
import 'cart.dart';
import 'plant_medicine.dart';
import 'seasonal_plants.dart';
import 'buy_plants.dart';
import 'scan_page.dart';
import 'chatbot_page.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;

  const HomePage({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  static const String _baseUrl = 'http://localhost:5000';

  // Products loaded from backend
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProducts();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_image_${widget.userEmail}';
    final base64String = prefs.getString(key);
    if (base64String != null && mounted) {
      setState(() => _profileImageBytes = base64Decode(base64String));
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List).map((p) => {
          'name': p['name'],
          'price': double.parse(p['price'].toString()),
          'image': p['image_url'],
          'category': p['category'],
          'type': p['type'],
        }).toList();
        setState(() {
          _allProducts = List<Map<String, dynamic>>.from(products);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (_searchQuery.isEmpty) return [];
    return _allProducts.where((product) {
      return product['name'].toString().toLowerCase().contains(_searchQuery) ||
          product['category'].toString().toLowerCase().contains(_searchQuery) ||
          product['type'].toString().toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _getByType(String type) =>
      _allProducts.where((p) => p['type'] == type).toList();

  List<Map<String, dynamic>> _getByCategory(String category) =>
      _allProducts.where((p) => p['category'] == category).toList();

  void _addToCart(String productName, double price, String imageUrl, String category) {
    setState(() => CartStorage().addItem(productName, price, imageUrl, category));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart!'),
        backgroundColor: const Color(0xFF4A7C4A),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CartPage()))
              .then((_) => setState(() {})),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ProfilePage(userName: widget.userName, userEmail: widget.userEmail, userPhone: widget.userPhone),
      )).then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPage(userEmail: widget.userEmail)))
          .then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()))
          .then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HOMEHARVEST AI',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5233), letterSpacing: 1.2)),
                      Text('Hello, ${widget.userName}!',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF4A7C4A),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ProfilePage(userName: widget.userName, userEmail: widget.userEmail, userPhone: widget.userPhone),
                    )).then((_) {
                      // Reload profile image when returning from profile page
                      _loadProfileImage();
                    }),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF2D5233),
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!) as ImageProvider
                          : null,
                      child: _profileImageBytes == null
                          ? Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName.trim()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFE8F5E8), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search plants, medicines...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() { _searchQuery = ''; _isSearching = false; });
                            })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A7C4A)))
                  : _isSearching ? _buildSearchResults() : _buildHomeContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'chatbot',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ChatbotPage())),
            backgroundColor: const Color(0xFF4A7C4A),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'scanner',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ScanPage())),
            backgroundColor: const Color(0xFF2D5233),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.shopping_cart_outlined, 'Cart', 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.receipt_long_outlined, 'Order', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final filteredProducts = _getFilteredProducts();
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No results found for "$_searchQuery"',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('${filteredProducts.length} result${filteredProducts.length == 1 ? '' : 's'} found',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A))),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final p = filteredProducts[index];
              return _buildSearchResultCard(p['name'], p['price'], p['image'], p['category'], p['type']);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(String name, double price, String imageUrl, String category, String type) {
    return GestureDetector(
      onTap: () => _addToCart(name, price, imageUrl, category),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 50, color: Colors.grey))),
                  ),
                  Positioned(top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF4A7C4A), borderRadius: BorderRadius.circular(12)),
                      child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(category, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('₨${price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF2D5233), fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final indoorPlants  = _getByType('Indoor');
    final outdoorPlants = _getByType('Outdoor');
    final seasonalPlants = _getByType('Seasonal');
    final medicines     = _getByCategory('Medicine');

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: const Color(0xFF4A7C4A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heal Your Plants Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1A4D2E), Color(0xFF4A7C59)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Opacity(opacity: 0.3,
                            child: Image.network('https://images.unsplash.com/photo-1466781783364-36c955e42a7f?w=800',
                                fit: BoxFit.cover)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Heal Your Plants',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Snap a photo to detect\ndiseases instantly.',
                              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const ScanPage())),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, foregroundColor: const Color(0xFF2D5233),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), elevation: 0),
                            child: const Text('Scan Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Indoor Jungle
            if (indoorPlants.isNotEmpty) ...[
              _buildSectionHeader('Indoor Jungle', () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const BuyPlantsPage(initialCategory: 'Indoor')))),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: indoorPlants.length,
                  itemBuilder: (context, i) => _buildPlantCard(
                      indoorPlants[i]['name'], indoorPlants[i]['price'], indoorPlants[i]['image']),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // Plant Care & Medicines
            if (medicines.isNotEmpty) ...[
              _buildSectionHeader('Plant Care & Medicines', () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PlantMedicinePage()))),
              const SizedBox(height: 10),
              SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: medicines.length,
                  itemBuilder: (context, i) => _buildMedicineCard(
                      medicines[i]['name'], medicines[i]['price'], medicines[i]['image']),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // Seasonal Picks
            if (seasonalPlants.isNotEmpty) ...[
              _buildSectionHeader('Seasonal Picks', () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SeasonalPlantsPage()))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.80),
                  itemCount: seasonalPlants.length,
                  itemBuilder: (context, i) => _buildSeasonalCard(
                      seasonalPlants[i]['name'], seasonalPlants[i]['price'], seasonalPlants[i]['image']),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // Outdoor Garden
            if (outdoorPlants.isNotEmpty) ...[
              _buildSectionHeader('Outdoor Garden', () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const BuyPlantsPage(initialCategory: 'Outdoor')))),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: outdoorPlants.length,
                  itemBuilder: (context, i) => _buildPlantCard(
                      outdoorPlants[i]['name'], outdoorPlants[i]['price'], outdoorPlants[i]['image']),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All', style: TextStyle(color: Color(0xFF4A7C4A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF2D5233) : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
              color: isSelected ? const Color(0xFF2D5233) : Colors.grey,
              fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildPlantCard(String name, double price, String imageUrl) {
    return GestureDetector(
      onTap: () => _addToCart(name, price, imageUrl, 'Plant'),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 140, color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey))),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('₨${price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF2D5233), fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(String name, double price, String imageUrl) {
    return GestureDetector(
      onTap: () => _addToCart(name, price, imageUrl, 'Medicine'),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(imageUrl, height: 90, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 90, color: Colors.grey[200],
                      child: const Icon(Icons.medical_services, color: Colors.grey))),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('₨${price.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF2D5233), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalCard(String name, double price, String imageUrl) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50, color: Colors.grey))),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFF4A7C4A), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      onPressed: () => _addToCart(name, price, imageUrl, 'Plant'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('₨${price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFF2D5233), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





