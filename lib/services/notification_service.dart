import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // FCM Initialization
  // ============================================================

  static Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('FCM: permission not granted.');
      return;
    }

    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.data}');
    });

    FirebaseMessaging.onBackgroundMessage(_bgHandler);
  }

  @pragma('vm:entry-point')
  static Future<void> _bgHandler(RemoteMessage message) async {
    debugPrint('FCM background message: ${message.messageId}');
  }

  // ============================================================
  // CUSTOMER NOTIFICATIONS — fan-out to all active customers
  // ============================================================

  /// Called when an entrepreneur publishes a new product.
  static Future<void> sendNewProductNotification({
    required String productId,
    required String productName,
    required String entrepreneurName,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'userId': doc.id,
          'title': '🛍️ New Product Available!',
          'message':
              '"$productName" by $entrepreneurName has just been added. Check it out now!',
          'type': 'new_product',
          'isRead': false,
          'productId': productId,
          'orderId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint(
          'New product notification sent to ${snap.docs.length} customers.');
    } catch (e) {
      debugPrint('sendNewProductNotification error: $e');
    }
  }

  /// Called when a promotion is created for a product.
  static Future<void> sendPromotionNotification({
    required String productId,
    required String productName,
    required String promoDescription,
    required String entrepreneurName,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'userId': doc.id,
          'title': '🏷️ Special Offer!',
          'message': '$promoDescription on "$productName" by $entrepreneurName.',
          'type': 'promotion',
          'isRead': false,
          'productId': productId,
          'orderId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('sendPromotionNotification error: $e');
    }
  }

  // ============================================================
  // ENTREPRENEUR NOTIFICATIONS
  // ============================================================

  /// New order placed for the entrepreneur's product.
  static Future<void> sendNewOrderNotification({
    required String entrepreneurId,
    required String orderId,
    required String customerName,
    required double amount,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': entrepreneurId,
        'title': '🛍️ New Order Received!',
        'message':
            '$customerName placed a new order worth TZS ${amount.toStringAsFixed(0)}.',
        'type': 'new_order',
        'isRead': false,
        'productId': null,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendNewOrderNotification error: $e');
    }
  }

  /// Payment initiated but not yet confirmed.
  static Future<void> sendPaymentPendingNotification({
    required String entrepreneurId,
    required String orderId,
    required double amount,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': entrepreneurId,
        'title': '💳 Payment Pending Approval',
        'message':
            'A payment of TZS ${amount.toStringAsFixed(0)} for order #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId} is awaiting confirmation.',
        'type': 'payment_pending',
        'isRead': false,
        'productId': null,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendPaymentPendingNotification error: $e');
    }
  }

  /// Payment confirmed by AzamPesa callback.
  static Future<void> sendPaymentApprovedNotification({
    required String entrepreneurId,
    required String orderId,
    required double amount,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': entrepreneurId,
        'title': '✅ Payment Confirmed!',
        'message':
            'Payment of TZS ${amount.toStringAsFixed(0)} for order #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId} has been approved.',
        'type': 'payment_approved',
        'isRead': false,
        'productId': null,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendPaymentApprovedNotification error: $e');
    }
  }

  /// Stock dropped to ≤ 5 units.
  static Future<void> sendLowStockAlert({
    required String entrepreneurId,
    required String productId,
    required String productName,
    required int stockLeft,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': entrepreneurId,
        'title': '⚠️ Low Stock Alert',
        'message':
            '"$productName" is running low with only $stockLeft unit${stockLeft == 1 ? '' : 's'} remaining. Restock soon.',
        'type': 'low_stock',
        'isRead': false,
        'productId': productId,
        'orderId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendLowStockAlert error: $e');
    }
  }

  /// Stock hit 0.
  static Future<void> sendOutOfStockAlert({
    required String entrepreneurId,
    required String productId,
    required String productName,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': entrepreneurId,
        'title': '🚫 Out of Stock!',
        'message':
            '"$productName" is now out of stock. Update your inventory immediately to avoid losing sales.',
        'type': 'out_of_stock',
        'isRead': false,
        'productId': productId,
        'orderId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendOutOfStockAlert error: $e');
    }
  }

  /// Generic order status update for both customer and entrepreneur.
  static Future<void> sendOrderStatusUpdateNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    try {
      final shortId =
          orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
      await _db.collection('notifications').add({
        'userId': userId,
        'title': '📦 Order Status Updated',
        'message': 'Order #$shortId status changed to: $status.',
        'type': 'order_update',
        'isRead': false,
        'productId': null,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendOrderStatusUpdateNotification error: $e');
    }
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  /// Mark a single notification as read.
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  /// Batch-mark all unread notifications for a user as read.
  static Future<void> markAllRead(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }

  /// Stream of unread notification count for AppBar badge.
  static Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}