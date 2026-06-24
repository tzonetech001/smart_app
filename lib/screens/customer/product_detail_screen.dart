<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isProcessingBuyNow = false;

  Future<void> _addToCart({bool silent = false, double? overridePrice, String? customName}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!silent) setState(() => _isAddingToCart = true);

    try {
      final cartRef = FirebaseFirestore.instance.collection('cart').doc('${userId}_${widget.product.id}');
      final doc = await cartRef.get();

      if (doc.exists) {
        final currentQty = doc.get('quantity') ?? 0;
        await cartRef.update({
          'quantity': currentQty + _quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.set({
          'userId': userId,
          'productId': widget.product.id,
          'productName': customName ?? widget.product.productName,
          'imageUrl': widget.product.imageUrl ?? '',
          'price': overridePrice ?? widget.product.price,
          'quantity': _quantity,
          'entrepreneurId': widget.product.entrepreneurId,
          'category': widget.product.category.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.productName} added to cart!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (!silent) setState(() => _isAddingToCart = false);
  }

  Future<void> _handleBuyNow() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessingBuyNow = true);

    try {
      // 1. Add it to the Firestore cart database
      await _addToCart(silent: true);

      // 2. Navigate straight to Checkout screen with this item
      final cartItem = CartItemModel(
        productId: widget.product.id,
        productName: widget.product.productName,
        imageUrl: widget.product.imageUrl ?? '',
        price: widget.product.price,
        quantity: _quantity,
        entrepreneurId: widget.product.entrepreneurId,
        category: widget.product.category.toString().split('.').last,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(
              cartItems: [cartItem],
              subtotal: widget.product.price * _quantity,
              deliveryFee: 3000.0, // Standard delivery fee
              total: (widget.product.price * _quantity) + 3000.0,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buy Now error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isProcessingBuyNow = false);
  }

  // Define smart bundle triggers
  Map<String, String>? _getBundleTrigger() {
    final name = widget.product.productName.toLowerCase();
    if (name.contains('rice')) {
      return {'search': 'oil', 'name': 'Cooking Oil', 'desc': 'Cooking Oil (30% Off!)', 'discount': '0.30'};
    } else if (name.contains('laptop')) {
      return {'search': 'antivirus', 'name': 'Antivirus', 'desc': 'Antivirus Security (15% Off!)', 'discount': '0.15'};
    } else if (name.contains('phone')) {
      return {'search': 'protector', 'name': 'Screen Protector', 'desc': 'Glass Screen Protector (50% Off!)', 'discount': '0.50'};
    } else if (name.contains('printer')) {
      return {'search': 'paper', 'name': 'Paper', 'desc': 'A4 Printing Paper (20% Off!)', 'discount': '0.20'};
    } else if (name.contains('drink') || name.contains('soda') || name.contains('cola')) {
      return {'search': 'snack', 'name': 'Snack', 'desc': 'Delicious Snacks Combo!', 'discount': '0.25'};
    }
    return null;
  }

  Future<void> _addBundleToCart(BuildContext context, ProductModel recommendedProduct, double discount) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Add current product
      await _addToCart(silent: true);

      // Add recommended product (with discount applied)
      final discountedPrice = recommendedProduct.price * (1.0 - discount);
      await FirebaseFirestore.instance.collection('cart').doc('${userId}_${recommendedProduct.id}').set({
        'userId': userId,
        'productId': recommendedProduct.id,
        'productName': '${recommendedProduct.productName} (Promo Bundle)',
        'imageUrl': recommendedProduct.imageUrl ?? '',
        'price': discountedPrice,
        'quantity': 1,
        'entrepreneurId': recommendedProduct.entrepreneurId,
        'category': recommendedProduct.category.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Frequently Bought Together bundle added to Cart!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add bundle: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _getBundleTrigger();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.productName, style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF3BC77A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: widget.product.imageUrl != null
                  ? Image.network(
                      widget.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 80, color: Colors.grey),
                    )
                  : const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Category
                  Text(widget.product.productName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3BC77A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.product.category.displayName,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF3BC77A), fontWeight: FontWeight.bold),
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
                            const Text('Price', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              'TZS ${widget.product.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3BC77A)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Available', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              '${widget.product.stock} units',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: widget.product.stock > 5 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: Color(0xFF3BC77A)),
                              onPressed: widget.product.stock > _quantity ? () => setState(() => _quantity++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Buy Actions Layout
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isAddingToCart ? null : () => _addToCart(),
                            icon: _isAddingToCart
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add to Cart', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3BC77A)),
                              foregroundColor: const Color(0xFF3BC77A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessingBuyNow ? null : _handleBuyNow,
                            icon: _isProcessingBuyNow
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.flash_on, size: 18),
                            label: const Text('Buy Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3BC77A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Frequently Bought Together Bundle recommendations
                  if (bundle != null) ...[
                    _buildFrequentlyBoughtTogether(bundle),
                    const SizedBox(height: 24),
                  ],
                  
                  // Description
                  const Text('Product Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentlyBoughtTogether(Map<String, String> bundleInfo) {
    final searchTerm = bundleInfo['search']!;
    final discountPercent = double.parse(bundleInfo['discount']!);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        // Search for items whose names contain the target search keyword
        final products = snapshot.data!.docs.map((doc) {
          return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();

        final recProductIndex = products.indexWhere((p) => p.productName.toLowerCase().contains(searchTerm) && p.id != widget.product.id);
        if (recProductIndex == -1) return const SizedBox.shrink();

        final recommendedProduct = products[recProductIndex];

        return Card(
          color: Colors.lightGreen[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.green[200]!)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handshake_outlined, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Frequently Bought Together',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Primary Product Mini Preview
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: widget.product.imageUrl != null
                                ? Image.network(widget.product.imageUrl!, height: 40, width: 40, fit: BoxFit.cover)
                                : Container(height: 40, width: 40, color: Colors.grey[200], child: const Icon(Icons.image, size: 16)),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.product.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.add, size: 16, color: Colors.grey),
                    // Secondary Product Mini Preview
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: recommendedProduct.imageUrl != null
                                ? Image.network(recommendedProduct.imageUrl!, height: 40, width: 40, fit: BoxFit.cover)
                                : Container(height: 40, width: 40, color: Colors.grey[200], child: const Icon(Icons.image, size: 16)),
                          ),
                          const SizedBox(height: 4),
                          Text(recommendedProduct.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Offer: Add ${recommendedProduct.productName} now and get it for TZS ${(recommendedProduct.price * (1.0 - discountPercent)).toStringAsFixed(0)} (normally TZS ${recommendedProduct.price.toStringAsFixed(0)})!',
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _addBundleToCart(context, recommendedProduct, discountPercent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add both to Cart', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
=======
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
>>>>>>> 4117d75f10e027f01c5a93aa1ad8936a92927495
