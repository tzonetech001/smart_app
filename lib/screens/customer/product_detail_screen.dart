import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/comment_model.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/rating_stars.dart';

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
      if (mounted) setState(() => _isLiked = likeDoc.exists);
    }
  }

  Future<void> _incrementViewCount() async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({'views': FieldValue.increment(1)});
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
          .update({'likes': FieldValue.increment(-1)});
      setState(() => _isLiked = false);
    } else {
      await likeRef.set({
        'userId': userId,
        'productId': widget.product.id,
        'createdAt': FieldValue.serverTimestamp()
      });
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({'likes': FieldValue.increment(1)});
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

    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('ratings')
        .where('productId', isEqualTo: widget.product.id)
        .get();
    double totalRating = 0;
    for (var doc in ratingsSnapshot.docs) totalRating += doc.get('rating');
    final averageRating = totalRating / ratingsSnapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({'rating': averageRating});
    setState(() => _isLoading = false);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Thank you for rating!')));
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    final sentimentResult =
        await _aiService.analyzeSentiment(_commentController.text);
    final comment = CommentModel(
      id: '',
      productId: widget.product.id,
      userId: userId,
      userName: authService.currentUser!.fullName,
      comment: _commentController.text.trim(),
      sentiment: sentimentResult['sentiment'],
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('comments')
        .add(comment.toMap());
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({'comments': FieldValue.increment(1)});
    _commentController.clear();
    setState(() => _isLoading = false);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Comment added!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.productName,
            style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey[200],
                child: widget.product.imageUrl != null
                    ? Image.network(widget.product.imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 80, color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.productName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF59F797).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(widget.product.category.displayName,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF59F797)))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Price',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('\$${widget.product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF59F797))),
                          ])),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Stock',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text('${widget.product.stock} units',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: widget.product.stock > 10
                                        ? Colors.green
                                        : Colors.orange)),
                          ])),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      RatingStars(rating: widget.product.rating),
                      const SizedBox(width: 8),
                      Text('(${widget.product.rating.toStringAsFixed(1)})',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${widget.product.comments} reviews',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 24),
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.product.description,
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                    const SizedBox(height: 24),
                    const Text('Rate this product',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: RatingStars(
                              rating: _userRating,
                              onRatingChanged: (rating) =>
                                  setState(() => _userRating = rating),
                              allowHalfRating: false)),
                      if (_userRating > 0)
                        ElevatedButton(
                            onPressed: _submitRating,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF59F797)),
                            child: const Text('Submit',
                                style: TextStyle(fontSize: 11))),
                    ]),
                    const SizedBox(height: 24),
                    const Text('Customer Reviews',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _commentController,
                              style: const TextStyle(fontSize: 12),
                              maxLines: null,
                              decoration: const InputDecoration(
                                  hintText: 'Write a review...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8)))),
                      const SizedBox(width: 8),
                      IconButton(
                          onPressed: _isLoading ? null : _submitComment,
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF59F797)),
                    ]),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('comments')
                          .where('productId', isEqualTo: widget.product.id)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        final comments = snapshot.data!.docs
                            .map((doc) => CommentModel.fromMap(
                                doc.id, doc.data() as Map<String, dynamic>))
                            .toList();
                        if (comments.isEmpty)
                          return Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: const Text(
                                      'No reviews yet. Be the first!',
                                      style: TextStyle(fontSize: 12))));
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const CircleAvatar(
                                          radius: 14,
                                          child: Icon(Icons.person, size: 12)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(comments[index].userName,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                '${comments[index].createdAt.day}/${comments[index].createdAt.month}/${comments[index].createdAt.year}',
                                                style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey)),
                                          ])),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: _getSentimentColor(
                                                    comments[index].sentiment)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Text(comments[index].sentiment,
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: _getSentimentColor(
                                                    comments[index]
                                                        .sentiment))),
                                      ),
                                    ]),
                                    const SizedBox(height: 8),
                                    Text(comments[index].comment,
                                        style: const TextStyle(fontSize: 12)),
                                  ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
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
}
