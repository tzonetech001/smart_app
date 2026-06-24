import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/product_model.dart';
import 'edit_product_screen.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  String _selectedFilter = 'all'; // all | low | out | in_stock
  String _selectedSort = 'demand'; // demand | stock_asc | stock_desc | revenue | sold

  String _formatTZS(double v) => 'TZS ${v.toStringAsFixed(0)}';

  Color _stockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(int stock) {
    if (stock == 0) return 'Out of Stock';
    if (stock <= 5) return 'Low Stock';
    return 'In Stock';
  }

  IconData _stockIcon(int stock) {
    if (stock == 0) return Icons.block;
    if (stock <= 5) return Icons.warning;
    return Icons.check_circle;
  }

  Color _demandColor(String level) {
    switch (level) {
      case 'High Demand':
        return Colors.green;
      case 'Moderate Demand':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Future<void> _quickUpdateStock(BuildContext context, ProductModel product, int delta) async {
    final newStock = (product.stock + delta).clamp(0, 99999);
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({'stock': newStock});

      // Stock alerts
      if (newStock == 0) {
        await NotificationService.sendOutOfStockAlert(
          entrepreneurId: product.entrepreneurId,
          productId: product.id,
          productName: product.productName,
        );
      } else if (newStock <= 5 && product.stock > 5) {
        await NotificationService.sendLowStockAlert(
          entrepreneurId: product.entrepreneurId,
          productId: product.id,
          productName: product.productName,
          stockLeft: newStock,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final entrepreneurId = authService.currentUser?.id ?? '';

    return Column(
      children: [
        // Filters & Sort bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('🟢 In Stock', 'in_stock'),
                    const SizedBox(width: 8),
                    _filterChip('🟡 Low Stock', 'low'),
                    const SizedBox(width: 8),
                    _filterChip('🔴 Out of Stock', 'out'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Sort: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 4),
                  DropdownButton<String>(
                    value: _selectedSort,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'demand', child: Text('Demand Level')),
                      DropdownMenuItem(value: 'stock_asc', child: Text('Stock ↑')),
                      DropdownMenuItem(value: 'stock_desc', child: Text('Stock ↓')),
                      DropdownMenuItem(value: 'revenue', child: Text('Revenue ↓')),
                      DropdownMenuItem(value: 'sold', child: Text('Units Sold ↓')),
                    ],
                    onChanged: (v) => setState(() => _selectedSort = v ?? 'demand'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Products list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('entrepreneurId', isEqualTo: entrepreneurId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var products = snapshot.data!.docs
                  .map((d) => ProductModel.fromMap(d.id, d.data() as Map<String, dynamic>))
                  .toList();

              // Apply stock filter
              if (_selectedFilter == 'out') {
                products = products.where((p) => p.stock == 0).toList();
              } else if (_selectedFilter == 'low') {
                products = products.where((p) => p.stock > 0 && p.stock <= 5).toList();
              } else if (_selectedFilter == 'in_stock') {
                products = products.where((p) => p.stock > 5).toList();
              }

              // Apply sort
              switch (_selectedSort) {
                case 'stock_asc':
                  products.sort((a, b) => a.stock.compareTo(b.stock));
                  break;
                case 'stock_desc':
                  products.sort((a, b) => b.stock.compareTo(a.stock));
                  break;
                case 'revenue':
                  products.sort((a, b) => b.revenue.compareTo(a.revenue));
                  break;
                case 'sold':
                  products.sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
                  break;
                default: // demand
                  products.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
              }

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No products found for this filter', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              // Summary row
              final totalStock = products.fold(0, (s, p) => s + p.stock);
              final totalSold = products.fold(0, (s, p) => s + p.unitsSold);
              final totalRevenue = products.fold(0.0, (s, p) => s + p.revenue);

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      _summaryCard('Total Stock', '$totalStock units', Icons.inventory, const Color(0xFF59F797)),
                      const SizedBox(width: 8),
                      _summaryCard('Units Sold', '$totalSold', Icons.shopping_cart, Colors.blue),
                      const SizedBox(width: 8),
                      _summaryCard('Revenue', _formatTZS(totalRevenue), Icons.attach_money, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product cards
                  ...products.map((p) => _buildInventoryCard(context, p)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, ProductModel product) {
    final stockCol = _stockColor(product.stock);
    final stockLbl = _stockLabel(product.stock);
    final stockIco = _stockIcon(product.stock);
    final demandCol = _demandColor(product.demandLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: stockCol.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 28)))
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 28)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.productName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(product.category.displayName,
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: stockCol.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(stockIco, size: 10, color: stockCol),
                                const SizedBox(width: 3),
                                Text(stockLbl,
                                    style: TextStyle(fontSize: 9, color: stockCol, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: demandCol.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(product.demandLevel,
                                style: TextStyle(fontSize: 9, color: demandCol, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metricItem('Stock', '${product.stock}', Colors.black87),
                const SizedBox(width: 8),
                _metricItem('Units Sold', '${product.unitsSold}', Colors.blue),
                const SizedBox(width: 8),
                _metricItem('Revenue', _formatTZS(product.revenue), Colors.purple),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Quick Stock:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const Spacer(),
                _stockButton(context, '-10', product, -10, Colors.red.shade100),
                const SizedBox(width: 4),
                _stockButton(context, '-1', product, -1, Colors.red.shade50),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${product.stock}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                _stockButton(context, '+1', product, 1, Colors.green.shade50),
                const SizedBox(width: 4),
                _stockButton(context, '+10', product, 10, Colors.green.shade100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _stockButton(BuildContext context, String label, ProductModel product, int delta, Color bg) {
    return GestureDetector(
      onTap: () => _quickUpdateStock(context, product, delta),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF59F797).withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF59F797) : Colors.grey[300]!),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF59F797) : Colors.black87)),
      ),
    );
  }
}