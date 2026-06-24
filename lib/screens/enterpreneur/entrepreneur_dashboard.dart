import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'entrepreneur_notifications_screen.dart' hide EditProductScreen;
import '../profile/profile_page.dart';

class EntrepreneurDashboard extends StatefulWidget {
  const EntrepreneurDashboard({super.key});

  @override
  State<EntrepreneurDashboard> createState() => _EntrepreneurDashboardState();
}

class _EntrepreneurDashboardState extends State<EntrepreneurDashboard> {
  int _selectedIndex = 0;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final List<String> _titles = [
    'Business Dashboard',
    'Product Catalog',
    'Manage Orders',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Authentication error. Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.getUnreadCount(_currentUserId!),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Badge(
                label: Text('$unread', style: const TextStyle(fontSize: 8, color: Colors.white)),
                isLabelVisible: unread > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notifications',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EntrepreneurNotificationsScreen()),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: _buildCurrentTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: const Color(0xFF59F797),
        elevation: 6,
        child: const Icon(Icons.add, color: Color(0xFF0F172A), size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF0F172A),
        elevation: 10,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
              _buildTabButton(1, Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, 'Products'),
              const SizedBox(width: 48), // Spacing for the floating + FAB in the center
              _buildTabButton(2, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
              _buildTabButton(3, Icons.person_rounded, Icons.person_outlined, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF59F797) : Colors.grey[400],
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF59F797) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _HomeTab(currentUserId: _currentUserId!);
      case 1:
        return _ProductsTab(currentUserId: _currentUserId!);
      case 2:
        return _OrdersTab(currentUserId: _currentUserId!);
      case 3:
        return const ProfilePage();
      default:
        return Container();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ========================== TAB 0: HOME (DASHBOARD) ==========================
class _HomeTab extends StatelessWidget {
  final String currentUserId;
  const _HomeTab({required this.currentUserId});

  String _formatTZS(double value) => 'Tsh ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('entrepreneurId', isEqualTo: currentUserId)
        .snapshots();

    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('entrepreneurId', isEqualTo: currentUserId)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: productsStream,
      builder: (context, productsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: ordersStream,
          builder: (context, ordersSnapshot) {
            if (productsSnapshot.hasError || ordersSnapshot.hasError) {
              return const Center(child: Text('Error loading business metrics.'));
            }
            if (!productsSnapshot.hasData || !ordersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF59F797)));
            }

            final products = productsSnapshot.data!.docs
                .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            final orders = ordersSnapshot.data!.docs
                .map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            // Computations
            final int totalProducts = products.length;
            final int activeProducts = products.where((p) => p.isActive).length;
            final int inactiveProducts = products.where((p) => !p.isActive).length;
            final int totalOrders = orders.length;

            double totalRevenue = 0.0;
            for (var order in orders) {
              if (order.paymentStatus == PaymentStatus.paid || order.status == OrderStatus.delivered) {
                totalRevenue += order.totalAmount;
              }
            }

            // Trend: Rank products based on ordered items quantities
            Map<String, int> productSalesCounts = {};
            for (var order in orders) {
              for (var item in order.items) {
                productSalesCounts[item.productName] = (productSalesCounts[item.productName] ?? 0) + item.quantity;
              }
            }

            var sortedSales = productSalesCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Summary',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      
                      // Stat Cards Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'My Products',
                              value: '$totalProducts',
                              subText: 'Active: $activeProducts • Inactive: $inactiveProducts',
                              gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                              icon: Icons.inventory_2_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Orders',
                              value: '$totalOrders',
                              subText: 'Total customer purchases',
                              gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                              icon: Icons.receipt_long_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Revenue',
                              value: _formatTZS(totalRevenue),
                              subText: 'Paid transactions',
                              gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                              icon: Icons.monetization_on_rounded,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Product Order Rankings (Most to Least Ordered)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),

                      // Rank list / Progress Graph
                      if (sortedSales.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No orders received yet',
                                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Analytics graphs will appear once products are ordered.',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: sortedSales.length,
                                  itemBuilder: (context, index) {
                                    final entry = sortedSales[index];
                                    final maxVal = sortedSales.first.value;
                                    final percent = maxVal > 0 ? (entry.value / maxVal) : 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 10,
                                                      backgroundColor: index == 0
                                                          ? const Color(0xFF59F797).withOpacity(0.2)
                                                          : Colors.grey[200],
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: index == 0
                                                              ? const Color(0xFF0F172A)
                                                              : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        entry.key,
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${entry.value} ordered',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: percent,
                                              backgroundColor: Colors.grey[100],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                index == 0 ? const Color(0xFF59F797) : Colors.blue.withOpacity(0.7),
                                              ),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 80), // Padding to prevent layout clip behind FAB
                    ],
                  ),
                ),
                
                // Pulsing AI Floating Button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showAITrendsSheet(context, products),
                    label: const Text(
                      'AI Insights',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFF59F797), size: 18),
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 5,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subText,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subText, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
              ],
            ),
          ),
          Icon(icon, color: Colors.white.withOpacity(0.2), size: 40),
        ],
      ),
    );
  }

  void _showAITrendsSheet(BuildContext context, List<ProductModel> myProducts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AITrendsBottomSheet(myProducts: myProducts, currentUserId: currentUserId),
    );
  }
}

// ========================== AI TRENDS SHEET SYSTEM ==========================
class _AITrendsBottomSheet extends StatefulWidget {
  final List<ProductModel> myProducts;
  final String currentUserId;
  const _AITrendsBottomSheet({required this.myProducts, required this.currentUserId});

  @override
  State<_AITrendsBottomSheet> createState() => _AITrendsBottomSheetState();
}

class _AITrendsBottomSheetState extends State<_AITrendsBottomSheet> {
  bool _isLoading = true;
  String _loadingMessage = 'Gathering global catalog statistics...';

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _loadingMessage = 'Comparing user views and rating indexes...');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _loadingMessage = 'Running neural demand forecasting models...');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading ? _buildLoading() : _buildReport(context),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF59F797),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Smart Business AI Assistant',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('products').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF59F797)));
        }

        final allDocs = snapshot.data!.docs;
        final allProducts = allDocs.map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

        // Calculate other entrepreneur products & global categories
        final otherProducts = allProducts.where((p) => p.entrepreneurId != widget.currentUserId).toList();

        // Global trends calculation
        Map<String, double> categoryEngagement = {};
        Map<String, int> categoryProductCounts = {};
        Map<String, int> categorySellerCounts = {};
        Map<String, List<double>> categoryRatings = {};

        for (var p in allProducts) {
          final cat = p.category.displayName;
          final score = p.likes + p.comments + (p.rating * 10) + p.views;
          categoryEngagement[cat] = (categoryEngagement[cat] ?? 0) + score;
          categoryProductCounts[cat] = (categoryProductCounts[cat] ?? 0) + 1;
          categoryRatings.putIfAbsent(cat, () => []).add(p.rating);
        }

        // Calculate distinct sellers per category
        for (var catName in categoryProductCounts.keys) {
          final catProducts = allProducts.where((p) => p.category.displayName == catName).toList();
          final distinctSellers = catProducts.map((p) => p.entrepreneurId).toSet().length;
          categorySellerCounts[catName] = distinctSellers;
        }

        var sortedCategories = categoryEngagement.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Insights for my products
        List<String> personalInsights = [];
        for (var p in widget.myProducts) {
          if (p.stock < 15 && p.isActive) {
            personalInsights.add('⚠️ Low Stock Warning: "${p.productName}" is in high demand, but stock is low (${p.stock}). Restock now.');
          } else if (p.views > 30 && p.unitsSold == 0) {
            personalInsights.add('💡 Pricing Insight: "${p.productName}" has received ${p.views} views but zero sales. Consider launching a 10% discount promo.');
          } else if (p.likes > 5 && p.unitsSold < 2) {
            personalInsights.add('🔥 Promotion Insight: "${p.productName}" has high popularity (${p.likes} likes). Run a flash promotion to capture buyer interest.');
          }
        }
        if (personalInsights.isEmpty) {
          personalInsights.add('✅ Product Health: All listed products show stable stocks and healthy engagement ratios.');
        }

        // Top category selection for recommendation
        String topCategoryName = 'Electronics';
        double topEngagement = 0.0;
        if (sortedCategories.isNotEmpty) {
          topCategoryName = sortedCategories.first.key;
          topEngagement = sortedCategories.first.value;
        }

        final topCategorySellers = categorySellerCounts[topCategoryName] ?? 1;

        return Column(
          children: [
            // Sheet Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF59F797), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI Investment & Trend Assistant',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: My Product Insights
                    const Text(
                      'Personal Catalog Analysis',
                      style: TextStyle(color: Color(0xFF59F797), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...personalInsights.map((insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    insight,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),

                    const SizedBox(height: 24),

                    // Section 2: Competitor & Market Trends
                    const Text(
                      'Global Category Engagement Rankings',
                      style: TextStyle(color: Color(0xFF59F797), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (sortedCategories.isEmpty)
                      const Text(
                        'No global listings data available yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      )
                    else
                      ...sortedCategories.take(3).map((entry) {
                        final index = sortedCategories.indexOf(entry) + 1;
                        final count = categoryProductCounts[entry.key] ?? 0;
                        final sellers = categorySellerCounts[entry.key] ?? 0;
                        final ratingsList = categoryRatings[entry.key] ?? [0.0];
                        final avgRating = ratingsList.reduce((a, b) => a + b) / ratingsList.length;

                        return Card(
                          color: Colors.white.withOpacity(0.02),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF59F797).withOpacity(0.1),
                                  child: Text(
                                    '$index',
                                    style: const TextStyle(color: Color(0xFF59F797), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$count products • $sellers active sellers • Average Rating: ${avgRating.toStringAsFixed(1)} ★',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Section 3: AI Investment Recommendation
                    const Text(
                      'AI Capital Allocation Recommendation',
                      style: TextStyle(color: Color(0xFF59F797), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF59F797).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.rocket_launch, color: Color(0xFF59F797), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Recommended Niche: $topCategoryName',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Based on cross-platform consumer telemetry, the "$topCategoryName" sector currently boasts the highest user engagement (score: ${topEngagement.toStringAsFixed(0)}). With only $topCategorySellers distinct sellers in this workspace, this market slice exhibits low saturation and high growth prospects.\n\nWe recommend allocating capital to procure and list items in the "$topCategoryName" category over the next 14 days to capture high transactional margins.',
                            style: TextStyle(color: Colors.grey[300], fontSize: 10, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ========================== TAB 1: PRODUCTS TAB ==========================
class _ProductsTab extends StatefulWidget {
  final String currentUserId;
  const _ProductsTab({required this.currentUserId});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _formatTZS(double v) => 'Tsh ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('entrepreneurId', isEqualTo: widget.currentUserId)
        .snapshots();

    return Column(
      children: [
        // Total Stock and Products statistics header cards
        StreamBuilder<QuerySnapshot>(
          stream: productsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final products = snapshot.data!.docs
                .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            final totalProducts = products.length;
            final totalStock = products.fold<int>(0, (sum, p) => sum + p.stock);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard('Total Products', '$totalProducts', Icons.category_rounded, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard('Total Stock Qty', '$totalStock units', Icons.inventory_2_rounded, Colors.teal),
                  ),
                ],
              ),
            );
          },
        ),

        // Search & Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search my catalog...',
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF59F797))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('All Categories', 'all'),
                    const SizedBox(width: 8),
                    ...ProductCategory.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(cat.displayName, cat.name),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Catalog List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: productsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error retrieving product list.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF59F797)));
              }

              var products = snapshot.data!.docs
                  .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                  .toList();

              // Filters implementation
              if (_selectedCategory != 'all') {
                products = products.where((p) => p.category.name == _selectedCategory).toList();
              }
              if (_searchQuery.isNotEmpty) {
                products = products.where((p) => p.productName.toLowerCase().contains(_searchQuery)).toList();
              }

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_clear, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? 'No matches for "$_searchQuery"' : 'Product list is empty',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: p.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: p.imageUrl!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[100],
                                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1))),
                                        ),
                                        errorWidget: (context, url, e) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.productName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      p.category.displayName,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTZS(p.price),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stock quantity: ${p.stock}',
                                      style: TextStyle(fontSize: 10, color: p.stock < 10 ? Colors.red : Colors.grey[600], fontWeight: p.stock < 10 ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Active Switch
                              Column(
                                children: [
                                  Text(p.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 8, color: p.isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                                  Switch(
                                    value: p.isActive,
                                    activeColor: const Color(0xFF59F797),
                                    onChanged: (val) async {
                                      await FirebaseFirestore.instance.collection('products').doc(p.id).update({'isActive': val});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          
                          // Bottom Actions Row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showProductDetailsDialog(context, p),
                                  icon: const Icon(Icons.info_outline_rounded, size: 14),
                                  label: const Text('Product Details', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EditProductScreen(product: p)),
                                    );
                                    if (res == true && mounted) setState(() {});
                                  },
                                  icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.blue),
                                  label: const Text('Edit Product', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String val, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? value : 'all';
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[200]!)),
    );
  }

  void _showProductDetailsDialog(BuildContext context, ProductModel p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(p.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: p.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              _buildDetailRow('Category', p.category.displayName),
              _buildDetailRow('Price', _formatTZS(p.price)),
              _buildDetailRow('Stock Level', '${p.stock} units'),
              _buildDetailRow('Brand', p.brand ?? 'N/A'),
              _buildDetailRow('SKU', p.sku ?? 'N/A'),
              _buildDetailRow('Active Status', p.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Demand Level', p.demandLevel),
              _buildDetailRow('Performance Level', p.performanceLevel),
              const SizedBox(height: 12),
              const Text('Product Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(p.description, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4)),
              const SizedBox(height: 12),
              const Text('Interactive Metrics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell(Icons.visibility, '${p.views}', 'Views'),
                  _buildMetricCell(Icons.favorite, '${p.likes}', 'Likes'),
                  _buildMetricCell(Icons.comment, '${p.comments}', 'Comments'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell(Icons.shopping_bag, '${p.unitsSold}', 'Units Sold'),
                  _buildMetricCell(Icons.monetization_on, _formatTZS(p.revenue), 'Revenue'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCell(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }
}

// ========================== TAB 2: ORDERS TAB ==========================
class _OrdersTab extends StatefulWidget {
  final String currentUserId;
  const _OrdersTab({required this.currentUserId});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _formatTZS(double v) => 'Tsh ${v.toStringAsFixed(0)}';

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment: return Colors.amber;
      case OrderStatus.paymentConfirmed: return Colors.blue;
      case OrderStatus.processing: return Colors.indigo;
      case OrderStatus.packed: return Colors.teal;
      case OrderStatus.shipped: return Colors.purple;
      case OrderStatus.outForDelivery: return Colors.pink;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(order.id);

      Map<String, dynamic> updates = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.paymentConfirmed) {
        updates['paymentStatus'] = PaymentStatus.paid.name;
      }

      batch.update(orderRef, updates);
      await batch.commit();

      await NotificationService.sendOrderStatusUpdateNotification(
        userId: order.userId,
        orderId: order.id,
        status: newStatus.displayName,
      );

      if (newStatus == OrderStatus.paymentConfirmed) {
        await NotificationService.sendPaymentApprovedNotification(
          entrepreneurId: order.entrepreneurId,
          orderId: order.id,
          amount: order.totalAmount,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated: ${newStatus.displayName}', style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status update failed: $e', style: const TextStyle(fontSize: 12)), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('entrepreneurId', isEqualTo: widget.currentUserId)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF0F172A),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF59F797),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Paid Orders'),
                Tab(text: 'Pending Orders'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ordersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading orders list.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF59F797)));
                }

                final allOrders = snapshot.data!.docs
                    .map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                // Paid Orders Filter
                final paidOrders = allOrders.where((o) => o.paymentStatus == PaymentStatus.paid || o.status != OrderStatus.pendingPayment).toList();
                paidOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

                // Pending Orders Filter
                final pendingOrders = allOrders.where((o) => o.paymentStatus == PaymentStatus.pending && o.status == OrderStatus.pendingPayment).toList();
                pendingOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

                return TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildOrdersList(paidOrders),
                    _buildOrdersList(pendingOrders),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'No orders in this category',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final o = orders[index];
        final shortId = o.id.length >= 8 ? o.id.substring(0, 8).toUpperCase() : o.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID: #$shortId', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(o.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        o.status.displayName,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getStatusColor(o.status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Customer: ${o.shippingAddress.fullName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Location: ${o.shippingAddress.district} - ${o.shippingAddress.street}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Placed on: ${o.orderDate.day}/${o.orderDate.month}/${o.orderDate.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Divider(height: 20),
                const Text('Items Ordered:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 6),
                ...o.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.quantity}x ${item.productName}', style: const TextStyle(fontSize: 11))),
                          Text(_formatTZS(item.price * item.quantity), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(_formatTZS(o.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionsForOrder(o),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsForOrder(OrderModel order) {
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    List<Widget> buttons = [];

    if (order.status == OrderStatus.pendingPayment) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.paymentConfirmed),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Approve Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.paymentConfirmed) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.processing),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Start Processing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.processing) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.packed),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Mark Packed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.packed) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.shipped),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Ship Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.shipped) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.outForDelivery),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Send Out for Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.outForDelivery) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.delivered),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Mark Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    if (order.status == OrderStatus.pendingPayment ||
        order.status == OrderStatus.paymentConfirmed ||
        order.status == OrderStatus.processing ||
        order.status == OrderStatus.packed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
      buttons.add(
        OutlinedButton(
          onPressed: () => _updateStatus(order, OrderStatus.cancelled),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Cancel', style: TextStyle(fontSize: 11)),
        ),
      );
    }

    return Row(children: buttons);
  }
}
