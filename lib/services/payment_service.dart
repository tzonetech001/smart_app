import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'azampesa_provider.dart';
import '../models/cart_item_model.dart';

class PaymentService {
  /// Orchestrates the entire AzamPesa payment flow.
  /// 
  /// Returns `true` if payment succeeds, `false` if it fails, or throws an Exception on error.
  static Future<bool> processAzamPesaPayment({
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
    // 1. Initiate checkout request via AzamPesa Provider
    final response = await AzamPesaProvider.initiateCheckout(
      mobileNumber: mobileNumber,
      amount: amount,
      orderId: orderId,
      userId: userId,
      customerName: customerName,
      customerEmail: customerEmail,
      shippingAddress: shippingAddress,
      city: city,
      country: country,
      cartItems: cartItems,
    );

    if (!response['success']) {
      throw Exception(response['message'] ?? 'Failed to initiate checkout.');
    }

    final String transactionId = response['transactionId'];
    debugPrint('[PaymentService] Checkout initiated. Transaction ID: $transactionId. Waiting for callback...');

    // 2. Listen to the payments collection in Firestore for status changes
    final completer = Completer<bool>();
    StreamSubscription<DocumentSnapshot>? subscription;

    subscription = FirebaseFirestore.instance
        .collection('payments')
        .doc(transactionId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>?;
            final status = data?['status'] as String?;
            debugPrint('[PaymentService] Payment status updated in Firestore: $status');
            
            if (status == 'success') {
              if (!completer.isCompleted) completer.complete(true);
            } else if (status == 'failed') {
              if (!completer.isCompleted) completer.complete(false);
            }
          }
        }, onError: (err) {
          debugPrint('[PaymentService] Firestore listener error: $err');
          if (!completer.isCompleted) completer.completeError(err);
        });

    try {
      // Set a 45-second timeout for the payment callback
      final success = await completer.future.timeout(const Duration(seconds: 45));
      await subscription.cancel();
      return success;
    } on TimeoutException {
      await subscription.cancel();
      debugPrint('[PaymentService] Payment confirmation timed out.');
      
      // Fallback: If for some reason the listener timed out but the backend checkout succeeded,
      // let's check the document one final time
      final snap = await FirebaseFirestore.instance.collection('payments').doc(transactionId).get();
      if (snap.exists) {
        final status = snap.get('status') as String?;
        if (status == 'success') return true;
        if (status == 'failed') return false;
      }
      
      throw Exception('Payment verification timed out. Please check your My Profile -> Orders section in a moment.');
    } catch (e) {
      await subscription.cancel();
      rethrow;
    }
  }
}
