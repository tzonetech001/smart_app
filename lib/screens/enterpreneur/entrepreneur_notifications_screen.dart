import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/product_model.dart';
import 'entrepreneur_orders_screen.dart';

// Local fallback EditProductScreen to avoid missing import during development.
// Replace this with your actual edit_product_screen.dart implementation when available.
class EditProductScreen extends StatelessWidget {
  final ProductModel product;
  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: const Color(0xFF59F797),
      ),
      body: const Center(
        child: Text('Edit Product screen (placeholder)', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class EntrepreneurNotificationsScreen extends StatefulWidget {
  const EntrepreneurNotificationsScreen({super.key});

  @override
  State<EntrepreneurNotificationsScreen> createState() => _EntrepreneurNotificationsScreenState();
}

class _EntrepreneurNotificationsScreenState extends State<EntrepreneurNotificationsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'all';

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_order': return Icons.shopping_bag;
      case 'payment_pending': return Icons.pending_actions;
      case 'payment_approved': return Icons.check_circle;
      case 'low_stock': return Icons.warning;
      case 'out_of_stock': return Icons.block;
      case 'order_update': return Icons.local_shipping;
      case 'new_product': return Icons.new_releases;
      case 'promotion': return Icons.local_offer;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'new_order': return Colors.blue;
      case 'payment_pending': return Colors.orange;
      case 'payment_approved': return Colors.green;
      case 'low_stock': return Colors.amber;
      case 'out_of_stock': return Colors.red;
      case 'order_update': return Colors.teal;
      case 'new_product': return const Color(0xFF59F797);
      case 'promotion': return Colors.purple;
      default: return const Color(0xFF59F797);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: Text('Please login to view notifications.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => NotificationService.markAllRead(_userId!),
            child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Stats
          _buildNotificationStats(),
          const Divider(height: 1),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🛒 Orders', 'orders'),
                  const SizedBox(width: 8),
                  _buildFilterChip('💳 Payments', 'payments'),
                  const SizedBox(width: 8),
                  _buildFilterChip('📦 Stock', 'stock'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🆕 Products', 'products'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Notifications Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: _userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59F797))));
                }

                var notifications = snapshot.data!.docs.map((doc) =>
                    NotificationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

                // Apply local filters
                if (_selectedFilter == 'orders') {
                  notifications = notifications.where((n) => n.type == 'new_order' || n.type == 'order_update').toList();
                } else if (_selectedFilter == 'payments') {
                  notifications = notifications.where((n) => n.type == 'payment_pending' || n.type == 'payment_approved').toList();
                } else if (_selectedFilter == 'stock') {
                  notifications = notifications.where((n) => n.type == 'low_stock' || n.type == 'out_of_stock').toList();
                } else if (_selectedFilter == 'products') {
                  notifications = notifications.where((n) => n.type == 'new_product' || n.type == 'promotion').toList();
                }

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('No alerts or notifications', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final isUnread = !n.isRead;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnread ? Colors.white : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: isUnread
                            ? const Border(left: BorderSide(color: Color(0xFF59F797), width: 4))
                            : Border.all(color: Colors.grey[200]!),
                        boxShadow: isUnread
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(n.type).withOpacity(0.1),
                          child: Icon(_getIconForType(n.type), color: _getColorForType(n.type), size: 20),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                            color: isUnread ? Colors.black : Colors.grey[800],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              n.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: isUnread ? Colors.black87 : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(_timeAgo(n.createdAt), style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                                if (n.productId != null || n.orderId != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF59F797).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      n.productId != null ? 'View Product' : 'View Order',
                                      style: TextStyle(fontSize: 8, color: const Color(0xFF59F797)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (isUnread) await NotificationService.markAsRead(n.id);
                          if (!mounted) return;

                          // Deep linking
                          if (n.productId != null && n.productId!.isNotEmpty) {
                            final doc = await FirebaseFirestore.instance
                                .collection('products')
                                .doc(n.productId)
                                .get();
                            if (doc.exists && mounted) {
                              final product = ProductModel.fromMap(doc.id, doc.data()!);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                              );
                            }
                          } else if (n.orderId != null && n.orderId!.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EntrepreneurOrdersScreen()),
                            );
                          }
                        },
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

  Widget _buildNotificationStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final notifications = snapshot.data!.docs;
        final total = notifications.length;
        final unread = notifications.where((n) => n.get('isRead') == false).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: $total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Unread: $unread', style: TextStyle(fontSize: 11, color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      checkmarkColor: const Color(0xFF59F797),
      onSelected: (selected) => setState(() => _selectedFilter = selected ? filterValue : 'all'),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 7) return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    if (difference.inDays >= 1) return '${difference.inDays}d ago';
    if (difference.inHours >= 1) return '${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}