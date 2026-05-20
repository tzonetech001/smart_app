import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'admin_user_management.dart';
import 'admin_product_management.dart';
import 'admin_analytics.dart';
import '../../widgets/chart_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const _AdminHomeScreen(),
    const AdminUserManagement(),
    const AdminProductManagement(),
    const AdminAnalytics(),
  ];
  
  final List<String> _titles = [
    'Admin Dashboard',
    'User Management',
    'Product Management',
    'Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF667eea),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class _AdminHomeScreen extends StatelessWidget {
  const _AdminHomeScreen();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome, Admin',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here\'s what\'s happening with your business today',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Stats Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              int totalUsers = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, productSnapshot) {
                  int totalProducts = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
                  
                  // Count entrepreneurs
                  int totalEntrepreneurs = 0;
                  if (userSnapshot.hasData) {
                    totalEntrepreneurs = userSnapshot.data!.docs.where((doc) {
                      return doc.get('role') == 'entrepreneur';
                    }).length;
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
                      _StatsCard(
                        title: 'Total Users',
                        value: totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _StatsCard(
                        title: 'Total Products',
                        value: totalProducts.toString(),
                        icon: Icons.inventory,
                        color: Colors.green,
                      ),
                      _StatsCard(
                        title: 'Entrepreneurs',
                        value: totalEntrepreneurs.toString(),
                        icon: Icons.business,
                        color: Colors.orange,
                      ),
                      _StatsCard(
                        title: 'Active Products',
                        value: '${totalProducts ~/ 2}',
                        icon: Icons.check_circle,
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Trending Products
          const Text(
            'Trending Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
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
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: product.get('imageUrl') != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(product.get('imageUrl')),
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.image),
                            ),
                      title: Text(product.get('productName')),
                      subtitle: Text('Likes: ${product.get('likes')} | Views: ${product.get('views')}'),
                      trailing: const Icon(Icons.trending_up, color: Colors.green),
                    ),
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Sales Chart
          const Text(
            'Sales Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SimpleBarChart(
                  data: [50, 75, 100, 125, 150, 200, 175],
                  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                ),
              ),
            ),
          ),
        ],
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}