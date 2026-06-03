import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../models/product_model.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  final AIService _aiService = AIService();
  bool _isLoading = true;
  Map<String, dynamic>? _predictions;
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('entrepreneurId', isEqualTo: authService.currentUser?.id)
        .get();
    
    _products = productsSnapshot.docs.map((doc) {
      return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
    
    final salesHistory = await _getSalesHistory();
    
    _predictions = await _aiService.getSalesPrediction(_products, salesHistory);
    _recommendations = _predictions?['recommendations'] ?? [];
    
    setState(() => _isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _getSalesHistory() async {
    return List.generate(30, (index) {
      return {
        'date': DateTime.now().subtract(Duration(days: index)),
        'sales': 100 + index * 5,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No products to analyze',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text('Add products to get AI predictions', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales Forecast Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF59F797), Color(0xFF3BC77A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Sales Forecast',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildForecastMetric(
                      'Next Week',
                      _predictions?['predictedSalesNextWeek'] ?? '0%',
                      Icons.trending_up,
                    ),
                    _buildForecastMetric(
                      'Demand Level',
                      _predictions?['demandLevel'] ?? 'MEDIUM',
                      Icons.analytics,
                    ),
                    _buildForecastMetric(
                      'Confidence',
                      '85%',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // AI Recommendations
          const Text(
            'AI Recommendations',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          if (_recommendations.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 12),
                    const Text(
                      'All products are performing well!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Continue monitoring for new insights',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final rec = _recommendations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: rec['priority'] == 'HIGH'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      child: Icon(
                        rec['priority'] == 'HIGH' ? Icons.priority_high : Icons.lightbulb,
                        size: 16,
                        color: rec['priority'] == 'HIGH' ? Colors.red : Colors.orange,
                      ),
                    ),
                    title: Text(rec['recommendation'], style: const TextStyle(fontSize: 12)),
                    subtitle: Text('Priority: ${rec['priority']}', style: const TextStyle(fontSize: 10)),
                    trailing: rec['priority'] == 'HIGH'
                        ? const Icon(Icons.warning, color: Colors.red, size: 18)
                        : null,
                  ),
                );
              },
            ),
          
          const SizedBox(height: 24),
          
          // Product Performance Analysis
          const Text(
            'Product Performance Analysis',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              double growthRate = product.engagementScore > 1000 ? 0.20 : 
                                 (product.engagementScore > 500 ? 0.10 : -0.05);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: growthRate > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              growthRate > 0 ? '+${(growthRate * 100).round()}%' : '${(growthRate * 100).round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: growthRate > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: product.engagementScore / 2000,
                        backgroundColor: Colors.grey[200],
                        color: growthRate > 0 ? const Color(0xFF59F797) : Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Engagement Score: ${product.engagementScore.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                          Text('Views: ${product.views}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Market Trends
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _aiService.getMarketTrends(_products),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              
              final trends = snapshot.data!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Market Trends',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trends.length,
                    itemBuilder: (context, index) {
                      final trend = trends[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.trending_up, color: Color(0xFF59F797), size: 18),
                          title: Text(trend['productName'], style: const TextStyle(fontSize: 12)),
                          subtitle: Text('${trend['category']} • ${trend['trendPercentage']} growth', style: const TextStyle(fontSize: 10)),
                          trailing: Text(
                            'Score: ${trend['engagementScore'].toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForecastMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}