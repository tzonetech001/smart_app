import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product_model.dart';

class EntrepreneurAnalyticsScreen extends StatefulWidget {
  const EntrepreneurAnalyticsScreen({super.key});

  @override
  State<EntrepreneurAnalyticsScreen> createState() => _EntrepreneurAnalyticsScreenState();
}

class _EntrepreneurAnalyticsScreenState extends State<EntrepreneurAnalyticsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  int _selectedTab = 0;
  String _selectedTimeframe = 'week';

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view analytics.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          _buildTimeframeSelector(),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          _buildTabs(),
          const SizedBox(height: 16),
          // Content based on selected tab
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _selectedTab == 0
                  ? _buildMarketTrends()
                  : _selectedTab == 1
                      ? _buildProductPerformance()
                      : _buildRevenueAnalytics(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['Week', 'Month', 'Year'];
    return PopupMenuButton<String>(
      icon: const Icon(Icons.calendar_today),
      onSelected: (value) {
        setState(() {
          _selectedTimeframe = value.toLowerCase();
        });
      },
      itemBuilder: (context) => timeframes.map((tf) => PopupMenuItem(
        value: tf.toLowerCase(),
        child: Text(tf, style: const TextStyle(fontSize: 12)),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(_selectedTimeframe.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Market Trends', 'Product Performance', 'Revenue'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF59F797) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== MARKET TRENDS ====================
  Widget _buildMarketTrends() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('entrepreneurId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        // Sort by engagement score
        products.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No products to analyze.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        final topProducts = products.take(5).toList();
        final totalEngagement = products.fold<double>(0, (sum, p) => sum + p.engagementScore);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Market Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMarketMetric('Total Products', products.length.toString(), Icons.inventory),
                    ),
                    Expanded(
                      child: _buildMarketMetric('Total Engagement', totalEngagement.round().toString(), Icons.trending_up),
                    ),
                    Expanded(
                      child: _buildMarketMetric('Top Product', topProducts.isNotEmpty ? topProducts.first.productName : 'N/A', Icons.leaderboard),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trending Products
            const Text('Trending Products', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...topProducts.map((product) => _buildTrendingProductCard(product, topProducts.indexOf(product))),

            const SizedBox(height: 16),

            // Market Trends Chart
            const Text('Market Trends', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 8)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (v.toInt() >= 0 && v.toInt() < days.length) {
                            return Text(days[v.toInt()], style: const TextStyle(fontSize: 8));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(7, (i) => FlSpot(i.toDouble(), 100 + i * 15 + (i % 3) * 10)),
                      isCurved: true,
                      color: const Color(0xFF59F797),
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF59F797).withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarketMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF59F797)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTrendingProductCard(ProductModel product, int rank) {
    final isTop = rank < 3;
    final color = isTop ? const Color(0xFF59F797) : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isTop ? const Color(0xFF59F797).withOpacity(0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${rank + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isTop ? const Color(0xFF59F797) : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('${product.likes} likes • ${product.views} views', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(product.engagementScore / 1000).toStringAsFixed(1)}K',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRODUCT PERFORMANCE ====================
  Widget _buildProductPerformance() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('entrepreneurId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No products to evaluate.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        // Calculate performance levels
        int high = 0, medium = 0, low = 0;
        for (var p in products) {
          if (p.engagementScore > 1000) high++;
          else if (p.engagementScore > 400) medium++;
          else low++;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPerformanceMetric('High', high.toString(), Icons.trending_up, Colors.green),
                    ),
                    Expanded(
                      child: _buildPerformanceMetric('Medium', medium.toString(), Icons.trending_flat, Colors.orange),
                    ),
                    Expanded(
                      child: _buildPerformanceMetric('Low', low.toString(), Icons.trending_down, Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Performance Distribution Chart
            const Text('Performance Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: high,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          high > 0 ? '$high' : '',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: medium,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          medium > 0 ? '$medium' : '',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: low,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          low > 0 ? '$low' : '',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('High', Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem('Medium', Colors.orange),
                const SizedBox(width: 16),
                _buildLegendItem('Low', Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // Individual Product Performance
            const Text('Product Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...products.map((product) => _buildProductPerformanceCard(product)),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductPerformanceCard(ProductModel product) {
    final performanceLevel = product.performanceLevel;
    final color = performanceLevel == 'HIGH PERFORMANCE'
        ? Colors.green
        : (performanceLevel == 'MEDIUM PERFORMANCE' ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                performanceLevel == 'HIGH PERFORMANCE' ? Icons.emoji_events : Icons.trending_up,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Text('Score: ${product.engagementScore.round()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          performanceLevel == 'HIGH PERFORMANCE'
                              ? '🔥 High'
                              : performanceLevel == 'MEDIUM PERFORMANCE'
                                  ? '📊 Medium'
                                  : '📉 Low',
                          style: TextStyle(fontSize: 9, color: color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text('${product.likes} ❤️', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ==================== REVENUE ANALYTICS ====================
  Widget _buildRevenueAnalytics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('entrepreneurId', isEqualTo: _userId)
          .where('status', isEqualTo: 'delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        double totalRevenue = 0;
        int totalOrders = orders.length;
        for (var order in orders) {
          totalRevenue += (order.get('totalAmount') ?? 0).toDouble();
        }
        final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRevenueMetric('Total Revenue', 'TZS ${totalRevenue.toStringAsFixed(0)}', Icons.attach_money),
                    ),
                    Expanded(
                      child: _buildRevenueMetric('Total Orders', totalOrders.toString(), Icons.shopping_bag),
                    ),
                    Expanded(
                      child: _buildRevenueMetric('Avg Order', 'TZS ${avgOrderValue.toStringAsFixed(0)}', Icons.trending_up),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Revenue Chart
            const Text('Revenue Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, m) => Text('TZS ${v.toInt()}', style: const TextStyle(fontSize: 8)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (v.toInt() >= 0 && v.toInt() < days.length) {
                            return Text(days[v.toInt()], style: const TextStyle(fontSize: 8));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: 1000 + i * 500 + (i % 3) * 200,
                          color: const Color(0xFF59F797),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF59F797)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}