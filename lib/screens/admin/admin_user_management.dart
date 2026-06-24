import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  String _selectedFilter = 'all';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentAdminId;

  @override
  void initState() {
    super.initState();
    _getCurrentAdminId();
  }

  Future<void> _getCurrentAdminId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentAdminId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter and Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
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

                // Filter Chips - Role
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Users', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('👤 Customers', 'customer'),
                      const SizedBox(width: 8),
                      _buildFilterChip('💼 Entrepreneurs', 'entrepreneur'),
                      const SizedBox(width: 8),
                      _buildFilterChip('👑 Admins', 'admin'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Filter Chips - Status
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('All Status', 'all'),
                      const SizedBox(width: 8),
                      _buildStatusChip('✅ Active', 'active'),
                      const SizedBox(width: 8),
                      _buildStatusChip('⛔ Suspended', 'suspended'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Users List - Scrollable
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.map((doc) {
                  return UserModel.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

                // Apply role filter
                if (_selectedFilter != 'all') {
                  users = users.where((user) {
                    return user.role.toString().split('.').last ==
                        _selectedFilter;
                  }).toList();
                }

                // Apply status filter
                if (_selectedStatus != 'all') {
                  final isActive = _selectedStatus == 'active';
                  users = users.where((user) {
                    return user.isActive == isActive;
                  }).toList();
                }

                // Apply search
                if (_searchQuery.isNotEmpty) {
                  users = users.where((user) {
                    return user.fullName.toLowerCase().contains(_searchQuery) ||
                        user.email.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No users match your search'
                              : 'No users found',
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
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isCurrentAdmin = user.id == _currentAdminId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isCurrentAdmin
                            ? BorderSide(color: Colors.blue.shade300, width: 1)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                              child: Text(
                                user.firstName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isCurrentAdmin) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'You',
                                            style: TextStyle(fontSize: 10, color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: user.isActive 
                                              ? Colors.green.withOpacity(0.1) 
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          user.isActive ? 'Active' : 'Suspended',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: user.isActive ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.phoneNumber,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(user.role).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getRoleDisplayName(user.role),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getRoleColor(user.role),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Registered: ${_formatDate(user.createdAt)}',
                                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Action Buttons
                            if (!isCurrentAdmin)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                                    onPressed: () => _showUserProfile(user),
                                    tooltip: 'View Profile',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      user.isActive ? Icons.block : Icons.check_circle,
                                      size: 18,
                                      color: user.isActive ? Colors.orange : Colors.green,
                                    ),
                                    onPressed: () => _toggleUserStatus(user),
                                    tooltip: user.isActive ? 'Suspend' : 'Activate',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                    onPressed: () => _showEditUserInfoDialog(user),
                                    tooltip: 'Edit User',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmDialog(user),
                                    tooltip: 'Delete User',
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Current Admin',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
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
        onPressed: () => _showAddUserDialog(),
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

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '👑 ADMIN';
      case UserRole.entrepreneur:
        return '💼 ENTREPRENEUR';
      default:
        return '👤 CUSTOMER';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.entrepreneur:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  void _showUserProfile(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Profile: ${user.fullName}', style: const TextStyle(fontSize: 16)),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow('Name', user.fullName),
              _buildProfileRow('Email', user.email),
              _buildProfileRow('Phone', user.phoneNumber),
              _buildProfileRow('Role', _getRoleDisplayName(user.role)),
              _buildProfileRow('Status', user.isActive ? 'Active' : 'Suspended'),
              _buildProfileRow('Joined', _formatDate(user.createdAt)),
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

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final action = user.isActive ? 'suspend' : 'activate';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.isActive ? 'Suspend' : 'Activate'} User', style: const TextStyle(fontSize: 16)),
        content: Text(
          'Are you sure you want to ${user.isActive ? 'suspend' : 'activate'} ${user.fullName}?',
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
                  .collection('users')
                  .doc(user.id)
                  .update({'isActive': !user.isActive});
              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessMessage('User ${user.isActive ? 'suspended' : 'activated'} successfully');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: user.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(
              user.isActive ? 'Suspend' : 'Activate',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _passwordController = TextEditingController();
    final _locationController = TextEditingController();
    UserRole _selectedRole = UserRole.customer;
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New User', style: TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Valid email required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            _getRoleDisplayName(role),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            _selectedRole = value;
                          });
                        }
                      },
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
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setDialogState(() => _isLoading = true);

                          final authService =
                              Provider.of<AuthService>(context, listen: false);
                          final newUser = UserModel(
                            id: '',
                            firstName: _firstNameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                            email: _emailController.text.trim(),
                            phoneNumber: _phoneController.text.trim(),
                            role: _selectedRole,
                            createdAt: DateTime.now(),
                          );

                          bool success = await authService.createUserByAdmin(
                            newUser,
                            _passwordController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              _showSuccessMessage('User created successfully!');
                            } else {
                              _showErrorMessage('Failed to create user. Please try again.');
                            }
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add User', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditUserInfoDialog(UserModel user) {
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController(text: user.firstName);
    final _lastNameController = TextEditingController(text: user.lastName);
    final _phoneController = TextEditingController(text: user.phoneNumber);
    final _emailController = TextEditingController(text: user.email);
    final _locationController = TextEditingController(text: '');
    UserRole _newRole = user.role;
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit User: ${user.fullName}', style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 12),
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email (Cannot be changed)',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Change Role:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserRole>(
                      value: _newRole,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            _getRoleDisplayName(role),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() => _newRole = value!),
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
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setDialogState(() => _isLoading = true);

                          final authService =
                              Provider.of<AuthService>(context, listen: false);
                          
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.id)
                              .update({
                            'firstName': _firstNameController.text.trim(),
                            'lastName': _lastNameController.text.trim(),
                            'phoneNumber': _phoneController.text.trim(),
                          });
                          
                          if (_newRole != user.role) {
                            await authService.updateUserRole(user.id, _newRole);
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            _showSuccessMessage('User updated successfully!');
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${user.fullName}?',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${user.email}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              bool success = await authService.deleteUser(user.id);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  _showSuccessMessage('User deleted successfully!');
                } else {
                  _showErrorMessage('Failed to delete user.');
                }
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