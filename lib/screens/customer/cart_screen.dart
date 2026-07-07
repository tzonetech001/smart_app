import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_screen.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../services/analytics_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatCurrency(double amount) => 'Tsh ${amount.toStringAsFixed(0)}';

  Future<void> _updateQuantity(String productId, int oldQty, int change) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('cart')
        .doc('${userId}_$productId');

    final newQty = oldQty + change;
    if (newQty <= 0) {
      await _removeItem(productId, oldQty);
    } else {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (productDoc.exists) {
        final stock = productDoc.data()?['stock'] ?? 0;
        if (newQty > stock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot add more. Only $stock units left in stock.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      await docRef.update({'quantity': newQty});
    }
  }

  Future<void> _removeItem(String productId, int qty) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (productDoc.exists) {
        final product = ProductModel.fromMap(productId, productDoc.data()!);
        await AnalyticsService.logRemoveFromCart(product, qty);
      }
    } catch (_) {}

    await FirebaseFirestore.instance
        .collection('cart')
        .doc('${userId}_$productId')
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart.'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  
  Future<void> _addRecommendedToCart(ProductModel recommendedProduct) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('cart')
          .doc('${userId}_${recommendedProduct.id}');
      
      final doc = await cartRef.get();
      if (doc.exists) {
        final currentQty = doc.get('quantity') ?? 0;
        await cartRef.update({
          'quantity': currentQty + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.set({
          'userId': userId,
          'productId': recommendedProduct.id,
          'productName': recommendedProduct.productName,
          'imageUrl': recommendedProduct.imageUrl ?? '',
          'price': recommendedProduct.price,
          'quantity': 1,
          'entrepreneurId': recommendedProduct.entrepreneurId,
          'category': recommendedProduct.category.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${recommendedProduct.productName} to Cart!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  double _calculateTotal(List<CartItemModel> items) {
    double total = 0.0;
    for (var item in items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // Calculate promotional bundle discounts dynamically
  double _calculatePromoDiscount(List<CartItemModel> items) {
    double discount = 0.0;

    bool hasItem(String term) => items.any((i) => i.productId.toLowerCase().contains(term) || i.productName.toLowerCase().contains(term));
    CartItemModel getItem(String term) => items.firstWhere((i) => i.productId.toLowerCase().contains(term) || i.productName.toLowerCase().contains(term));

    // Rice -> Cooking Oil (30% off oil)
    if (hasItem('rice') && hasItem('oil')) {
      final rice = getItem('rice');
      final oil = getItem('oil');
      int matchQty = rice.quantity < oil.quantity ? rice.quantity : oil.quantity;
      discount += oil.price * 0.30 * matchQty;
    }

    // Laptop -> Antivirus (15% off antivirus)
    if (hasItem('laptop') && hasItem('antivirus')) {
      final laptop = getItem('laptop');
      final antivirus = getItem('antivirus');
      int matchQty = laptop.quantity < antivirus.quantity ? laptop.quantity : antivirus.quantity;
      discount += antivirus.price * 0.15 * matchQty;
    }

    // Phone -> Screen Protector (50% off protector)
    if (hasItem('phone') && hasItem('protector')) {
      final phone = getItem('phone');
      final protector = getItem('protector');
      int matchQty = phone.quantity < protector.quantity ? phone.quantity : protector.quantity;
      discount += protector.price * 0.50 * matchQty;
    }

    // Printer -> Printing Paper (20% off paper)
    if (hasItem('printer') && hasItem('paper')) {
      final printer = getItem('printer');
      final paper = getItem('paper');
      int matchQty = printer.quantity < paper.quantity ? printer.quantity : paper.quantity;
      discount += paper.price * 0.20 * matchQty;
    }

    // Drink -> Snack (25% off snacks)
    final hasDrink = items.any((i) => i.productId.toLowerCase().contains('drink') || i.productId.toLowerCase().contains('soda') || i.productName.toLowerCase().contains('drink') || i.productName.toLowerCase().contains('soda'));
    final hasSnack = items.any((i) => i.productId.toLowerCase().contains('snack') || i.productName.toLowerCase().contains('snack'));
    if (hasDrink && hasSnack) {
      final drink = items.firstWhere((i) => i.productId.toLowerCase().contains('drink') || i.productId.toLowerCase().contains('soda') || i.productName.toLowerCase().contains('drink') || i.productName.toLowerCase().contains('soda'));
      final snack = items.firstWhere((i) => i.productId.toLowerCase().contains('snack') || i.productName.toLowerCase().contains('snack'));
      int matchQty = drink.quantity < snack.quantity ? drink.quantity : snack.quantity;
      discount += snack.price * 0.25 * matchQty;
    }

    return discount;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please login to view your cart.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cart')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 17),
                  const Text('Your shopping cart is empty', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          final List<CartItemModel> cartItems = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CartItemModel.fromMap(data);
          }).toList();

          return _buildCartContent(cartItems);
        },
      ),
    );
  }

  Widget _buildCartContent(List<CartItemModel> cartItems) {
    final subtotal = _calculateTotal(cartItems);
    final promoDiscount = _calculatePromoDiscount(cartItems);
    const deliveryFee = 3000.0; // Fixed delivery fee
    final total = subtotal - promoDiscount + deliveryFee;

    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              ...cartItems.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageUrl?.isNotEmpty == true
                            ? Image.network(
                                item.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[100],
                                child: const Icon(Icons.shopping_bag, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(item.price),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3BC77A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Controls
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () => _removeItem(item.productId, item.quantity),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _updateQuantity(item.productId, item.quantity, -1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.remove, size: 12),
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                GestureDetector(
                                  onTap: () => _updateQuantity(item.productId, item.quantity, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.add, size: 12, color: Color(0xFF3BC77A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
              
              // Dynamic recommendations section
              const SizedBox(height: 8),
              _buildCartRecommendations(cartItems),
            ],
          ),
        ),

        // Checkout Summary Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_formatCurrency(subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (promoDiscount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Promo Bundle Discount', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                      Text('- ${_formatCurrency(promoDiscount)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_formatCurrency(deliveryFee), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3BC77A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Log Initiate Checkout for all items
                      for (var item in cartItems) {
                        try {
                          final productDoc = await FirebaseFirestore.instance
                              .collection('products')
                              .doc(item.productId)
                              .get();
                          if (productDoc.exists) {
                            final product = ProductModel.fromMap(item.productId, productDoc.data()!);
                            await AnalyticsService.logInitiateCheckout(product, item.quantity);
                          }
                        } catch (_) {}
                      }

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              cartItems: cartItems,
                              subtotal: subtotal - promoDiscount, // apply discount to subtotal
                              deliveryFee: deliveryFee,
                              total: total,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3BC77A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Proceed to Checkout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartRecommendations(List<CartItemModel> currentCart) {
    // Determine triggers
    String? searchWord;
    String? triggerName;
    String? recMessage;

    bool hasItem(String term) => currentCart.any((i) => i.productId.toLowerCase().contains(term) || i.productName.toLowerCase().contains(term));

    if (hasItem('rice') && !hasItem('oil')) {
      searchWord = 'oil';
      triggerName = 'Cooking Oil';
      recMessage = 'Buy Cooking Oil with Basmati Rice and get it at 30% Off!';
    } else if (hasItem('laptop') && !hasItem('antivirus')) {
      searchWord = 'antivirus';
      triggerName = 'Antivirus';
      recMessage = 'Protect your laptop! Add Antivirus security at 15% Off!';
    } else if (hasItem('phone') && !hasItem('protector')) {
      searchWord = 'protector';
      triggerName = 'Screen Protector';
      recMessage = 'Keep your screen safe! Add a Glass Screen Protector for 50% Off!';
    } else if (hasItem('printer') && !hasItem('paper')) {
      searchWord = 'paper';
      triggerName = 'Paper';
      recMessage = 'Need printing paper? Save 20% on A4 paper packs now!';
    } else {
      final hasDrink = currentCart.any((i) => i.productId.toLowerCase().contains('drink') || i.productId.toLowerCase().contains('soda') || i.productName.toLowerCase().contains('drink') || i.productName.toLowerCase().contains('soda'));
      final hasSnack = currentCart.any((i) => i.productId.toLowerCase().contains('snack') || i.productName.toLowerCase().contains('snack'));
      if (hasDrink && !hasSnack) {
        searchWord = 'snack';
        triggerName = 'Snack';
        recMessage = 'Complete your refreshment combo! Add a snack at 25% Off!';
      }
    }

    if (searchWord == null || triggerName == null || recMessage == null) {
      return const SizedBox.shrink();
    }

    final targetSearch = searchWord;
    final displayMsg = recMessage;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final products = snapshot.data!.docs.map((doc) {
          return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();

        final recProductIndex = products.indexWhere((p) => p.productName.toLowerCase().contains(targetSearch));
        if (recProductIndex == -1) return const SizedBox.shrink();

        final recommendedProduct = products[recProductIndex];

        return Card(
          color: Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green[150]!),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Frequently Bought Together Offer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayMsg,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: recommendedProduct.imageUrl != null
                          ? Image.network(recommendedProduct.imageUrl!, height: 35, width: 35, fit: BoxFit.cover)
                          : Container(height: 35, width: 35, color: Colors.grey[200], child: const Icon(Icons.image, size: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recommendedProduct.productName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            _formatCurrency(recommendedProduct.price),
                            style: const TextStyle(fontSize: 9, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _addRecommendedToCart(recommendedProduct),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3BC77A),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(60, 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
