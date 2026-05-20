import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class AIService {
  static const String baseUrl = 'YOUR_PHP_API_URL'; // Replace with your PHP API URL
  
  Future<Map<String, dynamic>> getSalesPrediction(
    List<ProductModel> products,
    List<Map<String, dynamic>> salesHistory,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict_sales.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': products.map((p) => {
            'id': p.id,
            'name': p.productName,
            'engagementScore': p.engagementScore,
            'views': p.views,
            'likes': p.likes,
          }).toList(),
          'salesHistory': salesHistory,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _getLocalPrediction(products);
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return _getLocalPrediction(products);
    }
  }
  
  Map<String, dynamic> _getLocalPrediction(List<ProductModel> products) {
    double avgEngagement = products.isEmpty 
        ? 0 
        : products.map((p) => p.engagementScore).reduce((a, b) => a + b) / products.length;
    
    double predictedGrowth = avgEngagement > 1000 ? 0.20 : (avgEngagement > 500 ? 0.10 : -0.05);
    
    List<Map<String, dynamic>> recommendations = [];
    
    for (var product in products) {
      if (product.engagementScore > 1000 && product.stock < 50) {
        recommendations.add({
          'productId': product.id,
          'productName': product.productName,
          'recommendation': 'Increase stock for ${product.productName}',
          'priority': 'HIGH',
        });
      } else if (product.engagementScore < 200 && product.stock > 20) {
        recommendations.add({
          'productId': product.id,
          'productName': product.productName,
          'recommendation': 'Consider promotion or discount for ${product.productName}',
          'priority': 'MEDIUM',
        });
      }
    }
    
    return {
      'predictedGrowth': predictedGrowth,
      'predictedSalesNextWeek': '${(predictedGrowth * 100).round()}%',
      'demandLevel': predictedGrowth > 0.15 ? 'HIGH' : (predictedGrowth > 0 ? 'MEDIUM' : 'LOW'),
      'recommendations': recommendations,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  Future<Map<String, dynamic>> analyzeSentiment(String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_sentiment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': comment}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Sentiment Analysis Error: $e');
    }
    
    // Local sentiment analysis
    String sentiment = _analyzeSentimentLocally(comment);
    return {
      'sentiment': sentiment,
      'confidence': 0.7,
    };
  }
  
  String _analyzeSentimentLocally(String comment) {
    String lowerComment = comment.toLowerCase();
    List<String> positiveWords = ['good', 'great', 'excellent', 'amazing', 'love', 'best', 'perfect', 'nice'];
    List<String> negativeWords = ['bad', 'poor', 'terrible', 'hate', 'worst', 'awful', 'disappointing'];
    
    int positiveCount = positiveWords.where((w) => lowerComment.contains(w)).length;
    int negativeCount = negativeWords.where((w) => lowerComment.contains(w)).length;
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }
  
  Future<List<Map<String, dynamic>>> getMarketTrends(List<ProductModel> allProducts) async {
    // Calculate trending products based on engagement
    var sortedProducts = List<ProductModel>.from(allProducts);
    sortedProducts.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    
    List<Map<String, dynamic>> trendingProducts = [];
    for (int i = 0; i < sortedProducts.length && i < 5; i++) {
      var product = sortedProducts[i];
      double trendGrowth = product.engagementScore > 1000 ? 0.35 : (product.engagementScore > 500 ? 0.20 : 0.10);
      
      trendingProducts.add({
        'productId': product.id,
        'productName': product.productName,
        'category': product.category.displayName,
        'engagementScore': product.engagementScore,
        'trendGrowth': trendGrowth,
        'trendPercentage': '${(trendGrowth * 100).round()}%',
      });
    }
    
    return trendingProducts;
  }
}