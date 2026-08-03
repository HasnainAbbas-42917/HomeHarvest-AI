import 'package:flutter/material.dart';
import 'cart.dart';

class BuyPlantsPage extends StatefulWidget {
  final String? initialCategory;

  const BuyPlantsPage({super.key, this.initialCategory});

  @override
  State<BuyPlantsPage> createState() => _BuyPlantsPageState();
}

class _BuyPlantsPageState extends State<BuyPlantsPage> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(
      String productName, double price, String imageUrl, String category) {
    setState(() {
      CartStorage().addItem(productName, price, imageUrl, category);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart!'),
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

  List<Map<String, dynamic>> _getFilteredPlants() {
    final allPlants = [
      {
        'name': 'Monstera',
        'price': 35.0,
        'image':
            'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400',
        'category': 'Indoor',
        'tag': 'INDOOR',
      },
      {
        'name': 'Snake Plant',
        'price': 25.0,
        'image':
            'https://images.unsplash.com/photo-1632207691143-643e2a9a9361?w=400',
        'category': 'Indoor',
        'tag': 'LOW LIGHT',
      },
      {
        'name': 'Aloe Vera',
        'price': 18.0,
        'image':
            'https://images.unsplash.com/photo-1509587584298-0f3b3a3a1797?w=400',
        'category': 'Indoor',
        'tag': 'MEDICINAL',
      },
      {
        'name': 'Peace Lily',
        'price': 28.0,
        'image':
            'https://images.unsplash.com/photo-1593482892540-73c6d4537b5f?w=400',
        'category': 'Indoor',
        'tag': 'PURIFYING',
      },
      {
        'name': 'Rubber Plant',
        'price': 32.0,
        'image':
            'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400',
        'category': 'Indoor',
        'tag': 'INDOOR',
      },
      {
        'name': 'Spider Plant',
        'price': 15.0,
        'image':
            'https://images.unsplash.com/photo-1572688484442-c0d1d8b7d06e?w=400',
        'category': 'Indoor',
        'tag': 'PET SAFE',
      },
      {
        'name': 'Pothos',
        'price': 20.0,
        'image':
            'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400',
        'category': 'Indoor',
        'tag': 'INDOOR',
      },
      {
        'name': 'Fiddle Leaf',
        'price': 45.0,
        'image':
            'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400',
        'category': 'Indoor',
        'tag': 'INDOOR',
      },
      {
        'name': 'Rose Bush',
        'price': 42.0,
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
        'category': 'Outdoor',
        'tag': 'OUTDOOR',
      },
      {
        'name': 'Jasmine',
        'price': 38.0,
        'image':
            'https://images.unsplash.com/photo-1611909023032-2d6b3134ecba?w=400',
        'category': 'Outdoor',
        'tag': 'OUTDOOR',
      },
      {
        'name': 'Hibiscus',
        'price': 33.0,
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
        'category': 'Outdoor',
        'tag': 'OUTDOOR',
      },
      {
        'name': 'Lavender',
        'price': 14.0,
        'image':
            'https://images.unsplash.com/photo-1611909023032-2d6b3134ecba?w=400',
        'category': 'Outdoor',
        'tag': 'OUTDOOR',
      },
      {
        'name': 'Marigold',
        'price': 8.0,
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
        'category': 'Outdoor',
        'tag': 'OUTDOOR',
      },
      {
        'name': 'Organic Fertilizer',
        'price': 12.0,
        'image':
            'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
        'category': 'Medicine',
        'tag': 'CARE',
      },
      {
        'name': 'Neem Oil',
        'price': 18.0,
        'image':
            'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
        'category': 'Medicine',
        'tag': 'CARE',
      },
    ];

    // Filter by category first
    List<Map<String, dynamic>> filtered = allPlants;
    if (_selectedCategory != 'All') {
      filtered = allPlants
          .where((plant) => plant['category'] == _selectedCategory)
          .toList();
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((plant) {
        final name = plant['name'].toString().toLowerCase();
        final category = plant['category'].toString().toLowerCase();
        final tag = plant['tag'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            category.contains(query) ||
            tag.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlants = _getFilteredPlants();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buy Plants',
          style: TextStyle(
            color: Color(0xFF1A2E1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFF1A2E1A)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartPage(),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
              if (CartStorage().items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${CartStorage().items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search indoor, outdoor, medicinal...',
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
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[400],
                          ),
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

          // Category Pills
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildCategoryPill('All'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('Indoor'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('Outdoor'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('Medicine'),
                ],
              ),
            ),
          ),

          // Plants Grid
          Expanded(
            child: filteredPlants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No plants found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredPlants.length,
                    itemBuilder: (context, index) {
                      final plant = filteredPlants[index];
                      return _buildPlantCard(
                        plant['name'],
                        plant['price'],
                        plant['image'],
                        plant['tag'],
                        plant['category'],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI Scan feature coming soon!'),
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
              _buildNavItem(Icons.home_outlined, 'Home', false),
              _buildNavItem(Icons.shopping_bag_outlined, 'Shop', true),
              const SizedBox(width: 40),
              _buildNavItem(Icons.receipt_long_outlined, 'Orders', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5233) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D5233) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1A2E1A),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCard(
      String name, double price, String imageUrl, String tag, String category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image,
                            size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E1A),
                      ),
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
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF1A2E1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _addToCart(name, price, imageUrl, category);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D5233),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
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
    );
  }
}









