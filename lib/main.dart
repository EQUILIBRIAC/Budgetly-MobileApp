import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budgetly',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        'login': (context) => const LoginScreen(),
        'forgot-password': (context) => const ForgotPasswordScreen(),
        'signup': (context) => const SignupScreen(),
        'member-dashboard': (context) => const DashboardScreen(role: 'member'),
        'representative-dashboard': (context) => const DashboardScreen(role: 'representative'),
      },
    );
  }
}

// Placeholder screens for navigation
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Center(child: Text('Forgot Password Screen')),
    );
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const Center(child: Text('Signup Screen')),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$role Dashboard')),
      body: Center(child: Text('$role Dashboard Screen')),
    );
  }
}
