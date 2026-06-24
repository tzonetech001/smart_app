import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import '../models/cart_item_model.dart';

class AzamPesaProvider {
  static String get _backendUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Sends a checkout request to the AzamPesa checkout endpoint on the Express server.
  static Future<Map<String, dynamic>> initiateCheckout({
    required String mobileNumber,
    required double amount,
    required String orderId,
    required String userId,
    required String customerName,
    required String customerEmail,
    required String shippingAddress,
    required String city,
    required String country,
    required List<CartItemModel> cartItems,
  }) async {
    final url = Uri.parse('$_backendUrl/api/payment/azampesa/checkout');
    
    final payload = {
      'mobileNumber': mobileNumber,
      'amount': amount,
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress,
      'city': city,
      'country': country,
      'cartItems': cartItems.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'price': item.price,
      }).toList(),
    };

    try {
      debugPrint('[AzamPesaProvider] Sending checkout payload: ${jsonEncode(payload)}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[AzamPesaProvider] Success response: $data');
        return {
          'success': true,
          'transactionId': data['transactionId'],
          'orderId': data['orderId'],
          'message': data['message'],
        };
      } else {
        final errorMsg = _parseError(response.body);
        debugPrint('[AzamPesaProvider] Error response code: ${response.statusCode}, body: ${response.body}');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      debugPrint('[AzamPesaProvider] Network/parsing exception: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the payment gateway. Please check your network connection.',
      };
    }
  }

  static String _parseError(String body) {
    try {
      final parsed = jsonDecode(body);
      return parsed['error'] ?? parsed['message'] ?? 'Payment request rejected.';
    } catch (_) {
      return 'Payment service temporarily unavailable.';
    }
  }
}
