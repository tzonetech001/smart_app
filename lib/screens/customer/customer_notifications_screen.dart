import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';
import 'customer_dashboard.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'all'; // all | products | orders | payments

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_product':
        return Icons.new_releases;
      case 'promotion':
        return Icons.local_offer;
      case 'order_update':
      case 'new_order':
        return Icons.local_shipping;
      case 'payment_pending':
      case 'payment_approved':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'new_product':
        return Colors.blue;
      case 'promotion':
        return Colors.purple;
      case 'order_update':
      case 'new_order':
        return Colors.orange;
      case 'payment_pending':
        return Colors.amber;
      case 'payment_approved':
        return Colors.green;
      default:
        return const Color(0xFF3BC77A);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3BC77A),
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
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All', style: TextStyle(fontSize: 11)),
                  selected: _selectedFilter == 'all',
                  selectedColor: const Color(0xFF3BC77A).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF3BC77A),
                  onSelected: (selected) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Products', style: TextStyle(fontSize: 11)),
                  selected: _selectedFilter == 'products',
                  selectedColor: const Color(0xFF3BC77A).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF3BC77A),
                  onSelected: (selected) => setState(() => _selectedFilter == 'products'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Orders', style: TextStyle(fontSize: 11)),
                  selected: _selectedFilter == 'orders',
                  selectedColor: const Color(0xFF3BC77A).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF3BC77A),
                  onSelected: (selected) => setState(() => _selectedFilter == 'orders'),
                ),
              ],
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
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3BC77A))));
                }

                var notifications = snapshot.data!.docs.map((doc) =>
                    NotificationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

                // Apply local filters
                if (_selectedFilter == 'products') {
                  notifications = notifications.where((n) => n.type == 'new_product' || n.type == 'promotion').toList();
                } else if (_selectedFilter == 'orders') {
                  notifications = notifications.where((n) => n.type == 'order_update').toList();
                }

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('No notifications yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            ? const Border(left: BorderSide(color: Color(0xFF3BC77A), width: 4))
                            : Border.all(color: Colors.grey[200]!),
                        boxShadow: isUnread
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(n.type).withValues(alpha: 0.1),
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
                            Text(
                              _timeAgo(n.createdAt),
                              style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (isUnread) {
                            await NotificationService.markAsRead(n.id);
                          }

                          if (!mounted) return;

                          // Deep linking
                          if (n.productId != null && n.productId!.isNotEmpty) {
                            // Fetch product
                            final doc = await FirebaseFirestore.instance.collection('products').doc(n.productId).get();
                            if (doc.exists && mounted) {
                              final product = ProductModel.fromMap(doc.id, doc.data()!);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                              );
                            }
                          } else if (n.orderId != null && n.orderId!.isNotEmpty) {
                            // Navigate to Orders Tab (index 3)
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerDashboard(initialTab: 3)),
                              (route) => false,
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

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
