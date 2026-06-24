import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCustomerInsights extends StatefulWidget {
  const AdminCustomerInsights({super.key});

  @override
  State<AdminCustomerInsights> createState() => _AdminCustomerInsightsState();
}

class _AdminCustomerInsightsState extends State<AdminCustomerInsights> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Behaviour Metrics
          const Text(
            'Customer Behaviour Metrics',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildBehaviourMetrics(),
          
          const SizedBox(height: 16),
          
          // Most Purchased Products
          const Text(
            'Most Purchased Products',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildMostPurchasedProducts(),
          
          const SizedBox(height: 16),
          
          // Customer Segments
          const Text(
            'Customer Segments',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCustomerSegments(),
          
          const SizedBox(height: 16),
          
          // Behaviour Insights
          const Text(
            'Behaviour Insights',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildBehaviourInsights(),
        ],
      ),
    );
  }

  Widget _buildBehaviourMetrics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final orders = orderSnapshot.data!.docs;
        final totalOrders = orders.length;
        double totalRevenue = 0;
        for (var order in orders) {
          totalRevenue += (order.get('totalAmount') ?? 0).toDouble();
        }
        final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
        
        // Count unique customers
        final customerIds = <String>{};
        for (var order in orders) {
          final userId = order.get('userId') as String?;
          if (userId != null) {
            customerIds.add(userId);
          }
        }
        final totalCustomers = customerIds.length;
        
        // Count repeat customers
        final customerOrderCount = <String, int>{};
        for (var order in orders) {
          final userId = order.get('userId') as String?;
          if (userId != null) {
            customerOrderCount[userId] = (customerOrderCount[userId] ?? 0) + 1;
          }
        }
        final repeatCustomers = customerOrderCount.values.where((count) => count > 1).length;
        final repeatRate = totalCustomers > 0 ? (repeatCustomers / totalCustomers * 100).round() : 0;
        
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          children: [
            _buildMetricCard('Total Orders', totalOrders.toString(), Icons.shopping_cart, Colors.blue),
            _buildMetricCard('Total Customers', totalCustomers.toString(), Icons.people, Colors.green),
            _buildMetricCard('Repeat Rate', '$repeatRate%', Icons.repeat, Colors.orange),
            _buildMetricCard('Avg Order', 'TZS ${avgOrderValue.toStringAsFixed(0)}', Icons.attach_money, const Color(0xFF59F797)),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostPurchasedProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Use Map<String, int> for productCount and Map<String, String> for productNames
        final productCount = <String, int>{};
        final productNames = <String, String>{};
        
        for (var order in snapshot.data!.docs) {
          final items = order.get('items') as List? ?? [];
          for (var item in items) {
            final id = item['productId'] as String? ?? '';
            final name = item['productName'] as String? ?? 'Unknown';
            // Convert qty to int safely
            final qty = (item['quantity'] as num?)?.toInt() ?? 0;
            
            if (id.isNotEmpty) {
              productCount[id] = (productCount[id] ?? 0) + qty;
              if (name.isNotEmpty) {
                productNames[id] = name;
              }
            }
          }
        }
        
        final sortedProducts = productCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final topProducts = sortedProducts.take(5).toList();
        
        if (topProducts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No products found', style: TextStyle(fontSize: 11)),
            ),
          );
        }
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: topProducts.map((entry) {
                final index = topProducts.indexOf(entry);
                final productName = productNames[entry.key] ?? 'Unknown';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF59F797).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF59F797),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value} units',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF59F797),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerSegments() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      children: [
        _buildSegmentCard('New Customers', '24', Icons.person_add, Colors.blue),
        _buildSegmentCard('Returning Customers', '67', Icons.repeat, Colors.green),
        _buildSegmentCard('Loyal Customers', '34', Icons.star, Colors.orange),
        _buildSegmentCard('High Value Customers', '12', Icons.attach_money, Colors.purple),
      ],
    );
  }

  Widget _buildSegmentCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviourInsights() {
    final insights = [
      {'title': 'Frequently Bought Together', 'subtitle': 'Coffee + Snacks + Sugar', 'icon': Icons.shopping_cart},
      {'title': 'Popular Shopping Times', 'subtitle': 'Weekdays 7PM - 9PM', 'icon': Icons.access_time},
      {'title': 'Customer Spending Trends', 'subtitle': 'Average order up 15% this month', 'icon': Icons.trending_up},
    ];
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: insights.map((insight) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF59F797).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    insight['icon'] as IconData,
                    size: 16,
                    color: const Color(0xFF59F797),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] as String,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        insight['subtitle'] as String,
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}