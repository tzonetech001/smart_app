import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pendingPayment,
  paymentConfirmed,
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Pending Payment';
      case OrderStatus.paymentConfirmed:
        return 'Payment Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PaymentMethod {
  mobile_money,
  credit_card,
  cash_on_delivery,
  bank_transfer,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

class OrderModel {
  final String id;
  final String userId;
  final String entrepreneurId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String paymentTransactionId;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final ShippingAddress shippingAddress;
  final String customerNotes;
  final Map<String, String>? customerLocation; // { 'region': '...', 'district': '...', 'ward': '...' }

  OrderModel({
    required this.id,
    required this.userId,
    required this.entrepreneurId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentTransactionId,
    required this.orderDate,
    this.deliveryDate,
    required this.shippingAddress,
    required this.customerNotes,
    this.customerLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'entrepreneurId': entrepreneurId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentTransactionId': paymentTransactionId,
      'orderDate': orderDate,
      'deliveryDate': deliveryDate,
      'shippingAddress': shippingAddress.toMap(),
      'customerNotes': customerNotes,
      'customerLocation': customerLocation,
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      entrepreneurId: map['entrepreneurId'] ?? '',
      items: (map['items'] as List? ?? []).map((item) => OrderItem.fromMap(item)).toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: _stringToOrderStatus(map['status'] ?? 'pendingPayment'),
      paymentMethod: _stringToPaymentMethod(map['paymentMethod'] ?? 'mobile_money'),
      paymentStatus: _stringToPaymentStatus(map['paymentStatus'] ?? 'pending'),
      paymentTransactionId: map['paymentTransactionId'] ?? '',
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryDate: (map['deliveryDate'] as Timestamp?)?.toDate(),
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress'] ?? {}),
      customerNotes: map['customerNotes'] ?? '',
      customerLocation: map['customerLocation'] != null ? Map<String, String>.from(map['customerLocation']) : null,
    );
  }

  static OrderStatus _stringToOrderStatus(String value) {
    switch (value) {
      case 'pendingPayment': return OrderStatus.pendingPayment;
      case 'paymentConfirmed': return OrderStatus.paymentConfirmed;
      case 'processing': return OrderStatus.processing;
      case 'packed': return OrderStatus.packed;
      case 'shipped': return OrderStatus.shipped;
      case 'outForDelivery': return OrderStatus.outForDelivery;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pendingPayment;
    }
  }

  static PaymentMethod _stringToPaymentMethod(String value) {
    switch (value) {
      case 'mobile_money': return PaymentMethod.mobile_money;
      case 'credit_card': return PaymentMethod.credit_card;
      case 'cash_on_delivery': return PaymentMethod.cash_on_delivery;
      case 'bank_transfer': return PaymentMethod.bank_transfer;
      default: return PaymentMethod.mobile_money;
    }
  }

  static PaymentStatus _stringToPaymentStatus(String value) {
    switch (value) {
      case 'pending': return PaymentStatus.pending;
      case 'paid': return PaymentStatus.paid;
      case 'failed': return PaymentStatus.failed;
      case 'refunded': return PaymentStatus.refunded;
      default: return PaymentStatus.pending;
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  }) : total = price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }
}

class ShippingAddress {
  final String fullName;
  final String phoneNumber;
  final String region;
  final String city;
  final String district;
  final String street;
  final String? landmark;
  final String? deliveryInstructions;

  ShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.region,
    required this.city,
    required this.district,
    required this.street,
    this.landmark,
    this.deliveryInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'region': region,
      'city': city,
      'district': district,
      'street': street,
      'landmark': landmark,
      'deliveryInstructions': deliveryInstructions,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      region: map['region'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      street: map['street'] ?? '',
      landmark: map['landmark'],
      deliveryInstructions: map['deliveryInstructions'],
    );
  }
}

class CartItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }
}