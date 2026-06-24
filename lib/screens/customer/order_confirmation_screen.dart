import 'package:flutter/material.dart';
import 'customer_dashboard.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double amountPaid;
  final String paymentMethod;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.amountPaid,
    required this.paymentMethod,
  });

  String _formatCurrency(double amount) => 'Tsh ${amount.toStringAsFixed(0)}';

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Estimated delivery is 3 days from now
    final estimatedDelivery = DateTime.now().add(const Duration(days: 3));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Checkmark Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF59F797).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF3BC77A),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),

                // Success Headers
                const Text(
                  'Order Placed Successfully!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for your business. Your payment was verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Order Receipt Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const Divider(height: 20),
                        
                        _buildReceiptRow('Order ID', '#${orderId.substring(0, 8).toUpperCase()}', isCopyable: true),
                        _buildReceiptRow('Amount Paid', _formatCurrency(amountPaid), isBold: true, valueColor: const Color(0xFF3BC77A)),
                        _buildReceiptRow('Payment Method', paymentMethod),
                        _buildReceiptRow('Est. Delivery Date', _formatDate(estimatedDelivery), isBold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Actions Layout
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to CustomerDashboard focusing on Orders tab (index 3)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerDashboard(initialTab: 3),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59F797),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Track Order',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate back to CustomerDashboard focusing on Home tab (index 0)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerDashboard(initialTab: 0),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF59F797)),
                      foregroundColor: const Color(0xFF3BC77A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Continue Shopping',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? valueColor, bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
