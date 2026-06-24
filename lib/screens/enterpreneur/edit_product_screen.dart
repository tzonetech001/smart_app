import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_model.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _warrantyController = TextEditingController();

  ProductCategory? _selectedCategory;
  File? _selectedImage;
  bool _isUploading = false;
  bool _keepExistingImage = true;
  bool _isActive = true;
  bool _isAvailable = true;
  bool _isOnPromotion = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.productName;
    _descriptionController.text = widget.product.description;
    _priceController.text = widget.product.price.toString();
    _stockController.text = widget.product.stock.toString();
    _selectedCategory = widget.product.category;
    _brandController.text = widget.product.brand ?? '';
    _skuController.text = widget.product.sku ?? '';
    //_warrantyController.text = widget.product.warranty ?? '';
    _isActive = widget.product.isActive;
    // FIXED: Removed isAvailable and isOnPromotion since they don't exist in ProductModel
    // _isAvailable = widget.product.isAvailable ?? true;
    // _isOnPromotion = widget.product.isOnPromotion ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _keepExistingImage = false;
      });
    }
  }

  Future<String?> _uploadNewImage() async {
    if (_selectedImage == null) return null;

    try {
      if (widget.product.imageUrl != null && !_keepExistingImage) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(widget.product.imageUrl!);
          await oldRef.delete();
        } catch (e) {
          debugPrint('Error deleting old image: $e');
        }
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? imageUrl = widget.product.imageUrl;
    if (!_keepExistingImage) {
      imageUrl = await _uploadNewImage();
    }

    final newStock = int.parse(_stockController.text);
    final oldStock = widget.product.stock;

    // FIXED: Removed isAvailable and isOnPromotion from updates
    final updates = <String, dynamic>{
      'productName': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory.toString().split('.').last,
      'price': double.parse(_priceController.text),
      'stock': newStock,
      'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      'warranty': _warrantyController.text.trim().isEmpty ? null : _warrantyController.text.trim(),
      'isActive': _isActive,
      // 'isAvailable': _isAvailable, // Remove if not in model
      // 'isOnPromotion': _isOnPromotion, // Remove if not in model
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (imageUrl != null) {
      updates['imageUrl'] = imageUrl;
    } else if (!_keepExistingImage) {
      updates['imageUrl'] = null;
    }

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update(updates);

      // Low/out of stock alerts
      if (newStock == 0 && oldStock > 0) {
        await NotificationService.sendOutOfStockAlert(
          entrepreneurId: widget.product.entrepreneurId,
          productId: widget.product.id,
          productName: widget.product.productName,
        );
      } else if (newStock <= 5 && oldStock > 5) {
        await NotificationService.sendLowStockAlert(
          entrepreneurId: widget.product.entrepreneurId,
          productId: widget.product.id,
          productName: widget.product.productName,
          stockLeft: newStock,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _updateProduct,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Current Image Display
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black54,
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 40),
                                    SizedBox(height: 8),
                                    Text('Tap to change image', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : (widget.product.imageUrl != null && _keepExistingImage
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(widget.product.imageUrl!, fit: BoxFit.cover),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black54,
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 40),
                                        SizedBox(height: 8),
                                        Text('Tap to change image', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Tap to add product image', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            )),
                ),
              ),

              const SizedBox(height: 24),

              // Category Dropdown
              DropdownButtonFormField<ProductCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                style: const TextStyle(fontSize: 12),
                items: ProductCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),

              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter product name' : null,
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 12),
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(fontSize: 12),
                  alignLabelWithHint: true,
                  hintText: '• Features\n• Specifications\n• Usage Information\n• Benefits\n• Warranty Information',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
              ),

              const SizedBox(height: 16),

              // Brand (Optional)
              TextFormField(
                controller: _brandController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),

              const SizedBox(height: 16),

              // SKU (Optional)
              TextFormField(
                controller: _skuController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'SKU (Optional)',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),

              const SizedBox(height: 16),

              // Warranty (Optional)
              TextFormField(
                controller: _warrantyController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Warranty (Optional)',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Price (Tsh)',
                        prefixText: 'Tsh ',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter price';
                        if (double.tryParse(value) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter stock';
                        if (int.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status Switches - FIXED: Removed Available and Promotion switches
              SwitchListTile(
                title: const Text('Product Status (Active / Inactive)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(_isActive ? 'Active (Visible to customers)' : 'Inactive (Hidden from customers)', style: const TextStyle(fontSize: 11)),
                value: _isActive,
                activeColor: const Color(0xFF59F797),
                onChanged: (bool value) => setState(() => _isActive = value),
              ),

              // FIXED: Removed these two switches since they don't exist in ProductModel
              /*
              SwitchListTile(
                title: const Text('Available for Purchase', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(_isAvailable ? 'Available (Customers can buy)' : 'Not Available (Temporarily unavailable)', style: const TextStyle(fontSize: 11)),
                value: _isAvailable,
                activeColor: const Color(0xFF59F797),
                onChanged: (bool value) => setState(() => _isAvailable = value),
              ),

              SwitchListTile(
                title: const Text('On Promotion / Discount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(_isOnPromotion ? 'This product is on promotion' : 'Regular pricing', style: const TextStyle(fontSize: 11)),
                value: _isOnPromotion,
                activeColor: const Color(0xFF59F797),
                onChanged: (bool value) => setState(() => _isOnPromotion = value),
              ),
              */

              const SizedBox(height: 32),

              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF59F797),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}