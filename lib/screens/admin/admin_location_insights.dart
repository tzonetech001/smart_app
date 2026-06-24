import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLocationInsights extends StatefulWidget {
  const AdminLocationInsights({super.key});

  @override
  State<AdminLocationInsights> createState() => _AdminLocationInsightsState();
}

class _AdminLocationInsightsState extends State<AdminLocationInsights> {
  String _selectedDistrict = 'all';
  final List<String> _districts = ['All', 'Kinondoni', 'Ubungo', 'Ilala', 'Temeke', 'Kigamboni'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Regional Dashboard
          const Text('Regional Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRegionalDashboard(),
          
          const SizedBox(height: 16),
          
          // District Filter
          _buildDistrictFilter(),
          
          const SizedBox(height: 16),
          
          // District Ranking
          const Text('District Ranking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDistrictRanking(),
          
          const SizedBox(height: 16),
          
          // Ward Analysis
          const Text('Ward Analysis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildWardAnalysis(),
        ],
      ),
    );
  }

  Widget _buildRegionalDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        final totalOrders = orders.length;
        double totalRevenue = 0;
        for (var order in orders) {
          totalRevenue += (order.get('totalAmount') ?? 0).toDouble();
        }

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
            _buildRegionCard('Total Orders', totalOrders.toString(), Icons.shopping_cart, Colors.blue),
            _buildRegionCard('Total Revenue', 'TZS ${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
            _buildRegionCard('Total Customers', '567', Icons.people, Colors.orange),
            _buildRegionCard('Products Sold', '2,345', Icons.inventory, const Color(0xFF59F797)),
          ],
        );
      },
    );
  }

  Widget _buildRegionCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictFilter() {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _districts.length,
        itemBuilder: (context, index) {
          final district = _districts[index];
          final isSelected = _selectedDistrict == district.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(district, style: TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedDistrict = selected ? district.toLowerCase() : 'all'),
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF59F797).withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistrictRanking() {
    final rankings = [
      {'rank': 1, 'name': 'Kinondoni', 'revenue': 'TZS 2.8M', 'orders': 456, 'growth': '+15%'},
      {'rank': 2, 'name': 'Ilala', 'revenue': 'TZS 2.1M', 'orders': 345, 'growth': '+12%'},
      {'rank': 3, 'name': 'Ubungo', 'revenue': 'TZS 1.6M', 'orders': 234, 'growth': '+20%'},
      {'rank': 4, 'name': 'Temeke', 'revenue': 'TZS 1.2M', 'orders': 123, 'growth': '+8%'},
      {'rank': 5, 'name': 'Kigamboni', 'revenue': 'TZS 0.8M', 'orders': 76, 'growth': '+5%'},
    ];
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: rankings.map((item) {
            final rank = item['rank'] as int? ?? 0;
            final name = item['name'] as String? ?? '';
            final revenue = item['revenue'] as String? ?? '';
            final growth = item['growth'] as String? ?? '';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rank <= 3 ? const Color(0xFF59F797).withOpacity(0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? const Color(0xFF59F797) : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    revenue,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      growth,
                      style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWardAnalysis() {
    final wards = [
      {'ward': 'Mikocheni', 'district': 'Kinondoni', 'revenue': 'TZS 850,000', 'orders': 120},
      {'ward': 'Mbezi', 'district': 'Kinondoni', 'revenue': 'TZS 720,000', 'orders': 95},
      {'ward': 'Kivukoni', 'district': 'Ilala', 'revenue': 'TZS 650,000', 'orders': 85},
      {'ward': 'Goba', 'district': 'Ubungo', 'revenue': 'TZS 580,000', 'orders': 70},
    ];
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: wards.map((ward) {
            final wardName = ward['ward'] as String? ?? '';
            final districtName = ward['district'] as String? ?? '';
            final orders = ward['orders'] as int? ?? 0;
            final revenue = ward['revenue'] as String? ?? '';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wardName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(districtName, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      orders.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    revenue,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF59F797)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}