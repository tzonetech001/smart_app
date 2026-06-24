import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/analytics_service.dart';
import 'order_confirmation_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  String _formatCurrency(double amount) => 'TZS ${amount.toStringAsFixed(0)}';

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return Colors.orange;
      case OrderStatus.paymentConfirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.teal;
      case OrderStatus.packed:
        return Colors.amber;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.outForDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // High-fidelity AzamPesa simulation prompt
  void _showAzamPesaRetryDialog(BuildContext context, OrderModel order) {
    final phoneController =
        TextEditingController(text: order.shippingAddress.phoneNumber);
    final pinController = TextEditingController();
    bool isSimulating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AzamPesa Header
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF005CAA), // Azam blue
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'azam',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AzamPesa Push Sim',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Retrying payment for Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  if (isSimulating) ...[
                    const CircularProgressIndicator(color: Color(0xFF005CAA)),
                    const SizedBox(height: 16),
                    const Text('Sending USSD Push to your phone...',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                  ] else ...[
                    Text(
                      _formatCurrency(order.totalAmount),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005CAA)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'AzamPesa Phone Number',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'AzamPesa Wallet PIN',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handlePaymentFailure(order.id);
                            },
                            child: const Text('Simulate Fail',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (phoneController.text.isEmpty ||
                                  pinController.text.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please enter valid number and PIN'),
                                      backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setModalState(() => isSimulating = true);
                              await Future.delayed(const Duration(seconds: 2));
                              Navigator.pop(ctx);
                              _handlePaymentSuccess(order);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005CAA)),
                            child: const Text('Pay Now',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePaymentSuccess(OrderModel order) async {
    try {
      final transactionId = 'APESA${DateTime.now().millisecondsSinceEpoch}';

      // Update Firestore Order
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'paymentTransactionId': transactionId,
        'paymentStatus': 'paid',
        'status': 'paymentConfirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Save payment transaction record
      await FirebaseFirestore.instance.collection('payments').add({
        'orderId': order.id,
        'amount': order.totalAmount,
        'method': 'azam_pesa',
        'phoneNumber': order.shippingAddress.phoneNumber,
        'transactionId': transactionId,
        'status': 'completed',
        'paymentDate': FieldValue.serverTimestamp(),
      });

      // Log purchase behavior analytics events
      for (var item in order.items) {
        try {
          final prodDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(item.productId)
              .get();
          if (prodDoc.exists) {
            final product =
                ProductModel.fromMap(item.productId, prodDoc.data()!);
            await AnalyticsService.logPurchase(
              product: product,
              quantity: item.quantity,
              city: order.shippingAddress.city,
              country: 'Tanzania',
            );
          }
        } catch (_) {}
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              orderId: order.id,
              amountPaid: order.totalAmount,
              paymentMethod: 'AzamPesa',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Payment validation failed: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _handlePaymentFailure(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Simulated AzamPesa payment failed. Order kept in Pending Payment state.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: Text('Please login to view orders.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: _userId)
            .orderBy('orderDate', descending: true)
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
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No orders yet',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = docs
              .map((doc) => OrderModel.fromMap(
                  doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusDisplayName = order.status.displayName;
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.orderDate),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusDisplayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_formatCurrency(order.totalAmount)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Text(
                'Items: ${order.items.fold(0, (sum, i) => sum + i.quantity)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Products List
                const Text('Items Details',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName} x${item.quantity}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ),
                          Text(
                            _formatCurrency(item.price * item.quantity),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),

                // Location Details
                if (order.customerLocation != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Location: ${order.customerLocation!['ward']}, ${order.customerLocation!['district']}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Payment Options & Stepper Tracker
                if (order.status == OrderStatus.pendingPayment) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAzamPesaRetryDialog(context, order),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Retry Payment (AzamPesa)',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005CAA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stepper Tracker Diagram
                const Text('Tracking Progress',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 12),
                _buildOrderTrackerStepper(order.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTrackerStepper(OrderStatus currentStatus) {
    final stages = [
      {'status': OrderStatus.pendingPayment, 'label': 'Pending Pay'},
      {'status': OrderStatus.paymentConfirmed, 'label': 'Paid'},
      {'status': OrderStatus.processing, 'label': 'Processing'},
      {'status': OrderStatus.packed, 'label': 'Packed'},
      {'status': OrderStatus.shipped, 'label': 'Shipped'},
      {'status': OrderStatus.outForDelivery, 'label': 'Out for Delivery'},
      {'status': OrderStatus.delivered, 'label': 'Delivered'},
    ];

    // Determine current index
    int currentIndex =
        stages.indexWhere((stage) => stage['status'] == currentStatus);

    // If order is cancelled, highlight it differently
    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red[50],
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 16),
            SizedBox(width: 8),
            Text('This order has been Cancelled.',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF59F797)
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                                color: const Color(0xFF59F797).withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1)
                          ]
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (index < stages.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: index < currentIndex
                        ? const Color(0xFF59F797)
                        : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  stage['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
