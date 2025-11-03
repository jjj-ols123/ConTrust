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
        errorMessage: 'Failed to fetch all projects: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch All Projects',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects: ');
    }
  }

  Future<Map<String, int>> getProjectStatistics() async {
    try {
      final totalProjects = await _supabase.from('Projects').select('project_id').then((res) => res.length);

      final statusCounts = <String, int>{};
      final statuses = ['active', 'completed', 'pending', 'cancelled'];

      for (final status in statuses) {
        final count = await _supabase
            .from('Projects')
            .select('project_id')
            .eq('status', status)
            .then((res) => res.length);
        statusCounts[status] = count;
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
        errorMessage: 'Failed to get project statistics: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Project Statistics',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to get project statistics: ');
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
        errorMessage: 'Failed to update project status: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Update Project Status',
          'project_id': projectId,
          'new_status': status,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to update project status: ');
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
        errorMessage: 'Failed to fetch projects by status: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Projects By Status',
          'status': status,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects by status: ');
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
        errorMessage: 'Failed to fetch projects by contractor: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Projects By Contractor',
          'contractor_id': contractorId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects by contractor: ');
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
        errorMessage: 'Failed to fetch projects by contractee: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Projects By Contractee',
          'contractee_id': contracteeId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch projects by contractee: ');
    }
  }
}
