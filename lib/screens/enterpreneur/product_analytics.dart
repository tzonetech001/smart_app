import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';

class EntrepreneurProductAnalysis extends StatefulWidget {
  const EntrepreneurProductAnalysis({super.key});

  @override
  State<EntrepreneurProductAnalysis> createState() =>
      _EntrepreneurProductAnalysisState();
}

class _EntrepreneurProductAnalysisState
    extends State<EntrepreneurProductAnalysis> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedProductId = '';
  String _selectedTimeframe = 'month';
  bool _isLoading = true;

  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  Map<String, dynamic> _productStats = {};
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _marketTrends = [];

  final List<String> _timeframes = ['Week', 'Month', 'Quarter', 'Year'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load products
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('entrepreneurId', isEqualTo: _userId)
        .get();

    _products = productsSnapshot.docs.map((doc) {
      return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    // Load orders
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('entrepreneurId', isEqualTo: _userId)
        .get();

    _orders = ordersSnapshot.docs.map((doc) {
      return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    // Select first product if available
    if (_products.isNotEmpty && _selectedProductId.isEmpty) {
      _selectedProductId = _products.first.id;
    }

    // Calculate product stats
    _calculateProductStats();

    // Generate sales data
    _generateSalesData();

    // Generate market trends
    _generateMarketTrends();

    setState(() => _isLoading = false);
  }

  void _calculateProductStats() {
    _productStats = {};

    for (var product in _products) {
      final productOrders = _orders.where((o) {
        return o.items.any((item) => item.productId == product.id);
      }).toList();

      final totalSold = productOrders.fold<int>(0, (sum, order) {
        final item = order.items.firstWhere(
          (i) => i.productId == product.id,
          orElse: () =>
              OrderItem(productId: '', productName: '', price: 0, quantity: 0),
        );
        return sum + item.quantity;
      });

      final totalRevenue = productOrders.fold<double>(0, (sum, order) {
        final item = order.items.firstWhere(
          (i) => i.productId == product.id,
          orElse: () =>
              OrderItem(productId: '', productName: '', price: 0, quantity: 0),
        );
        return sum + (item.price * item.quantity);
      });

      final totalOrders = productOrders.length;

      _productStats[product.id] = {
        'product': product,
        'totalSold': totalSold,
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'performanceLevel': _getPerformanceLevel(totalSold, totalRevenue),
        'demandLevel': _getDemandLevel(totalOrders, totalSold),
      };
    }
  }

  String _getPerformanceLevel(int totalSold, double totalRevenue) {
    if (totalSold > 100 && totalRevenue > 5000) {
      return 'HIGH';
    } else if (totalSold > 30 && totalRevenue > 1000) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }

  String _getDemandLevel(int totalOrders, int totalSold) {
    if (totalOrders > 20 && totalSold > 50) {
      return 'VERY HIGH';
    } else if (totalOrders > 10 && totalSold > 20) {
      return 'HIGH';
    } else if (totalOrders > 5 && totalSold > 10) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }

  void _generateSalesData() {
    final ProductModel? product = _products.isNotEmpty
        ? _products.firstWhere(
            (p) => p.id == _selectedProductId,
            orElse: () => _products.first,
          )
        : null;

    if (product == null) {
      _salesData = [];
      return;
    }

    // Get orders for this product
    final productOrders = _orders.where((o) {
      return o.items.any((item) => item.productId == product.id);
    }).toList();

    // Group by date
    final Map<DateTime, double> dailySales = {};

    for (var order in productOrders) {
      final date = DateTime(
          order.orderDate.year, order.orderDate.month, order.orderDate.day);
      final item = order.items.firstWhere(
        (i) => i.productId == product.id,
        orElse: () =>
            OrderItem(productId: '', productName: '', price: 0, quantity: 0),
      );
      final amount = item.price * item.quantity;
      dailySales[date] = (dailySales[date] ?? 0) + amount;
    }

    // Sort dates and convert to list
    final sortedDates = dailySales.keys.toList()..sort();
    final now = DateTime.now();

    // Limit based on timeframe
    int limit = 30;
    if (_selectedTimeframe == 'week')
      limit = 7;
    else if (_selectedTimeframe == 'month')
      limit = 30;
    else if (_selectedTimeframe == 'quarter')
      limit = 90;
    else if (_selectedTimeframe == 'year') limit = 365;

    final startDate = now.subtract(Duration(days: limit));

    _salesData = [];
    for (int i = 0; i < limit; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final amount = dailySales[dateKey] ?? 0;
      _salesData.add({
        'date': date,
        'amount': amount,
        'label': '${date.day}/${date.month}',
      });
    }
  }

  void _generateMarketTrends() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    _marketTrends = [];

    // Calculate performance for each product
    for (var product in _products) {
      final productOrders = _orders.where((o) {
        return o.items.any((item) => item.productId == product.id) &&
            o.orderDate.isAfter(monthAgo);
      }).toList();

      final totalSales = productOrders.fold<int>(0, (sum, order) {
        final item = order.items.firstWhere(
          (i) => i.productId == product.id,
          orElse: () =>
              OrderItem(productId: '', productName: '', price: 0, quantity: 0),
        );
        return sum + item.quantity;
      });

      final totalRevenue = productOrders.fold<double>(0, (sum, order) {
        final item = order.items.firstWhere(
          (i) => i.productId == product.id,
          orElse: () =>
              OrderItem(productId: '', productName: '', price: 0, quantity: 0),
        );
        return sum + (item.price * item.quantity);
      });

      // Calculate growth compared to previous period
      final previousMonth = now.subtract(const Duration(days: 60));
      final previousOrders = _orders.where((o) {
        return o.items.any((item) => item.productId == product.id) &&
            o.orderDate.isAfter(previousMonth) &&
            o.orderDate.isBefore(monthAgo);
      }).toList();

      final previousSales = previousOrders.fold<int>(0, (sum, order) {
        final item = order.items.firstWhere(
          (i) => i.productId == product.id,
          orElse: () =>
              OrderItem(productId: '', productName: '', price: 0, quantity: 0),
        );
        return sum + item.quantity;
      });

      double growth = 0;
      if (previousSales > 0) {
        growth = ((totalSales - previousSales) / previousSales) * 100;
      }

      _marketTrends.add({
        'productId': product.id,
        'productName': product.productName,
        'productImage': product.imageUrl,
        'category': product.category.displayName,
        'totalSales': totalSales,
        'totalRevenue': totalRevenue,
        'growth': growth,
        'performance': _getPerformanceLevel(totalSales, totalRevenue),
        'trend': growth > 20 ? 'HIGH' : (growth > 5 ? 'MEDIUM' : 'LOW'),
        'orders': productOrders.length,
      });
    }

    // Sort by performance
    _marketTrends.sort((a, b) =>
        (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading product analysis...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products to analyze',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Add products to see analysis',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    final selectedProduct = _products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => _products.first,
    );
    final stats = _productStats[_selectedProductId] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Analysis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Product Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: _selectedProductId,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox.shrink(),
              items: _products.map((product) {
                return DropdownMenuItem(
                  value: product.id,
                  child: SizedBox(
                    width: 120,
                    child: Text(
                      product.productName,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProductId = value;
                    _generateSalesData();
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Overview Card
            _buildProductOverview(selectedProduct, stats),
            const SizedBox(height: 16),

            // Timeframe Selector
            _buildTimeframeSelector(),
            const SizedBox(height: 16),

            // Sales Chart
            _buildSalesChart(selectedProduct),
            const SizedBox(height: 16),

            // Key Metrics
            _buildKeyMetrics(stats),
            const SizedBox(height: 16),

            // Market Trends
            const Text('Market Trends',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMarketTrends(),

            const SizedBox(height: 16),

            // Performance Summary
            _buildPerformanceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductOverview(
      ProductModel product, Map<String, dynamic> stats) {
    final totalSold = stats['totalSold'] ?? 0;
    final totalRevenue = stats['totalRevenue'] ?? 0.0;
    final totalOrders = stats['totalOrders'] ?? 0;
    final performanceLevel = stats['performanceLevel'] ?? 'LOW';
    final demandLevel = stats['demandLevel'] ?? 'LOW';

    Color getPerformanceColor(String level) {
      switch (level) {
        case 'HIGH':
          return Colors.green;
        case 'MEDIUM':
          return Colors.orange;
        default:
          return Colors.red;
      }
    }

    Color getDemandColor(String level) {
      switch (level) {
        case 'VERY HIGH':
          return Colors.deepPurple;
        case 'HIGH':
          return Colors.green;
        case 'MEDIUM':
          return Colors.orange;
        default:
          return Colors.red;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 35),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 70,
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
                        product.category.displayName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: getPerformanceColor(performanceLevel)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  performanceLevel == 'HIGH'
                                      ? Icons.trending_up
                                      : performanceLevel == 'MEDIUM'
                                          ? Icons.trending_flat
                                          : Icons.trending_down,
                                  size: 12,
                                  color: getPerformanceColor(performanceLevel),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  performanceLevel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        getPerformanceColor(performanceLevel),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  getDemandColor(demandLevel).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Demand: $demandLevel',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: getDemandColor(demandLevel),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewMetric('Units Sold', totalSold.toString(),
                    Icons.shopping_bag, Colors.blue),
                _buildOverviewMetric(
                    'Revenue',
                    'TZS ${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    const Color(0xFF59F797)),
                _buildOverviewMetric('Orders', totalOrders.toString(),
                    Icons.receipt, Colors.orange),
                _buildOverviewMetric(
                    'Avg Order',
                    totalOrders > 0
                        ? 'TZS ${(totalRevenue / totalOrders).toStringAsFixed(0)}'
                        : 'TZS 0',
                    Icons.trending_up,
                    Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewMetric(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 8, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = _timeframes[index];
          final isSelected = _selectedTimeframe == timeframe.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(timeframe, style: TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTimeframe = timeframe.toLowerCase();
                  _generateSalesData();
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF59F797).withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesChart(ProductModel product) {
    if (_salesData.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No sales data available',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final maxAmount = _salesData.fold<double>(0, (max, item) {
      return item['amount'] > max ? item['amount'] : max;
    });

    final step = maxAmount > 0 ? (maxAmount / 5).ceil() : 1;

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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'TZS ${value.toInt()}',
                    style: const TextStyle(fontSize: 8),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _salesData.length) {
                    // Show fewer labels to avoid clutter
                    if (index % 5 == 0 || index == _salesData.length - 1) {
                      return Text(
                        _salesData[index]['label'],
                        style: const TextStyle(fontSize: 8),
                      );
                    }
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
              spots: _salesData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['amount']);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF59F797),
              barWidth: 3,
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

  Widget _buildKeyMetrics(Map<String, dynamic> stats) {
    final product = _products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => _products.first,
    );

    final likes = product.likes;
    final comments = product.comments;
    final views = product.views;
    final rating = product.rating;

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
              'Product Engagement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEngagementMetric(
                    'Views', views.toString(), Icons.visibility, Colors.blue),
                _buildEngagementMetric(
                    'Likes', likes.toString(), Icons.favorite, Colors.red),
                _buildEngagementMetric('Comments', comments.toString(),
                    Icons.comment, Colors.orange),
                _buildEngagementMetric('Rating', rating.toStringAsFixed(1),
                    Icons.star, Colors.amber),
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
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMarketTrends() {
    if (_marketTrends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No market trends available',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
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
          children: _marketTrends.take(5).map((trend) {
            final isTop = _marketTrends.indexOf(trend) < 3;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isTop
                          ? const Color(0xFF59F797).withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${_marketTrends.indexOf(trend) + 1}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isTop
                              ? const Color(0xFF59F797)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trend['productName'] as String,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${trend['totalSales']} units • ${trend['totalRevenue'] > 0 ? 'TZS ${(trend['totalRevenue'] as double).toStringAsFixed(0)}' : 'No sales'}',
                          style:
                              TextStyle(fontSize: 9, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trend['growth'] as double) > 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(trend['growth'] as double).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: (trend['growth'] as double) > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    int high = 0, medium = 0, low = 0;
    for (var stat in _productStats.values) {
      final level = stat['performanceLevel'] as String;
      if (level == 'HIGH')
        high++;
      else if (level == 'MEDIUM')
        medium++;
      else
        low++;
    }

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
              'Performance Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceBar('High', high, Colors.green),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildPerformanceBar('Medium', medium, Colors.orange),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildPerformanceBar('Low', low, Colors.red),
                ),
              ],
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
            const SizedBox(height: 8),
            Text(
              'Total Products: ${_products.length}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(String label, int count, Color color) {
    final total = _products.length;
    final percentage = total > 0 ? (count / total * 100) : 0;

    return Column(
      children: [
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: percentage > 0 ? (percentage / 100 * 55) : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
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
}

// Extension to get product stats
extension ProductStats on ProductModel {
  double get engagementScore => likes + comments + (rating * 100) + views;
  String get performanceLevel => engagementScore > 1000
      ? 'HIGH'
      : (engagementScore > 500 ? 'MEDIUM' : 'LOW');
}
