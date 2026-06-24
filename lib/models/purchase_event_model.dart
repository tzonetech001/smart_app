import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseEventModel {
  final String id;
  final String userId;
  final String userEmail;
  final String action; // view_product, add_to_cart, remove_from_cart, initiate_checkout, purchase
  final String productId;
  final String productName;
  final String category;
  final double price;
  final int quantity;
  final String city;
  final String country;
  final DateTime timestamp;

  PurchaseEventModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.productId,
    required this.productName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.city,
    required this.country,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'action': action,
      'productId': productId,
      'productName': productName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'city': city,
      'country': country,
      'timestamp': timestamp,
    };
  }

  factory PurchaseEventModel.fromMap(String id, Map<String, dynamic> map) {
    return PurchaseEventModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      action: map['action'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
