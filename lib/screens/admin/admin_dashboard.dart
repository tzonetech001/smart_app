import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'admin_user_management.dart';
import 'admin_payment_management.dart';
import 'admin_product_management.dart';
import 'admin_analytics.dart';
import 'admin_customer_reacts.dart';
import 'admin_location_insights.dart';
import 'admin_ai_monitoring.dart';
import 'admin_notifications.dart';
import 'admin_order_monitoring.dart';
import '../profile/profile_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard,
      'title': 'Dashboard',
      'page': const _AdminHomeScreen()
    },
    {
      'icon': Icons.people,
      'title': 'Manage Users',
      'page': const AdminUserManagement()
    },
    {
      'icon': Icons.inventory,
      'title': 'Manage Products',
      'page': const AdminProductManagement()
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'Order Monitoring',
      'page': const AdminOrderMonitoring()
    },
    // FIXED: Added Payment Management
    {
      'icon': Icons.payment,
      'title': 'Payment Management',
      'page': const AdminPaymentManagement()
    },
    // FIXED: Added Analytics
    {
      'icon': Icons.analytics,
      'title': 'Analytics',
      'page': const AdminAnalytics()
    },
    {
      'icon': Icons.insights,
      'title': 'Customer Insights',
      'page': const AdminCustomerInsights()
    },
    {
      'icon': Icons.location_on,
      'title': 'Location Insights',
      'page': const AdminLocationInsights()
    },
    {
      'icon': Icons.psychology,
      'title': 'AI Monitoring',
      'page': const AdminAIMonitoring()
    },
    {
      'icon': Icons.notifications,
      'title': 'Notifications',
      'page': const AdminNotifications()
    },
    {'icon': Icons.person, 'title': 'My Profile', 'page': const ProfilePage()},
  ];

  final List<String> _titles = [
    'Dashboard',
    'Manage Users',
    'Manage Products',
    'Order Monitoring',
    'Payment Management',
    'Analytics',
    'Customer Insights',
    'Location Insights',
    'AI Monitoring',
    'Notifications',
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
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI'),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: const BoxDecoration(color: Color(0xFF59F797)),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings,
                        size: 35, color: Color(0xFF59F797)),
                  ),
                  const SizedBox(height: 8),
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
                              '${data['firstName'] ?? 'Admin'} ${data['lastName'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['email'] ?? 'admin@example.com',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        );
                      }
                      return const Text(
                        'Admin User',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _menuItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;
                  return ListTile(
                    dense: true,
                    leading: Icon(item['icon'],
                        size: 20,
                        color:
                            isSelected ? const Color(0xFF59F797) : Colors.grey),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF59F797)
                            : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
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
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, size: 20, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(fontSize: 11, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
            const SizedBox(height: 16),
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

// Admin Home Screen
class _AdminHomeScreen extends StatefulWidget {
  const _AdminHomeScreen();

  @override
  State<_AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<_AdminHomeScreen> {
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} • ${_getWeekday(now.weekday)}';
  }

  String _getWeekday(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF59F797), Color(0xFF3BC77A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Administrator!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Here\'s what\'s happening with your platform today',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  _getCurrentDate(),
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Cards
          const Text('Overview',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildStatsGrid(),

          const SizedBox(height: 16),

          // Quick Insights
          const Text('Quick Insights',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildQuickInsights(),

          const SizedBox(height: 16),

          // Recent Activity
          const Text('Recent Activity',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRecentActivity(),

          const SizedBox(height: 16),

          // Quick Actions
          const Text('Quick Actions',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildQuickActions(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        int totalUsers =
            userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
        int totalEntrepreneurs = 0;
        int totalCustomers = 0;
        if (userSnapshot.hasData) {
          totalEntrepreneurs = userSnapshot.data!.docs
              .where((doc) => doc.get('role') == 'entrepreneur')
              .length;
          totalCustomers = userSnapshot.data!.docs
              .where((doc) => doc.get('role') == 'customer')
              .length;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            int totalProducts =
                productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
            int activeProducts = 0;
            if (productSnapshot.hasData) {
              activeProducts = productSnapshot.data!.docs
                  .where((doc) => doc.get('isActive') == true)
                  .length;
            }

            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, orderSnapshot) {
                int totalOrders =
                    orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;
                int totalRevenue = 0;
                if (orderSnapshot.hasData) {
                  totalRevenue =
                      orderSnapshot.data!.docs.fold<int>(0, (sum, doc) {
                    final amount = doc.get('totalAmount');
                    return sum +
                        (amount is int
                            ? amount
                            : (amount is double ? amount.toInt() : 0));
                  });
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('payments')
                      .snapshots(),
                  builder: (context, paymentSnapshot) {
                    int totalPayments = paymentSnapshot.hasData
                        ? paymentSnapshot.data!.docs.length
                        : 0;

                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      children: [
                        _StatsCard(
                            title: 'Total Users',
                            value: totalUsers.toString(),
                            icon: Icons.people,
                            color: Colors.blue),
                        _StatsCard(
                            title: 'Customers',
                            value: totalCustomers.toString(),
                            icon: Icons.person,
                            color: Colors.green),
                        _StatsCard(
                            title: 'Entrepreneurs',
                            value: totalEntrepreneurs.toString(),
                            icon: Icons.business,
                            color: Colors.orange),
                        _StatsCard(
                            title: 'Total Products',
                            value: totalProducts.toString(),
                            icon: Icons.inventory,
                            color: const Color(0xFF59F797)),
                        _StatsCard(
                            title: 'Active Products',
                            value: activeProducts.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green),
                        _StatsCard(
                            title: 'Total Orders',
                            value: totalOrders.toString(),
                            icon: Icons.shopping_cart,
                            color: Colors.purple),
                        _StatsCard(
                            title: 'Total Payments',
                            value: totalPayments.toString(),
                            icon: Icons.payment,
                            color: Colors.teal),
                        _StatsCard(
                            title: 'Total Revenue',
                            value: 'TZS ${totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            color: Colors.red),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickInsights() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('likes', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;
        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child:
                    Text('No data available', style: TextStyle(fontSize: 11))),
          );
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          children: [
            _buildInsightCard(
              'Best Selling Product',
              products.isNotEmpty
                  ? products[0].get('productName') ?? 'N/A'
                  : 'N/A',
              Icons.trending_up,
              Colors.green,
            ),
            _buildInsightCard(
              'Top Entrepreneur',
              products.isNotEmpty
                  ? products[0].get('entrepreneurName') ?? 'N/A'
                  : 'N/A',
              Icons.business,
              Colors.orange,
            ),
            _buildInsightCard(
              'Most Active Customer',
              'Customer Data',
              Icons.people,
              Colors.blue,
            ),
            _buildInsightCard(
              'Top Revenue Category',
              'Electronics',
              Icons.category,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(title,
                      style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildActivityItem(Icons.person_add, 'New User Registration',
                'John Doe joined the platform', '2 min ago'),
            const Divider(height: 1),
            _buildActivityItem(Icons.add_box, 'New Product Added',
                'Bajaj Motorcycle was added', '15 min ago'),
            const Divider(height: 1),
            _buildActivityItem(Icons.shopping_cart, 'New Order',
                'Order #ORD-2026-001 placed', '1 hour ago'),
            const Divider(height: 1),
            _buildActivityItem(Icons.payment, 'New Payment',
                'Payment of TZS 250,000 received', '2 hours ago'),
            const Divider(height: 1),
            _buildActivityItem(Icons.warning, 'System Alert',
                'Low stock alert for Organic Coffee', '3 hours ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      IconData icon, String title, String subtitle, String time) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: const Color(0xFF59F797).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: const Color(0xFF59F797)),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      trailing:
          Text(time, style: TextStyle(fontSize: 8, color: Colors.grey[400])),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(Icons.people, 'Manage Users', () {}),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(Icons.inventory, 'Manage Products', () {}),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(Icons.analytics, 'Analytics', () {}),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(Icons.psychology, 'AI Monitor', () {}),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF59F797)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600])),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 8, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== AdminPaymentManagement Placeholder ====================
class AdminPaymentManagement extends StatelessWidget {
  const AdminPaymentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 64, color: Color(0xFF59F797)),
          SizedBox(height: 16),
          Text('Payment Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Coming Soon...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ==================== AdminAnalytics Placeholder ====================
class AdminAnalytics extends StatelessWidget {
  const AdminAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Color(0xFF59F797)),
          SizedBox(height: 16),
          Text('Analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Coming Soon...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
