import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../models/order_model.dart';

class EntrepreneurOrdersScreen extends StatefulWidget {
  const EntrepreneurOrdersScreen({super.key});

  @override
  State<EntrepreneurOrdersScreen> createState() => _EntrepreneurOrdersScreenState();
}

class _EntrepreneurOrdersScreenState extends State<EntrepreneurOrdersScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedStatusFilter = 'all';
  String _selectedSort = 'date'; // date | amount | customer

  String _formatTZS(double v) => 'Tsh ${v.toStringAsFixed(0)}';

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment: return Colors.amber;
      case OrderStatus.paymentConfirmed: return Colors.blue;
      case OrderStatus.processing: return Colors.indigo;
      case OrderStatus.packed: return Colors.teal;
      case OrderStatus.shipped: return Colors.purple;
      case OrderStatus.outForDelivery: return Colors.pink;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(order.id);

      Map<String, dynamic> updates = {
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.paymentConfirmed) {
        updates['paymentStatus'] = PaymentStatus.paid.toString().split('.').last;
      }

      batch.update(orderRef, updates);
      await batch.commit();

      await NotificationService.sendOrderStatusUpdateNotification(
        userId: order.userId,
        orderId: order.id,
        status: newStatus.displayName,
      );

      if (newStatus == OrderStatus.paymentConfirmed) {
        await NotificationService.sendPaymentApprovedNotification(
          entrepreneurId: order.entrepreneurId,
          orderId: order.id,
          amount: order.totalAmount,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to: ${newStatus.displayName}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to manage orders.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Order Summary Stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('entrepreneurId', isEqualTo: _userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final orders = snapshot.data!.docs;
              final total = orders.length;
              final pending = orders.where((o) => o.get('status') == 'pendingPayment').length;
              return Row(
                children: [
                  _buildStatusBadge('Total: $total', Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatusBadge('Pending: $pending', Colors.amber),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending Payment', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Processing', 'processing'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled', 'cancelled'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Delivered', 'delivered'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Orders list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('entrepreneurId', isEqualTo: _userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59F797))));
                }

                var orders = snapshot.data!.docs
                    .map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

                // Status filtering
                if (_selectedStatusFilter == 'pending') {
                  orders = orders.where((o) => o.status == OrderStatus.pendingPayment).toList();
                } else if (_selectedStatusFilter == 'processing') {
                  orders = orders.where((o) =>
                      o.status == OrderStatus.paymentConfirmed ||
                      o.status == OrderStatus.processing ||
                      o.status == OrderStatus.packed ||
                      o.status == OrderStatus.shipped ||
                      o.status == OrderStatus.outForDelivery).toList();
                } else if (_selectedStatusFilter == 'completed') {
                  orders = orders.where((o) => o.status == OrderStatus.delivered).toList();
                } else if (_selectedStatusFilter == 'cancelled') {
                  orders = orders.where((o) => o.status == OrderStatus.cancelled).toList();
                } else if (_selectedStatusFilter == 'delivered') {
                  orders = orders.where((o) => o.status == OrderStatus.delivered).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('No orders found', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final shortId = o.id.length >= 8 ? o.id.substring(0, 8).toUpperCase() : o.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order #$shortId', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(o.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    o.status.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(o.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Customer & Location
                            Text('Customer: ${o.shippingAddress.fullName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('Location: ${o.shippingAddress.district} - ${o.shippingAddress.street}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Date: ${o.orderDate.day}/${o.orderDate.month}/${o.orderDate.year}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            
                            const Divider(height: 24),

                            // Items
                            const Text('Items:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 6),
                            ...o.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${item.quantity}x ${item.productName}', style: const TextStyle(fontSize: 11))),
                                  Text(_formatTZS(item.price * item.quantity), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )),
                            
                            const Divider(height: 24),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Amount:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(_formatTZS(o.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF59F797))),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Action Buttons
                            _buildActionsForOrder(o),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _selectedStatusFilter == filterValue;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      checkmarkColor: const Color(0xFF59F797),
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? filterValue : 'all';
        });
      },
    );
  }

  Widget _buildActionsForOrder(OrderModel order) {
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    List<Widget> buttons = [];

    if (order.status == OrderStatus.pendingPayment) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.paymentConfirmed),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Approve Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.paymentConfirmed) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.processing),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Start Processing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.processing) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.packed),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Mark Packed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.packed) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.shipped),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Ship Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.shipped) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.outForDelivery),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
            child: const Text('Send Out for Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (order.status == OrderStatus.outForDelivery) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, OrderStatus.delivered),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Mark Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    // Cancel order
    if (order.status == OrderStatus.pendingPayment ||
        order.status == OrderStatus.paymentConfirmed ||
        order.status == OrderStatus.processing ||
        order.status == OrderStatus.packed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
      buttons.add(
        OutlinedButton(
          onPressed: () => _updateStatus(order, OrderStatus.cancelled),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
          child: const Text('Cancel', style: TextStyle(fontSize: 11)),
        ),
      );
    }

    return Row(children: buttons);
  }
}