import 'package:flutter/material.dart';

class AdminAIMonitoring extends StatefulWidget {
  const AdminAIMonitoring({super.key});

  @override
  State<AdminAIMonitoring> createState() => _AdminAIMonitoringState();
}

class _AdminAIMonitoringState extends State<AdminAIMonitoring> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Status
          _buildAIStatus(),
          
          const SizedBox(height: 16),
          
          // Tabs
          _buildTabs(),
          
          const SizedBox(height: 16),
          
          // Content based on selected tab
          if (_selectedTab == 0) _buildSalesForecasting(),
          if (_selectedTab == 1) _buildDemandOptimization(),
          if (_selectedTab == 2) _buildBusinessRecommendations(),
          if (_selectedTab == 3) _buildBackendStatus(),
        ],
      ),
    );
  }

  Widget _buildAIStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF59F797), Color(0xFF3BC77A)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI System Status',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Online', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    const SizedBox(width: 12),
                    const Text('Last Prediction: 5 min ago', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    const SizedBox(width: 12),
                    const Text('Total Predictions: 1,234', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Sales Forecasting', 'Demand Optimization', 'Recommendations', 'Backend Status'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
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
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSalesForecasting() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildForecastItem('Forecast Requests', '2,456 requests', Icons.request_page),
            const Divider(height: 1),
            _buildForecastItem('Forecast Accuracy', '85% accuracy', Icons.check_circle),
            const Divider(height: 1),
            _buildForecastItem('Predicted Growth', '+12.5% average', Icons.trending_up),
            const Divider(height: 1),
            _buildForecastItem('Demand Level', 'HIGH (72% of products)', Icons.analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF59F797).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF59F797)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11))),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDemandOptimization() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildDemandItem('Stock Alerts', '15 products low stock', Icons.warning, Colors.orange),
            const Divider(height: 1),
            _buildDemandItem('Overstock Alerts', '8 products overstock', Icons.inventory, Colors.red),
            const Divider(height: 1),
            _buildDemandItem('Restock Recommendations', '5 products need restock', Icons.refresh, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBusinessRecommendations() {
    final recommendations = [
      {'title': 'Recommended Bundles', 'subtitle': 'Coffee + Snacks Bundle sells well', 'icon': Icons.local_offer},
      {'title': 'Promotion Suggestions', 'subtitle': 'End of month sale recommended', 'icon': Icons.discount},
      {'title': 'Location Expansion', 'subtitle': 'Consider expanding to Ubungo', 'icon': Icons.location_on},
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
          children: recommendations.map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF59F797).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(rec['icon'] as IconData, size: 16, color: const Color(0xFF59F797)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      Text(rec['subtitle'] as String, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildBackendStatus() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildBackendItem('Status', 'Online', Icons.check_circle, Colors.green),
            const Divider(height: 1),
            _buildBackendItem('Last Prediction', '5 min ago', Icons.access_time, Colors.blue),
            const Divider(height: 1),
            _buildBackendItem('Total Predictions', '1,234', Icons.numbers, const Color(0xFF59F797)),
            const Divider(height: 1),
            _buildBackendItem('Model Version', 'v2.4.1', Icons.code, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}