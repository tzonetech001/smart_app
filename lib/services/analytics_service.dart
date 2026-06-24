import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Main method to log any purchase behavior event
  static Future<void> logEvent({
    required String action,
    required ProductModel product,
    int quantity = 1,
    String city = 'Dar es Salaam',
    String country = 'Tanzania',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Fetch user profile to get names if available
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final userCity = userData['city'] ?? city;
      final userCountry = userData['country'] ?? country;

      await _firestore.collection('purchase_behavior_events').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'anonymous@example.com',
        'action': action,
        'productId': product.id,
        'productName': product.productName,
        'category': product.category.toString().split('.').last,
        'price': product.price,
        'quantity': quantity,
        'city': userCity,
        'country': userCountry,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  /// Helper: Log Product View
  static Future<void> logViewProduct(ProductModel product) async {
    await logEvent(action: 'view_product', product: product);
  }

  /// Helper: Log Add to Cart
  static Future<void> logAddToCart(ProductModel product, int quantity) async {
    await logEvent(action: 'add_to_cart', product: product, quantity: quantity);
  }

  /// Helper: Log Remove from Cart
  static Future<void> logRemoveFromCart(
      ProductModel product, int quantity) async {
    await logEvent(
        action: 'remove_from_cart', product: product, quantity: quantity);
  }

  /// Helper: Log Initiate Checkout
  static Future<void> logInitiateCheckout(
      ProductModel product, int quantity) async {
    await logEvent(
        action: 'initiate_checkout', product: product, quantity: quantity);
  }

  /// Helper: Log Purchase
  static Future<void> logPurchase({
    required ProductModel product,
    required int quantity,
    required String city,
    required String country,
  }) async {
    await logEvent(
      action: 'purchase',
      product: product,
      quantity: quantity,
      city: city,
      country: country,
    );
  }

  /// Log when an entrepreneur publishes a new product.
  static Future<void> logProductPublished(ProductModel product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('purchase_behavior_events').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'anonymous@example.com',
        'action': 'product_published',
        'productId': product.id,
        'productName': product.productName,
        'category': product.category.toString().split('.').last,
        'price': product.price,
        'quantity': 0,
        'city': 'Dar es Salaam',
        'country': 'Tanzania',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log product_published event: $e');
    }
  }

  /// Log when a promotion is created on a product.
  static Future<void> logPromotionCreated(ProductModel product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('purchase_behavior_events').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'anonymous@example.com',
        'action': 'promotion_created',
        'productId': product.id,
        'productName': product.productName,
        'category': product.category.toString().split('.').last,
        'price': product.promotionPrice ?? product.price,
        'quantity': 0,
        'city': 'Dar es Salaam',
        'country': 'Tanzania',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log promotion_created event: $e');
    }
  }

  /// Increment unitsSold and revenue on the product document after a confirmed order.
  static Future<void> updateProductSalesStats({
    required String productId,
    required int additionalUnitsSold,
    required double additionalRevenue,
  }) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'unitsSold': FieldValue.increment(additionalUnitsSold),
        'revenue': FieldValue.increment(additionalRevenue),
      });
    } catch (e) {
      print('Failed to update product sales stats: $e');
    }
  }
}
