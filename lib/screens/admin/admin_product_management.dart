import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_model.dart';

class AdminProductManagement extends StatefulWidget {
  const AdminProductManagement({super.key});

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

class _AdminProductManagementState extends State<AdminProductManagement> {
  String _selectedFilter = 'all';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search products by name or entrepreneur...',
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      ...ProductCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(category.displayName, category.toString().split('.').last),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('All Status', 'all'),
                      const SizedBox(width: 8),
                      _buildStatusChip('✅ Active', 'active'),
                      const SizedBox(width: 8),
                      _buildStatusChip('⛔ Inactive', 'inactive'),
                      const SizedBox(width: 8),
                      _buildStatusChip('📦 Out of Stock', 'out_of_stock'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Product Statistics
          _buildProductStatistics(),
          
          const SizedBox(height: 8),
          
          // Products List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var products = snapshot.data!.docs.map((doc) {
                  return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                }).toList();
                
                // Apply category filter
                if (_selectedFilter != 'all') {
                  products = products.where((product) {
                    return product.category.toString().split('.').last == _selectedFilter;
                  }).toList();
                }
                
                // Apply status filter
                if (_selectedStatus != 'all') {
                  if (_selectedStatus == 'active') {
                    products = products.where((p) => p.isActive == true && p.stock > 0).toList();
                  } else if (_selectedStatus == 'inactive') {
                    products = products.where((p) => p.isActive == false).toList();
                  } else if (_selectedStatus == 'out_of_stock') {
                    products = products.where((p) => p.isActive == true && p.stock <= 0).toList();
                  }
                }
                
                // Apply search
                if (_searchQuery.isNotEmpty) {
                  products = products.where((product) {
                    return product.productName.toLowerCase().contains(_searchQuery) ||
                        (product.entrepreneurName?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();
                }
                
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? 'No products match your search' : 'No products found',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear Search', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final stockStatus = product.stock <= 0 ? 'Out of Stock' : 'In Stock';
                    final stockColor = product.stock <= 0 ? Colors.red : Colors.green;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product.imageUrl != null
                                      ? Image.network(
                                          product.imageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 30),
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, size: 30),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.category.displayName,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'By: ${product.entrepreneurName}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _buildStat(Icons.favorite, product.likes.toString(), Colors.red),
                                          const SizedBox(width: 12),
                                          _buildStat(Icons.comment, product.comments.toString(), Colors.blue),
                                          const SizedBox(width: 12),
                                          _buildStat(Icons.visibility, product.views.toString(), Colors.grey),
                                          const SizedBox(width: 12),
                                          _buildStat(Icons.shopping_cart, '${product.unitsSold ?? 0}', Colors.orange),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: product.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        product.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: product.isActive ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stockColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        stockStatus,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: stockColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tsh ${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF59F797),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showProductDetails(product),
                                    icon: const Icon(Icons.visibility, size: 14),
                                    label: const Text('View', style: TextStyle(fontSize: 10)),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showEditProductDialog(product),
                                    icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
                                    label: const Text('Edit', style: TextStyle(fontSize: 10)),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _toggleProductStatus(product),
                                    icon: Icon(
                                      product.isActive ? Icons.block : Icons.check_circle,
                                      size: 14,
                                      color: product.isActive ? Colors.orange : Colors.green,
                                    ),
                                    label: Text(
                                      product.isActive ? 'Disable' : 'Enable',
                                      style: TextStyle(fontSize: 10, color: product.isActive ? Colors.orange : Colors.green),
                                    ),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showDeleteConfirmDialog(product),
                                    icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                    label: const Text('Delete', style: TextStyle(fontSize: 10, color: Colors.red)),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: const Color(0xFF59F797),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        color: _selectedFilter == value ? const Color(0xFF59F797) : Colors.black87,
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _selectedStatus == value,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : 'all';
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF59F797).withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        color: _selectedStatus == value ? const Color(0xFF59F797) : Colors.black87,
      ),
    );
  }

  Widget _buildProductStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final products = snapshot.data!.docs;
        final total = products.length;
        final active = products.where((p) => p.get('isActive') == true).length;
        final inactive = total - active;
        final outOfStock = products.where((p) => p.get('isActive') == true && (p.get('stock') ?? 0) <= 0).length;
        
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
            _buildStatCard('Total Products', total.toString(), Icons.inventory, Colors.blue),
            _buildStatCard('Active', active.toString(), Icons.check_circle, Colors.green),
            _buildStatCard('Inactive', inactive.toString(), Icons.block, Colors.red),
            _buildStatCard('Out of Stock', outOfStock.toString(), Icons.warning, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.productName, style: const TextStyle(fontSize: 16)),
        content: Container(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              _buildDetailRow('Category', product.category.displayName),
              _buildDetailRow('Entrepreneur', product.entrepreneurName ?? 'Unknown'),
              _buildDetailRow('Price', 'Tsh ${product.price.toStringAsFixed(0)}'),
              _buildDetailRow('Stock', product.stock.toString()),
              _buildDetailRow('Likes', product.likes.toString()),
              _buildDetailRow('Comments', product.comments.toString()),
              _buildDetailRow('Views', product.views.toString()),
              _buildDetailRow('Rating', product.rating.toStringAsFixed(1)),
              _buildDetailRow('Status', product.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Added', _formatDate(product.createdAt)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleProductStatus(ProductModel product) async {
    final action = product.isActive ? 'disable' : 'enable';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.isActive ? 'Disable' : 'Enable'} Product', style: const TextStyle(fontSize: 16)),
        content: Text(
          'Are you sure you want to ${product.isActive ? 'disable' : 'enable'} "${product.productName}"?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(product.id)
                  .update({'isActive': !product.isActive});
              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessMessage('Product ${product.isActive ? 'disabled' : 'enabled'} successfully');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: product.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(
              product.isActive ? 'Disable' : 'Enable',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _priceController = TextEditingController();
    final _stockController = TextEditingController();
    ProductCategory? _selectedCategory;
    File? _selectedImage;
    bool _isLoading = false;
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Product', style: TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setDialogState(() {
                            _selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('Tap to add product image', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  Text('(Optional)', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProductCategory>(
                      value: _selectedCategory,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ProductCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() => _selectedCategory = value),
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Price *',
                              prefixText: 'Tsh ',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Stock *',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setDialogState(() => _isLoading = true);
                    String? imageUrl;
                    if (_selectedImage != null) {
                      final storageRef = FirebaseStorage.instance
                          .ref()
                          .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await storageRef.putFile(_selectedImage!);
                      imageUrl = await storageRef.getDownloadURL();
                    }
                    final product = ProductModel(
                      id: '',
                      productName: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      imageUrl: imageUrl,
                      category: _selectedCategory!,
                      entrepreneurId: 'admin',
                      entrepreneurName: 'System Admin',
                      price: double.parse(_priceController.text),
                      stock: int.parse(_stockController.text),
                      createdAt: DateTime.now(),
                    );
                    await FirebaseFirestore.instance.collection('products').add(product.toMap());
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showSuccessMessage('Product added successfully!');
                    }
                  }
                },
                child: _isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Product', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: product.productName);
    final _descriptionController = TextEditingController(text: product.description);
    final _priceController = TextEditingController(text: product.price.toString());
    final _stockController = TextEditingController(text: product.stock.toString());
    ProductCategory _selectedCategory = product.category;
    File? _selectedImage;
    bool _isLoading = false;
    bool _keepExistingImage = true;
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Product', style: TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setDialogState(() {
                            _selectedImage = File(pickedFile.path);
                            _keepExistingImage = false;
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : (product.imageUrl != null && _keepExistingImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('Tap to change image', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProductCategory>(
                      value: _selectedCategory,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ProductCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() => _selectedCategory = value!),
                      validator: (v) => v == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Price *',
                              prefixText: 'Tsh ',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Stock *',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setDialogState(() => _isLoading = true);
                    String? imageUrl = product.imageUrl;
                    if (!_keepExistingImage && _selectedImage != null) {
                      if (product.imageUrl != null) {
                        try {
                          await FirebaseStorage.instance.refFromURL(product.imageUrl!).delete();
                        } catch (_) {}
                      }
                      final storageRef = FirebaseStorage.instance
                          .ref()
                          .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await storageRef.putFile(_selectedImage!);
                      imageUrl = await storageRef.getDownloadURL();
                    } else if (!_keepExistingImage) {
                      imageUrl = null;
                    }
                    await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                      'productName': _nameController.text.trim(),
                      'description': _descriptionController.text.trim(),
                      'category': _selectedCategory.toString().split('.').last,
                      'price': double.parse(_priceController.text),
                      'stock': int.parse(_stockController.text),
                      'imageUrl': imageUrl,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showSuccessMessage('Product updated successfully!');
                    }
                  }
                },
                child: _isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${product.productName}"?', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text('This will also delete all comments and likes related to this product.', style: TextStyle(fontSize: 11, color: Colors.red)),
            const SizedBox(height: 8),
            const Text('This action cannot be undone.', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              if (product.imageUrl != null) {
                try {
                  await FirebaseStorage.instance.refFromURL(product.imageUrl!).delete();
                } catch (_) {}
              }
              await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
              final comments = await FirebaseFirestore.instance
                  .collection('comments')
                  .where('productId', isEqualTo: product.id)
                  .get();
              for (var comment in comments.docs) await comment.reference.delete();
              final likes = await FirebaseFirestore.instance
                  .collection('likes')
                  .where('productId', isEqualTo: product.id)
                  .get();
              for (var like in likes.docs) await like.reference.delete();
              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessMessage('Product deleted successfully');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}