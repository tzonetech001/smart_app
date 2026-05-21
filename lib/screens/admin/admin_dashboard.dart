import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import 'admin_user_management.dart';
import 'admin_product_management.dart';
import 'admin_analytics.dart';
import 'admin_customer_reacts.dart';
import '../profile/profile_page.dart';
import '../../widgets/chart_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'page': const _AdminHomeScreen()},
    {'icon': Icons.people, 'title': 'Manage Users', 'page': const AdminUserManagement()},
    {'icon': Icons.inventory, 'title': 'Manage Products', 'page': const AdminProductManagement()},
    {'icon': Icons.favorite, 'title': 'Customer Reacts', 'page': const AdminCustomerReacts()},
    {'icon': Icons.analytics, 'title': 'Analytics', 'page': const AdminAnalytics()},
    {'icon': Icons.person, 'title': 'My Profile', 'page': const ProfilePage()},
  ];

  final List<String> _titles = [
    'Dashboard',
    'Manage Users',
    'Manage Products',
    'Customer Reacts',
    'Analytics',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildSidebar(),
      body: _menuItems[_selectedIndex]['page'],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF59F797),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Reacts'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF59F797),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFF59F797)),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        return Column(
                          children: [
                            Text(
                              '${data['firstName'] ?? 'Admin'} ${data['lastName'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['email'] ?? 'admin@example.com',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        );
                      }
                      return const Text(
                        'Admin User',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menu Items
            Expanded(
              child: ListView.separated(
                itemCount: _menuItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return ListTile(
                    leading: Icon(item['icon'], color: _selectedIndex == index ? const Color(0xFF59F797) : Colors.grey),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                        color: _selectedIndex == index ? const Color(0xFF59F797) : Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == index,
                    selectedTileColor: const Color(0xFF59F797).withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
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

// Admin Home Screen
class _AdminHomeScreen extends StatelessWidget {
  const _AdminHomeScreen();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF59F797), Color(0xFF3BC77A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Administrator!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here\'s what\'s happening with your platform today',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                // Quick date info
                Text(
                  _getCurrentDate(),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Cards
          const Text(
            'Overview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              int totalUsers = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
              int totalEntrepreneurs = 0;
              if (userSnapshot.hasData) {
                totalEntrepreneurs = userSnapshot.data!.docs.where((doc) {
                  return doc.get('role') == 'entrepreneur';
                }).length;
              }
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, productSnapshot) {
                  int totalProducts = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
                  int totalLikes = 0;
                  if (productSnapshot.hasData) {
                    totalLikes = productSnapshot.data!.docs.fold<int>(0, (sum, doc) {
                      final likes = doc.get('likes');
                      return sum + (likes is int ? likes : 0);
                    });
                  }
                  
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    children: [
                      _StatsCard(title: 'Total Users', value: totalUsers.toString(), icon: Icons.people, color: Colors.blue),
                      _StatsCard(title: 'Entrepreneurs', value: totalEntrepreneurs.toString(), icon: Icons.business, color: Colors.orange),
                      _StatsCard(title: 'Total Products', value: totalProducts.toString(), icon: Icons.inventory, color: const Color(0xFF59F797)),
                      _StatsCard(title: 'Total Likes', value: totalLikes.toString(), icon: Icons.favorite, color: Colors.red),
                    ],
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Recent Products
          const Text(
            'Recent Products',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final products = snapshot.data!.docs;
              if (products.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No products yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.get('imageUrl') != null
                            ? Image.network(product.get('imageUrl'), width: 40, height: 40, fit: BoxFit.cover)
                            : Container(width: 40, height: 40, color: Colors.grey[300], child: const Icon(Icons.image, size: 20)),
                      ),
                      title: Text(product.get('productName') ?? 'No Name', style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        'By: ${product.get('entrepreneurName') ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Text(
                        '\$${product.get('price')?.toStringAsFixed(2) ?? '0'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} • ${_getWeekday(now.weekday)}';
  }

  String _getWeekday(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}