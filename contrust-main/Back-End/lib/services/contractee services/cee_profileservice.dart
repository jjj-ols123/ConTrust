// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_datetime_helper.dart';
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

      final allProjects = [...completedProjects, ...ongoingProjects];
      final contractorIds = allProjects
          .map((p) => p['contractor_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();
      
      final Map<String, String> contractorNamesMap = {};
      if (contractorIds.isNotEmpty) {
        try {
          final contractorData = await Supabase.instance.client
              .from('Contractor')
              .select('contractor_id, firm_name')
              .inFilter('contractor_id', contractorIds);
          
          for (var contractor in contractorData) {
            contractorNamesMap[contractor['contractor_id']] = 
                contractor['firm_name'] ?? 'Unknown Contractor';
          }
        } catch (e) {
          // Error fetching contractor data - will use defaults
        }
      }
      
      List<Map<String, dynamic>> projectHistoryWithNames = [];
      for (var project in completedProjects) {
        final contractorId = project['contractor_id'] as String?;
        if (contractorId != null && contractorNamesMap.containsKey(contractorId)) {
          project['contractor_name'] = contractorNamesMap[contractorId]!;
        } else if (contractorId != null) {
          project['contractor_name'] = 'Unknown Contractor';
        } else {
          project['contractor_name'] = 'No Contractor Assigned';
        }
        projectHistoryWithNames.add(project);
      }

      List<Map<String, dynamic>> ongoingProjectsWithNames = [];
      for (var project in ongoingProjects) {
        final contractorId = project['contractor_id'] as String?;
        if (contractorId != null && contractorNamesMap.containsKey(contractorId)) {
          project['contractor_name'] = contractorNamesMap[contractorId]!;
        } else if (contractorId != null) {
          project['contractor_name'] = 'Unknown Contractor';
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

      // Check file size (max 10MB)
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (fileBytes.length > maxSizeBytes) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context, 
            'Image size exceeds 10MB limit. Please choose a smaller image.'
          );
        }
        return null;
      }

      // Check file extension or image format (only PNG/JPG)
      final extension = file.extension?.toLowerCase() ?? '';
      
      // If no extension, check image format from bytes (PNG starts with 89 50 4E 47, JPEG starts with FF D8 FF)
      bool isValidImage = false;
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        isValidImage = true;
      } else if (fileBytes.length >= 4) {
        // Check PNG signature: 89 50 4E 47 (0x89 0x50 0x4E 0x47)
        if (fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && fileBytes[2] == 0x4E && fileBytes[3] == 0x47) {
          isValidImage = true;
        }
        // Check JPEG signature: FF D8 FF
        else if (fileBytes.length >= 3 && fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF) {
          isValidImage = true;
        }
      }
      
      if (!isValidImage) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context, 
            'Only PNG and JPG images are allowed.'
          );
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

      final contractorIds = ratingsData
          .map((r) => r['contractor_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();
      
      final Map<String, Map<String, dynamic>> contractorInfoMap = {};
      if (contractorIds.isNotEmpty) {
        try {
          final contractorData = await Supabase.instance.client
              .from('Contractor')
              .select('contractor_id, firm_name, profile_photo')
              .inFilter('contractor_id', contractorIds);
          
          for (var contractor in contractorData) {
            contractorInfoMap[contractor['contractor_id']] = {
              'firm_name': contractor['firm_name'] ?? 'Unknown Contractor',
              'profile_photo': contractor['profile_photo'],
            };
          }
        } catch (e) {
          //
        }
      }
      
      List<Map<String, dynamic>> reviewsWithNames = [];
      for (var rating in ratingsData) {
        final contractorId = rating['contractor_id'] as String?;
        if (contractorId != null && contractorInfoMap.containsKey(contractorId)) {
          final contractorInfo = contractorInfoMap[contractorId]!;
          rating['contractor_name'] = contractorInfo['firm_name'];
          rating['contractor_photo'] = contractorInfo['profile_photo'];
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
            'payment_date': payment['date'] ?? DateTimeHelper.getLocalTimeISOString(),
            'reference': payment['reference'] ?? payment['payment_id'] ?? '',
            'receipt_path': payment['receipt_path'],
            'project_id': project['project_id'],
            'payment_id': payment['payment_id'] ?? payment['reference'] ?? '',
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