// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_datetime_helper.dart';
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

      if (signInResponse == null ||
          signInResponse.user == null ||
          signInResponse.user!.id == null) {
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
      final userType = user.userMetadata != null
          ? user.userMetadata!['user_type']
          : null;

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
        await supabase
            .from('Users')
            .update({'last_login': DateTimeHelper.getLocalTimeISOString()})
            .eq('users_id', user.id);
      } catch (e) {
        await _errorService.logError(
          errorMessage: 'Failed to update last_login for contractee: $e',
          module: 'Contractee Sign-in',
          severity: 'Low',
          extraInfo: {
            'operation': 'Update Last Login',
            'users_id': user.id,
            'timestamp': DateTimeHelper.getLocalTimeISOString(),
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
        userId: signInResponse != null && signInResponse.user != null
            ? signInResponse.user!.id
            : null,
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
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );

      if (context.mounted) {
        String message = 'Login failed. Please try again.';
        final errorText = e.toString().toLowerCase();
        if (e is AuthException) {
          final m = e.message.toLowerCase();
          if (m.contains('invalid login') ||
              m.contains('invalid') ||
              m.contains('credentials')) {
            message = 'Invalid email or password.';
          } else if (m.contains('email not confirmed') ||
              m.contains('not confirmed') ||
              m.contains('verify')) {
            message =
                'Your account is not yet verified. Please try again later.';
          } else if (m.contains('rate') && m.contains('limit')) {
            message = 'Too many attempts. Please try again later.';
          } else {
            message = 'Authentication error. Please try again.';
          }
        } else if (errorText.contains('network') ||
            errorText.contains('socket')) {
          message = 'Network error. Please check your connection.';
        }
        ConTrustSnackBar.error(context, message);
      }
      return false;
    }
  }
}
