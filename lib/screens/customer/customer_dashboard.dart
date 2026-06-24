import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../utils/location_data.dart';
import 'product_detail_screen.dart';
import 'browse_products_screen.dart';
import 'trending_products_screen.dart';
import '../profile/profile_page.dart';
import 'cart_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_notifications_screen.dart';
import '../../services/notification_service.dart';

class CustomerDashboard extends StatefulWidget {
  final int initialTab;
  const CustomerDashboard({super.key, this.initialTab = 0});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  late int _selectedIndex;
  ProductCategory? _selectedBrowseCategory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedDistrict = 'Kinondoni';
  String _selectedWard = 'Mabibo';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _initializeLocation();
  }

  void _initializeLocation() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      setState(() {
        _selectedDistrict = user.district ?? 'Kinondoni';
        _selectedWard = user.ward ?? 'Mabibo';
      });
    }
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _HomeScreen(
          onNavigateToSearch: () {
            setState(() {
              _selectedBrowseCategory = null;
              _selectedIndex = 1;
            });
          },
          onSelectCategory: (cat) {
            setState(() {
              _selectedBrowseCategory = cat;
              _selectedIndex = 1;
            });
          },
          selectedDistrict: _selectedDistrict,
          selectedWard: _selectedWard,
          onLocationChanged: (district, ward) {
            setState(() {
              _selectedDistrict = district;
              _selectedWard = ward;
            });
          },
        );
      case 1:
        return BrowseProductsScreen(
          key: ValueKey('browse_${_selectedBrowseCategory?.name}'),
          initialCategory: _selectedBrowseCategory,
        );
      case 2:
        return const CartScreen();
      case 3:
        return const CustomerOrdersScreen();
      case 4:
        return const ProfilePage();
      default:
        return const _HomeScreen(
          onNavigateToSearch: null,
          onSelectCategory: null,
          selectedDistrict: 'Kinondoni',
          selectedWard: 'Mabibo',
          onLocationChanged: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'Smart App Home',
      'Explore Products',
      'Shopping Cart',
      'My Orders',
      'My Profile',
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3BC77A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // Shopping Cart Shortcut Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cart')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  count += (doc.get('quantity') ?? 0) as int;
                }
              }
              return Badge(
                label: Text('$count', style: const TextStyle(fontSize: 8, color: Colors.white)),
                isLabelVisible: count > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => setState(() => _selectedIndex = 2),
                ),
              );
            },
          ),
          // Notification Bell
          StreamBuilder<int>(
            stream: NotificationService.getUnreadCount(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Badge(
                label: Text('$unreadCount', style: const TextStyle(fontSize: 8, color: Colors.white)),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerNotificationsScreen()),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildSidebar(),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3BC77A),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF3BC77A),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.shopping_cart, size: 40, color: Color(0xFF3BC77A)),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        return Column(
                          children: [
                            Text(
                              '${data['firstName'] ?? 'Customer'} ${data['lastName'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['email'] ?? 'customer@example.com',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        );
                      }
                      return const Text(
                        'Customer',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Explore Products', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Cart', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 40),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(fontSize: 12, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontSize: 16)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final Function(ProductCategory)? onSelectCategory;
  final String selectedDistrict;
  final String selectedWard;
  final Function(String, String)? onLocationChanged;

  const _HomeScreen({
    this.onNavigateToSearch,
    this.onSelectCategory,
    required this.selectedDistrict,
    required this.selectedWard,
    this.onLocationChanged,
  });

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  String _formatCurrency(double amount) => 'Tsh ${amount.toStringAsFixed(0)}';

  void _showLocationPicker(BuildContext context) {
    String tempDistrict = widget.selectedDistrict;
    String? tempWard = widget.selectedWard;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Delivery Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Selecting a ward updates your Trending Near You recommendations.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: tempDistrict,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                  items: darDistrictsAndWards.keys
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() {
                        tempDistrict = v;
                        tempWard = darDistrictsAndWards[v]!.first; // Auto select first ward
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tempWard,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Ward',
                    border: OutlineInputBorder(),
                  ),
                  items: darDistrictsAndWards[tempDistrict]!
                      .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) {
                    setModalState(() {
                      tempWard = v;
                    });
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.onLocationChanged != null && tempWard != null) {
                        widget.onLocationChanged!(tempDistrict, tempWard!);
                        // Update default location on profile in Firestore in background
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          FirebaseFirestore.instance.collection('users').doc(userId).update({
                            'district': tempDistrict,
                            'ward': tempWard,
                          });
                        }
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3BC77A)),
                    child: const Text('Update Location', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addBundleToCart(
    BuildContext context, {
    required String p1Id,
    required String p1Name,
    required double p1Price,
    required String p1Image,
    required String p1Cat,
    required String p1Ent,
    required String p2Id,
    required String p2Name,
    required double p2Price,
    required String p2Image,
    required String p2Cat,
    required String p2Ent,
    required double discount,
  }) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    try {
      // Primary Item
      await FirebaseFirestore.instance.collection('cart').doc('${_userId}_$p1Id').set({
        'userId': _userId,
        'productId': p1Id,
        'productName': p1Name,
        'imageUrl': p1Image,
        'price': p1Price,
        'quantity': 1,
        'entrepreneurId': p1Ent,
        'category': p1Cat,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Discounted Item
      final discountedPrice = p2Price * (1.0 - discount);
      await FirebaseFirestore.instance.collection('cart').doc('${_userId}_$p2Id').set({
        'userId': _userId,
        'productId': p2Id,
        'productName': '$p2Name (Promo Discount)',
        'imageUrl': p2Image,
        'price': discountedPrice,
        'quantity': 1,
        'entrepreneurId': p2Ent,
        'category': p2Cat,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bundle added to Cart! Added $p1Name + discounted $p2Name'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add bundle: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ward/District Chip Header selector
          InkWell(
            onTap: () => _showLocationPicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3BC77A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF3BC77A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Deliver to: ${widget.selectedDistrict} - ${widget.selectedWard}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3BC77A)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF3BC77A), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar Shortcut
          TextField(
            readOnly: true,
            onTap: widget.onNavigateToSearch,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search products by name or description...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Newly Added Products
          const Text('🆕 Newly Added Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildNewlyAddedProductsSection(),
          const SizedBox(height: 24),

          // Categories Row
          const Text('Product Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: ProductCategory.values.length,
              itemBuilder: (context, index) {
                final category = ProductCategory.values[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(category.displayName, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[200]!),
                    onPressed: () {
                      if (widget.onSelectCategory != null) {
                        widget.onSelectCategory!(category);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Special Offers Section
          const Text('Special Offers & Promo Bundles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildSpecialOffersCarousel(),
          const SizedBox(height: 24),

          // Trending Near You (Analytics Location based popularity)
          Text('Trending in ${widget.selectedWard}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTrendingNearYouSection(),
          const SizedBox(height: 24),

          // Recommended Products based on history
          const Text('Recommended for You', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildRecommendedProductsSection(),
          const SizedBox(height: 24),

          // Featured Products List
          const Text('Featured Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildFeaturedProductsList(),
        ],
      ),
    );
  }

  Widget _buildNewlyAddedProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        // Fallback: if index doesn't exist yet, query without orderBy
        if (snapshot.hasError) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('isActive', isEqualTo: true)
                .limit(6)
                .snapshots(),
            builder: (context, fallbackSnapshot) {
              if (!fallbackSnapshot.hasData) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final products = fallbackSnapshot.data!.docs.map((doc) {
                return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              }).toList();
              return _buildNewlyAddedList(products);
            },
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = snapshot.data!.docs.map((doc) {
          return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();

        return _buildNewlyAddedList(products);
      },
    );
  }

  Widget _buildNewlyAddedList(List<ProductModel> products) {
    if (products.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text(
          'No new products at the moment. Check back soon!',
          style: TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 145,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.only(right: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 130,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.imageUrl != null
                              ? Image.network(
                                  product.imageUrl!,
                                  width: double.infinity,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: double.infinity,
                                    height: 70,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 20, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, size: 20, color: Colors.grey),
                                ),
                        ),
                        // "NEW" badge
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3BC77A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 7,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.productName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _formatCurrency(product.price),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3BC77A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialOffersCarousel() {
    final bundles = [
      {
        'title': 'Household Combo 🌾',
        'desc': 'Buy Rice (1kg) & get Cooking Oil 30% Off!',
        'p1Id': 'p_rice_001', 'p1Name': 'Super Basmati Rice (1kg)', 'p1Price': 3500.0, 'p1Image': 'https://firebasestorage.googleapis.com/v0/b/smart-business-analytics.appspot.com/o/product_images%2Frice.jpg', 'p1Cat': 'food', 'p1Ent': 'demo_ent',
        'p2Id': 'p_oil_001', 'p2Name': 'Pure Sunflower Cooking Oil (1L)', 'p2Price': 8000.0, 'p2Image': 'https://firebasestorage.googleapis.com/v0/b/smart-business-analytics.appspot.com/o/product_images%2Foil.jpg', 'p2Cat': 'food', 'p2Ent': 'demo_ent',
        'discount': 0.30,
      },
      {
        'title': 'Tech Protection Package 💻',
        'desc': 'Purchase a Laptop and Save 15% on Kaspersky Antivirus!',
        'p1Id': 'p_laptop_001', 'p1Name': 'HP EliteBook Core i7', 'p1Price': 1200000.0, 'p1Image': 'https://firebasestorage.googleapis.com/v0/b/smart-business-analytics.appspot.com/o/product_images%2Flaptop.jpg', 'p1Cat': 'electronics', 'p1Ent': 'demo_ent',
        'p2Id': 'p_antivirus_001', 'p2Name': 'Kaspersky Internet Security 2026', 'p2Price': 60000.0, 'p2Image': 'https://firebasestorage.googleapis.com/v0/b/smart-business-analytics.appspot.com/o/product_images%2Fantivirus.jpg', 'p2Cat': 'electronics', 'p2Ent': 'demo_ent',
        'discount': 0.15,
      },
      {
        'title': 'Combo Lunch Offer 🍔',
        'desc': 'Buy Selected Meal and get Mineral Water FREE!',
        'p1Id': 'p_meal_001', 'p1Name': 'Tanzanian Chicken Biryani', 'p1Price': 12000.0, 'p1Image': 'https://firebasestorage.googleapis.com/v0/b/smart-business-analytics.appspot.com/o/product_images%2Fbiryani.jpg', 'p1Cat': 'food', 'p1Ent': 'demo_ent',
        'p2Id': 'p_water_001', 'p2Name': 'Kilimanjaro Drinking Water 500ml', 'p2Price': 1000.0, 'p2Image': 'https://firebasestorage.googleapis.com/v0/b/smart-business-analytics.appspot.com/o/product_images%2Fwater.jpg', 'p2Cat': 'food', 'p2Ent': 'demo_ent',
        'discount': 1.0, // Free!
      }
    ];

    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: bundles.length,
        itemBuilder: (context, index) {
          final b = bundles[index];
          return Card(
            margin: const EdgeInsets.only(right: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3BC77A))),
                  const SizedBox(height: 4),
                  Text(b['desc'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () => _addBundleToCart(
                        context,
                        p1Id: b['p1Id'] as String, p1Name: b['p1Name'] as String, p1Price: b['p1Price'] as double, p1Image: b['p1Image'] as String, p1Cat: b['p1Cat'] as String, p1Ent: b['p1Ent'] as String,
                        p2Id: b['p2Id'] as String, p2Name: b['p2Name'] as String, p2Price: b['p2Price'] as double, p2Image: b['p2Image'] as String, p2Cat: b['p2Cat'] as String, p2Ent: b['p2Ent'] as String,
                        discount: b['discount'] as double,
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 12),
                      label: const Text('Add Bundle', style: TextStyle(fontSize: 10)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: const Color(0xFF3BC77A).withOpacity(0.1),
                        foregroundColor: const Color(0xFF3BC77A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingNearYouSection() {
    // Queries completed orders to identify ward purchase volumes
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerLocation.ward', isEqualTo: widget.selectedWard)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final Map<String, int> productCounts = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List? ?? [];
          for (var item in items) {
            final productId = item['productId'] ?? '';
            final quantity = item['quantity'] ?? 1;
            if (productId.isNotEmpty) {
              productCounts[productId] = (productCounts[productId] ?? 0) + (quantity as int);
            }
          }
        }

        // Fetch products matching the trending IDs
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, pSnapshot) {
            if (!pSnapshot.hasData) {
              return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
            }

            var products = pSnapshot.data!.docs.map((doc) {
              return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            // Sort products by location order count
            if (productCounts.isNotEmpty) {
              products.sort((a, b) {
                final countA = productCounts[a.id] ?? 0;
                final fontB = productCounts[b.id] ?? 0;
                return fontB.compareTo(countA);
              });
            } else {
              // Fallback to highest performance rating
              products.sort((a, b) => b.rating.compareTo(a.rating));
            }

            final trendingList = products.take(4).toList();

            if (trendingList.isEmpty) {
              return const Text('No location trending items yet.', style: TextStyle(fontSize: 11, color: Colors.grey));
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: trendingList.length,
                itemBuilder: (context, index) {
                  final product = trendingList[index];
                  final localCount = productCounts[product.id] ?? 0;

                  return _buildItemMiniCard(context, product, badge: localCount > 0 ? '$localCount bought near you' : 'Popular choice');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedProductsSection() {
    if (_userId == null) {
      return const Text('Sign in to view recommendations', style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    // Recommended based on categories previously bought
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final Set<String> preferredCategories = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List? ?? [];
          for (var item in items) {
            final category = item['category'] ?? '';
            if (category.isNotEmpty) {
              preferredCategories.add(category as String);
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, pSnapshot) {
            if (!pSnapshot.hasData) {
              return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
            }

            var products = pSnapshot.data!.docs.map((doc) {
              return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            // Filter products matching preferred categories
            List<ProductModel> recs = [];
            if (preferredCategories.isNotEmpty) {
              recs = products.where((p) => preferredCategories.contains(p.category.toString().split('.').last)).toList();
            }

            // Fallback to top rated products
            if (recs.isEmpty) {
              recs = products.where((p) => p.rating >= 4.0).toList();
            }

            final recsList = recs.take(4).toList();

            if (recsList.isEmpty) {
              return const Text('Browse items to generate recommendation history.', style: TextStyle(fontSize: 11, color: Colors.grey));
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recsList.length,
                itemBuilder: (context, index) {
                  final product = recsList[index];
                  return _buildItemMiniCard(context, product, badge: 'For You');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs.map((doc) {
          return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();

        if (products.isEmpty) {
          return const Text('No products featured currently.', style: TextStyle(fontSize: 11, color: Colors.grey));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, width: 45, height: 45, fit: BoxFit.cover)
                      : Container(width: 45, height: 45, color: Colors.grey[200], child: const Icon(Icons.image)),
                ),
                title: Text(product.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text('Tsh ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF3BC77A), fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemMiniCard(BuildContext context, ProductModel product, {required String badge}) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, width: double.infinity, height: 50, fit: BoxFit.cover)
                    : Container(width: double.infinity, height: 50, color: Colors.grey[200], child: const Icon(Icons.image, size: 16)),
              ),
              const SizedBox(height: 6),
              Text(
                product.productName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(product.price),
                style: const TextStyle(fontSize: 9, color: Color(0xFF3BC77A), fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                child: Text(badge, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
