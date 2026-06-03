import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';

class TrendingProductsScreen extends StatefulWidget {
  const TrendingProductsScreen({super.key});

  @override
  State<TrendingProductsScreen> createState() => _TrendingProductsScreenState();
}

class _TrendingProductsScreenState extends State<TrendingProductsScreen> {
  String _timeframe = 'week';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search trending products...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        // Timeframe Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('Trending: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildTimeframeChip('This Week', 'week'),
              const SizedBox(width: 8),
              _buildTimeframeChip('This Month', 'month'),
              const SizedBox(width: 8),
              _buildTimeframeChip('All Time', 'all'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Trending Products List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              var products = snapshot.data!.docs.map((doc) {
                return ProductModel.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              // Calculate trending score (likes + comments + views)
              for (var product in products) {
                // Store calculated score
              }

              // Sort by engagement score (likes + comments)
              products.sort((a, b) {
                int scoreA = a.likes + a.comments;
                int scoreB = b.likes + b.comments;
                return scoreB.compareTo(scoreA);
              });

              // Apply search
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) =>
                        p.productName.toLowerCase().contains(_searchQuery) ||
                        p.description.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (products.isEmpty) {
                return const Center(
                    child: Text('No trending products found',
                        style: TextStyle(fontSize: 12)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final engagementScore = product.likes + product.comments;
                  final isTopTrending = index < 3;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product))),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Rank Badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isTopTrending
                                    ? const Color(0xFF59F797)
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isTopTrending
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.imageUrl != null
                                  ? Image.network(product.imageUrl!,
                                      width: 60, height: 60, fit: BoxFit.cover)
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image)),
                            ),
                            const SizedBox(width: 12),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.productName,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isTopTrending)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text('🔥 HOT',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(product.category.displayName,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite,
                                          size: 12, color: Colors.red),
                                      const SizedBox(width: 2),
                                      Text('${product.likes}',
                                          style: const TextStyle(fontSize: 10)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.comment,
                                          size: 12, color: Colors.blue),
                                      const SizedBox(width: 2),
                                      Text('${product.comments}',
                                          style: const TextStyle(fontSize: 10)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.visibility,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Text('${product.views}',
                                          style: const TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Engagement Score
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF59F797)),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF59F797)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$engagementScore pts',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF59F797),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _timeframe == value,
      onSelected: (selected) => setState(() => _timeframe = value),
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
    );
  }
}
