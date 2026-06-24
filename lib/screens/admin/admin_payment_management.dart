import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentManagement extends StatefulWidget {
  const AdminPaymentManagement({super.key});

  @override
  State<AdminPaymentManagement> createState() => _AdminPaymentManagementState();
}

class _AdminPaymentManagementState extends State<AdminPaymentManagement> {
  String _selectedStatus = 'all';
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Summary
          const Text('Payment Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPaymentSummary(),
          
          const SizedBox(height: 16),
          
          // Tab Bar
          _buildTabs(),
          
          const SizedBox(height: 12),
          
          // Payment Table
          const Text('Payment Table', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPaymentTable(),
          
          const SizedBox(height: 16),
          
          // Payment Analytics
          const Text('Payment Analytics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPaymentAnalytics(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payments').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final payments = snapshot.data!.docs;
        final total = payments.length;
        int successful = payments.where((p) => p.get('status') == 'completed').length;
        int pending = payments.where((p) => p.get('status') == 'pending').length;
        int failed = payments.where((p) => p.get('status') == 'failed').length;
        
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          children: [
            _buildSummaryCard('Total Payments', total.toString(), Icons.payment, Colors.blue),
            _buildSummaryCard('Successful', successful.toString(), Icons.check_circle, Colors.green),
            _buildSummaryCard('Pending', pending.toString(), Icons.pending, Colors.orange),
            _buildSummaryCard('Failed', failed.toString(), Icons.error, Colors.red),
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

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTab('Payments', 0),
          _buildTab('Analytics', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF59F797) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final payments = snapshot.data!.docs;
        
        if (payments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No payments found', style: TextStyle(fontSize: 11))),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final data = payment.data() as Map<String, dynamic>;
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
                          'Payment #${payment.id.substring(0, 8)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          'TZS ${(data['amount'] ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Method: ${data['method'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Order: ${data['orderId']?.substring(0, 8) ?? 'N/A'}',
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
                            label: const Text('View Receipt', style: TextStyle(fontSize: 10)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.info, size: 14),
                            label: const Text('Details', style: TextStyle(fontSize: 10)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          ),
                        ),
                        if (status == 'pending')
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.check, size: 14, color: Colors.green),
                                label: const Text('Approve', style: TextStyle(fontSize: 10, color: Colors.green)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.close, size: 14, color: Colors.red),
                                label: const Text('Reject', style: TextStyle(fontSize: 10, color: Colors.red)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              ),
                            ],
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
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'refunded': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildPaymentAnalytics() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildAnalyticsItem('Revenue by Day', 'TZS 125,000', 'Today'),
            const Divider(height: 1),
            _buildAnalyticsItem('Revenue by Month', 'TZS 3,750,000', 'June 2026'),
            const Divider(height: 1),
            _buildAnalyticsItem('Revenue by Payment Method', 'M-Pesa: 60%, Tigo: 25%, COD: 15%', 'Distribution'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String title, String value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}