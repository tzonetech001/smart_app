import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double price;
  final int quantity;
  final String entrepreneurId;
  final String category;

  CartItemModel({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.entrepreneurId,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'entrepreneurId': entrepreneurId,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'],
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      entrepreneurId: map['entrepreneurId'] ?? '',
      category: map['category'] ?? '',
    );
  }
}
