// ignore_for_file: use_build_context_synchronously

import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class SuperAdminProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllProjects() async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('''
            *,
            contractor:Contractor(firm_name, contact_number),
            contractee:Contractee(full_name)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch all projects: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch All Projects',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects: $e');
    }
  }

  Future<Map<String, int>> getProjectStatistics() async {
    try {
      final allProjects = await _supabase
          .from('Projects')
          .select('status')
          .limit(10000);

      final totalProjects = allProjects.length;
      final statusCounts = <String, int>{
        'active': 0,
        'completed': 0,
        'pending': 0,
        'cancelled': 0,
      };

      for (final project in allProjects) {
        final status = project['status'] as String?;
        if (status != null && statusCounts.containsKey(status)) {
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      }

      return {
        'total': totalProjects,
        'active': statusCounts['active'] ?? 0,
        'completed': statusCounts['completed'] ?? 0,
        'pending': statusCounts['pending'] ?? 0,
        'cancelled': statusCounts['cancelled'] ?? 0,
      };
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to get project statistics: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Project Statistics',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to get project statistics: $e');
    }
  }

  Future<void> updateProjectStatus(String projectId, String status) async {
    try {
      await _supabase
          .from('Projects')
          .update({'status': status})
          .eq('project_id', projectId);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to update project status: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Update Project Status',
          'project_id': projectId,
          'new_status': status,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to update project status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsByStatus(String status) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('''
            *,
            contractor:Contractor(firm_name, contact_number),
            contractee:Contractee(full_name)
          ''')
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch projects by status: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Projects By Status',
          'status': status,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects by status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsByContractor(String contractorId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('''
            *,
            contractor:Contractor(firm_name, contact_number),
            contractee:Contractee(full_name)
          ''')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch projects by contractor: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Projects By Contractor',
          'contractor_id': contractorId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects by contractor: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsByContractee(String contracteeId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('''
            *,
            contractor:Contractor(firm_name, contact_number),
            contractee:Contractee(full_name)
          ''')
          .eq('contractee_id', contracteeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch projects by contractee: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Projects By Contractee',
          'contractee_id': contracteeId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects by contractee: $e');
    }
  }
}
