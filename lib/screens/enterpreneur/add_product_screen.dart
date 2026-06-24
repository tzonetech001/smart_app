import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';

class AddProductScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onSuccess;
  const AddProductScreen({super.key, this.isEmbedded = false, this.onSuccess});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _warrantyController = TextEditingController();

  bool _isActive = true;
  bool _notifyCustomers = true;
  bool _isOnPromotion = false;
  bool _isAvailable = true;

  ProductCategory? _selectedCategory;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _uploadProgress;
  final ImagePicker _picker = ImagePicker();

  late final FirebaseStorage _storage;
  late final Reference _storageRef;

  @override
  void initState() {
    super.initState();
    _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://smart-app-33082.firebasestorage.app',
    );
    _storageRef = _storage.ref();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _takePhotoFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Camera error: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Image Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF59F797)),
              title: const Text('Choose from Gallery', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF59F797)),
              title: const Text('Take a Photo', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _takePhotoFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _uploadProgress = 'Uploading image...';
      });

      final bytes = await _selectedImage!.readAsBytes();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileRef = _storageRef.child('product_images/$fileName');

      final uploadTask = fileRef.putData(bytes);

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() {
            _uploadProgress = 'Uploading: ${(progress * 100).toStringAsFixed(0)}%';
          });
        }
      });

      final snapshot = await uploadTask;
      setState(() {
        _uploadProgress = 'Getting download URL...';
      });
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadProgress = null;
      });
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      setState(() {
        _uploadProgress = null;
      });
      _showErrorSnackBar('Upload failed: $e');
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() => _isUploading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            StreamBuilder<String?>(
              stream: Stream.value(_uploadProgress),
              builder: (context, snapshot) => Text(
                snapshot.data ?? 'Processing...',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    final authService = Provider.of<AuthService>(context, listen: false);
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
    }

    // FIXED: Removed unsupported properties (isOnPromotion, isAvailable, warranty, unitsSold, revenue)
    final product = ProductModel(
      id: '',
      productName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      category: _selectedCategory!,
      entrepreneurId: authService.currentUser!.id,
      entrepreneurName: authService.currentUser!.fullName,
      price: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      createdAt: DateTime.now(),
      likes: 0,
      comments: 0,
      rating: 0.0,
      views: 0,
      isActive: _isActive,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      // warranty: _warrantyController.text.trim().isEmpty ? null : _warrantyController.text.trim(), // Remove if not in model
      // unitsSold: 0, // Remove if not in model
      // revenue: 0.0, // Remove if not in model
      // isOnPromotion: _isOnPromotion, // Remove if not in model
      // isAvailable: _isAvailable, // Remove if not in model
    );

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('products')
          .add(product.toMap());

      // Log product published event
      await AnalyticsService.logProductPublished(product);

      // Send notifications if enabled
      if (_notifyCustomers) {
        await NotificationService.sendNewProductNotification(
          productId: docRef.id,
          productName: product.productName,
          entrepreneurName: product.entrepreneurName,
        );
      }

      // Stock alerts
      if (product.stock <= 5 && product.stock > 0) {
        await NotificationService.sendLowStockAlert(
          entrepreneurId: product.entrepreneurId,
          productId: docRef.id,
          productName: product.productName,
          stockLeft: product.stock,
        );
      } else if (product.stock == 0) {
        await NotificationService.sendOutOfStockAlert(
          entrepreneurId: product.entrepreneurId,
          productId: docRef.id,
          productName: product.productName,
        );
      }

      if (mounted) {
        Navigator.pop(context); // close progress dialog
        _showSuccessSnackBar('Product added successfully!');
        
        if (widget.isEmbedded) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
          _nameController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _stockController.clear();
          _brandController.clear();
          _skuController.clear();
          _warrantyController.clear();
          setState(() {
            _selectedCategory = null;
            _selectedImage = null;
            _imageBytes = null;
            _isActive = true;
            _notifyCustomers = true;
            _isOnPromotion = false;
            _isAvailable = true;
          });
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
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

  void _showErrorSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    final formWidget = Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _imageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
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
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF59F797).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo, size: 48, color: Color(0xFF59F797)),
                            ),
                            const SizedBox(height: 16),
                            const Text('Tap to add product image', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text('(Optional - JPG, PNG)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Category
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                ),
                child: DropdownButtonFormField<ProductCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category, color: Color(0xFF59F797)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: ProductCategory.values.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayName),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Select category' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Product Name
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    prefixIcon: Icon(Icons.shopping_bag, color: Color(0xFF59F797)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Description with rich format
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    alignLabelWithHint: true,
                    hintText: 'Describe your product:\n• Features\n• Specifications\n• Usage Information\n• Benefits\n• Warranty Information (if applicable)',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 160),
                      child: Icon(Icons.description, color: Color(0xFF59F797)),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Brand (Optional)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                ),
                child: TextFormField(
                  controller: _brandController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Brand (Optional)',
                    prefixIcon: Icon(Icons.branding_watermark, color: Color(0xFF59F797)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SKU (Optional)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                ),
                child: TextFormField(
                  controller: _skuController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'SKU (Optional)',
                    prefixIcon: Icon(Icons.qr_code, color: Color(0xFF59F797)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Warranty (Optional)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                ),
                child: TextFormField(
                  controller: _warrantyController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Warranty (Optional)',
                    prefixIcon: Icon(Icons.verified, color: Color(0xFF59F797)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price and Stock Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                      ),
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (Tsh) *',
                          prefixIcon: Icon(Icons.attach_money, color: Color(0xFF59F797)),
                          hintText: 'e.g., 5000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Price required';
                          if (double.tryParse(v) == null) return 'Invalid price';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                      ),
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock *',
                          prefixIcon: Icon(Icons.inventory, color: Color(0xFF59F797)),
                          hintText: 'Quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Stock required';
                          if (int.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Switch
              SwitchListTile(
                title: const Text('Product Status (Active / Inactive)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(_isActive ? 'Active (Visible to customers)' : 'Inactive (Hidden from customers)', style: const TextStyle(fontSize: 11)),
                value: _isActive,
                activeColor: const Color(0xFF59F797),
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),

              // Notify customers Switch
              SwitchListTile(
                title: const Text('Notify customers on publish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Send notification to all active customers', style: TextStyle(fontSize: 11)),
                value: _notifyCustomers,
                activeColor: const Color(0xFF59F797),
                onChanged: (bool value) {
                  setState(() {
                    _notifyCustomers = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF59F797),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Product', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return formWidget;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: formWidget,
    );
  }
}