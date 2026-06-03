import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  ProductCategory? _selectedCategory;
  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadProgress;
  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce size
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        _showErrorSnackBar('No image selected');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // Function to take photo from camera
  Future<void> _takePhotoFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        _showErrorSnackBar('No photo taken');
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  // Show dialog to choose image source
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

  // Upload image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    try {
      setState(() {
        _uploadProgress = 'Uploading image...';
      });
      
      // Create unique filename
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images/$fileName');
      
      // Upload file
      final uploadTask = storageRef.putFile(_selectedImage!);
      
      // Track upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = 'Uploading: ${(progress * 100).toStringAsFixed(0)}%';
        });
      });
      
      final snapshot = await uploadTask;
      
      setState(() {
        _uploadProgress = 'Getting download URL...';
      });
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _uploadProgress = null;
      });
      
      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() {
        _uploadProgress = null;
      });
      _showErrorSnackBar('Error uploading image: $e');
      return null;
    }
  }

  // Save product to Firestore
  Future<void> _saveProduct() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }
    
    setState(() => _isUploading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Upload image if selected
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
    }
    
    // Create product object
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
      isActive: true,
    );
    
    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('products').add(product.toMap());
      
      if (mounted) {
        _showSuccessSnackBar('Product added successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isUploading = false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF59F797),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Image Picker Section - NO asset image required
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
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Display selected image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              // Overlay with edit text
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black54,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.edit, color: Colors.white, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to change image',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Camera icon on top right
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
                              // Icon only - NO asset image required
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF59F797).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: Color(0xFF59F797),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to add product image',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(Optional - JPG, PNG)',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Category Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<ProductCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      labelStyle: TextStyle(fontSize: 13),
                      prefixIcon: Icon(Icons.category, size: 20, color: Color(0xFF59F797)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13),
                    items: ProductCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Product Name
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      labelStyle: TextStyle(fontSize: 13),
                      prefixIcon: Icon(Icons.shopping_bag, size: 20, color: Color(0xFF59F797)),
                      hintText: 'Enter product name',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter product name' : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      labelStyle: TextStyle(fontSize: 13),
                      prefixIcon: Icon(Icons.description, size: 20, color: Color(0xFF59F797)),
                      hintText: 'Enter product description',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    maxLines: 3,
                    validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _priceController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Price *',
                            prefixIcon: Icon(Icons.attach_money, size: 20, color: Color(0xFF59F797)),
                            hintText: '0.00',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter price';
                            if (double.tryParse(value) == null) return 'Invalid price';
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _stockController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Stock *',
                            prefixIcon: Icon(Icons.inventory, size: 20, color: Color(0xFF59F797)),
                            hintText: 'Quantity',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter stock';
                            if (int.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Upload Progress Indicator
                if (_uploadProgress != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF59F797).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: null,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF59F797),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _uploadProgress!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59F797),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Product',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
}