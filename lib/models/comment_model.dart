import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  String id;
  String productId;
  String userId;
  String userName;
  String comment;
  String sentiment;
  DateTime createdAt;

  CommentModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.sentiment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'sentiment': sentiment,
      'createdAt': createdAt,
    };
  }

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      comment: map['comment'] ?? '',
      sentiment: map['sentiment'] ?? 'neutral',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}