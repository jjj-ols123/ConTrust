// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/superadmin%20services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:superadmin/pages/dashboard.dart';
import '../build/buildadminlogin.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import '../build/builddrawer.dart'; // Added import for SuperAdminShell

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (!AdminLoginService().isAdminAccount(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid admin email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminLoginService().signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const SuperAdminShell(
              currentPage: SuperAdminPage.dashboard,
              child: SuperAdminDashboard(),
            ),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Super Admin login failed: $e',
        module: 'Super Admin Login',
        severity: 'High',
        extraInfo: {
          'operation': 'Admin Sign In',
          'email': _emailController.text,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BuildAdminLogin.buildLoginForm(
            context: context,
            emailController: _emailController,
            passwordController: _passwordController,
            passwordFocusNode: _passwordFocusNode,
            isLoading: _isLoading,
            obscurePassword: _obscurePassword,
            errorMessage: _errorMessage,
            onSignIn: _signIn,
            onTogglePasswordVisibility: _togglePasswordVisibility,
          ),
        ],
      ),
    );
  }
}
