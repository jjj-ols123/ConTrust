// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class CorOTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String userId;
  final String email;
  final String firmName;

  const CorOTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.userId,
    required this.email,
    required this.firmName,
  });

  @override
  State<CorOTPVerificationPage> createState() => _CorOTPVerificationPageState();
}

class _CorOTPVerificationPageState extends State<CorOTPVerificationPage> {
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
        module: 'OTP Verification - Contractor',
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
          await supabase.auth.signOut();
        }
        
        UserService().updateUserVerifiedStatus(widget.userId, true);

        _auditService.logAuditEvent(
          userId: widget.userId,
          action: 'PHONE_VERIFIED',
          details: 'Contractor phone number verified successfully',
          metadata: {
            'phone_number': widget.phoneNumber,
            'email': widget.email,
            'verification_method': 'sms_otp',
            'user_type': 'contractor',
            'otp_user_id': otpUserId,
            'original_user_id': widget.userId,
            'ids_matched': otpUserId == widget.userId,
          },
        );

        if (!mounted) return;
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (otpUserId != widget.userId) {
          if (!mounted) return;
          setState(() => _isVerifying = false);
          
          ConTrustSnackBar.success(
            context, 
            'Phone verified! Please log in with your email and password to continue.',
          );
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ToLoginScreen()),
            (route) => false,
          );
        } else {
          if (!mounted) return;
          setState(() => _isVerifying = false);
          
          ConTrustSnackBar.success(context, 'Phone verified successfully!');
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ToLoginScreen()),
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
        details: 'Contractor phone verification failed',
        metadata: {
          'phone_number': widget.phoneNumber,
          'error_message': e.message,
          'error_type': 'AuthException',
          'user_type': 'contractor',
        },
      );

      await _errorService.logError(
        errorMessage: 'OTP verification failed - AuthException: ${e.message}',
        module: 'OTP Verification - Contractor',
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
        errorMessage: 'Unexpected error during OTP verification: $e',
        module: 'OTP Verification - Contractor',
        severity: 'High',
        extraInfo: {
          'operation': 'Verify OTP',
          'phone_number': widget.phoneNumber,
          'users_id': widget.userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ConTrustSnackBar.error(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;
    
    setState(() => _isResending = true);
    
    try {
      await UserService().sendPhoneOTP(phoneNumber: widget.phoneNumber);
      if (mounted) {
        ConTrustSnackBar.success(context, 'OTP resent successfully');
        _startCountdown();
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to resend OTP: $e',
        module: 'OTP Verification - Contractor',
        severity: 'Low',
        extraInfo: {
          'operation': 'Resend OTP',
          'phone_number': widget.phoneNumber,
        },
      );
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to resend OTP. Please try again');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 1000;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgloginscreen.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: isPhone ? screenWidth * 0.8 : 600,
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Image.asset('assets/images/logo3.png', width: 80, height: 80),
                            const SizedBox(height: 16),
                            Text(
                              'Verify Phone Number',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'We sent a verification code to ${widget.phoneNumber}',
                              style: TextStyle(
                                color: Colors.amber.shade600,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 50,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.amber.shade700,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (value.length == 1 && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Didn't receive the code? "),
                            TextButton(
                              onPressed: _resendCountdown > 0 || _isResending
                                  ? null
                                  : _resendOTP,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _resendCountdown > 0
                                          ? 'Resend (${_resendCountdown}s)'
                                          : 'Resend',
                                      style: TextStyle(
                                        color: _resendCountdown > 0
                                            ? Colors.grey
                                            : Colors.amber.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 30,
              child: InkWell(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
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
          ],
        ),
      ),
    );
  }
}

