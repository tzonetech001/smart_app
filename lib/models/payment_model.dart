import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final String status; // success, failed
  final String paymentMethod; // card, mobile_money
  final String transactionId;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt,
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'TZS',
      status: map['status'] ?? 'failed',
      paymentMethod: map['paymentMethod'] ?? 'card',
      transactionId: map['transactionId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
