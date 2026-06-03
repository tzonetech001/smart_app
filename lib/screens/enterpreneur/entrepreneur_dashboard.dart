import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../models/product_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'product_analytics.dart';
import 'ai_predictions_screen.dart';
import '../profile/profile_page.dart';

class EntrepreneurDashboard extends StatefulWidget {
  const EntrepreneurDashboard({super.key});

  @override
  State<EntrepreneurDashboard> createState() => _EntrepreneurDashboardState();
}

class _EntrepreneurDashboardState extends State<EntrepreneurDashboard> {
  int _selectedIndex = 0;
  int _selectedAnalyticsSubmenu = 0;
  bool _isAnalyticsExpanded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.shopping_bag,
      'title': 'My Products',
      'page': const _ProductsScreen(),
      'isExpandable': false,
    },
    {
      'icon': Icons.analytics,
      'title': 'Analytics',
      'page': null,
      'isExpandable': true,
      'submenu': [
        {'icon': Icons.speed, 'title': 'Product Performance Level', 'index': 0},
        {'icon': Icons.trending_up, 'title': 'Market Trends', 'index': 1},
        {'icon': Icons.people, 'title': 'Customer Insights', 'index': 2},
      ],
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'AI Predictions',
      'page': const AIPredictionsScreen(),
      'isExpandable': false,
    },
    {
      'icon': Icons.person,
      'title': 'My Profile',
      'page': const ProfilePage(),
      'isExpandable': false,
    },
  ];

  final List<String> _titles = [
    'My Products',
    'Analytics',
    'AI Predictions',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _getCurrentTitle(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ).then((_) => setState(() {}));
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      drawer: _buildSidebar(),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 1) {
              _isAnalyticsExpanded = false;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF59F797),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getCurrentTitle() {
    if (_selectedIndex == 1 && _isAnalyticsExpanded) {
      const submenuTitles = [
        'Product Performance',
        'Market Trends',
        'Customer Insights',
      ];
      return submenuTitles[_selectedAnalyticsSubmenu];
    }
    return _titles[_selectedIndex];
  }

  Widget _getCurrentPage() {
    if (_selectedIndex == 1 && _isAnalyticsExpanded) {
      return ProductAnalytics(
        initialSubmenuIndex: _selectedAnalyticsSubmenu,
      );
    }
    return _menuItems[_selectedIndex]['page'] ?? Container();
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(color: Color(0xFF59F797)),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.business,
                        size: 40, color: Color(0xFF59F797)),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        return Column(
                          children: [
                            Text(
                              '${data['firstName'] ?? 'Entrepreneur'} ${data['lastName'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['email'] ?? 'entrepreneur@example.com',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        );
                      }
                      return const Text(
                        'Entrepreneur',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _menuItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;
                  final isExpanded = _isAnalyticsExpanded && isSelected;

                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(item['icon'],
                            color: isSelected
                                ? const Color(0xFF59F797)
                                : Colors.grey),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF59F797)
                                : Colors.black87,
                          ),
                        ),
                        trailing: item['isExpandable'] == true
                            ? Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18,
                                color: isSelected
                                    ? const Color(0xFF59F797)
                                    : Colors.grey)
                            : null,
                        selected: isSelected,
                        selectedTileColor:
                            const Color(0xFF59F797).withOpacity(0.1),
                        onTap: () {
                          if (item['isExpandable'] == true) {
                            setState(() {
                              if (isSelected) {
                                _isAnalyticsExpanded = !_isAnalyticsExpanded;
                              } else {
                                _selectedIndex = index;
                                _isAnalyticsExpanded = true;
                                _selectedAnalyticsSubmenu = 0;
                              }
                            });
                          } else {
                            setState(() {
                              _selectedIndex = index;
                              _isAnalyticsExpanded = false;
                            });
                            Navigator.pop(context);
                          }
                        },
                      ),
                      if (isExpanded && item['isExpandable'] == true)
                        Column(
                          children: List.generate(item['submenu'].length, (i) {
                            final subItem = item['submenu'][i];
                            final isSubSelected =
                                _selectedAnalyticsSubmenu == subItem['index'];
                            return ListTile(
                              leading: Icon(subItem['icon'],
                                  size: 18,
                                  color: isSubSelected
                                      ? const Color(0xFF59F797)
                                      : Colors.grey),
                              title: Text(
                                subItem['title'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSubSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSubSelected
                                      ? const Color(0xFF59F797)
                                      : Colors.grey[700],
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedAnalyticsSubmenu = subItem['index'];
                                });
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
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
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 12)),
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

// ==================== PRODUCTS SCREEN ====================
class _ProductsScreen extends StatefulWidget {
  const _ProductsScreen();

  @override
  State<_ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<_ProductsScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedProductId;

  // Helper to format TZS currency
  String _formatTZS(double price) {
    final formatter = NumberFormat.currency(
        locale: 'sw_TZ', symbol: 'TZS ', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    ...ProductCategory.values.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(category.displayName,
                            category.toString().split('.').last),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('entrepreneurId', isEqualTo: authService.currentUser?.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 12)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var products = snapshot.data!.docs.map((doc) {
                return ProductModel.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (_selectedFilter != 'all') {
                products = products
                    .where((product) =>
                        product.category.toString().split('.').last ==
                        _selectedFilter)
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((product) => product.productName
                        .toLowerCase()
                        .contains(_searchQuery))
                    .toList();
              }

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No products match your search'
                            : 'No products yet',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: const Text('Clear Search',
                              style: TextStyle(fontSize: 12)),
                        )
                      else
                        const Text('Tap + button to add your first product',
                            style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isExpanded = _expandedProductId == product.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: product.imageUrl != null
                                        ? Image.network(
                                            product.imageUrl!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                  Icons.broken_image,
                                                  size: 35),
                                            ),
                                          )
                                        : Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image,
                                                size: 35),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(product.productName,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(product.category.displayName,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.favorite,
                                                size: 14, color: Colors.red),
                                            const SizedBox(width: 4),
                                            Text('${product.likes}',
                                                style: const TextStyle(
                                                    fontSize: 11)),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.comment,
                                                size: 14, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text('${product.comments}',
                                                style: const TextStyle(
                                                    fontSize: 11)),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.visibility,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${product.views}',
                                                style: const TextStyle(
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: product.performanceLevel ==
                                                  'HIGH PERFORMANCE'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          product.performanceLevel ==
                                                  'HIGH PERFORMANCE'
                                              ? '🔥 High'
                                              : '⚠️ Low',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: product.performanceLevel ==
                                                    'HIGH PERFORMANCE'
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTZS(product.price),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF59F797)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => setState(() =>
                                          _expandedProductId =
                                              isExpanded ? null : product.id),
                                      icon: Icon(
                                          isExpanded
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 16),
                                      label: Text(
                                          isExpanded
                                              ? 'Hide Insights'
                                              : 'View Insights',
                                          style: const TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditProductScreen(
                                                            product: product)))
                                            .then((_) => setState(() {}));
                                      },
                                      icon: const Icon(Icons.edit,
                                          size: 16, color: Colors.blue),
                                      label: const Text('Edit',
                                          style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showDeleteDialog(
                                          context,
                                          product.id,
                                          product.imageUrl),
                                      icon: const Icon(Icons.delete,
                                          size: 16, color: Colors.red),
                                      label: const Text('Delete',
                                          style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isExpanded)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12)),
                            ),
                            child: _buildCustomerInsights(product.id),
                          ),
                      ],
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

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _selectedFilter == value,
      onSelected: (selected) =>
          setState(() => _selectedFilter = selected ? value : 'all'),
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        color:
            _selectedFilter == value ? const Color(0xFF59F797) : Colors.black87,
      ),
    );
  }

  // Updated customer insights with real counts
  Widget _buildCustomerInsights(String productId) {
    // Get product data for views (from product collection)
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get(),
      builder: (context, productSnapshot) {
        int views = 0;
        if (productSnapshot.hasData && productSnapshot.data != null) {
          final data = productSnapshot.data!.data() as Map<String, dynamic>;
          views = data['views'] ?? 0;
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const Row(
                children: [
                  Icon(Icons.people, size: 16, color: Color(0xFF59F797)),
                  SizedBox(width: 8),
                  Text('Customer Insights',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              // Comments Section
              const Text('Recent Comments',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comments')
                    .where('productId', isEqualTo: productId)
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, commentSnapshot) {
                  if (!commentSnapshot.hasData) {
                    return const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final comments = commentSnapshot.data!.docs;
                  if (comments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8)),
                      child: const Center(
                          child: Text('No comments yet',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey))),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final sentiment = comment.get('sentiment') ?? 'neutral';
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(comment.get('userId'))
                            .get(),
                        builder: (context, userSnapshot) {
                          String userName = 'User';
                          if (userSnapshot.hasData &&
                              userSnapshot.data != null) {
                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            userName =
                                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                                    .trim();
                            if (userName.isEmpty)
                              userName =
                                  userData['email']?.split('@').first ?? 'User';
                          }
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            _getSentimentColor(sentiment)
                                                .withOpacity(0.1),
                                        child: Icon(
                                            _getSentimentIcon(sentiment),
                                            size: 12,
                                            color:
                                                _getSentimentColor(sentiment)),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(userName,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Text(
                                          _formatDate((comment.get('createdAt')
                                                  as Timestamp)
                                              .toDate()),
                                          style: const TextStyle(
                                              fontSize: 9, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment.get('comment') ?? '',
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // Likes Section
              const Text('Recent Likes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('likes')
                    .where('productId', isEqualTo: productId)
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, likeSnapshot) {
                  if (!likeSnapshot.hasData) {
                    return const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final likes = likeSnapshot.data!.docs;
                  if (likes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8)),
                      child: const Center(
                          child: Text('No likes yet',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey))),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: likes.map((like) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(like.get('userId'))
                            .get(),
                        builder: (context, userSnapshot) {
                          String userName = 'User';
                          if (userSnapshot.hasData &&
                              userSnapshot.data != null) {
                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            userName =
                                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                                    .trim();
                            if (userName.isEmpty)
                              userName =
                                  userData['email']?.split('@').first ?? 'User';
                          }
                          return Chip(
                            avatar: const Icon(Icons.favorite,
                                size: 12, color: Colors.red),
                            label: Text(userName,
                                style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.red.withOpacity(0.05),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Overall Stats (dynamic counts)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('likes')
                    .where('productId', isEqualTo: productId)
                    .snapshots(),
                builder: (context, likeCountSnap) {
                  final likeCount = likeCountSnap.hasData
                      ? likeCountSnap.data!.docs.length
                      : 0;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('comments')
                        .where('productId', isEqualTo: productId)
                        .snapshots(),
                    builder: (context, commentCountSnap) {
                      final commentCount = commentCountSnap.hasData
                          ? commentCountSnap.data!.docs.length
                          : 0;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF59F797).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF59F797).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                                Icons.favorite, likeCount.toString(), 'Likes'),
                            _buildStatItem(Icons.comment,
                                commentCount.toString(), 'Comments'),
                            _buildStatItem(
                                Icons.visibility, views.toString(), 'Views'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF59F797)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _showDeleteDialog(
      BuildContext context, String productId, String? imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product', style: TextStyle(fontSize: 16)),
        content: const Text(
            'Are you sure you want to delete this product? This action cannot be undone.',
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 12))),
          TextButton(
            onPressed: () async {
              if (imageUrl != null) {
                try {
                  await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                } catch (_) {}
              }
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .delete();
              final comments = await FirebaseFirestore.instance
                  .collection('comments')
                  .where('productId', isEqualTo: productId)
                  .get();
              for (var c in comments.docs) await c.reference.delete();
              final likes = await FirebaseFirestore.instance
                  .collection('likes')
                  .where('productId', isEqualTo: productId)
                  .get();
              for (var l in likes.docs) await l.reference.delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Product deleted successfully',
                          style: TextStyle(fontSize: 12))),
                );
                setState(() {});
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
