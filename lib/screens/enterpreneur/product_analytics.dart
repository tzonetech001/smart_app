import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';

class ProductAnalytics extends StatefulWidget {
  final int initialSubmenuIndex;

  const ProductAnalytics({super.key, this.initialSubmenuIndex = 0});

  @override
  State<ProductAnalytics> createState() => _ProductAnalyticsState();
}

class _ProductAnalyticsState extends State<ProductAnalytics> {
  String? _selectedProductId;
  List<ProductModel> _products = [];
  late int _selectedSubmenuIndex;

  @override
  void initState() {
    super.initState();
    _selectedSubmenuIndex = widget.initialSubmenuIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Product Selector Dropdown - Fixed at top
          Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('entrepreneurId', isEqualTo: authService.currentUser?.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                _products = snapshot.data!.docs.map((doc) {
                  return ProductModel.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

                if (_products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No products to analyze',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('Add products to see analytics',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }

                if (_selectedProductId == null && _products.isNotEmpty) {
                  _selectedProductId = _products.first.id;
                }

                final selectedProduct = _products.firstWhere(
                  (p) => p.id == _selectedProductId,
                  orElse: () => _products.first,
                );

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Product Dropdown
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
                              style: const TextStyle(fontSize: 12),
                              items: _products.map((product) {
                                return DropdownMenuItem(
                                  value: product.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: product.imageUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  product.imageUrl!,
                                                  width: 30,
                                                  height: 30,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.image, size: 16, color: Colors.grey),
                                                ),
                                              )
                                            : const Icon(Icons.image, size: 16, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          product.productName,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Dynamic Content - Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('entrepreneurId', isEqualTo: authService.currentUser?.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _products = snapshot.data!.docs.map((doc) {
                    return ProductModel.fromMap(
                        doc.id, doc.data() as Map<String, dynamic>);
                  }).toList();

                  if (_products.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  if (_selectedProductId == null && _products.isNotEmpty) {
                    _selectedProductId = _products.first.id;
                  }

                  final selectedProduct = _products.firstWhere(
                    (p) => p.id == _selectedProductId,
                    orElse: () => _products.first,
                  );

                  return _buildDynamicContent(selectedProduct);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent(ProductModel selectedProduct) {
    if (_selectedSubmenuIndex == 0) {
      return _buildPerformanceContent(selectedProduct);
    } else if (_selectedSubmenuIndex == 1) {
      return _buildMarketTrendsContent(selectedProduct);
    } else {
      return _buildCustomerInsightsContent(selectedProduct.id);
    }
  }

  // ==================== SECTION 1: PRODUCT PERFORMANCE LEVEL CONTENT ====================
  Widget _buildPerformanceContent(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF59F797), Color(0xFF3BC77A)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Performance Level',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.performanceLevel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.performanceLevel == 'HIGH PERFORMANCE'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPerformanceMetric('Engagement Score',
                      product.engagementScore.toStringAsFixed(0)),
                  _buildPerformanceMetric('Views', product.views.toString()),
                  _buildPerformanceMetric('Likes', product.likes.toString()),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Engagement Metrics Grid
        const Text('Engagement Metrics',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          children: [
            _buildMetricCard('Rating', product.rating.toStringAsFixed(1),
                Icons.star, Colors.amber, '/5'),
            _buildMetricCard('Comments', product.comments.toString(),
                Icons.comment, Colors.blue, ''),
            _buildMetricCard(
                'Conversion Rate',
                _calculateConversionRate(product),
                Icons.trending_up,
                Colors.green,
                '%'),
            _buildMetricCard(
                'Stock Status',
                product.stock > 50
                    ? 'High'
                    : (product.stock > 10 ? 'Medium' : 'Low'),
                Icons.inventory,
                product.stock > 50
                    ? Colors.green
                    : (product.stock > 10 ? Colors.orange : Colors.red),
                ''),
          ],
        ),

        const SizedBox(height: 20),

        // Engagement Trend Chart
        const Text('Engagement Trend',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _buildEngagementChart(product),
        ),

        const SizedBox(height: 20),

        // Performance Insights
        const Text('Performance Insights',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildPerformanceInsights(product),
      ],
    );
  }

  // ==================== SECTION 2: MARKET TRENDS CONTENT ====================
  Widget _buildMarketTrendsContent(ProductModel currentProduct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('Market Position',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allProducts = snapshot.data!.docs.map((doc) {
                      return ProductModel.fromMap(
                          doc.id, doc.data() as Map<String, dynamic>);
                    }).toList();

                    allProducts.sort((a, b) =>
                        b.engagementScore.compareTo(a.engagementScore));

                    final rank = allProducts
                            .indexWhere((p) => p.id == currentProduct.id) +
                        1;
                    final total = allProducts.length;
                    final percentile = total > 0
                        ? ((total - rank) / total * 100).round()
                        : 0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMarketStat('Rank', '#$rank of $total',
                            Icons.leaderboard, Colors.blue),
                        _buildMarketStat('Percentile', 'Top ${percentile}%',
                            Icons.percent, const Color(0xFF59F797)),
                        _buildMarketStat(
                            'Score',
                            currentProduct.engagementScore.round().toString(),
                            Icons.score,
                            Colors.orange),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text('Similar Products in Market',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('category',
                  isEqualTo: currentProduct.category.toString().split('.').last)
              .where('isActive', isEqualTo: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var similarProducts = snapshot.data!.docs.map((doc) {
              return ProductModel.fromMap(
                  doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            similarProducts.sort((a, b) =>
                b.engagementScore.compareTo(a.engagementScore));

            if (similarProducts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('No similar products found',
                        style: TextStyle(fontSize: 11, color: Colors.grey))),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: similarProducts.length,
              itemBuilder: (context, index) {
                final product = similarProducts[index];
                final isCurrent = product.id == currentProduct.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF59F797).withOpacity(0.05)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF59F797).withOpacity(0.2)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          size: 18,
                          color: isCurrent
                              ? const Color(0xFF59F797)
                              : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        product.productName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                          '${product.likes} likes • ${product.views} views',
                          style: const TextStyle(fontSize: 9)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF59F797)),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF59F797),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('Current',
                                  style: TextStyle(
                                      fontSize: 7, color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 20),

        const Text('Market Opportunities',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildMarketOpportunities(currentProduct),
      ],
    );
  }

  // ==================== SECTION 3: CUSTOMER INSIGHTS CONTENT ====================
  Widget _buildCustomerInsightsContent(String productId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('Customer Engagement Overview',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
                  future: Future.wait([
                    FirebaseFirestore.instance
                        .collection('comments')
                        .where('productId', isEqualTo: productId)
                        .get(),
                    FirebaseFirestore.instance
                        .collection('likes')
                        .where('productId', isEqualTo: productId)
                        .get(),
                    FirebaseFirestore.instance
                        .collection('ratings')
                        .where('productId', isEqualTo: productId)
                        .get(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final commentsCount = snapshot.data![0].docs.length;
                    final likesCount = snapshot.data![1].docs.length;
                    final ratingsCount = snapshot.data![2].docs.length;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCustomerStat('Comments', commentsCount.toString(),
                            Icons.comment, Colors.blue),
                        _buildCustomerStat('Likes', likesCount.toString(),
                            Icons.favorite, Colors.red),
                        _buildCustomerStat('Ratings', ratingsCount.toString(),
                            Icons.star, Colors.amber),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text('Sentiment Analysis',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('comments')
              .where('productId', isEqualTo: productId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final comments = snapshot.data!.docs;
            int positive = 0, neutral = 0, negative = 0;

            for (var comment in comments) {
              final sentiment = comment.get('sentiment') ?? 'neutral';
              if (sentiment == 'positive')
                positive++;
              else if (sentiment == 'negative')
                negative++;
              else
                neutral++;
            }

            final total = comments.length;
            final positivePercent =
                total > 0 ? (positive / total * 100).round() : 0;
            final neutralPercent =
                total > 0 ? (neutral / total * 100).round() : 0;
            final negativePercent =
                total > 0 ? (negative / total * 100).round() : 0;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.sentiment_very_satisfied,
                              color: Colors.green, size: 28),
                          const SizedBox(height: 4),
                          Text('$positivePercent%',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          Text('Positive',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                          LinearProgressIndicator(
                            value: positivePercent / 100,
                            backgroundColor: Colors.grey[200],
                            color: Colors.green,
                            minHeight: 3,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.sentiment_neutral,
                              color: Colors.grey, size: 28),
                          const SizedBox(height: 4),
                          Text('$neutralPercent%',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text('Neutral',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                          LinearProgressIndicator(
                            value: neutralPercent / 100,
                            backgroundColor: Colors.grey[200],
                            color: Colors.grey,
                            minHeight: 3,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.sentiment_very_dissatisfied,
                              color: Colors.red, size: 28),
                          const SizedBox(height: 4),
                          Text('$negativePercent%',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          Text('Negative',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                          LinearProgressIndicator(
                            value: negativePercent / 100,
                            backgroundColor: Colors.grey[200],
                            color: Colors.red,
                            minHeight: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        const Text('Recent Customer Comments',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('comments')
              .where('productId', isEqualTo: productId)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final comments = snapshot.data!.docs;

            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('No comments yet',
                        style: TextStyle(fontSize: 11, color: Colors.grey))),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final sentiment = comment.get('sentiment') ?? 'neutral';
                final userName = comment.get('userName') ?? 'Anonymous';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: _getSentimentColor(sentiment)
                                  .withOpacity(0.1),
                              child: Icon(_getSentimentIcon(sentiment),
                                  size: 12,
                                  color: _getSentimentColor(sentiment)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              _formatDateTime(
                                  (comment.get('createdAt') as Timestamp)
                                      .toDate()),
                              style: const TextStyle(
                                  fontSize: 8, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(comment.get('comment') ?? '',
                            style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ==================== HELPER METHODS ====================
  Widget _buildPerformanceMetric(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String suffix) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text('$value$suffix',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerStat(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMarketStat(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEngagementChart(ProductModel product) {
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
      height: 180,
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
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(),
                    style: const TextStyle(fontSize: 8)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(days[value.toInt()],
                        style: const TextStyle(fontSize: 8));
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(engagementData.length, (index) {
                return FlSpot(index.toDouble(), engagementData[index]);
              }),
              isCurved: true,
              color: const Color(0xFF59F797),
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF59F797).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights(ProductModel product) {
    final insights = <String>[];

    if (product.engagementScore > 1000) {
      insights.add(
          '✓ Excellent engagement! Your product is performing exceptionally well.');
      insights.add('✓ Consider expanding this product line based on demand.');
    } else if (product.engagementScore > 500) {
      insights.add('✓ Good performance. Keep engaging with customers.');
      insights.add('✓ Run targeted promotions to boost sales.');
    } else {
      insights.add(
          '⚠️ Low engagement detected. Consider improving product visibility.');
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
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(insights[index], style: const TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }

  Widget _buildMarketOpportunities(ProductModel product) {
    final opportunities = <String>[];

    if (product.engagementScore > 800) {
      opportunities
          .add('📈 High demand detected - Consider increasing production');
      opportunities
          .add('🎯 Your product is trending - Leverage social media marketing');
    } else if (product.engagementScore > 400) {
      opportunities
          .add('📊 Steady growth - Run promotional campaigns to boost sales');
      opportunities.add('💡 Consider adding product variations or bundles');
    } else {
      opportunities
          .add('⚠️ Low engagement - Improve product visibility and marketing');
      opportunities.add('🎨 Consider updating product images and description');
    }

    if (product.stock < 30 && product.engagementScore > 500) {
      opportunities.add('🚚 Stock running low - Reorder soon to meet demand');
    }

    if (product.rating < 4.0 && product.comments > 3) {
      opportunities.add('⭐ Address customer feedback to improve ratings');
    }

    opportunities
        .add('🔍 Analyze top competitors to identify improvement areas');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: opportunities.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(opportunities[index], style: const TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }

  String _calculateConversionRate(ProductModel product) {
    if (product.views == 0) return '0';
    double rate = (product.likes / product.views) * 100;
    return rate.toStringAsFixed(1);
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
}