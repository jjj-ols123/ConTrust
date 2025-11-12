// ignore_for_file: file_names, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, avoid_web_libraries_in_flutter
import 'dart:io';

import 'package:backend/utils/be_validation.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/services/contractor services/cor_signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:backend/build/html_stub.dart' if (dart.library.html) 'dart:html' as html;

class ToLoginScreen extends StatefulWidget {
  const ToLoginScreen({super.key});

  @override
  _ToLoginScreenState createState() => _ToLoginScreenState();
}

class _ToLoginScreenState extends State<ToLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _passwordVisible = false; 
  final AssetImage _bgImage = const AssetImage('assets/images/bgloginscreen.jpg');

  @override
  void initState() {
    super.initState();
    _checkPasswordResetRedirect();
  }

  void _checkPasswordResetRedirect() {
    Uri url = Uri.base;
    String hash = '';
    
    if (kIsWeb) {
      try {
        hash = html.window.location.hash;
        url = Uri.parse(html.window.location.href);
      } catch (e) {
        debugPrint('[ToLoginScreen] Error parsing URL: $e');
      }
    } else {
      url = Uri.base;
      hash = url.fragment;
    }
    
    if (hash.isEmpty) {
      hash = url.fragment;
    }
    
    if (hash.startsWith('#')) {
      hash = hash.substring(1);
    }
    
    final queryParams = url.queryParameters;
    final hashParams = hash.isNotEmpty ? Uri.splitQueryString(hash) : <String, String>{};
    
    // Check for password reset indicators
    final hasRecoveryCode = hashParams.containsKey('access_token') ||
                           (hashParams.containsKey('type') && hashParams['type'] == 'recovery') ||
                           hashParams.containsKey('code') ||
                           queryParams.containsKey('access_token') ||
                           (queryParams.containsKey('type') && queryParams['type'] == 'recovery') ||
                           queryParams.containsKey('code');
    
    if (hasRecoveryCode) {
      debugPrint('[ToLoginScreen] Detected password reset flow, redirecting to /auth/reset-password');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Preserve hash for web
          if (kIsWeb && hash.isNotEmpty) {
            final baseUrl = html.window.location.origin;
            final hashWithPrefix = hash.startsWith('#') ? hash : '#$hash';
            html.window.location.href = '$baseUrl/auth/reset-password$hashWithPrefix';
          } else {
            // For mobile, use router with query parameters
            final redirectUrl = hash.isNotEmpty 
                ? '/auth/reset-password#$hash'
                : '/auth/reset-password';
            context.go(redirectUrl);
          }
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_bgImage, context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    
    setState(() => _isLoggingIn = true);
    try {
      final signInContractor = SignInContractor();
      final success = await signInContractor.signInContractor(
        context,
        _emailController.text,
        _passwordController.text,
        () => validateFieldsLogin(
          context,
          _emailController.text,
          _passwordController.text,
        ),
      );

      if (success && mounted) {
        context.replace('/dashboard');
      }

    } on SocketException {
      ConTrustSnackBar.error(
        context,
        'No internet connection. Please check your network settings.',
      );
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 1000;
    final isSmallScreen = screenWidth < 600;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final bool isMobile = screenWidth < 600;
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: _bgImage,
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: isSmallScreen ? 4 : 6,
                        height: isSmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Text(
                        'ConTrust',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1a1a1a),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 8 : 20,
                      ),
                      child: Container(
                        width: isPhone ? screenWidth * 0.9 : 600,
                        padding: EdgeInsets.all(isMobile ? 20 : 28),
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _buildLoginForm(context),
                      ),
                    ),
                  ),
                ),
                if (!keyboardVisible || !isMobile)
                  _buildFooter(context, isDesktop, isTablet, isMobile),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildLoginForm(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Column(
        children: [
          Icon(
            Icons.business,
            size: isMobile ? 60 : 80,
            color: Colors.amber.shade400,
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            'Be a part of our community and start your journey with us today!',
            style: TextStyle(
              color: Colors.amber.shade600,
              fontSize: isMobile ? 11 : 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      SizedBox(height: isMobile ? 20 : 30),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Email Address',
          prefixIcon: const Icon(Icons.email_outlined),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      SizedBox(height: isMobile ? 12 : 18),
      TextFormField(
        controller: _passwordController,
        keyboardType: TextInputType.visiblePassword,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      SizedBox(height: isMobile ? 18 : 25),
      ElevatedButton(
        onPressed: _isLoggingIn ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: _isLoggingIn
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
      SizedBox(height: isMobile ? 12 : 20),
      Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Or Continue With',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 20),
      InkWell(
        onTap: () {
          SignInGoogleContractor().signInGoogle(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.g_mobiledata, size: 28, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              const Text(
                "Continue with Google",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: isMobile ? 12 : 20),
      TextButton(
        onPressed: () {
          context.go('/auth/reset-password');
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Colors.amber.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(height: isMobile ? 6 : 10),
      InkWell(
        onTap: () {
          context.go('/register');
        },
        child: Text.rich(
          TextSpan(
            text: "Don't have an account? ",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            children: [
              TextSpan(
                text: "Sign up",
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

  Widget _buildFooter(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = 10;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
            child: Text(
              'Building trust in construction, one contract at a time.',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
