import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  bool _isLoading = true;
  List<ProductModel> _products = [];
  List<ProductPredictionData> _predictions = [];
  int _selectedProductIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    // Get entrepreneur's products
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('entrepreneurId', isEqualTo: authService.currentUser?.id)
        .get();

    _products = productsSnapshot.docs.map((doc) {
      return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    // Generate predictions for each product
    for (var product in _products) {
      final prediction = await _generateProductPrediction(product);
      _predictions.add(prediction);
    }

    setState(() => _isLoading = false);
  }

  Future<ProductPredictionData> _generateProductPrediction(
      ProductModel product) async {
    // Get sales history for this product
    final salesHistory = await _getProductSalesHistory(product.id);

    // Calculate metrics
    final double engagementScore = product.engagementScore.toDouble();
    final int engagementScoreInt = engagementScore.round();
    final views = product.views.toInt();
    final likes = product.likes.toInt();
    final comments = product.comments;
    final rating = product.rating;
    final stock = product.stock.toInt();
    final price = product.price;

    // Sales Forecast Calculation
    double forecastGrowth =
        _calculateForecastGrowth(salesHistory, engagementScore);
    int predictedSales = _calculatePredictedSales(salesHistory, forecastGrowth);

    // Demand Score Calculation (0-100)
    int demandScore =
        _calculateDemandScore(engagementScore, views, likes, stock, rating);
    String demandLevel = _getDemandLevel(demandScore);
    Color demandColor = _getDemandColor(demandScore);

    // Generate Recommendations
    List<Recommendation> recommendations = _generateRecommendations(product,
        demandScore, engagementScore, stock, views, likes, rating, price);

    return ProductPredictionData(
      productId: product.id,
      productName: product.productName,
      productImage: product.imageUrl,
      productCategory: product.category.displayName,
      price: price,
      stock: stock,
      rating: rating,
      forecastGrowth: forecastGrowth,
      predictedSales: predictedSales,
      demandScore: demandScore,
      demandLevel: demandLevel,
      demandColor: demandColor,
      recommendations: recommendations,
      engagementScore: engagementScoreInt,
      views: views,
      likes: likes,
      comments: comments,
    );
  }

  double _calculateForecastGrowth(
      List<double> salesHistory, double engagementScore) {
    if (salesHistory.length >= 4) {
      // Use weighted moving average
      final weights = [0.4, 0.3, 0.2, 0.1];
      double weightedSum = 0;
      for (int i = 0; i < 4 && i < salesHistory.length; i++) {
        weightedSum += salesHistory[i] * weights[i];
      }
      final recentAvg = weightedSum /
          weights.take(salesHistory.length).fold(0, (a, b) => a + b);
      final lastSale = salesHistory.first;

      if (recentAvg > 0) {
        double growth = ((lastSale - recentAvg) / recentAvg) * 100;
        return growth.clamp(-30, 50).toDouble();
      }
    }

    // Fallback: Use engagement score
    double growth = (engagementScore / 2000) * 60 - 20;
    return growth.clamp(-30, 50).toDouble();
  }

  int _calculatePredictedSales(
      List<double> salesHistory, double forecastGrowth) {
    if (salesHistory.isNotEmpty) {
      final currentSales = salesHistory.first;
      return (currentSales * (1 + (forecastGrowth / 100))).round();
    }
    return 100 + (forecastGrowth.round());
  }

  int _calculateDemandScore(
      double engagement, int views, int likes, int stock, double rating) {
    double score = 0;

    // Engagement Score (35% weight) - Max 2000 engagement
    score += (engagement / 2000).clamp(0, 1) * 35;

    // Conversion Rate (25% weight)
    double conversionRate = views > 0 ? (likes / views) : 0;
    score += conversionRate.clamp(0, 1) * 25;

    // Stock Score (20% weight) - Lower stock = higher demand
    double stockScore =
        stock < 10 ? 1 : (stock < 30 ? 0.7 : (stock < 100 ? 0.4 : 0.2));
    score += stockScore * 20;

    // Rating Score (20% weight)
    score += (rating / 5).clamp(0, 1) * 20;

    return score.round().clamp(0, 100);
  }

  String _getDemandLevel(int score) {
    if (score >= 80) return 'VERY HIGH';
    if (score >= 60) return 'HIGH';
    if (score >= 40) return 'MEDIUM';
    if (score >= 20) return 'LOW';
    return 'CRITICAL';
  }

  Color _getDemandColor(int score) {
    if (score >= 80) return Colors.deepPurple;
    if (score >= 60) return Colors.green;
    if (score >= 40) return const Color(0xFF59F797);
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  List<Recommendation> _generateRecommendations(
    ProductModel product,
    int demandScore,
    double engagementScore,
    int stock,
    int views,
    int likes,
    double rating,
    double price,
  ) {
    final recommendations = <Recommendation>[];

    // Stock Recommendations
    if (demandScore >= 60 && stock < 30) {
      recommendations.add(Recommendation(
        title: '📦 Increase Stock',
        message: 'High demand detected with only $stock units left',
        action: 'Order ${(50 - stock).clamp(20, 100)} more units immediately',
        priority: 'HIGH',
        icon: Icons.inventory,
      ));
    } else if (stock > 100 && demandScore < 40) {
      recommendations.add(Recommendation(
        title: '🏷️ Reduce Stock',
        message: 'Low demand with excess stock ($stock units)',
        action: 'Run a promotion or discount to clear inventory',
        priority: 'MEDIUM',
        icon: Icons.local_offer,
      ));
    }

    // Engagement Recommendations
    if (engagementScore < 300) {
      recommendations.add(Recommendation(
        title: '📢 Improve Visibility',
        message: 'Low customer engagement detected',
        action: 'Run social media campaign or improve product images',
        priority: 'HIGH',
        icon: Icons.visibility,
      ));
    } else if (engagementScore > 1000) {
      recommendations.add(Recommendation(
        title: '🚀 Expand Product Line',
        message: 'Excellent engagement! Your product is trending',
        action: 'Consider adding variations, bundles, or accessories',
        priority: 'MEDIUM',
        icon: Icons.trending_up,
      ));
    }

    // Rating Recommendations
    if (rating < 3.0 && product.comments > 5) {
      recommendations.add(Recommendation(
        title: '⭐ Quality Improvement',
        message:
            'Customer feedback indicates quality issues (${rating.toStringAsFixed(1)}⭐)',
        action: 'Review customer comments and make product improvements',
        priority: 'HIGH',
        icon: Icons.star,
      ));
    } else if (rating > 4.5 && product.comments > 10) {
      recommendations.add(Recommendation(
        title: '✨ Highlight Success',
        message: 'Excellent customer satisfaction',
        action: 'Feature as "Best Seller" and showcase testimonials',
        priority: 'LOW',
        icon: Icons.emoji_events,
      ));
    }

    // Conversion Rate Recommendations
    final conversionRate = views > 0 ? (likes / views) * 100 : 0;
    if (views > 200 && conversionRate < 10) {
      recommendations.add(Recommendation(
        title: '🎯 Optimize Listing',
        message:
            'High views (${views.toInt()}) but low conversion rate (${conversionRate.toInt()}%)',
        action: 'Improve product description, images, and pricing strategy',
        priority: 'MEDIUM',
        icon: Icons.tune,
      ));
    }

    // Price Recommendations
    if (price > 200 && engagementScore < 200) {
      recommendations.add(Recommendation(
        title: '💰 Review Pricing',
        message: 'High price but low engagement',
        action: 'Consider price reduction or bundle offers',
        priority: 'LOW',
        icon: Icons.attach_money,
      ));
    } else if (price < 20 && engagementScore > 800) {
      recommendations.add(Recommendation(
        title: '💎 Increase Price',
        message: 'High demand with low price point',
        action: 'Consider increasing price by 10-20% to maximize profit',
        priority: 'LOW',
        icon: Icons.trending_up,
      ));
    }

    // Add default recommendation if none
    if (recommendations.isEmpty) {
      recommendations.add(Recommendation(
        title: '✅ Maintain Performance',
        message: 'Your product is performing well',
        action: 'Continue monitoring and engaging with customers',
        priority: 'LOW',
        icon: Icons.check_circle,
      ));
    }

    // Sort by priority (HIGH > MEDIUM > LOW)
    recommendations.sort((a, b) {
      final priorityOrder = {'HIGH': 3, 'MEDIUM': 2, 'LOW': 1};
      return priorityOrder[b.priority]!.compareTo(priorityOrder[a.priority]!);
    });

    return recommendations;
  }

  Future<List<double>> _getProductSalesHistory(String productId) async {
    final List<double> history = [];

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(8)
          .get();

      if (ordersSnapshot.docs.isNotEmpty) {
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['totalAmount'] ?? 0).toDouble();
          history.add(amount);
        }
        return history;
      }
    } catch (e) {
      // No orders collection
    }

    // Generate sample sales history based on engagement score
    final product = _products.firstWhere((p) => p.id == productId,
        orElse: () => _products.first);
    final baseSales = 50 + (product.engagementScore / 100).round();

    for (int i = 0; i < 8; i++) {
      final weekSales = baseSales + (i * 3) + (product.likes % 30);
      history.add(weekSales.toDouble());
    }
    history.sort((a, b) => b.compareTo(a));

    return history;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[50],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing each product...', style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              Text('AI is generating predictions',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No products to analyze',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Add products to get AI predictions for each product',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    final currentPrediction = _predictions[_selectedProductIndex];
    final currentProduct = _products[_selectedProductIndex];

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Product Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 85,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final prediction = _predictions[index];
                      final isSelected = _selectedProductIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProductIndex = index;
                          });
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF59F797).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF59F797)
                                  : Colors.grey[200]!,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Product Image or Icon
                              product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.imageUrl!,
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 40,
                                          width: 40,
                                          color: Colors.grey[200],
                                          child:
                                              const Icon(Icons.image, size: 20),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.shopping_bag,
                                          size: 20, color: Colors.grey),
                                    ),
                              const SizedBox(height: 6),
                              Text(
                                product.productName.length > 12
                                    ? '${product.productName.substring(0, 10)}...'
                                    : product.productName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF59F797)
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              // Demand indicator
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 30,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: prediction.demandColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Predictions Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header Card
                  _buildProductHeader(currentProduct, currentPrediction),
                  const SizedBox(height: 16),

                  // Key Metrics Row
                  Row(
                    children: [
                      Expanded(
                          child: _buildSalesForecastCard(currentPrediction)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDemandScoreCard(currentPrediction)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Predicted Sales Card
                  _buildPredictedSalesCard(currentPrediction),
                  const SizedBox(height: 16),

                  // Engagement Metrics Card
                  _buildEngagementMetricsCard(currentPrediction),
                  const SizedBox(height: 16),

                  // Recommendations Card
                  _buildRecommendationsCard(currentPrediction),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader(
      ProductModel product, ProductPredictionData prediction) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 70,
                        width: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 35),
                      ),
                    )
                  : Container(
                      height: 70,
                      width: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_bag, size: 35),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prediction.productCategory,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF59F797).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_money,
                                size: 12, color: Color(0xFF59F797)),
                            const SizedBox(width: 2),
                            Text(
                              product.price.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF59F797)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              'Stock: ${prediction.stock}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              prediction.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesForecastCard(ProductPredictionData prediction) {
    final isPositive = prediction.forecastGrowth >= 0;
    final growthText = isPositive
        ? '+${prediction.forecastGrowth.round()}'
        : '${prediction.forecastGrowth.round()}';
    final growthColor = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Icon(Icons.trending_up, size: 24, color: Color(0xFF59F797)),
            const SizedBox(height: 8),
            Text(
              'Sales Forecast',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '$growthText%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: growthColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'vs last week',
              style: TextStyle(fontSize: 9, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandScoreCard(ProductPredictionData prediction) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Icon(Icons.analytics, size: 24, color: Color(0xFF59F797)),
            const SizedBox(height: 8),
            Text(
              'Demand Score',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '${prediction.demandScore}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: prediction.demandColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: prediction.demandColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prediction.demandLevel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: prediction.demandColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictedSalesCard(ProductPredictionData prediction) {
    final currentSales =
        (prediction.predictedSales / (1 + prediction.forecastGrowth / 100))
            .round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Next Week Sales Prediction',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${prediction.predictedSales}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF59F797),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Current: \$$currentSales',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetricsCard(ProductPredictionData prediction) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Engagement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEngagementMetric('Views', prediction.views.toString(),
                    Icons.visibility, Colors.blue),
                _buildEngagementMetric('Likes', prediction.likes.toString(),
                    Icons.favorite, Colors.red),
                _buildEngagementMetric(
                    'Comments',
                    prediction.comments.toString(),
                    Icons.comment,
                    Colors.orange),
                _buildEngagementMetric(
                    'Score',
                    prediction.engagementScore.toString(),
                    Icons.trending_up,
                    const Color(0xFF59F797)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard(ProductPredictionData prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF59F797), size: 18),
            SizedBox(width: 8),
            Text(
              'AI Recommendations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...prediction.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: rec.priority == 'HIGH'
                        ? Colors.red.withOpacity(0.3)
                        : (rec.priority == 'MEDIUM'
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3)),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: rec.priority == 'HIGH'
                              ? Colors.red.withOpacity(0.1)
                              : (rec.priority == 'MEDIUM'
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          rec.icon,
                          size: 20,
                          color: rec.priority == 'HIGH'
                              ? Colors.red
                              : (rec.priority == 'MEDIUM'
                                  ? Colors.orange
                                  : Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rec.title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rec.message,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF59F797).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rec.action,
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF59F797)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rec.priority == 'HIGH'
                              ? Colors.red.withOpacity(0.1)
                              : (rec.priority == 'MEDIUM'
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rec.priority,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: rec.priority == 'HIGH'
                                ? Colors.red
                                : (rec.priority == 'MEDIUM'
                                    ? Colors.orange
                                    : Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

// Data Models
class ProductPredictionData {
  final String productId;
  final String productName;
  final String? productImage;
  final String productCategory;
  final double price;
  final int stock;
  final double rating;
  final double forecastGrowth;
  final int predictedSales;
  final int demandScore;
  final String demandLevel;
  final Color demandColor;
  final List<Recommendation> recommendations;
  final int engagementScore;
  final int views;
  final int likes;
  final int comments;

  ProductPredictionData({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.productCategory,
    required this.price,
    required this.stock,
    required this.rating,
    required this.forecastGrowth,
    required this.predictedSales,
    required this.demandScore,
    required this.demandLevel,
    required this.demandColor,
    required this.recommendations,
    required this.engagementScore,
    required this.views,
    required this.likes,
    required this.comments,
  });
}

class Recommendation {
  final String title;
  final String message;
  final String action;
  final String priority;
  final IconData icon;

  Recommendation({
    required this.title,
    required this.message,
    required this.action,
    required this.priority,
    required this.icon,
  });
}
