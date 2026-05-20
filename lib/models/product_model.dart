import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory {
  electronics,
  fashion,
  food,
  automobile,
  beauty,
  health,
  agriculture,
  home,
  education,
  construction;

  String get displayName {
    switch (this) {
      case ProductCategory.electronics:
        return 'Electronics';
      case ProductCategory.fashion:
        return 'Fashion & Clothing';
      case ProductCategory.food:
        return 'Food & Beverages';
      case ProductCategory.automobile:
        return 'Automobile & Transport';
      case ProductCategory.beauty:
        return 'Beauty & Cosmetics';
      case ProductCategory.health:
        return 'Health & Pharmacy';
      case ProductCategory.agriculture:
        return 'Agriculture & Farming';
      case ProductCategory.home:
        return 'Home & Furniture';
      case ProductCategory.education:
        return 'Education & Books';
      case ProductCategory.construction:
        return 'Construction & Hardware';
    }
  }
}

class ProductModel {
  String id;
  String productName;
  String description;
  String? imageUrl;
  ProductCategory category;
  String entrepreneurId;
  String entrepreneurName;
  int likes;
  int comments;
  double rating;
  int views;
  double price;
  int stock;
  DateTime createdAt;
  bool isActive;

  ProductModel({
    required this.id,
    required this.productName,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.entrepreneurId,
    required this.entrepreneurName,
    this.likes = 0,
    this.comments = 0,
    this.rating = 0.0,
    this.views = 0,
    this.price = 0,
    this.stock = 0,
    required this.createdAt,
    this.isActive = true,
  });

  double get engagementScore => likes + comments + rating * 100 + views;
  String get performanceLevel => engagementScore > 1000 ? 'HIGH PERFORMANCE' : 'LOW PERFORMANCE';

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.toString().split('.').last,
      'entrepreneurId': entrepreneurId,
      'entrepreneurName': entrepreneurName,
      'likes': likes,
      'comments': comments,
      'rating': rating,
      'views': views,
      'price': price,
      'stock': stock,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      productName: map['productName'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      category: _stringToCategory(map['category'] ?? 'electronics'),
      entrepreneurId: map['entrepreneurId'] ?? '',
      entrepreneurName: map['entrepreneurName'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      views: map['views'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  static ProductCategory _stringToCategory(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return ProductCategory.electronics;
      case 'fashion':
        return ProductCategory.fashion;
      case 'food':
        return ProductCategory.food;
      case 'automobile':
        return ProductCategory.automobile;
      case 'beauty':
        return ProductCategory.beauty;
      case 'health':
        return ProductCategory.health;
      case 'agriculture':
        return ProductCategory.agriculture;
      case 'home':
        return ProductCategory.home;
      case 'education':
        return ProductCategory.education;
      case 'construction':
        return ProductCategory.construction;
      default:
        return ProductCategory.electronics;
    }
  }
}