import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';
import '../../widgets/product_card.dart';

class BrowseProductsScreen extends StatefulWidget {
  final ProductCategory? initialCategory;

  const BrowseProductsScreen({super.key, this.initialCategory});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  ProductCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'newest'; // newest, price_low, price_high, popular

  final List<Map<String, dynamic>> _sortOptions = [
    {'label': 'Newest', 'value': 'newest'},
    {'label': 'Price: Low to High', 'value': 'price_low'},
    {'label': 'Price: High to Low', 'value': 'price_high'},
    {'label': 'Most Popular', 'value': 'popular'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
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
              hintText: 'Search products by name or description...',
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Category Filter - Horizontal Scroll
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: ProductCategory.values.length,
            itemBuilder: (context, index) {
              final category = ProductCategory.values[index];
              final isSelected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.displayName,
                      style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF59F797).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        isSelected ? const Color(0xFF59F797) : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ),

        // Sort By Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    style: const TextStyle(fontSize: 12),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'] as String,
                        child: Text(option['label'],
                            style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Products Grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text('Error: ${snapshot.error}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var products = snapshot.data!.docs.map((doc) {
                return ProductModel.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              // Apply category filter
              if (_selectedCategory != null) {
                products = products.where((product) {
                  return product.category == _selectedCategory;
                }).toList();
              }

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                products = products.where((product) {
                  return product.productName
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      product.description.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              // Apply sorting
              _applySorting(products);

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No products match your search'
                            : 'No products found',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: const Text('Clear Search',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(product: products[index]),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _applySorting(List<ProductModel> products) {
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
        products.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'newest':
      default:
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }
}
