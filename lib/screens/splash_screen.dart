import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      _redirectBasedOnRole(authService.currentUser!.role);
    } else {
      // User is not logged in. Remove loading state and let them read the details.
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectBasedOnRole(role) {
    String route;
    switch (role.toString().split('.').last) {
      case 'admin':
        route = '/admin';
        break;
      case 'entrepreneur':
        route = '/entrepreneur';
        break;
      default:
        route = '/customer';
    }
    
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Deep Premium Gradient Background
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
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
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
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),

          // Glassmorphic Overlay for Depth
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation (Login Button at Right-hand side)
                AnimatedOpacity(
                  opacity: _isLoading ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo Glass Effect
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF59F797).withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.analytics,
                              size: 70,
                              color: Color(0xFF59F797),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Hero Text
                          const Text(
                            'Smart Business',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'Analytics',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF59F797),
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'AI-Powered Business Intelligence\nfor Modern Markets',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Details Glass Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                            child: Column(
                              children: [
                                _buildFeatureRow('✨', 'Smart Business Solutions'),
                                const SizedBox(height: 16),
                                _buildFeatureRow('📊', 'Real-time Analytics'),
                                const SizedBox(height: 16),
                                _buildFeatureRow('🤖', 'AI-Powered Predictions'),
                                const SizedBox(height: 16),
                                _buildFeatureRow('🛍️', 'Seamless Shopping Experience'),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Loading or Get Started
                          if (_isLoading)
                            Column(
                              children: const [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59F797)),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Initializing...',
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            )
                          else
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, '/register');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF59F797),
                                    foregroundColor: const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
