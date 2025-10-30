// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignInContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signInContractee(
    BuildContext context,
    String email,
    String password,
    bool Function() validateFields,
  ) async {
    if (!validateFields()) {
      return;
    }

    dynamic signInResponse;
    try {
      signInResponse = await UserService().signIn(
        email: email,
        password: password,
      );

      if (signInResponse == null || signInResponse.user == null || signInResponse.user!.id == null) {
        await _auditService.logAuditEvent(
          action: 'USER_LOGIN_FAILED',
          details: 'Contractee login failed - no user ID returned',
          metadata: {
            'user_type': 'contractee',
            'email': email,
            'failure_reason': 'no_user_id',
          },
        );
        ConTrustSnackBar.error(context, 'Authentication failed');
        return;
      }

      final user = signInResponse.user!;
      final userType = user.userMetadata != null ? user.userMetadata!['user_type'] : null;

      if (userType == null || userType.toLowerCase() != 'contractee') {
        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN_FAILED',
          details: 'Login attempt with wrong user type',
          metadata: {
            'user_type': userType,
            'expected_type': 'contractee',
            'email': email,
            'failure_reason': 'wrong_user_type',
          },
        );
        ConTrustSnackBar.error(context, 'Not a contractee account');
        return;
      }

      final supabase = Supabase.instance.client;

      try {
        await supabase.from('Users').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('users_id', user.id);
      } catch (e) {
        await _errorService.logError(
          errorMessage: 'Failed to update last_login for contractee: $e',
          module: 'Contractee Sign-in',
          severity: 'Low',
          extraInfo: {
            'operation': 'Update Last Login',
            'users_id': user.id,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      await _auditService.logAuditEvent(
        userId: user.id,
        action: 'USER_LOGIN',
        details: 'Contractee logged in successfully',
        metadata: {
          'user_type': 'contractee',
          'email': email,
          'login_method': 'email_password',
        },
      );

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Successfully logged in');
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
      }

    } catch (e) {
      await _auditService.logAuditEvent(
        userId: signInResponse != null && signInResponse.user != null ? signInResponse.user!.id : null,
        action: 'USER_LOGIN_FAILED',
        details: 'Contractee login failed due to error: $e',
        metadata: {
          'user_type': 'contractee',
          'email': email,
          'error_message': e.toString(),
          'failure_reason': 'system_error',
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee sign-in failed: $e',
        module: 'Contractee Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign In Contractee',
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Login failed. Please try again.');
      }
    }
  }

  void signUpContractee(
    BuildContext context,
    String email,
    String password,
    String userType,
    Map<String, dynamic>? data,
    bool Function() validateFields,
  ) async {
    if (!validateFields()) {
      return;
    }

    dynamic signUpResponse;
    try {
      signUpResponse = await UserService().signUp(
        email: email,
        password: password,
        data: data,
      );

      if (signUpResponse.user == null) {
        if (!context.mounted) return;
        ConTrustSnackBar.success(context, 'Account created! Please check your email to confirm and complete registration.');
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
        return;
      }

      final user = signUpResponse.user!;
      
      final supabase = Supabase.instance.client;

      await Future.delayed(const Duration(milliseconds: 1000));

      bool insertSuccess = false;
      for (int attempt = 0; attempt < 5 && !insertSuccess; attempt++) {
        try {
          await supabase.from('Users').upsert({
            'users_id': user.id,
            'email': email,
            'name': data?['full_name'] ?? 'Contractee',
            'role': 'contractee',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'last_login': DateTime.now().toIso8601String(),
            'profile_image_url': data?['profilePhoto'],
            'phone_number': data?['phone_number'] ?? '',
            'verified': false,
          }, onConflict: 'users_id');
          insertSuccess = true;
        } catch (e) {
          if (attempt == 4) {
            // Last attempt failed
            throw Exception('Failed to create user record: $e');
          }
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }

      final insertResponse = await supabase.from('Contractee').insert({
        'contractee_id': user.id,
        'full_name': data?['full_name'] ?? 'Contractee',
        'address': data?['address'] ?? '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select();

      if (insertResponse.isEmpty) {
        throw Exception('Failed to save contractee data');
      }

      await _auditService.logAuditEvent(
        userId: user.id,
        action: 'USER_REGISTRATION',
        details: 'Contractee account created successfully - pending phone verification',
        metadata: {
          'user_type': userType,
          'email': email,
          'full_name': data?['full_name'],
          'registration_method': 'email_password',
        },
      );

      if (!context.mounted) return;
      ConTrustSnackBar.success(context, 'Account created! Please verify your phone number');
      

    } on AuthException catch (e) {
      await _auditService.logAuditEvent(
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractee registration failed due to authentication error',
        metadata: {
          'user_type': userType,
          'email': email,
          'error_type': 'AuthException',
          'error_message': e.message,
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee sign-up failed - AuthException: ${e.message}',
        module: 'Contractee Sign-up',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Sign Up Contractee',
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Error creating account: ${e.message}');
      return;
    } catch (e) {
      await _auditService.logAuditEvent(
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractee registration failed due to unexpected error',
        metadata: {
          'user_type': userType,
          'email': email,
          'error_type': 'UnexpectedError',
          'error_message': e.toString(),
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee sign-up failed - Unexpected error: $e',
        module: 'Contractee Sign-up',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign Up Contractee',
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Unexpected error: $e');
    }
  }
}

class SignInGoogleContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signInGoogle(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.contrust://login-callback/',
      );
      
      // OAuth callback will be handled by AuthRedirectPage
      // No need for onAuthStateChange listener here
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in failed for contractee: $e',
        module: 'Contractee Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Google Sign In Contractee',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ConTrustSnackBar.error(context, 'Google sign-in failed: $e');
    }
  }

  Future<void> handleSignIn(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;

      final existingContractee = await supabase
          .from('Contractee')
          .select()
          .eq('contractee_id', user.id)
          .maybeSingle();

      if (existingContractee == null) {
        await setupContractee(context, user);
      } else {
        final userType = user.userMetadata != null ? user.userMetadata!['user_type'] : null;
        if (userType == null || userType.toLowerCase() != 'contractee') {
          await _auditService.logAuditEvent(
            userId: user.id,
            action: 'USER_LOGIN_FAILED',
            details: 'Google login attempt with wrong user type',
            metadata: {
              'user_type': userType,
              'expected_type': 'contractee',
              'email': user.email,
              'login_method': 'google_oauth',
              'failure_reason': 'wrong_user_type',
            },
          );

          ConTrustSnackBar.error(
              context, 'This Google account is not registered as a contractee');
          await supabase.auth.signOut();
          return;
        }

        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN',
          details: 'Contractee logged in via Google successfully',
          metadata: {
            'user_type': 'contractee',
            'email': user.email,
            'login_method': 'google_oauth',
          },
        );

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/home', (route) => false);
        }
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in handling failed for contractee: $e',
        module: 'Contractee Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Handle Google Sign In Contractee',
          'users_id': user.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Sign-in failed: $e');
      }
    }
  }

  Future<void> setupContractee(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'user_type': 'contractee',
            'full_name': user.userMetadata?['full_name'] ?? 'User',
            'email': user.email,
            'profile_photo': user.userMetadata?['avatar_url'],
          },
        ),
      );

      await supabase.from('Users').upsert({
        'users_id': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'] ?? 'User',
        'role': 'contractee',
        'status': 'active',
        'last_login': DateTime.now().toIso8601String(),
        'profile_image_url': user.userMetadata?['avatar_url'],
        'phone_number': '',
        'verified': false,
      }, onConflict: 'users_id');

      await supabase.from('Contractee').insert({
        'contractee_id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'profile_photo': user.userMetadata?['avatar_url'],
        'created_at': DateTime.now().toIso8601String(),
      });

      await _auditService.logAuditEvent(
        userId: user.id,
        action: 'USER_REGISTRATION',
        details: 'Contractee account created via Google OAuth',
        metadata: {
          'user_type': 'contractee',
          'email': user.email,
          'full_name': user.userMetadata?['full_name'],
          'registration_method': 'google_oauth',
        },
      );

      ConTrustSnackBar.success(
          context, 'Welcome! Your contractee account has been created.');

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));

    } catch (e) {
      await _auditService.logAuditEvent(
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractee Google registration failed',
        metadata: {
          'user_type': 'contractee',
          'email': user.email,
          'error_message': e.toString(),
          'registration_method': 'google_oauth',
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee setup failed during Google sign-in: $e',
        module: 'Contractee Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Setup Contractee Google',
          'users_id': user.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ConTrustSnackBar.error(context, 'Account setup failed: $e');
    }
  }
}
