// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String userId;
  final String email;
  final String fullName;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.userId,
    required this.email,
    required this.fullName,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOTP() async {
    try {
      await UserService().sendPhoneOTP(phoneNumber: widget.phoneNumber);
      if (mounted) {
        ConTrustSnackBar.success(context, 'OTP sent to ${widget.phoneNumber}');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to send OTP: $e',
        module: 'OTP Verification',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Send OTP',
          'phone_number': widget.phoneNumber,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to send OTP. Please try again');
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      ConTrustSnackBar.error(context, 'Please enter complete OTP');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await UserService().verifyPhoneOTP(
        phoneNumber: widget.phoneNumber,
        otpCode: otp,
      );

      if (response.user != null) {
        final supabase = Supabase.instance.client;
        final otpUserId = response.user!.id;
        
        if (otpUserId != widget.userId) {
          // Sign out of the OTP session
          await supabase.auth.signOut();
        }
        
        // Update the ORIGINAL user's verified status in background
        UserService().updateUserVerifiedStatus(widget.userId, true);

        _auditService.logAuditEvent(
          userId: widget.userId,
          action: 'PHONE_VERIFIED',
          details: 'Phone number verified successfully',
          metadata: {
            'phone_number': widget.phoneNumber,
            'email': widget.email,
            'verification_method': 'sms_otp',
            'otp_user_id': otpUserId,
            'original_user_id': widget.userId,
            'ids_matched': otpUserId == widget.userId,
          },
        );

        if (!mounted) return;
        
        // Small delay for processing
        await Future.delayed(const Duration(milliseconds: 500));
        
        // If user IDs don't match, redirect to login
        if (otpUserId != widget.userId) {
          if (!mounted) return;
          setState(() => _isVerifying = false);
          
          ConTrustSnackBar.success(
            context, 
            'Phone verified! Please log in with your email and password to continue.',
          );
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (!mounted) return;
          // Navigate to login page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        } else {
          // IDs match - can proceed normally
          if (!mounted) return;
          setState(() => _isVerifying = false);
          
          ConTrustSnackBar.success(context, 'Phone verified successfully!');
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      } else {
        throw Exception('Verification failed - no user returned');
      }
    } on AuthException catch (e) {
      await _auditService.logAuditEvent(
        userId: widget.userId,
        action: 'PHONE_VERIFICATION_FAILED',
        details: 'Phone verification failed',
        metadata: {
          'phone_number': widget.phoneNumber,
          'error_message': e.message,
          'error_type': 'AuthException',
        },
      );

      await _errorService.logError(
        errorMessage: 'OTP verification failed - AuthException: ${e.message}',
        module: 'OTP Verification',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Verify OTP',
          'phone_number': widget.phoneNumber,
          'users_id': widget.userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ConTrustSnackBar.error(context, 'Invalid OTP. Please try again.');
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'OTP verification failed - Unexpected error: $e',
        module: 'OTP Verification',
        severity: 'High',
        extraInfo: {
          'operation': 'Verify OTP',
          'phone_number': widget.phoneNumber,
          'users_id': widget.userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ConTrustSnackBar.error(context, 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;
    
    setState(() => _isResending = true);
    
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    try {
      await UserService().sendPhoneOTP(phoneNumber: widget.phoneNumber);
      
      await _auditService.logAuditEvent(
        userId: widget.userId,
        action: 'OTP_RESENT',
        details: 'OTP resent to phone',
        metadata: {
          'phone_number': widget.phoneNumber,
        },
      );

      if (!mounted) return;
      ConTrustSnackBar.success(context, 'New OTP sent successfully!');
      _startCountdown();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to resend OTP: $e',
        module: 'OTP Verification',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Resend OTP',
          'phone_number': widget.phoneNumber,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ConTrustSnackBar.error(context, 'Failed to resend OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade100,
              Colors.white,
              Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 60,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Verify Phone Number',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the 6-digit code sent to',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOTPField(index),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 60,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: (_isResending || _resendCountdown > 0) ? null : _resendOTP,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.amber,
                              ),
                            )
                          : Text(
                              _resendCountdown > 0 
                                  ? 'Resend OTP in ${_resendCountdown}s'
                                  : 'Resend OTP',
                              style: TextStyle(
                                color: _resendCountdown > 0 
                                    ? Colors.grey 
                                    : Colors.teal.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: _resendCountdown > 0 
                                    ? TextDecoration.none 
                                    : TextDecoration.underline,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
            
          if (index == 5 && value.isNotEmpty) {
            _verifyOTP();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

