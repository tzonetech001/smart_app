import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/analytics_service.dart';
import '../../utils/location_data.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double subtotal;
  final double deliveryFee;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedDistrict = 'Kinondoni';
  String? _selectedWard = 'Mabibo';
  String _selectedPaymentMethod = 'azam_pesa'; // azam_pesa, cash_on_delivery
  
  int _currentStep = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          _phoneController.text = data['phoneNumber'] ?? '';
          _selectedDistrict = data['district'] ?? 'Kinondoni';
          _selectedWard = data['ward'] ?? 'Mabibo';
        });
      }
    }
  }

  String _formatCurrency(double amount) => 'TZS ${amount.toStringAsFixed(0)}';

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('Please login first', Colors.red);
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // 1. Get entrepreneur ID from first product
      final firstProductId = widget.cartItems.first.productId;
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(firstProductId)
          .get();
      final entrepreneurId = productDoc.data()?['entrepreneurId'] ?? '';

      // 2. Build shipping address details
      final address = ShippingAddress(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        region: 'Dar es Salaam',
        city: 'Dar es Salaam',
        district: _selectedDistrict,
        street: _streetController.text.trim(),
        landmark: _landmarkController.text.isNotEmpty ? _landmarkController.text.trim() : null,
        deliveryInstructions: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      );

      final orderItems = widget.cartItems.map((item) => OrderItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
      )).toList();

      PaymentMethod paymentMethod = _selectedPaymentMethod == 'azam_pesa' 
          ? PaymentMethod.mobile_money 
          : PaymentMethod.cash_on_delivery;

      // 3. Create the initial Order Model (Pending Payment)
      final order = OrderModel(
        id: '',
        userId: userId,
        entrepreneurId: entrepreneurId,
        items: orderItems,
        subtotal: widget.subtotal,
        deliveryFee: widget.deliveryFee,
        totalAmount: widget.total,
        status: OrderStatus.pendingPayment, // Always start pending
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.pending,
        paymentTransactionId: '',
        orderDate: DateTime.now(),
        shippingAddress: address,
        customerNotes: _notesController.text.trim(),
        customerLocation: {
          'region': 'Dar es Salaam',
          'district': _selectedDistrict,
          'ward': _selectedWard ?? 'Mabibo',
        },
      );

      // Save order to Firestore (returns generated ID)
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(order.toMap());

      final orderId = docRef.id;

      // Update Order model with ID locally
      final finalizedOrder = OrderModel(
        id: orderId,
        userId: userId,
        entrepreneurId: entrepreneurId,
        items: orderItems,
        subtotal: widget.subtotal,
        deliveryFee: widget.deliveryFee,
        totalAmount: widget.total,
        status: OrderStatus.pendingPayment,
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.pending,
        paymentTransactionId: '',
        orderDate: order.orderDate,
        shippingAddress: address,
        customerNotes: order.customerNotes,
        customerLocation: order.customerLocation,
      );

      // 4. Branch based on Payment Method
      if (_selectedPaymentMethod == 'cash_on_delivery') {
        // Direct transition for Cash on Delivery (simulates verified offline flow)
        await _completeSuccessfulPayment(finalizedOrder, 'CASH_ON_DELIVERY');
      } else {
        // Online payment via AzamPesa
        setState(() => _isProcessing = false);
        _showAzamPesaVerificationPrompt(finalizedOrder);
      }

    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Failed to place order: $e', Colors.red);
    }
  }

  // High-Fidelity USSD Push overlay prompt
  void _showAzamPesaVerificationPrompt(OrderModel order) {
    final apesaPhoneController = TextEditingController(text: order.shippingAddress.phoneNumber);
    final pinController = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Force them to explicitly make a choice
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Azam Logo Mock
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF005CAA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('azam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Confirm AzamPesa Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Enter your AzamPesa details below to approve the USSD push.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 16),

                  if (isVerifying) ...[
                    const CircularProgressIndicator(color: Color(0xFF005CAA)),
                    const SizedBox(height: 12),
                    const Text('Verifying transaction PIN with AzamPesa...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ] else ...[
                    Text(
                      _formatCurrency(order.totalAmount),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF005CAA)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: apesaPhoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'AzamPesa Phone Number',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'AzamPesa Wallet PIN',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handlePaymentFailure(order.id);
                            },
                            child: const Text('Cancel/Fail', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (apesaPhoneController.text.isEmpty || pinController.text.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter valid number and PIN'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setModalState(() => isVerifying = true);
                              await Future.delayed(const Duration(seconds: 2));
                              Navigator.pop(ctx);
                              _completeSuccessfulPayment(order, 'azam_pesa');
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005CAA)),
                            child: const Text('Confirm PIN', style: TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _completeSuccessfulPayment(OrderModel order, String method) async {
    setState(() => _isProcessing = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      // 1. Update Order in Firestore
      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
        'paymentTransactionId': transactionId,
        'paymentStatus': 'paid',
        'status': 'paymentConfirmed', // Mark as paid/confirmed
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Decrement Stocks
      for (var item in widget.cartItems) {
        await FirebaseFirestore.instance.collection('products').doc(item.productId).update({
          'stock': FieldValue.increment(-item.quantity),
        });
      }

      // 3. Clear Cart
      await FirebaseFirestore.instance.collection('cart')
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });

      // 4. Record Payment Details
      await FirebaseFirestore.instance.collection('payments').add({
        'orderId': order.id,
        'amount': order.totalAmount,
        'method': method,
        'phoneNumber': order.shippingAddress.phoneNumber,
        'transactionId': transactionId,
        'status': 'completed',
        'paymentDate': FieldValue.serverTimestamp(),
      });

      // 5. Log analytics purchase events
      for (var item in widget.cartItems) {
        try {
          final prodDoc = await FirebaseFirestore.instance.collection('products').doc(item.productId).get();
          if (prodDoc.exists) {
            final product = ProductModel.fromMap(item.productId, prodDoc.data()!);
            await AnalyticsService.logPurchase(
              product: product,
              quantity: item.quantity,
              city: order.shippingAddress.city,
              country: 'Tanzania',
            );
          }
        } catch (_) {}
      }

      setState(() => _isProcessing = false);

      // Redirect to success confirmation page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              orderId: order.id,
              amountPaid: order.totalAmount,
              paymentMethod: method == 'azam_pesa' ? 'AzamPesa' : 'Cash on Delivery',
            ),
          ),
        );
      }

    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Payment finalization error: $e', Colors.red);
    }
  }

  void _handlePaymentFailure(String orderId) {
    // Payment failed path: keep cart, direct to orders
    _showSnackBar('AzamPesa transaction rejected. Order saved as Pending Payment.', Colors.orange);
    
    // Redirect to parent page which is Dashboard Orders tab (focus initialTab: 3)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Pop checkout screen back to cart
      }
    });
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: const TextStyle(fontSize: 12)), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Checkout Wizard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF3BC77A),
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3BC77A)),
                  SizedBox(height: 16),
                  Text('Processing your order...', style: TextStyle(fontSize: 12)),
                ],
              ),
            )
          : Column(
              children: [
                // Step Progress Indicator
                _buildStepProgress(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: [
                      _buildDeliveryAddressStep(),
                      _buildPaymentMethodStep(),
                      _buildOrderSummaryStep(),
                    ][_currentStep],
                  ),
                ),

                // Wizard Nav Controls
                _buildWizardControls(),
              ],
            ),
    );
  }

  Widget _buildStepProgress() {
    final stepLabels = ['Delivery', 'Payment', 'Review'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stepLabels.length, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          final color = isCompleted 
              ? const Color(0xFF3BC77A) 
              : (isActive ? const Color(0xFF3BC77A) : Colors.grey[300]);

          return Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF3BC77A) : Colors.white,
                  border: Border.all(color: color!, width: 2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : Text('${index + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF3BC77A) : Colors.grey)),
              ),
              const SizedBox(width: 6),
              Text(
                stepLabels[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
              if (index < stepLabels.length - 1) ...[
                const SizedBox(width: 12),
                Container(width: 24, height: 1, color: Colors.grey[300]),
              ]
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDeliveryAddressStep() {
    return Form(
      key: _formKey,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Recipient Full Name *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Region Lock (dar es salaam only in pilot)
              DropdownButtonFormField<String>(
                value: 'Dar es Salaam',
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Region *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [DropdownMenuItem(value: 'Dar es Salaam', child: Text('Dar es Salaam', style: TextStyle(fontSize: 12)))],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),

              // District Selector
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'District *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: darDistrictsAndWards.keys
                    .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedDistrict = v;
                      _selectedWard = darDistrictsAndWards[v]!.first;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Ward Selector
              DropdownButtonFormField<String>(
                value: _selectedWard,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Ward *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: darDistrictsAndWards[_selectedDistrict]!
                    .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedWard = v),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _streetController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Street Name *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _landmarkController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Landmark / Nearby place (Optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodStep() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Selection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // AzamPesa
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.phone_iphone, color: Color(0xFF005CAA)),
                  SizedBox(width: 8),
                  Text('AzamPesa Mobile Wallet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: const Text('Enter wallet PIN to confirm transaction push.', style: TextStyle(fontSize: 10)),
              value: 'azam_pesa',
              groupValue: _selectedPaymentMethod,
              activeColor: const Color(0xFF3BC77A),
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
            ),
            const Divider(),

            // Cash on Delivery
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.handshake_outlined, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Cash on Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: const Text('Complete payment physically during package delivery.', style: TextStyle(fontSize: 10)),
              value: 'cash_on_delivery',
              groupValue: _selectedPaymentMethod,
              activeColor: const Color(0xFF3BC77A),
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryStep() {
    return Column(
      children: [
        // Items Details
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...widget.cartItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.productName} x${item.quantity}', style: const TextStyle(fontSize: 12)),
                      ),
                      Text(_formatCurrency(item.price * item.quantity), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delivery Review
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Address Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Recipient: ${_fullNameController.text}', style: const TextStyle(fontSize: 11)),
                Text('Contact: ${_phoneController.text}', style: const TextStyle(fontSize: 11)),
                Text('Location: ${_selectedWard}, ${_selectedDistrict}, Dar es Salaam', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                Text('Street: ${_streetController.text}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pricing summary
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                    Text(_formatCurrency(widget.subtotal), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee:', style: TextStyle(fontSize: 12)),
                    Text(_formatCurrency(widget.deliveryFee), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order Total:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      _formatCurrency(widget.total),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3BC77A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3BC77A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back', style: TextStyle(fontSize: 12, color: Color(0xFF3BC77A))),
              ),
            )
          else
            const Spacer(),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 2 ? _placeOrder : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3BC77A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _currentStep == 2 
                    ? (_selectedPaymentMethod == 'cash_on_delivery' ? 'Confirm Order' : 'Pay Now') 
                    : 'Next',
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}