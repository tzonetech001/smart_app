import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class EntrepreneurPaymentsScreen extends StatefulWidget {
  const EntrepreneurPaymentsScreen({super.key});

  @override
  State<EntrepreneurPaymentsScreen> createState() => _EntrepreneurPaymentsScreenState();
}

class _EntrepreneurPaymentsScreenState extends State<EntrepreneurPaymentsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'all';

  String _formatTZS(double v) => 'TZS ${v.toStringAsFixed(0)}';

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.amber;
      case 'failed': return Colors.red;
      case 'refunded': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: Text('Please login to manage payments.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Payment Summary
          _buildPaymentSummary(),
          const SizedBox(height: 8),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('✅ Completed', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('⏳ Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('❌ Failed', 'failed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('↩️ Refunded', 'refunded'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Payments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('payments')
                  .where('entrepreneurId', isEqualTo: _userId)
                  .orderBy('paymentDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59F797))));
                }

                var payments = snapshot.data!.docs;

                // Apply filter
                if (_selectedFilter != 'all') {
                  payments = payments.where((p) => p.get('status') == _selectedFilter).toList();
                }

                if (payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('No payments found', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final data = payment.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final amount = (data['amount'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPaymentStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getPaymentStatusColor(status),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Payment #${payment.id.substring(0, 8)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTZS(amount),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Method: ${data['method'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ),
                                Expanded(
                                  child: Text('Order: ${data['orderId']?.substring(0, 8) ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ),
                                Text(
                                  _formatDate((data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now()),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (status == 'pending')
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('payments')
                                            .doc(payment.id)
                                            .update({'status': 'completed'});
                                        await NotificationService.sendPaymentApprovedNotification(
                                          entrepreneurId: _userId!,
                                          orderId: data['orderId'] ?? '',
                                          amount: amount,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Payment approved!'), backgroundColor: Colors.green),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Approve', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                if (status == 'pending') const SizedBox(width: 8),
                                if (status == 'pending')
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('payments')
                                            .doc(payment.id)
                                            .update({'status': 'failed'});
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Payment rejected!'), backgroundColor: Colors.red),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                if (status == 'completed')
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showReceiptDialog(context, data, amount),
                                      icon: const Icon(Icons.receipt, size: 16),
                                      label: const Text('Receipt', style: TextStyle(fontSize: 11)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('entrepreneurId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final payments = snapshot.data!.docs;
        final total = payments.length;
        final completed = payments.where((p) => p.get('status') == 'completed').length;
        final pending = payments.where((p) => p.get('status') == 'pending').length;
        final totalAmount = payments.fold<double>(0, (sum, p) => sum + ((p.get('amount') ?? 0).toDouble()));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Total', total.toString(), Icons.payment, Colors.blue),
              ),
              Expanded(
                child: _buildSummaryCard('Completed', completed.toString(), Icons.check_circle, Colors.green),
              ),
              Expanded(
                child: _buildSummaryCard('Pending', pending.toString(), Icons.pending, Colors.amber),
              ),
              Expanded(
                child: _buildSummaryCard('Amount', _formatTZS(totalAmount), Icons.attach_money, const Color(0xFF59F797)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      checkmarkColor: const Color(0xFF59F797),
      onSelected: (selected) => setState(() => _selectedFilter = selected ? value : 'all'),
    );
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> data, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Receipt', style: TextStyle(fontSize: 16)),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReceiptRow('Amount', _formatTZS(amount)),
              _buildReceiptRow('Method', data['method'] ?? 'N/A'),
              _buildReceiptRow('Transaction ID', data['transactionId'] ?? 'N/A'),
              _buildReceiptRow('Date', _formatDate((data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now())),
              _buildReceiptRow('Status', data['status'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}