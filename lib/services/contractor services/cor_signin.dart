// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignInContractor {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signInContractor(
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

      if (signInResponse.user?.id == null) {
        await _auditService.logAuditEvent(
          action: 'USER_LOGIN_FAILED',
          details: 'Contractor login failed - no user ID returned',
          metadata: {
            'user_type': 'contractor',
            'email': email,
            'failure_reason': 'no_user_id',
          },
        );
        ConTrustSnackBar.error(context, 'Authentication failed');
        return;
      }

      final user = signInResponse.user!;
      final userType = user.userMetadata?['user_type'];

      if (userType?.toLowerCase() != 'contractor') {
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
        ConTrustSnackBar.error(context, 'Not a contractor account');
        return;
      }

      final supabase = Supabase.instance.client;
      
      final userRow = await supabase
          .from('Users')
          .select('verified')
          .eq('users_id', user.id)
          .maybeSingle();

      bool verified = false;
      if (userRow != null && userRow['verified'] != null) {
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
        ConTrustSnackBar.show(
          context,
          'Please wait for your account to be verified to login',
          type: SnackBarType.info,
        );
        return;
      }

      try {
        await supabase.from('Users').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('users_id', user.id);
      } catch (e) {

        await _errorService.logError(
          errorMessage: 'Failed to update last_login for contractor: $e',
          module: 'Contractor Sign-in',
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
        details: 'Contractor logged in successfully',
        metadata: {
          'user_type': 'contractor',
          'email': email,
          'login_method': 'email_password',
        },
      );

      ConTrustSnackBar.success(context, 'Successfully logged in');
      Navigator.pushNamedAndRemoveUntil(
          context, '/dashboard', (route) => false);
          
    } catch (e) {
      await _auditService.logAuditEvent(
        userId: signInResponse?.user?.id,
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
          'users_id': signInResponse?.user?.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (e.toString().contains('null check')) {
        ConTrustSnackBar.error(context, 'Authentication error. Please try again.');
      } else {
        ConTrustSnackBar.error(context, 'Error logging in: ${e.toString()}');
      }
    }
  }
}

class SignInGoogleContractor {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signInGoogle(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );

      supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final user = data.session?.user;

        if (event == AuthChangeEvent.signedIn && user != null) {
          handleSignIn(context, user);
        } else if (event == AuthChangeEvent.signedOut) {
          ConTrustSnackBar.warning(context, 'Signed in cancelled');
        }
      });
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in failed for contractor: $e',
        module: 'Contractor Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Google Sign In Contractor',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ConTrustSnackBar.error(context, 'Google sign-in failed: $e');
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
        final userType = user.userMetadata?['user_type'];
        if (userType?.toLowerCase() != 'contractor') {
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

        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in handling failed for contractor: $e',
        module: 'Contractor Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Handle Google Sign In Contractor',
          'users_id': user.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ConTrustSnackBar.error(context, 'Sign-in failed: $e');
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

      await supabase.from('Users').upsert({
        'users_id': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
        'role': 'contractor',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'last_login': DateTime.now().toIso8601String(),
        'profile_image_url': user.userMetadata?['avatar_url'],
        'phone_number': '',
        'verified': false,
      }, onConflict: 'users_id');

      await supabase.from('Contractor').insert({
        'contractor_id': user.id,
        'firm_name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
        'profile_photo': user.userMetadata?['avatar_url'],
        'contact_number': '',
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
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

      Navigator.pushNamedAndRemoveUntil(
          context, '/dashboard', (route) => false);
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
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ConTrustSnackBar.error(context, 'Account setup failed: $e');
    }
  }
}