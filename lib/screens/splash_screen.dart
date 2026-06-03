import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      _redirectBasedOnRole(authService.currentUser!.role);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF59F797), Color(0xFF3BC77A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Login Button at Top Right
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topRight,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.analytics,
                            size: 60,
                            color: Color(0xFF59F797),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Smart Business Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'AI-Powered Business Intelligence',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                '✨ Smart Business Solutions',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '📊 Real-time Analytics',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '🤖 AI-Powered Predictions',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '💼 Entrepreneur Tools',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '🛍️ Smart Shopping Experience',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}