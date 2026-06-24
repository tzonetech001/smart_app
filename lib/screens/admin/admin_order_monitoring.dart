import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderMonitoring extends StatefulWidget {
  const AdminOrderMonitoring({super.key});

  @override
  State<AdminOrderMonitoring> createState() => _AdminOrderMonitoringState();
}

class _AdminOrderMonitoringState extends State<AdminOrderMonitoring> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary
          const Text('Order Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildOrderSummary(),
          
          const SizedBox(height: 16),
          
          // Filter Tabs
          _buildFilterTabs(),
          
          const SizedBox(height: 12),
          
          // Orders Table
          const Text('Orders Table', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildOrdersTable(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final orders = snapshot.data!.docs;
        final total = orders.length;
        int pending = orders.where((o) => o.get('status') == 'pending').length;
        int processing = orders.where((o) => o.get('status') == 'processing').length;
        int delivered = orders.where((o) => o.get('status') == 'delivered').length;
        int cancelled = orders.where((o) => o.get('status') == 'cancelled').length;
        
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          children: [
            _buildSummaryCard('Total Orders', total.toString(), Icons.shopping_cart, Colors.blue),
            _buildSummaryCard('Pending', pending.toString(), Icons.pending, Colors.orange),
            _buildSummaryCard('Processing', processing.toString(), Icons.refresh, Colors.purple),
            _buildSummaryCard('Delivered', delivered.toString(), Icons.check_circle, Colors.green),
            _buildSummaryCard('Cancelled', cancelled.toString(), Icons.cancel, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Pending', 'Processing', 'Delivered', 'Cancelled'];
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter, style: TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedFilter = selected ? filter.toLowerCase() : 'all'),
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF59F797).withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        var orders = snapshot.data!.docs;
        
        // Apply filter
        if (_selectedFilter != 'all') {
          orders = orders.where((o) => o.get('status') == _selectedFilter).toList();
        }
        
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No orders found', style: TextStyle(fontSize: 11))),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[200]!)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(fontSize: 9, color: _getStatusColor(status), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          'TZS ${(data['totalAmount'] ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Customer: ${data['userId'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Items: ${(data['items'] as List? ?? []).length}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Payment: ${data['paymentMethod'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('View', style: TextStyle(fontSize: 10)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.local_shipping, size: 14),
                            label: const Text('Track', style: TextStyle(fontSize: 10)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.error_outline, size: 14),
                            label: const Text('Resolve', style: TextStyle(fontSize: 10)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.red),
                          ),
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}