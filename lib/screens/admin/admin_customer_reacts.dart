import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCustomerReacts extends StatefulWidget {
  const AdminCustomerReacts({super.key});

  @override
  State<AdminCustomerReacts> createState() => _AdminCustomerReactsState();
}

class _AdminCustomerReactsState extends State<AdminCustomerReacts> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = ['Comments', 'Likes'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.all(12),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  label: Text('Comments', style: TextStyle(fontSize: 12))),
              ButtonSegment(
                  value: 1,
                  label: Text('Likes', style: TextStyle(fontSize: 12))),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<int> selection) {
              setState(() {
                _selectedTab = selection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF59F797);
                }
                return Colors.grey[200];
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
            ),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Content
        Expanded(
          child: _selectedTab == 0 ? _buildCommentsList() : _buildLikesList(),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 12)));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var comments = snapshot.data!.docs;

        // Apply search
        if (_searchQuery.isNotEmpty) {
          comments = comments.where((comment) {
            final text = comment.get('comment')?.toLowerCase() ?? '';
            final userName = comment.get('userName')?.toLowerCase() ?? '';
            return text.contains(_searchQuery) ||
                userName.contains(_searchQuery);
          }).toList();
        }

        if (comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No comments found',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final sentiment = comment.get('sentiment') ?? 'neutral';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              _getSentimentColor(sentiment).withOpacity(0.1),
                          child: Icon(
                            _getSentimentIcon(sentiment),
                            size: 14,
                            color: _getSentimentColor(sentiment),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.get('userName') ?? 'Unknown User',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatDate(
                                    (comment.get('createdAt') as Timestamp)
                                        .toDate()),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                _getSentimentColor(sentiment).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sentiment.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                color: _getSentimentColor(sentiment),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () => _showDeleteCommentDialog(comment.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(comment.get('comment') ?? '',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    // Product info
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('products')
                          .doc(comment.get('productId'))
                          .get(),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.hasData &&
                            productSnapshot.data != null) {
                          final product = productSnapshot.data!.data()
                              as Map<String, dynamic>;
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Product: ${product['productName'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('likes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 12)));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var likes = snapshot.data!.docs;

        // Apply search
        if (_searchQuery.isNotEmpty) {
          likes = likes.where((like) {
            final userId = like.get('userId')?.toLowerCase() ?? '';
            return userId.contains(_searchQuery);
          }).toList();
        }

        if (likes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No likes found',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final like = likes[index];

            return FutureBuilder<DocumentSnapshot>(
              future: Future.wait([
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(like.get('userId'))
                    .get(),
                FirebaseFirestore.instance
                    .collection('products')
                    .doc(like.get('productId'))
                    .get(),
              ]).then((results) => results),
              builder: (context, futures) {
                if (!futures.hasData) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final userData =
                    futures.data![0].data() as Map<String, dynamic>?;
                final productData =
                    futures.data![1].data() as Map<String, dynamic>?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              const Color(0xFF59F797).withOpacity(0.1),
                          child: Icon(Icons.favorite,
                              size: 16, color: const Color(0xFF59F797)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData?['firstName'] ?? 'Unknown User',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Liked: ${productData?['productName'] ?? 'Unknown Product'}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate((like.get('createdAt') as Timestamp)
                                    .toDate()),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () => _showDeleteLikeDialog(like.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment', style: TextStyle(fontSize: 16)),
        content: const Text('Are you sure you want to delete this comment?',
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('comments')
                  .doc(commentId)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Comment deleted successfully',
                          style: TextStyle(fontSize: 12))),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDeleteLikeDialog(String likeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Like', style: TextStyle(fontSize: 16)),
        content: const Text('Are you sure you want to remove this like?',
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('likes')
                  .doc(likeId)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Like removed successfully',
                          style: TextStyle(fontSize: 12))),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
