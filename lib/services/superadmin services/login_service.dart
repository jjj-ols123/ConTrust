import 'package:backend/utils/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class AdminLoginService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  bool isAdminAccount(String email) {
    return email == SupabaseConfig.adminAccount;
  }

  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (!isAdminAccount(email)) {
        await _auditService.logAuditEvent(
          action: 'USER_LOGIN_FAILED',
          details: 'Admin login attempt with non-admin email',
          metadata: {
            'user_type': 'admin',
            'email': email,
            'failure_reason': 'non_admin_email',
          },
        );

        return {
          'success': false,
          'message': 'Access denied. Super admin privileges required.',
        };
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _auditService.logAuditEvent(
          userId: response.user!.id,
          action: 'USER_LOGIN',
          details: 'Super admin logged in successfully',
          metadata: {
            'user_type': 'admin',
            'email': email,
            'login_method': 'email_password',
          },
        );

        return {
          'success': true,
          'message': 'Login successful',
          'user': response.user,
        };
      } else {
        await _auditService.logAuditEvent(
          action: 'USER_LOGIN_FAILED',
          details: 'Admin login failed - invalid credentials',
          metadata: {
            'user_type': 'admin',
            'email': email,
            'failure_reason': 'invalid_credentials',
          },
        );

        return {
          'success': false,
          'message': 'Login failed. Please check your credentials.',
        };
      }
    } catch (e) {
      await _auditService.logAuditEvent(
        action: 'USER_LOGIN_FAILED',
        details: 'Admin login failed due to error',
        metadata: {
          'user_type': 'admin',
          'email': email,
          'error_message': e.toString(),
          'failure_reason': 'system_error',
        },
      );

      await SuperAdminErrorService().logError(
        errorMessage: 'Admin authentication failed: $e',
        module: 'Super Admin Login',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign In With Email Password',
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return {
        'success': false,
        'message': 'Authentication failed. Please try again.',
      };
    }
  }

  Future<void> signOut() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      await _supabase.auth.signOut();

      if (currentUser != null) {
        await _auditService.logAuditEvent(
          userId: currentUser.id,
          action: 'USER_LOGOUT',
          details: 'Super admin logged out successfully',
          metadata: {
            'user_type': 'admin',
            'email': currentUser.email,
          },
        );
      }
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Admin sign out failed: $e',
        module: 'Super Admin Login',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Sign Out',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Sign out failed: $e');
    }
  }
}