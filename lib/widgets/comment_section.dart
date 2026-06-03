import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentSection extends StatelessWidget {
  final String productId;
  final VoidCallback onCommentAdded;
  final TextEditingController commentController;
  final bool isLoading;

  const CommentSection({
    super.key,
    required this.productId,
    required this.onCommentAdded,
    required this.commentController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Reviews',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Add Comment Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(fontSize: 12),
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Write your review...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: isLoading ? null : onCommentAdded,
                icon: Icon(
                  Icons.send,
                  size: 18,
                  color: isLoading ? Colors.grey : const Color(0xFF59F797),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Comments List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('comments')
              .where('productId', isEqualTo: productId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final comments = snapshot.data!.docs.map((doc) {
              return CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();
            
            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.comment_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No reviews yet',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Be the first to review this product!',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF59F797).withOpacity(0.1),
                              child: Text(
                                comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF59F797),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(comment.createdAt),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSentimentColor(comment.sentiment).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getSentimentIcon(comment.sentiment),
                                    size: 10,
                                    color: _getSentimentColor(comment.sentiment),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    comment.sentiment,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _getSentimentColor(comment.sentiment),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment.comment,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}