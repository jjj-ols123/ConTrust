// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignInContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<bool> signInContractee(
    BuildContext context,
    String email,
    String password,
    bool Function() validateFields,
  ) async {
    if (!validateFields()) {
      return false;
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
        return false;
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
        return false;
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
        userId: signInResponse.user!.id,
        action: 'USER_LOGIN',
        details: 'Contractee logged in successfully',
        metadata: {
          'user_type': 'contractee',
          'email': email,
          'login_method': 'email_password',
        },
      );

      return true;
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
        ConTrustSnackBar.error(context, 'Login failed. Please try again. $e');
      }
      return false;
    }
  }
}

class SignInGoogleContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signInGoogle(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      final redirectTo = kIsWeb ? '${Uri.base.origin}/auth/callback' : null;
      
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
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
          // Navigation handled by auth listener in main.dart
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
        'profile_image_url': user.userMetadata?['avatar_url'] ?? 'assets/defaultpic.png',
        'phone_number': '',
        'verified': true,
      }, onConflict: 'users_id');

      await supabase.from('Contractee').insert({
        'contractee_id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'profile_photo': user.userMetadata?['avatar_url'] ?? 'assets/defaultpic.png',
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
