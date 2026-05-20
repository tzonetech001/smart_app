import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product_model.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  String _selectedTimeframe = 'week';
  
  final List<Map<String, String>> _timeframes = [
    {'label': 'Week', 'value': 'week'},
    {'label': 'Month', 'value': 'month'},
    {'label': 'Year', 'value': 'year'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeframe Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _timeframes.map((tf) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(tf['label']!),
                  selected: _selectedTimeframe == tf['value'],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTimeframe = tf['value']!;
                      });
                    }
                  },
                  selectedColor: const Color(0xFF667eea).withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Revenue Chart
          const Text(
            'Revenue Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _buildRevenueChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Category Distribution
          const Text(
            'Products by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _buildCategoryChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Top Performing Products
          const Text(
            'Top Performing Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTopProducts(),
          
          const SizedBox(height: 24),
          
          // User Growth
          const Text(
            'User Growth',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _buildUserGrowthChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Key Metrics
          const Text(
            'Key Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildKeyMetrics(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenueData = _getRevenueData();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text('\$${value.toInt()}');
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(revenueData[value.toInt()]['label']);
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: revenueData.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value['value']);
                }).toList(),
                isCurved: true,
                color: const Color(0xFF667eea),
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF667eea).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getRevenueData() {
    // Sample revenue data
    if (_selectedTimeframe == 'week') {
      return [
        {'label': 'Mon', 'value': 1250},
        {'label': 'Tue', 'value': 1480},
        {'label': 'Wed', 'value': 1320},
        {'label': 'Thu', 'value': 1650},
        {'label': 'Fri', 'value': 1890},
        {'label': 'Sat', 'value': 2100},
        {'label': 'Sun', 'value': 1950},
      ];
    } else if (_selectedTimeframe == 'month') {
      return List.generate(4, (i) {
        return {'label': 'Week ${i + 1}', 'value': 5000 + (i * 1500)};
      });
    } else {
      return List.generate(12, (i) {
        return {'label': '${i + 1}', 'value': 15000 + (i * 2000)};
      });
    }
  }

  Widget _buildCategoryChart() {
    return FutureBuilder<Map<String, int>>(
      future: _getCategoryDistribution(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data!;
        final total = data.values.fold(0, (a, b) => a + b);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: data.entries.map((entry) {
                        final percentage = (entry.value / total) * 100;
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: _getCategoryColor(entry.key),
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: data.entries.map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${entry.key}: ${entry.value}'),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getCategoryDistribution() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final Map<String, int> distribution = {};
    
    for (var doc in snapshot.docs) {
      final category = doc.get('category') as String;
      distribution[category] = (distribution[category] ?? 0) + 1;
    }
    
    return distribution;
  }

  Color _getCategoryColor(String category) {
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
    ];
    
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildTopProducts() {
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
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF667eea),
                  child: Text('${index + 1}'),
                ),
                title: Text(product.get('productName')),
                subtitle: Text('${product.get('likes')} likes • ${product.get('views')} views'),
                trailing: Text(
                  '\$${product.get('price').toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserGrowthChart() {
    final growthData = _getUserGrowthData();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(growthData[value.toInt()]['label']);
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            barGroups: growthData.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value['value'].toDouble(),
                    color: const Color(0xFF667eea),
                    width: 20,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getUserGrowthData() {
    if (_selectedTimeframe == 'week') {
      return [
        {'label': 'Mon', 'value': 5},
        {'label': 'Tue', 'value': 8},
        {'label': 'Wed', 'value': 12},
        {'label': 'Thu', 'value': 7},
        {'label': 'Fri', 'value': 15},
        {'label': 'Sat', 'value': 20},
        {'label': 'Sun', 'value': 18},
      ];
    } else if (_selectedTimeframe == 'month') {
      return List.generate(4, (i) {
        return {'label': 'Week ${i + 1}', 'value': 25 + (i * 10)};
      });
    } else {
      return List.generate(12, (i) {
        return {'label': '${i + 1}', 'value': 50 + (i * 15)};
      });
    }
  }

  Widget _buildKeyMetrics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        final totalUsers = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
        final entrepreneurs = userSnapshot.hasData 
            ? userSnapshot.data!.docs.where((d) => d.get('role') == 'entrepreneur').length
            : 0;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            final totalProducts = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;
            final totalLikes = productSnapshot.hasData
                ? productSnapshot.data!.docs.fold<int>(0, (sum, doc) => sum + (doc.get('likes') ?? 0))
                : 0;
            
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
                _buildMetricCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue),
                _buildMetricCard('Entrepreneurs', entrepreneurs.toString(), Icons.business, Colors.orange),
                _buildMetricCard('Total Products', totalProducts.toString(), Icons.inventory, Colors.green),
                _buildMetricCard('Total Likes', totalLikes.toString(), Icons.favorite, Colors.red),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
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
                fontSize: 24,
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