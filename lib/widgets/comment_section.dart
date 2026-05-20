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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Add Comment
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Write a review...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isLoading ? null : onCommentAdded,
              icon: const Icon(Icons.send),
              color: const Color(0xFF667eea),
            ),
          ],
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
              return const Center(child: CircularProgressIndicator());
            }
            
            final comments = snapshot.data!.docs.map((doc) {
              return CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();
            
            if (comments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No reviews yet. Be the first to review!'),
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 16),
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(comment.createdAt),
                                    style: const TextStyle(
                                      fontSize: 10,
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
                              child: Text(
                                comment.sentiment,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getSentimentColor(comment.sentiment),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment.comment),
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
    return '${date.day}/${date.month}/${date.year}';
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
}