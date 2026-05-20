import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/comment_model.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/comment_section.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 0;
  bool _isLiked = false;
  bool _isLoading = false;
  final AIService _aiService = AIService();
  String _sentimentAnalysis = '';

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _incrementViewCount();
  }

  Future<void> _checkIfLiked() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId != null) {
      final likeDoc = await FirebaseFirestore.instance
          .collection('likes')
          .doc('${userId}_${widget.product.id}')
          .get();
      
      if (mounted) {
        setState(() {
          _isLiked = likeDoc.exists;
        });
      }
    }
  }

  Future<void> _incrementViewCount() async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({
      'views': FieldValue.increment(1),
    });
  }

  Future<void> _toggleLike() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    final likeRef = FirebaseFirestore.instance
        .collection('likes')
        .doc('${userId}_${widget.product.id}');
    
    if (_isLiked) {
      await likeRef.delete();
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
        'likes': FieldValue.increment(-1),
      });
      setState(() => _isLiked = false);
    } else {
      await likeRef.set({
        'userId': userId,
        'productId': widget.product.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
        'likes': FieldValue.increment(1),
      });
      setState(() => _isLiked = true);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    await FirebaseFirestore.instance
        .collection('ratings')
        .doc('${userId}_${widget.product.id}')
        .set({
      'userId': userId,
      'productId': widget.product.id,
      'rating': _userRating,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update average rating
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('ratings')
        .where('productId', isEqualTo: widget.product.id)
        .get();
    
    double totalRating = 0;
    for (var doc in ratingsSnapshot.docs) {
      totalRating += doc.get('rating');
    }
    
    final averageRating = totalRating / ratingsSnapshot.docs.length;
    
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({
      'rating': averageRating,
    });
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for rating!')),
      );
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    // Analyze sentiment
    final sentimentResult = await _aiService.analyzeSentiment(_commentController.text);
    setState(() {
      _sentimentAnalysis = sentimentResult['sentiment'];
    });
    
    final comment = CommentModel(
      id: '',
      productId: widget.product.id,
      userId: userId,
      userName: authService.currentUser!.fullName,
      comment: _commentController.text.trim(),
      sentiment: _sentimentAnalysis,
      createdAt: DateTime.now(),
    );
    
    await FirebaseFirestore.instance
        .collection('comments')
        .add(comment.toMap());
    
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({
      'comments': FieldValue.increment(1),
    });
    
    _commentController.clear();
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.productName),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
            ),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: widget.product.imageUrl != null
                  ? Image.network(
                      widget.product.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Category
                  Text(
                    widget.product.productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.product.category.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price & Stock
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '\$${widget.product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667eea),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stock',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '${widget.product.stock} units',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.product.stock > 10
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ratings
                  Row(
                    children: [
                      RatingStars(rating: widget.product.rating),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.product.rating.toStringAsFixed(1)})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.product.comments} reviews',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rate this product
                  const Text(
                    'Rate this product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RatingStars(
                          rating: _userRating,
                          onRatingChanged: (rating) {
                            setState(() {
                              _userRating = rating;
                            });
                          },
                          allowHalfRating: false,
                        ),
                      ),
                      if (_userRating > 0)
                        ElevatedButton(
                          onPressed: _submitRating,
                          child: const Text('Submit'),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comments Section
                  CommentSection(
                    productId: widget.product.id,
                    onCommentAdded: _submitComment,
                    commentController: _commentController,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}