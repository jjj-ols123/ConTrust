import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class SuperAdminUserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('*')
          .eq('role', role)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch users by role: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Users By Role',
          'role': role,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch users by role: ');
    }
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final totalUsers = await _supabase.from('Users').select('users_id').then((res) => res.length);

      final contractors = await _supabase
          .from('Users')
          .select('users_id')
          .eq('role', 'contractor')
          .then((res) => res.length);

      final contractees = await _supabase
          .from('Users')
          .select('users_id')
          .eq('role', 'contractee')
          .then((res) => res.length);

      return {
        'total': totalUsers,
        'contractors': contractors,
        'contractees': contractees,
      };
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to get user statistics: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get User Statistics',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to get user statistics: ');
    }
  }

  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _supabase
          .from('Users')
          .update({'status': status})
          .eq('users_id', userId);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to update user status: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Update User Status',
          'users_id': userId,
          'new_status': status,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to update user status: ');
    }
  }

  Future<void> updateUserVerification(String userId, bool verified) async {
    try {
      await _supabase
          .from('Users')
          .update({'verified': verified})
          .eq('users_id', userId);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to update user verification: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Update User Verification',
          'users_id': userId,
          'verified': verified,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to update user verification: ');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('Users')
          .delete()
          .eq('users_id', userId);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to delete user: ',
        module: 'Super Admin Users',
        severity: 'High',
        extraInfo: {
          'operation': 'Delete User',
          'users_id': userId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to delete user: ');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('*')
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to search users: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Search Users',
          'query': query,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to search users: ');
    }
  }

  Future<List<Map<String, dynamic>>> getUsersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('Users')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch users by status: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Users By Status',
          'status': status,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch users by status: ');
    }
  }
}