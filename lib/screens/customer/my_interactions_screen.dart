import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';

class MyInteractionsScreen extends StatefulWidget {
  const MyInteractionsScreen({super.key});

  @override
  State<MyInteractionsScreen> createState() => _MyInteractionsScreenState();
}

class _MyInteractionsScreenState extends State<MyInteractionsScreen> {
  int _selectedTab = 0;
  
  final List<String> _tabs = ['❤️ Liked Products', '💬 My Reviews'];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.all(12),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: const Text('❤️ Liked Products', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 1,
                label: const Text('💬 My Reviews', style: TextStyle(fontSize: 11)),
              ),
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

        Expanded(
          child: _selectedTab == 0
              ? _buildLikedProducts(authService.currentUser!.id)
              : _buildMyReviews(authService.currentUser!.id),
        ),
      ],
    );
  }

  Widget _buildLikedProducts(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, likeSnapshot) {
        if (!likeSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final likedProductIds = likeSnapshot.data!.docs.map((doc) => doc.get('productId') as String).toList();
        
        if (likedProductIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No liked products yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start liking products to see them here',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where(FieldPath.documentId, whereIn: likedProductIds)
              .snapshots(),
          builder: (context, productSnapshot) {
            if (!productSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            var products = productSnapshot.data!.docs.map((doc) {
              return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();
            
            // Sort by liked date (maintain order from likes collection)
            products.sort((a, b) {
              final aIndex = likedProductIds.indexOf(a.id);
              final bIndex = likedProductIds.indexOf(b.id);
              return aIndex.compareTo(bIndex);
            });
            
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMyReviews(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final comments = snapshot.data!.docs;
        
        if (comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your reviews will appear here',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final productId = comment.get('productId');
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
              builder: (context, productSnapshot) {
                if (!productSnapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                
                final productData = productSnapshot.data!.data() as Map<String, dynamic>;
                final product = ProductModel.fromMap(productId, productData);
                final sentiment = comment.get('sentiment') ?? 'neutral';
                final createdAt = (comment.get('createdAt') as Timestamp).toDate();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product.imageUrl != null
                                    ? Image.network(
                                        product.imageUrl!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 25),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.productName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getSentimentColor(sentiment).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            sentiment.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: _getSentimentColor(sentiment),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(createdAt),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              comment.get('comment') ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF59F797),
                              ),
                              child: const Text('View Product', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Icon(Icons.image, size: 40, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF59F797),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 10, color: Colors.red),
                      const SizedBox(width: 2),
                      Text('${product.likes}', style: const TextStyle(fontSize: 9)),
                      const SizedBox(width: 8),
                      const Icon(Icons.comment, size: 10, color: Colors.blue),
                      const SizedBox(width: 2),
                      Text('${product.comments}', style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}