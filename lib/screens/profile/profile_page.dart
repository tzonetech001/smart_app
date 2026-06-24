import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../utils/location_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;
  UserModel? _userData;

  // Personal Info Form fields
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Address fields
  String _selectedDistrict = 'Kinondoni';
  String? _selectedWard = 'Mabibo';

  // Toggle flags
  bool _isEditingPersonalInfo = false;
  bool _isEditingLocation = false;
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (doc.exists) {
      final userMap = doc.data() as Map<String, dynamic>;
      setState(() {
        _userData = UserModel.fromMap(doc.id, userMap);
        _firstNameController.text = _userData!.firstName;
        _lastNameController.text = _userData!.lastName;
        _phoneController.text = _userData!.phoneNumber;
        _selectedGender = _userData!.gender;
        _selectedDistrict = _userData!.district ?? 'Kinondoni';
        _selectedWard = _userData!.ward ?? 'Mabibo';
      });
    }
  }

  Future<void> _updatePersonalInfo() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedGender,
      });

      setState(() {
        _isEditingPersonalInfo = false;
        _isLoading = false;
      });

      _showSnackBar('Personal information updated!', Colors.green);
      _loadUserData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to update: $e', Colors.red);
    }
  }

  Future<void> _updateLocation() async {
    if (_userId == null || _selectedWard == null) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'district': _selectedDistrict,
        'ward': _selectedWard,
      });

      setState(() {
        _isEditingLocation = false;
        _isLoading = false;
      });

      _showSnackBar('Delivery location updated!', Colors.green);
      _loadUserData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to update location: $e', Colors.red);
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: const TextStyle(fontSize: 12)), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  String _formatCurrency(double amount) => 'TZS ${amount.toStringAsFixed(0)}';

  void _showPaymentHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final allDocs = snapshot.data!.docs;
                  // Filter locally where transaction belongs to users orders
                  // Since orderId maps to orders we can fetch payments
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: _userId)
                        .snapshots(),
                    builder: (context, oSnap) {
                      if (!oSnap.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final userOrderIds = oSnap.data!.docs.map((d) => d.id).toSet();
                      final myPayments = allDocs.where((doc) {
                        final orderId = doc.get('orderId') ?? '';
                        return userOrderIds.contains(orderId);
                      }).toList();

                      if (myPayments.isEmpty) {
                        return const Center(child: Text('No payment transactions found.', style: TextStyle(fontSize: 12, color: Colors.grey)));
                      }

                      return ListView.builder(
                        itemCount: myPayments.length,
                        itemBuilder: (context, index) {
                          final payment = myPayments[index];
                          final amount = (payment.get('amount') ?? 0.0).toDouble();
                          final method = payment.get('method') ?? 'azam_pesa';
                          final methodDisplay = method == 'azam_pesa' ? 'AzamPesa' : 'Cash on Delivery';
                          final status = payment.get('status') ?? 'completed';
                          final txId = payment.get('transactionId') ?? '';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              method == 'azam_pesa' ? Icons.phone_iphone : Icons.handshake,
                              color: const Color(0xFF3BC77A),
                            ),
                            title: Text('Payment Verified ($methodDisplay)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text('Tx ID: ${txId.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            trailing: Text(
                              _formatCurrency(amount),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3BC77A)),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF3BC77A),
                      child: Icon(Icons.person, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData!.fullName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userData!.email,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Joined: ${_userData!.createdAt.day}/${_userData!.createdAt.month}/${_userData!.createdAt.year}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Sections Accordion List
            _buildPersonalInfoSection(),
            const SizedBox(height: 12),
            _buildLocationSection(),
            const SizedBox(height: 12),
            _buildHistoryAndVerificationSection(),
            const SizedBox(height: 12),
            _buildNotificationAndAppSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: Color(0xFF3BC77A)),
                      SizedBox(width: 8),
                      Text('Personal Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditingPersonalInfo = !_isEditingPersonalInfo;
                      });
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    child: Text(_isEditingPersonalInfo ? 'Cancel' : 'Edit', style: const TextStyle(fontSize: 11, color: Color(0xFF3BC77A))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isEditingPersonalInfo) ...[
                TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePersonalInfo,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3BC77A)),
                    child: const Text('Save Info', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                _buildInfoTile('Phone', _userData!.phoneNumber),
                _buildInfoTile('Gender', _userData!.gender ?? 'Not specified'),
                _buildInfoTile('Email', _userData!.email),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF3BC77A)),
                    SizedBox(width: 8),
                    Text('Saved Delivery Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingLocation = !_isEditingLocation;
                    });
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: Text(_isEditingLocation ? 'Cancel' : 'Change', style: const TextStyle(fontSize: 11, color: Color(0xFF3BC77A))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditingLocation) ...[
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
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
              DropdownButtonFormField<String>(
                value: _selectedWard,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(labelText: 'Ward', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                items: darDistrictsAndWards[_selectedDistrict]!
                    .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedWard = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateLocation,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3BC77A)),
                  child: const Text('Save Location', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              _buildInfoTile('Region', 'Dar es Salaam (Pilot Region)'),
              _buildInfoTile('District', _userData!.district ?? 'Not specified'),
              _buildInfoTile('Ward', _userData!.ward ?? 'Not specified'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndVerificationSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.payment_outlined, color: Color(0xFF3BC77A)),
            title: const Text('Payment History & Verified Transactions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12),
            onTap: _showPaymentHistory,
          ),
          const Divider(height: 1, indent: 56),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: _userId)
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return ListTile(
                leading: const Icon(Icons.history_outlined, color: Color(0xFF3BC77A)),
                title: const Text('Purchase History (Completed Orders)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF3BC77A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('$count orders', style: const TextStyle(fontSize: 10, color: Color(0xFF3BC77A), fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationAndAppSettingsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email Notifications', style: TextStyle(fontSize: 12)),
              activeColor: const Color(0xFF3BC77A),
              value: _emailNotifications,
              onChanged: (v) => setState(() => _emailNotifications = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push Notifications', style: TextStyle(fontSize: 12)),
              activeColor: const Color(0xFF3BC77A),
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark Mode Settings', style: TextStyle(fontSize: 12)),
              activeColor: const Color(0xFF3BC77A),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}