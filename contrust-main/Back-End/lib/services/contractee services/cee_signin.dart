// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignInContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signInContractee(BuildContext modalContext, String email,
      String password, bool Function() validateFields) async {
    if (!validateFields()) {
      return;
    }

    dynamic signInResponse;
    try {
      signInResponse = await UserService().signIn(
        email: email,
        password: password,
      );

      if (signInResponse.user == null) {
        await _auditService.logAuditEvent(
          action: 'USER_LOGIN_FAILED',
          details: 'Contractee login failed - invalid credentials',
          metadata: {
            'user_type': 'contractee',
            'email': email,
            'failure_reason': 'invalid_credentials',
          },
        );

        ConTrustSnackBar.error(modalContext, 'Invalid email or password');
        return;
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];

      if (userType?.toLowerCase() != 'contractee') {
        await _auditService.logAuditEvent(
          userId: signInResponse.user!.id,
          action: 'USER_LOGIN_FAILED',
          details: 'Login attempt with wrong user type',
          metadata: {
            'user_type': userType,
            'expected_type': 'contractee',
            'email': email,
            'failure_reason': 'wrong_user_type',
          },
        );

        ConTrustSnackBar.error(modalContext, 'Not a contractee...');
        return;
      }

      final supabase = Supabase.instance.client;
      await supabase.from('Users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('users_id', signInResponse.user!.id);

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

      Navigator.pushReplacement(
        modalContext,
        MaterialPageRoute(builder: (context) => const HomePage(contracteeId: '')),
      );

        ConTrustSnackBar.success(modalContext, 'Successfully logged in');

    } catch (e) {
      await _auditService.logAuditEvent(
        userId: signInResponse.user?.id, 
        action: 'USER_LOGIN_FAILED',
        details: 'Contractee login failed due to error',
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
          'users_id': signInResponse.user?.id,  
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      ConTrustSnackBar.error(modalContext, 'Error logging in: $e');
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
        final userType = user.userMetadata?['user_type'];
        if (userType?.toLowerCase() != 'contractee') {
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

          ConTrustSnackBar.error(context, 'This Google account is not registered as a contractee');
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

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
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
      ConTrustSnackBar.error(context, 'Sign-in failed: $e');
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

      ConTrustSnackBar.success(context, 'Welcome! Your contractee account has been created.');

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );

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
