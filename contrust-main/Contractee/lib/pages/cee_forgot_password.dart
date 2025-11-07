// ignore_for_file: file_names, use_build_context_synchronously, deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html show window;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSendingReset = false;
  bool _emailSent = false;
  bool _isRecoveryMode = false;
  bool _isLoading = false;

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@gmail\.com$').hasMatch(email);
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ConTrustSnackBar.error(context, 'Please enter your email address');
      return;
    }

    if (!isValidEmail(email)) {
      ConTrustSnackBar.error(
        context,
        'Please enter a valid Gmail address (example@gmail.com).',
      );
      return;
    }

    setState(() => _isSendingReset = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'send-password-reset-email',
        body: {
          'email': email,
          'redirectTo': 'https://www.contractee.contrust-sjdm.com/auth/reset-password',
          'userType': 'contractee',
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data?['error'] ?? data?['message'] ?? 'Failed to send password reset email';
        throw Exception(message);
      }

      if (!mounted) return;

      setState(() => _emailSent = true);
      
      ConTrustSnackBar.success(
        context,
        'Password reset email sent! Please check your inbox.',
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Failed to send reset email. Please try again later.';
      
      if (e is AuthException) {
        final msg = e.message.toLowerCase();
        if (msg.contains('not found') || msg.contains('no user') || msg.contains('user not found')) {
          errorMessage = 'No account found with this email address.';
        } else if (msg.contains('recovery email') || msg.contains('sending') || msg.contains('email')) {
          errorMessage = 'Unable to send reset email. Please check your Supabase email configuration or try again later.';
        } else if (msg.contains('rate') || msg.contains('limit') || msg.contains('too many')) {
          errorMessage = 'Too many attempts. Please try again later.';
        } else {
          errorMessage = 'Error: ${e.message}';
        }
      } else {
        final errorText = e.toString().toLowerCase();
        if (errorText.contains('not found') || errorText.contains('no user')) {
          errorMessage = 'No account found with this email address.';
        } else if (errorText.contains('recovery email') || errorText.contains('sending') || errorText.contains('unexpected_failure')) {
          errorMessage = 'Unable to send reset email. Please check your Supabase email configuration or try again later.';
        } else if (errorText.contains('network') || errorText.contains('socket')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }
      }
      
      ConTrustSnackBar.error(
        context,
        errorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[ForgotPassword] Screen initialized');
    debugPrint('[ForgotPassword] Current URL: ${Uri.base}');
    if (kIsWeb) {
      try {
        debugPrint('[ForgotPassword] Window location: ${html.window.location.href}');
        debugPrint('[ForgotPassword] Window hash: ${html.window.location.hash}');
      } catch (e) {
        debugPrint('[ForgotPassword] Error getting window location: $e');
      }
    }
    _initRecovery();
  }

  Future<void> _initRecovery() async {
    setState(() => _isLoading = true);
    
    String hash = '';
    if (kIsWeb) {
      try {
        hash = html.window.location.hash;
        if (hash.startsWith('#')) {
          hash = hash.substring(1); 
        }
      } catch (_) {
        final uri = Uri.base;
        hash = uri.fragment;
      }
    } else {
      final uri = Uri.base;
      hash = uri.fragment;
    }
    if (hash.isNotEmpty) {
      debugPrint('[ForgotPassword] Parsing hash parameters');
      final params = Uri.splitQueryString(hash);
      final error = params['error'];
      final errorCode = params['error_code'];
      final errorDescription = params['error_description'];
      debugPrint('[ForgotPassword] Error: $error, ErrorCode: $errorCode, Description: $errorDescription');
      
      if (error != null || errorCode != null) {
        String errorMessage = 'Password reset link error.';
        if (errorCode == 'otp_expired') {
          errorMessage = 'This password reset link has expired. Please request a new one.';
        } else if (error == 'access_denied') {
          errorMessage = 'Access denied. The reset link may be invalid or expired.';
        } else if (errorDescription != null) {
          errorMessage = Uri.decodeComponent(errorDescription.replaceAll('+', ' '));
        }
        
        debugPrint('[ForgotPassword] Showing error message: $errorMessage');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ConTrustSnackBar.error(context, errorMessage);
          });
        }
        setState(() {
          _isRecoveryMode = false;
          _isLoading = false;
        });
        return;
      }
    }
    
    try {
      // Get the full URL including hash for web
      Uri url;
      if (kIsWeb) {
        try {
          url = Uri.parse(html.window.location.href);
        } catch (_) {
          url = Uri.base;
        }
      } else {
        url = Uri.base;
      }
      await Supabase.instance.client.auth.getSessionFromUrl(url, storeSession: true);
      setState(() {
        _isRecoveryMode = true;
      });
    } catch (e) {
      String errorMessage = 'Unable to process password reset link.';
      if (e is AuthException) {
        if (e.message.toLowerCase().contains('expired') || e.message.toLowerCase().contains('invalid')) {
          errorMessage = 'This password reset link has expired or is invalid. Please request a new one.';
        } else {
          errorMessage = e.message;
        }
      }
      
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ConTrustSnackBar.error(context, errorMessage);
        });
      }
      
      setState(() {
        _isRecoveryMode = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdatePassword() async {
    final newPw = _newPasswordController.text.trim();
    final confirmPw = _confirmPasswordController.text.trim();

    if (newPw.isEmpty || confirmPw.isEmpty) {
      ConTrustSnackBar.error(context, 'Please enter and confirm your new password');
      return;
    }
    if (newPw != confirmPw) {
      ConTrustSnackBar.error(context, 'Passwords do not match');
      return;
    }
    if (newPw.length < 6 || newPw.length > 15) {
      ConTrustSnackBar.error(context, 'Password must be 6-15 characters long');
      return;
    }

    final hasUpper = newPw.contains(RegExp(r'[A-Z]'));
    final hasNum = newPw.contains(RegExp(r'[0-9]'));
    final hasSpecial = newPw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (!hasUpper || !hasNum || !hasSpecial) {
      ConTrustSnackBar.error(context, 'Password must include uppercase, number and special character');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPw));
      ConTrustSnackBar.success(context, 'Password updated. Please sign in.');
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      ConTrustSnackBar.error(context, e.message);
    } catch (_) {
      ConTrustSnackBar.error(context, 'Failed to update password');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: const AssetImage('assets/bgloginscreen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 16 : 24,
                    vertical: isPhone ? 16 : 20,
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
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Container(
                        width: isPhone ? 4 : 6,
                        height: isPhone ? 28 : 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: isPhone ? 8 : 12),
                      const Text(
                        'ConTrust',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1a1a1a),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                      ),
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: isPhone ? screenWidth * 0.9 : 500,
                        padding: const EdgeInsets.all(24),
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
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                            : _isRecoveryMode
                                ? _buildRecoveryForm()
                                : (_emailSent ? _buildEmailSentContent() : _buildResetForm()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            size: 48,
            color: Colors.amber.shade700,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address (Gmail only)',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingReset ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: _isSendingReset
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Back to Login',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSentContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Click the link in the email to reset your password. The link will expire in 1 hour.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
            _emailController.clear();
          },
          child: Text(
            'Send to a different email',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.amber.shade700,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Set New Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleUpdatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Update Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Back',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

