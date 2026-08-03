import 'package:flutter/material.dart';
import 'cart.dart';
import 'profile.dart';
import 'order.dart';

class PlantMedicinePage extends StatefulWidget {
  const PlantMedicinePage({super.key});

  @override
  State<PlantMedicinePage> createState() => _PlantMedicinePageState();
}

class _PlantMedicinePageState extends State<PlantMedicinePage> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allProducts = [
    {
      'name': 'Copper Fungicide',
      'price': 14.99,
      'category': 'Fungicides',
      'tags': ['Leaf Spot', 'AI RECOMMENDED'],
      'image':
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
      'description': 'Treats: Leaf Spot',
    },
    {
      'name': 'Organic Neem Oil',
      'price': 12.99,
      'category': 'Pest Control',
      'tags': ['FOR PESTS'],
      'image':
          'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      'description': 'Natural pest control',
    },
    {
      'name': 'Root Booster Pro',
      'price': 18.50,
      'category': 'Fertilizers',
      'tags': ['ROOT GROWTH'],
      'image':
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
      'description': 'Promotes healthy roots',
    },
    {
      'name': 'Rose Bloom Food',
      'price': 9.99,
      'category': 'Fertilizers',
      'tags': ['FLOWERING'],
      'image':
          'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      'description': 'Enhances blooming',
    },
    {
      'name': 'Fungal Fighter',
      'price': 15.00,
      'category': 'Fungicides',
      'tags': ['DISEASE CONTROL'],
      'image':
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
      'description': 'Controls fungal diseases',
    },
    {
      'name': 'Leaf Shine Spray',
      'price': 8.50,
      'category': 'Fertilizers',
      'tags': ['LEAF CARE'],
      'image':
          'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      'description': 'Natural leaf polish',
    },
    {
      'name': 'Soil Probiotic',
      'price': 22.00,
      'category': 'Fertilizers',
      'tags': ['SOIL HEALTH'],
      'image':
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
      'description': 'Beneficial microbes',
    },
    {
      'name': 'Insect Killer',
      'price': 16.99,
      'category': 'Pest Control',
      'tags': ['FOR PESTS'],
      'image':
          'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      'description': 'Fast-acting pesticide',
    },
    {
      'name': 'Growth Spray',
      'price': 13.50,
      'category': 'Fertilizers',
      'tags': ['GROWTH BOOST'],
      'image':
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
      'description': 'Stimulates growth',
    },
    {
      'name': 'Mildew Control',
      'price': 11.99,
      'category': 'Fungicides',
      'tags': ['DISEASE CONTROL'],
      'image':
          'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      'description': 'Prevents mildew',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    var products = _allProducts;

    // Filter by category
    if (_selectedCategory != 'All') {
      products =
          products.where((p) => p['category'] == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) {
        final name = p['name'].toString().toLowerCase();
        final category = p['category'].toString().toLowerCase();
        final description = p['description'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            category.contains(query) ||
            description.contains(query);
      }).toList();
    }

    return products;
  }

  void _addToCart(String name, double price, String imageUrl) {
    setState(() {
      CartStorage().addItem(name, price, imageUrl, 'Medicine');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart!'),
        backgroundColor: const Color(0xFF4A7C4A),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            ).then((_) => setState(() {}));
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDE5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8EDE5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Plant Care & Medicines',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF1A2E1A)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter feature coming soon!'),
                  backgroundColor: Color(0xFF4A7C4A),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search medicines, fertilizers...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Fertilizers'),
                _buildCategoryChip('Pest Control'),
                _buildCategoryChip('Fungicides'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scanner feature coming soon!'),
              backgroundColor: Color(0xFF4A7C4A),
            ),
          );
        },
        backgroundColor: const Color(0xFF2D5233),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
              _buildNavItem(Icons.home, 'Home', false),
              _buildNavItem(Icons.shopping_cart_outlined, 'Cart', false),
              const SizedBox(width: 40),
              _buildNavItem(Icons.receipt_long_outlined, 'Order', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        if (label == 'Home') {
          Navigator.pop(context);
        } else if (label == 'Cart') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          ).then((_) => setState(() {}));
        } else if (label == 'Order') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderPage()),
          );
        } else if (label == 'Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF2D5233) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2D5233) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF4A7C4A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color:
                isSelected ? const Color(0xFF4A7C4A) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isRecommended = product['tags'].contains('AI RECOMMENDED');

    return Container(
      decoration: BoxDecoration(
        color: isRecommended ? const Color(0xFF4A7C4A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isRecommended
                        ? const Color(0xFF5A8C5A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      product['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medical_services,
                          size: 50,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                ),
                if (isRecommended)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: 14,
                            color: Color(0xFF4A7C4A),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI RECOMMENDED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A7C4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product['tags'].isNotEmpty && !isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getTagColor(product['tags'][0]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product['tags'][0],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getTagTextColor(product['tags'][0]),
                            ),
                          ),
                        ),
                      if (isRecommended)
                        Text(
                          product['description'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        product['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isRecommended
                              ? Colors.white
                              : const Color(0xFF1A2E1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isRecommended
                              ? Colors.white
                              : const Color(0xFF4A7C4A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(
                          product['name'],
                          product['price'],
                          product['image'],
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isRecommended
                                ? Colors.white
                                : const Color(0xFF4A7C4A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: isRecommended
                                ? const Color(0xFF4A7C4A)
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'FOR PESTS':
        return const Color(0xFFFFF3E0);
      case 'ROOT GROWTH':
        return const Color(0xFFE3F2FD);
      case 'FLOWERING':
        return const Color(0xFFFCE4EC);
      case 'DISEASE CONTROL':
        return const Color(0xFFFFEBEE);
      case 'LEAF CARE':
        return const Color(0xFFE8F5E9);
      case 'SOIL HEALTH':
        return const Color(0xFFFFF9C4);
      case 'GROWTH BOOST':
        return const Color(0xFFE0F2F1);
      default:
        return const Color(0xFFE8F5E8);
    }
  }

  Color _getTagTextColor(String tag) {
    switch (tag) {
      case 'FOR PESTS':
        return const Color(0xFFFF9800);
      case 'ROOT GROWTH':
        return const Color(0xFF2196F3);
      case 'FLOWERING':
        return const Color(0xFFE91E63);
      case 'DISEASE CONTROL':
        return const Color(0xFFE74C3C);
      case 'LEAF CARE':
        return const Color(0xFF4A7C4A);
      case 'SOIL HEALTH':
        return const Color(0xFFF57C00);
      case 'GROWTH BOOST':
        return const Color(0xFF00897B);
      default:
        return const Color(0xFF4A7C4A);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 50,
              color: Color(0xFF4A7C4A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}









