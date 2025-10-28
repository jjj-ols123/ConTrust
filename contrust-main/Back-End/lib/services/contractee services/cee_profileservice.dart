// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

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
      throw Exception('Error loading contractee data: ');
    }
  }

  Future<void> saveField(String contracteeId, String fieldType, String newValue) async {
    try {
      String columnName;
      switch (fieldType) {
        case 'fullName':
          columnName = 'full_name';
          break;
        case 'contact':
          columnName = 'phone_number';
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
      throw Exception('Error saving field: ');
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

  Future<String?> uploadProfilePhoto({
    required String contracteeId,
    required BuildContext context,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final Uint8List? fileBytes = file.bytes;
      final String fileName = file.name;

      if (fileBytes == null) {
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Failed to read file');
        }
        return null;
      }

      final String uniqueFileName = '${contracteeId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await Supabase.instance.client.storage
          .from('profilephotos')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: file.extension != null ? 'image/${file.extension}' : 'image/jpeg',
              upsert: true,
            ),
          );

      final String baseImageUrl = Supabase.instance.client.storage
          .from('profilephotos')
          .getPublicUrl(uniqueFileName);
      
      final String imageUrl = '$baseImageUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client
          .from('Contractee')
          .update({'profile_photo': baseImageUrl})
          .eq('contractee_id', contracteeId);

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Profile photo updated successfully!');
      }

      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error uploading photo: ${e.toString()}');
      }
      return null;
    }
  }
}