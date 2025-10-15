// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CeeProfileService { 

  Future<Map<String, dynamic>> loadContracteeData(String contracteeId) async {
    try {
      final contracteeData = await UserService().fetchUserData(
        contracteeId,
        isContractor: false,
      );

      final completedProjects = await Supabase.instance.client
          .from('Projects')
          .select('project_id, project_name, completion_date, contractor_id')
          .eq('contractee_id', contracteeId)
          .eq('status', 'completed')
          .order('completion_date', ascending: false);

      final ongoingProjects = await Supabase.instance.client
          .from('Projects')
          .select('project_id, project_name, start_date, contractor_id')
          .eq('contractee_id', contracteeId)
          .eq('status', 'in_progress')
          .order('start_date', ascending: false);

      List<Map<String, dynamic>> projectHistoryWithNames = [];
      for (var project in completedProjects) {
        if (project['contractor_id'] != null) {
          final contractorData = await Supabase.instance.client
              .from('Contractor')
              .select('firm_name')
              .eq('contractor_id', project['contractor_id'])
              .single();
              
          if (contractorData.isNotEmpty) {
            project['contractor_name'] = contractorData['firm_name'];
          } else {
            project['contractor_name'] = 'Unknown Contractor';
          }
        } else {
          project['contractor_name'] = 'No Contractor Assigned';
        }
        projectHistoryWithNames.add(project);
      }

      List<Map<String, dynamic>> ongoingProjectsWithNames = [];
      for (var project in ongoingProjects) {
        if (project['contractor_id'] != null) {
          final contractorData = await Supabase.instance.client
              .from('Contractor')
              .select('firm_name')
              .eq('contractor_id', project['contractor_id'])
              .single();
              
          if (contractorData.isNotEmpty) {
            project['contractor_name'] = contractorData['firm_name'];
          } else {
            project['contractor_name'] = 'Unknown Contractor';
          }
        } else {
          project['contractor_name'] = 'No Contractor Assigned';
        }
        ongoingProjectsWithNames.add(project);
      }

      return {
        'contracteeData': contracteeData,
        'completedProjectsCount': completedProjects.length,
        'ongoingProjectsCount': ongoingProjects.length,
        'projectHistory': projectHistoryWithNames,
        'ongoingProjects': ongoingProjectsWithNames,
      };
    } catch (e) {
      throw Exception('Error loading contractee data: $e');
    }
  }

  Future<void> saveField(String contracteeId, String fieldType, String newValue) async {
    try {
      String columnName;
      switch (fieldType) {
        case 'bio':
          columnName = 'bio';
          break;
        case 'contact':
          columnName = 'contact_number';
          break;
        case 'firstName':
          columnName = 'first_name';
          break;
        case 'lastName':
          columnName = 'last_name';
          break;
        case 'address':
          columnName = 'address';
          break;
        default:
          throw Exception('Invalid field type');
      }

      await Supabase.instance.client
          .from('Contractee')
          .update({columnName: newValue})
          .eq('contractee_id', contracteeId);
    } catch (e) {
      throw Exception('Error saving field: $e');
    }
  }

  Future<void> handleSaveField({
    required String contracteeId,
    required String fieldType,
    required String newValue,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      await saveField(contracteeId, fieldType, newValue);
      
      if (context.mounted) {
          ConTrustSnackBar.success(context, '${fieldType.replaceAll(RegExp('([A-Z])'), ' \$1').toUpperCase()} updated successfully!');
      }
      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error updating ${fieldType.toLowerCase()}');
      }
    }
  }

  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}