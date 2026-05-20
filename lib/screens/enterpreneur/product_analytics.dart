import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';

class ProductAnalytics extends StatefulWidget {
  const ProductAnalytics({super.key});

  @override
  State<ProductAnalytics> createState() => _ProductAnalyticsState();
}

class _ProductAnalyticsState extends State<ProductAnalytics> {
  String? _selectedProductId;
  List<ProductModel> _products = [];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('entrepreneurId', isEqualTo: authService.currentUser?.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        _products = snapshot.data!.docs.map((doc) {
          return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        
        if (_products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products to analyze',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text('Add products to see analytics'),
              ],
            ),
          );
        }
        
        // Select first product if none selected
        if (_selectedProductId == null && _products.isNotEmpty) {
          _selectedProductId = _products.first.id;
        }
        
        final selectedProduct = _products.firstWhere(
          (p) => p.id == _selectedProductId,
          orElse: () => _products.first,
        );
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProductId,
                    isExpanded: true,
                    items: _products.map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text(product.productName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Performance Card
              _buildPerformanceCard(selectedProduct),
              
              const SizedBox(height: 24),
              
              // Engagement Metrics
              const Text(
                'Engagement Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildEngagementMetrics(selectedProduct),
              
              const SizedBox(height: 24),
              
              // Engagement Chart
              const Text(
                'Engagement Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildEngagementChart(selectedProduct),
              
              const SizedBox(height: 24),
              
              // Product Insights
              const Text(
                'Product Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInsights(selectedProduct),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceCard(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance Level',
                style: TextStyle(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: product.performanceLevel == 'HIGH PERFORMANCE'
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.performanceLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Engagement Score', product.engagementScore.toStringAsFixed(0)),
              _buildMetric('Views', product.views.toString()),
              _buildMetric('Likes', product.likes.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics(ProductModel product) {
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
        _MetricCard(
          title: 'Rating',
          value: product.rating.toStringAsFixed(1),
          icon: Icons.star,
          color: Colors.amber,
          suffix: '/5',
        ),
        _MetricCard(
          title: 'Comments',
          value: product.comments.toString(),
          icon: Icons.comment,
          color: Colors.blue,
        ),
        _MetricCard(
          title: 'Conversion Rate',
          value: _calculateConversionRate(product),
          icon: Icons.trending_up,
          color: Colors.green,
          suffix: '%',
        ),
        _MetricCard(
          title: 'Stock Status',
          value: product.stock > 50 ? 'High' : (product.stock > 10 ? 'Medium' : 'Low'),
          icon: Icons.inventory,
          color: product.stock > 50 ? Colors.green : (product.stock > 10 ? Colors.orange : Colors.red),
        ),
      ],
    );
  }

  String _calculateConversionRate(ProductModel product) {
    if (product.views == 0) return '0';
    double rate = (product.likes / product.views) * 100;
    return rate.toStringAsFixed(1);
  }

  Widget _buildEngagementChart(ProductModel product) {
    // Sample engagement data over last 7 days
    final List<double> engagementData = [
      product.engagementScore * 0.6,
      product.engagementScore * 0.7,
      product.engagementScore * 0.8,
      product.engagementScore * 0.85,
      product.engagementScore * 0.9,
      product.engagementScore * 0.95,
      product.engagementScore,
    ];
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(engagementData.length, (index) {
                return FlSpot(index.toDouble(), engagementData[index]);
              }),
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
    );
  }

  Widget _buildInsights(ProductModel product) {
    final insights = <String>[];
    
    if (product.engagementScore > 1000) {
      insights.add('✓ Excellent engagement! Your product is performing exceptionally well.');
      insights.add('✓ Consider expanding this product line based on demand.');
    } else if (product.engagementScore > 500) {
      insights.add('✓ Good performance. Keep engaging with customers.');
      insights.add('✓ Run targeted promotions to boost sales.');
    } else {
      insights.add('⚠️ Low engagement detected. Consider improving product visibility.');
      insights.add('⚠️ Run marketing campaigns to increase awareness.');
    }
    
    if (product.stock < 20 && product.engagementScore > 500) {
      insights.add('⚠️ Low stock alert! Restock soon to meet demand.');
    }
    
    if (product.rating < 3.0 && product.comments > 5) {
      insights.add('⚠️ Customer feedback indicates areas for improvement.');
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(insights[index]),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '$value${suffix ?? ''}',
              style: TextStyle(
                fontSize: 20,
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