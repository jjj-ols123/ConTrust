// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class CeeProfileService { 

  Future<Map<String, dynamic>> loadContracteeData(String contracteeId) async {
    try {
      final contracteeResponse = await Supabase.instance.client
          .from('Contractee')
          .select()
          .eq('contractee_id', contracteeId)
          .single();

      String email = '';
      try {
        final userData = await Supabase.instance.client
            .from('Users')
            .select('email')
            .eq('users_id', contracteeId)
            .maybeSingle();
        if (userData != null) {
          email = userData['email'] ?? '';
        }
      } catch (e) {
        //
      }

      final contracteeData = {
        'full_name': contracteeResponse['full_name'] ?? "",
        'phone_number': contracteeResponse['phone_number'] ?? "",
        'address': contracteeResponse['address'] ?? "",
        'email': email,
        'profile_photo': contracteeResponse['profile_photo'] ?? 'defaultpic.png',
      };

      final completedProjects = await Supabase.instance.client
          .from('Projects')
          .select('project_id, title, estimated_completion, contractor_id')
          .eq('contractee_id', contracteeId)
          .eq('status', 'completed')
          .order('estimated_completion', ascending: false);

      final ongoingProjects = await Supabase.instance.client
          .from('Projects')
          .select('project_id, title, start_date, contractor_id')
          .eq('contractee_id', contracteeId)
          .inFilter('status', ['ongoing', 'pending', 'awaiting_contract', 'awaiting_agreement'])
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
          ConTrustSnackBar.success(context, 'Updated successfully!');
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

  Future<List<Map<String, dynamic>>> loadReviews(String contracteeId) async {
    try {
      final ratingsData = await Supabase.instance.client
          .from('ContractorRatings')
          .select('rating, review, created_at, contractor_id')
          .eq('contractee_id', contracteeId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> reviewsWithNames = [];
      for (var rating in ratingsData) {
        final contractorData = await Supabase.instance.client
            .from('Contractor')
            .select('firm_name, profile_photo')
            .eq('contractor_id', rating['contractor_id'])
            .maybeSingle();

        if (contractorData != null) {
          rating['contractor_name'] = contractorData['firm_name'];
          rating['contractor_photo'] = contractorData['profile_photo'];
        } else {
          rating['contractor_name'] = 'Unknown Contractor';
          rating['contractor_photo'] = null;
        }

        reviewsWithNames.add(rating);
      }

      return reviewsWithNames;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadTransactions(String contracteeId) async {
    try {
      final projectsResponse = await Supabase.instance.client
          .from('Projects')
          .select('''
            project_id,
            title,
            projectdata,
            contractor_id,
            Contractor!inner(firm_name)
          ''')
          .eq('contractee_id', contracteeId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allTransactions = [];

      for (var project in projectsResponse) {
        final projectdata =
            project['projectdata'] as Map<String, dynamic>? ?? {};
        final payments = projectdata['payments'] as List<dynamic>? ?? [];

        for (var payment in payments) {
          allTransactions.add({
            'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
            'payment_type': getPaymentType(payment['contract_type'] ?? '',
                payment['payment_structure'] ?? ''),
            'project_title': project['title'] ?? 'Unknown Project',
            'contractor_name':
                project['Contractor']?['firm_name'] ?? 'Unknown Contractor',
            'payment_date': payment['date'] ?? DateTime.now().toIso8601String(),
            'reference': payment['reference'] ?? payment['payment_id'] ?? '',
          });
        }
      }

      allTransactions.sort((a, b) {
        final dateA = DateTime.parse(a['payment_date']);
        final dateB = DateTime.parse(b['payment_date']);
        return dateB.compareTo(dateA);
      });

      return allTransactions;
    } catch (e) {
      return [];
    }
  }

  List<Map<String, dynamic>> filterProjects(
    List<Map<String, dynamic>> allProjects,
    String searchQuery,
    String statusFilter,
  ) {
    return allProjects.where((project) {
      final matchesSearch = searchQuery.isEmpty ||
          (project['title']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (project['description']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesStatus = statusFilter == 'All' ||
          (statusFilter == 'Active' && ['active', 'awaiting_contract', 'awaiting_agreement'].contains(project['status']?.toLowerCase())) ||
          (statusFilter == 'Pending' && project['status']?.toLowerCase() == 'pending') ||
          (statusFilter == 'Completed' && project['status']?.toLowerCase() == 'completed') ||
          (statusFilter == 'Cancelled' && project['status']?.toLowerCase() == 'cancelled');

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> filterTransactions(
    List<Map<String, dynamic>> transactions,
    String searchQuery,
    String selectedPaymentType,
  ) {
    final query = searchQuery.toLowerCase();
    return transactions.where((transaction) {
      final matchesSearch = (transaction['project_title']
                  ?.toString()
                  .toLowerCase()
                  .contains(query) ??
              false) ||
          (transaction['amount']?.toString().toLowerCase().contains(query) ??
              false);

      final matchesType = selectedPaymentType == 'All' ||
          (transaction['payment_type']?.toString() ?? '') ==
              selectedPaymentType;

      return matchesSearch && matchesType;
    }).toList();
  }

  String getPaymentType(String contractType, String paymentStructure) {
    if (contractType == 'lump_sum') {
      return 'Full Payment';
    } else if (contractType == 'percentage_based') {
      return 'Milestone Payment';
    } else if (contractType == 'custom') {
      if (paymentStructure.toLowerCase().contains('down')) {
        return 'Down Payment';
      } else if (paymentStructure.toLowerCase().contains('final')) {
        return 'Final Payment';
      } else if (paymentStructure.toLowerCase().contains('milestone')) {
        return 'Milestone Payment';
      }
      return 'Contract Payment';
    }
    return 'Payment';
  }
}