import 'package:flutter/material.dart';
import 'cart.dart';
import 'profile.dart';
import 'order.dart';

class SeasonalPlantsPage extends StatefulWidget {
  const SeasonalPlantsPage({super.key});

  @override
  State<SeasonalPlantsPage> createState() => _SeasonalPlantsPageState();
}

class _SeasonalPlantsPageState extends State<SeasonalPlantsPage> {
  String _selectedSeason = 'Summer';

  final Map<String, List<Map<String, dynamic>>> _seasonalPlants = {
    'Summer': [
      {
        'name': 'Sunflower',
        'price': 4.50,
        'tag': 'HEAT TOLERANT',
        'tagColor': const Color(0xFFE3F2FD),
        'tagTextColor': const Color(0xFF2196F3),
        'image':
            'https://images.unsplash.com/photo-1597848212624-e530bb536e90?w=400',
      },
      {
        'name': 'Cherry Tomato',
        'price': 6.99,
        'tag': 'FAST GROWTH',
        'tagColor': const Color(0xFFFFEBEE),
        'tagTextColor': const Color(0xFFE74C3C),
        'image':
            'https://images.unsplash.com/photo-1592841200221-a6898f307baa?w=400',
      },
      {
        'name': 'Marigold',
        'price': 3.99,
        'tag': 'PEST REPELLENT',
        'tagColor': const Color(0xFFFFF3E0),
        'tagTextColor': const Color(0xFFFF9800),
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
      },
      {
        'name': 'Sweet Basil',
        'price': 5.00,
        'tag': 'HERB',
        'tagColor': const Color(0xFFE8F5E9),
        'tagTextColor': const Color(0xFF4A7C4A),
        'image':
            'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?w=400',
      },
      {
        'name': 'Aloe Vera',
        'price': 8.99,
        'tag': 'LOW WATER',
        'tagColor': const Color(0xFFE0F2F1),
        'tagTextColor': const Color(0xFF00897B),
        'image':
            'https://images.unsplash.com/photo-1509587584298-0f3b3a3a1797?w=400',
      },
      {
        'name': 'Chili Pepper',
        'price': 5.50,
        'tag': 'SPICY',
        'tagColor': const Color(0xFFFFEBEE),
        'tagTextColor': const Color(0xFFE74C3C),
        'image':
            'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
      },
    ],
    'Winter': [
      {
        'name': 'Poinsettia',
        'price': 22.00,
        'tag': 'FESTIVE',
        'tagColor': const Color(0xFFFFEBEE),
        'tagTextColor': const Color(0xFFE74C3C),
        'image':
            'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?w=400',
      },
      {
        'name': 'Winter Jasmine',
        'price': 18.50,
        'tag': 'FRAGRANT',
        'tagColor': const Color(0xFFFFF3E0),
        'tagTextColor': const Color(0xFFFF9800),
        'image':
            'https://images.unsplash.com/photo-1611909023032-2d6b3134ecba?w=400',
      },
      {
        'name': 'Holly',
        'price': 24.99,
        'tag': 'EVERGREEN',
        'tagColor': const Color(0xFFE8F5E9),
        'tagTextColor': const Color(0xFF4A7C4A),
        'image':
            'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=400',
      },
      {
        'name': 'Pansy',
        'price': 6.50,
        'tag': 'COLD HARDY',
        'tagColor': const Color(0xFFE3F2FD),
        'tagTextColor': const Color(0xFF2196F3),
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
      },
    ],
    'Spring': [
      {
        'name': 'Tulip',
        'price': 12.00,
        'tag': 'COLORFUL',
        'tagColor': const Color(0xFFFCE4EC),
        'tagTextColor': const Color(0xFFE91E63),
        'image':
            'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=400',
      },
      {
        'name': 'Daffodil',
        'price': 10.50,
        'tag': 'EARLY BLOOM',
        'tagColor': const Color(0xFFFFF9C4),
        'tagTextColor': const Color(0xFFF57C00),
        'image':
            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
      },
      {
        'name': 'Lavender',
        'price': 14.00,
        'tag': 'AROMATIC',
        'tagColor': const Color(0xFFE1BEE7),
        'tagTextColor': const Color(0xFF9C27B0),
        'image':
            'https://images.unsplash.com/photo-1611909023032-2d6b3134ecba?w=400',
      },
      {
        'name': 'Strawberry',
        'price': 9.99,
        'tag': 'EDIBLE',
        'tagColor': const Color(0xFFFFEBEE),
        'tagTextColor': const Color(0xFFE74C3C),
        'image':
            'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      },
    ],
  };

  List<Map<String, dynamic>> get _filteredPlants {
    return _seasonalPlants[_selectedSeason] ?? [];
  }

  void _addToCart(String name, double price, String imageUrl) {
    setState(() {
      CartStorage().addItem(name, price, imageUrl, 'Plant');
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

  // Helper method to get responsive values
  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 0.8;
    if (width > 800) return 0.75;
    return 0.75;
  }

  double _getBannerHeight(double width) {
    if (width > 800) return 200;
    if (width > 600) return 180;
    return 160;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Seasonal Plants',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2E1A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: const Color(0xFF1A2E1A),
              size: isTablet ? 28 : 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar feature coming soon!'),
                  backgroundColor: Color(0xFF4A7C4A),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero Banner - Fully Responsive
          Padding(
            padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bannerWidth = constraints.maxWidth;
                final imageWidth = bannerWidth * 0.35;

                return Container(
                  height: _getBannerHeight(screenWidth),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A7C4A), Color(0xFF8BC34A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        bottom: -20,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
                            fit: BoxFit.cover,
                            width: imageWidth,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: Colors.transparent);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 28.0 : 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.eco,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Flexible(
                                  child: Text(
                                    'Best plants to',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'grow this season',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            Flexible(
                              child: Text(
                                'Maximize your harvest with\nthese summer picks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 15 : 13,
                                  height: 1.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Season Tabs - Responsive
          SizedBox(
            height: isTablet ? 60 : 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
              children: [
                _buildSeasonChip('Summer', '☀️', isTablet),
                _buildSeasonChip('Winter', '❄️', isTablet),
                _buildSeasonChip('Spring', '🌸', isTablet),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 20 : 16),

          // Plants Grid - Responsive
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(screenWidth),
                    childAspectRatio: _getChildAspectRatio(screenWidth),
                    crossAxisSpacing: isTablet ? 20 : 16,
                    mainAxisSpacing: isTablet ? 20 : 16,
                  ),
                  itemCount: _filteredPlants.length,
                  itemBuilder: (context, index) {
                    final plant = _filteredPlants[index];
                    return _buildPlantCard(plant, isTablet);
                  },
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
              content: Text('Scanner feature coming soon!'),
              backgroundColor: Color(0xFF4A7C4A),
            ),
          );
        },
        backgroundColor: const Color(0xFF2D5233),
        child: Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: isTablet ? 28 : 24,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: isTablet ? 70 : 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', false, isTablet),
              _buildNavItem(
                  Icons.shopping_bag_outlined, 'Shop', false, isTablet),
              const SizedBox(width: 40),
              _buildNavItem(
                  Icons.receipt_long_outlined, 'Order', false, isTablet),
              _buildNavItem(Icons.person_outline, 'Profile', false, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isSelected, bool isTablet) {
    return InkWell(
      onTap: () {
        if (label == 'Home') {
          Navigator.pop(context);
        } else if (label == 'Shop') {
          Navigator.pop(context);
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
            size: isTablet ? 30 : 26,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2D5233) : Colors.grey,
              fontSize: isTablet ? 14 : 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonChip(String season, String emoji, bool isTablet) {
    final isSelected = _selectedSeason == season;
    return Padding(
      padding: EdgeInsets.only(right: isTablet ? 16 : 12),
      child: ChoiceChip(
        label: Row(
          children: [
            Text(season),
            SizedBox(width: isTablet ? 8 : 6),
            Text(
              emoji,
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSeason = season;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFFFF9C4),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1A2E1A) : const Color(0xFF6B7280),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: isTablet ? 16 : 14,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color:
                isSelected ? const Color(0xFFF57C00) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> plant, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                plant['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image,
                      size: isTablet ? 60 : 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Tag
            Positioned(
              top: isTablet ? 16 : 12,
              left: isTablet ? 16 : 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: plant['tagColor'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plant['tag'],
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.bold,
                    color: plant['tagTextColor'],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Plant Info
            Positioned(
              bottom: isTablet ? 16 : 12,
              left: isTablet ? 16 : 12,
              right: isTablet ? 16 : 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant['name'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Text(
                          '\$${plant['price'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _addToCart(
                      plant['name'],
                      plant['price'],
                      plant['image'],
                    ),
                    child: Container(
                      width: isTablet ? 50 : 44,
                      height: isTablet ? 50 : 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: const Color(0xFF4A7C4A),
                        size: isTablet ? 28 : 24,
                      ),
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
}









