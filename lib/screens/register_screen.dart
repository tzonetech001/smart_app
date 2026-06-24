import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../utils/location_data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  String? _selectedDistrict;
  String? _selectedWard;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    bool success = await authService.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim(),
      gender: _selectedGender,
      district: _selectedDistrict,
      ward: _selectedWard,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Color(0xFF59F797)),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authService.errorMessage ?? 'Registration failed'), backgroundColor: Colors.redAccent),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.white54),
      prefixIcon: Icon(icon, size: 20, color: Colors.white70),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF59F797), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
             Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: Stack(
        children: [
          // Premium Dark Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),
          
          // Background Decorative Orbs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF59F797).withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF59F797).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),

          // Glassmorphic Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_outlined, size: 50, color: Color(0xFF59F797)),
                        const SizedBox(height: 20),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: _buildInputDecoration('First Name', Icons.person_outline),
                                validator: Validators.required,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: _buildInputDecoration('Last Name', Icons.person_outline),
                                validator: Validators.required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: _buildInputDecoration('Email', Icons.email_outlined),
                          validator: Validators.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: _buildInputDecoration('Phone Number', Icons.phone_outlined),
                          validator: Validators.phoneNumber,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: _buildInputDecoration('Gender', Icons.wc_outlined),
                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: _buildInputDecoration('District *', Icons.location_city_outlined),
                          items: darDistrictsAndWards.keys
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedDistrict = v;
                              _selectedWard = null;
                            });
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedWard,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          disabledHint: const Text('Select a District first', style: TextStyle(color: Colors.white54)),
                          decoration: _buildInputDecoration('Ward *', Icons.map_outlined),
                          items: _selectedDistrict == null
                              ? null
                              : darDistrictsAndWards[_selectedDistrict]!
                                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                                  .toList(),
                          onChanged: (v) => setState(() => _selectedWard = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _confirmPasswordController,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: _buildInputDecoration('Confirm Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (v) => v == null || v.isEmpty ? 'Please confirm your password' : null,
                        ),
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF59F797),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Consumer<AuthService>(
                              builder: (c, a, _) => a.isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                                  : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ", style: TextStyle(fontSize: 14, color: Colors.white54)),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text('Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF59F797))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}