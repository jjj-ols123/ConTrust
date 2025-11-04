// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignInContractor {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<bool> signInContractor(
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
          details: 'Contractor login failed - no user ID returned',
          metadata: {
            'user_type': 'contractor',
            'email': email,
            'failure_reason': 'no_user_id',
          },
        );
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Authentication failed');
        }
        return false;
      }

      final user = signInResponse.user!;
      final userType = user.userMetadata != null ? user.userMetadata!['user_type'] : null;

      if (userType == null || userType.toLowerCase() != 'contractor') {
        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN_FAILED',
          details: 'Login attempt with wrong user type',
          metadata: {
            'user_type': userType,
            'expected_type': 'contractor',
            'email': email,
            'failure_reason': 'wrong_user_type',
          },
        );
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Not a contractor account');
        }
        return false;
      }

      final supabase = Supabase.instance.client;
      
      final userRow = await supabase
          .from('Users')
          .select('verified')
          .eq('users_id', user.id)
          .maybeSingle();

      bool verified = false;
      if (userRow != null && userRow['verified'] != null && userRow['verified'] is bool) {
        verified = userRow['verified'] as bool;
      }

      if (!verified) {
        await supabase.auth.signOut();
        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN_FAILED',
          details: 'Contractor login blocked - account not verified',
          metadata: {
            'user_type': 'contractor',
            'email': email,
            'failure_reason': 'account_not_verified',
          },
        );
        if (context.mounted) {
          ConTrustSnackBar.show(
            context,
            'Please wait for your account to be verified to login',
            type: SnackBarType.info,
          );
        }
        return false;
      }

      try {
        await supabase.from('Users').update({
          'last_login': DateTimeHelper.getLocalTimeISOString(),
        }).eq('users_id', user.id);
      } catch (e) {
        
        await _errorService.logError(
          errorMessage: 'Failed to update last_login for contractor: $e',
          module: 'Contractor Sign-in',
          severity: 'Low',
          extraInfo: {
            'operation': 'Update Last Login',
            'users_id': user.id,
            'timestamp': DateTimeHelper.getLocalTimeISOString(),
          },
        );
      }

      await _auditService.logAuditEvent(
        userId: user.id,
        action: 'USER_LOGIN',
        details: 'Contractor logged in successfully',
        metadata: {
          'user_type': 'contractor',
          'email': email,
          'login_method': 'email_password',
        },
      );

      return true;
            
  } catch (e) {
      await _auditService.logAuditEvent(
        userId: signInResponse != null && signInResponse.user != null ? signInResponse.user!.id : null,
        action: 'USER_LOGIN_FAILED',
        details: 'Contractor login failed due to error: $e',
        metadata: {
          'user_type': 'contractor',
          'email': email,
          'error_message': e.toString(),
          'failure_reason': 'system_error',
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractor sign-in failed: $e',
        module: 'Contractor Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign In Contractor',
          'email': email,
          'users_id': signInResponse != null && signInResponse.user != null ? signInResponse.user!.id : null,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      
      if (context.mounted) {
        String message = 'Login failed. Please try again.';
        if (e is AuthException) {
          final m = e.message.toLowerCase();
          if (m.contains('invalid login') || m.contains('invalid') || m.contains('credentials')) {
            message = 'Invalid email or password.';
          } else if (m.contains('email not confirmed') || m.contains('not confirmed') || m.contains('verify')) {
            message = 'Your account is not yet verified. Please try again later.';
          } else if (m.contains('rate') && m.contains('limit')) {
            message = 'Too many attempts. Please try again later.';
          } else {
            message = 'Authentication error. Please try again.';
          }
        } else if (e.toString().toLowerCase().contains('null check')) {
          message = 'Authentication error. Please try again.';
        } else if (e.toString().toLowerCase().contains('network') || e.toString().toLowerCase().contains('socket')) {
          message = 'Network error. Please check your connection.';
        }
        ConTrustSnackBar.error(context, message);
      }
      
      return false;
    }
  }
}

class SignInGoogleContractor {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<void> signInGoogle(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Use the current origin (subdomain) dynamically for redirect URL
      // This ensures the redirect goes to the correct subdomain instead of the main domain
      String redirectUrl;
      
      if (kIsWeb) {
        // For web: use current origin (subdomain) + callback path
        final origin = Uri.base.origin; // This will be contractor.contrust-sjdm.com or contractee.contrust-sjdm.com
        redirectUrl = '$origin/auth/callback?next=${Uri.encodeComponent('/dashboard')}';
      } else {
        // For mobile: use deep link
        redirectUrl = 'io.supabase.contrust://login-callback/dashboard';
      }
      
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in failed for contractor: $e',
        module: 'Contractor Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Google Sign In Contractor',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Google sign-in failed: $e');
      }
      rethrow;
    }
  }

  Future<void> handleSignIn(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;

      final existingContractor = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', user.id)
          .maybeSingle();

      if (existingContractor == null) {
        await setupContractor(context, user);
      } else {
        final userType = user.userMetadata != null ? user.userMetadata!['user_type'] : null;
        if (userType == null || userType.toLowerCase() != 'contractor') {
          await _auditService.logAuditEvent(
            userId: user.id,
            action: 'USER_LOGIN_FAILED',
            details: 'Google login attempt with wrong user type',
            metadata: {
              'user_type': userType,
              'expected_type': 'contractor',
              'email': user.email,
              'login_method': 'google_oauth',
              'failure_reason': 'wrong_user_type',
            },
          );

          ConTrustSnackBar.error(
              context, 'This Google account is not registered as a contractor');
          await supabase.auth.signOut();
          return;
        }

        final userRow = await supabase
            .from('Users')
            .select('verified')
            .eq('users_id', user.id)
            .maybeSingle();

        bool verified = false;
        if (userRow != null && userRow['verified'] != null && userRow['verified'] is bool) {
          verified = userRow['verified'] as bool;
        }

        if (!verified) {
          await supabase.auth.signOut();
          await _auditService.logAuditEvent(
            userId: user.id,
            action: 'USER_LOGIN_FAILED',
            details: 'Contractor Google login blocked - account not verified',
            metadata: {
              'user_type': 'contractor',
              'email': user.email,
              'login_method': 'google_oauth',
              'failure_reason': 'account_not_verified',
            },
          );
          ConTrustSnackBar.show(
            context,
            'Please wait for your account to be verified to login',
            type: SnackBarType.info,
          );
          return;
        }

        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN',
          details: 'Contractor logged in via Google successfully',
          metadata: {
            'user_type': 'contractor',
            'email': user.email,
            'login_method': 'google_oauth',
          },
        );
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in handling failed for contractor: $e',
        module: 'Contractor Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Handle Google Sign In Contractor',
          'users_id': user.id,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Sign-in failed: $e');
      }
    }
  }

  Future<void> setupContractor(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'user_type': 'contractor',
            'firm_name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
            'email': user.email,
            'profile_photo': user.userMetadata?['avatar_url'],
          },
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      
      bool insertSuccess = false;
      for (int attempt = 0; attempt < 5 && !insertSuccess; attempt++) {
        try {
          await supabase.from('Users').upsert({
            'users_id': user.id,
            'email': user.email,
            'name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
            'role': 'contractor',
            'status': 'active',
            'created_at': DateTimeHelper.getLocalTimeISOString(),
            'last_login': DateTimeHelper.getLocalTimeISOString(),
            'profile_image_url': user.userMetadata?['avatar_url'],
            'phone_number': '',
            'verified': false,
          }, onConflict: 'users_id');
          insertSuccess = true;
        } catch (e) {
          if (attempt == 4) {
            throw Exception('Failed to create user record: $e');
          }
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }

      await supabase.from('Contractor').insert({
        'contractor_id': user.id,
        'firm_name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
        'profile_photo': user.userMetadata?['avatar_url'],
        'contact_number': '',
        'rating': 0.0,
        'created_at': DateTimeHelper.getLocalTimeISOString(),
      });

      await _auditService.logAuditEvent(
        userId: user.id,
        action: 'USER_REGISTRATION',
        details: 'Contractor account created via Google OAuth',
        metadata: {
          'user_type': 'contractor',
          'email': user.email,
          'firm_name': user.userMetadata?['full_name'],
          'registration_method': 'google_oauth',
        },
      );

      ConTrustSnackBar.success(
          context, 'Welcome! Your contractor account has been created.');

    } catch (e) {
      await _auditService.logAuditEvent(
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractor Google registration failed',
        metadata: {
          'user_type': 'contractor',
          'email': user.email,
          'error_message': e.toString(),
          'registration_method': 'google_oauth',
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractor setup failed during Google sign-in: $e',
        module: 'Contractor Google Sign-in',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Setup Contractor Google',
          'users_id': user.id,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      ConTrustSnackBar.error(context, 'Account setup failed: $e');
    }
  }
}
