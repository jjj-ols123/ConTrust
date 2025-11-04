// ignore_for_file: use_build_context_synchronously, unnecessary_type_check

import 'dart:typed_data';

import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/services/superadmin%20services/auditlogs_service.dart';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorProfileService { 
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  Future<Map<String, dynamic>> loadContractorData(String contractorId) async {
    try {
      final contractorData = await UserService().fetchUserData(
        contractorId,
        isContractor: true,
      );

      final completedProjects = await Supabase.instance.client
          .from('Projects')
          .select('project_id')
          .eq('contractor_id', contractorId)
          .eq('status', 'completed');

      final ratingsData = await Supabase.instance.client
          .from('ContractorRatings')
          .select('rating, review, created_at, contractee_id')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);
          
      final contracteeIds = ratingsData
          .map((r) => r['contractee_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();
      
      final Map<String, String> contracteeNamesMap = {};
      if (contracteeIds.isNotEmpty) {
        try {
          final contracteeData = await Supabase.instance.client
              .from('Contractee')
              .select('contractee_id, full_name')
              .inFilter('contractee_id', contracteeIds);
          
          for (var contractee in contracteeData) {
            contracteeNamesMap[contractee['contractee_id']] = 
                contractee['full_name'] ?? 'Anonymous Client';
          }
        } catch (e) {
          // Error fetching contractee data - will use defaults
        }
      }
      
      List<Map<String, dynamic>> reviewsWithNames = [];
      for (var rating in ratingsData) {
        final contracteeId = rating['contractee_id'] as String?;
        rating['client_name'] = contracteeId != null && contracteeNamesMap.containsKey(contracteeId)
            ? contracteeNamesMap[contracteeId]!
            : 'Anonymous Client';
        reviewsWithNames.add(rating);
      }

      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      int totalReviews = 0;
      
      for (var ratingData in reviewsWithNames) {
        final ratingValue = (ratingData['rating'] as num?)?.round() ?? 0;
        if (ratingValue >= 1 && ratingValue <= 5) {
          ratingDistribution[ratingValue] = (ratingDistribution[ratingValue] ?? 0) + 1;
          totalReviews++;
        }
      }

      return {
        'contractorData': contractorData,
        'completedProjectsCount': completedProjects.length,
        'allRatings': reviewsWithNames,
        'ratingDistribution': ratingDistribution,
        'totalReviews': totalReviews,
      };
    } catch (e) {
      throw Exception('Error loading contractor data: $e ');
    }
  }

  Future<void> saveField(String contractorId, String fieldType, String newValue) async {
    try {
      String columnName;
      switch (fieldType) {
        case 'bio':
          columnName = 'bio';
          break;
        case 'contact':
          columnName = 'contact_number';
          break;
        case 'specialization':
          columnName = 'specialization';
          break;
        case 'firmName':
          columnName = 'firm_name';
          break;
        case 'address':
          columnName = 'address';
          break;
        default:
          throw Exception('Invalid field type');
      }

      await Supabase.instance.client
          .from('Contractor')
          .update({columnName: newValue})
          .eq('contractor_id', contractorId);
    } catch (e) {
      throw Exception('Error saving field: ');
    }
  }

  Future<void> handleSaveField({
    required String contractorId,
    required String fieldType,
    required String newValue,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      await saveField(contractorId, fieldType, newValue);
      
      if (context.mounted) {
        ConTrustSnackBar.success(
          context,
          '${fieldType.toUpperCase()} updated successfully!',
        );
      }

      await _auditService.logAuditEvent(
        userId: Supabase.instance.client.auth.currentUser?.id,
        action: 'Profile_Field_Updated',
        details: '$fieldType updated',
        metadata: {
          'contractor_id': contractorId,
          'field': fieldType,
        },
      );

      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error updating ${fieldType.toLowerCase()}',
        );
      }
      await _errorService.logError(
        userId: Supabase.instance.client.auth.currentUser?.id,
        errorMessage: 'Failed to save field: $e',
        module: 'CorProfileService',
        severity: 'Medium',
        extraInfo: {'contractor_id': contractorId, 'field': fieldType},
      );
    }
  }

  Future<void> handleUploadProjectPhoto({
    required String contractorId,
    required BuildContext context,
    required Function(bool) setUploading,
    required VoidCallback onSuccess,
  }) async {
    setUploading(true);

    try {
      Uint8List? imageBytes = await UserService().pickImage();

      if (imageBytes != null) {
        bool success = await UserService().addPastProjectPhoto(
          contractorId,
          imageBytes,
        );

        if (success) {
          if (context.mounted) {
            ConTrustSnackBar.success(
              context,
              'Project photo uploaded successfully!',
            );
          }

          await _auditService.logAuditEvent(
            userId: Supabase.instance.client.auth.currentUser?.id,
            action: 'Project_Photo_Uploaded',
            details: 'Uploaded project photo',
            metadata: {
              'contractor_id': contractorId,
              'timestamp': DateTimeHelper.getLocalTimeISOString(),
            },
          );

          onSuccess();
      }   }
    } catch (e) {
      if (context.mounted) {
        String message = 'An error occurred while uploading the photo.';
        if (e.toString().contains('Failed to upload')) {
          message = 'Failed to upload project photo. Please try again.';
        }

        ConTrustSnackBar.error(
          context,
          message,
        );
      }

      await _errorService.logError(
        userId: Supabase.instance.client.auth.currentUser?.id,
        errorMessage: 'Project photo upload failed: $e',
        module: 'CorProfileService',
        severity: 'Medium',
        extraInfo: {'contractor_id': contractorId},
      );
    } finally {
      setUploading(false);
    }
  } 

  Future<void> handleUploadProfilePhoto({
    required String contractorId,
    required BuildContext context,
    required Function(bool) setUploading,
    required VoidCallback onSuccess,
  }) async {
    setUploading(true);
    try {
      Uint8List? imageBytes = await UserService().pickImage();
      if (imageBytes == null) return;

      final imageUrl = await UserService().uploadImage(
        imageBytes,
        'profilephotos',
        folderPath: 'contractor',
        fileName: '$contractorId.png',
        upsert: true,
      );

      final updated = await UserService().updateProfilePhoto(
        contractorId,
        imageUrl,
        isContractor: true,
      );

      if (!updated) throw Exception('Failed to update profile record');

      if (context.mounted) ConTrustSnackBar.success(context, 'Profile photo uploaded successfully!');

      await _auditService.logAuditEvent(
        userId: Supabase.instance.client.auth.currentUser?.id,
        action: 'PROFILE_PHOTO_UPDATED',
        details: imageUrl,
        metadata: {
          'contractor_id': contractorId,
          'path': 'profilephotos/contractor/$contractorId.png',
        },
      );

      onSuccess();
    } catch (e) {
      if (context.mounted) ConTrustSnackBar.error(context, 'Failed to upload profile photo: ${e.toString()}');
      await _errorService.logError(
        userId: Supabase.instance.client.auth.currentUser?.id,
        errorMessage: 'Upload profile photo failed: $e',
        module: 'CorProfileService',
        severity: 'Medium',
        extraInfo: {'contractor_id': contractorId},
      );
    } finally {
      setUploading(false);
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

  double getRatingPercentage(int stars, int totalReviews, Map<int, int> ratingDistribution) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[stars] ?? 0) / totalReviews;
  }

  void calculateRatingDistribution(List<Map<String, dynamic>> allRatings, 
      Map<int, int> ratingDistribution, int totalReviews) {
    ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    totalReviews = 0;
    
    for (var ratingData in allRatings) {
      final ratingValue = (ratingData['rating'] as num?)?.round() ?? 0;
      if (ratingValue >= 1 && ratingValue <= 5) {
        ratingDistribution[ratingValue] = (ratingDistribution[ratingValue] ?? 0) + 1;
        totalReviews++;
      }
    }
  }

  Future<List<Map<String, dynamic>>> loadTransactions(String contractorId) async {
    try {
      final projectsResponse = await Supabase.instance.client
          .from('Projects')
          .select('''
            project_id,
            title,
            projectdata,
            contractee_id,
            Contractee!inner(full_name)
          ''')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allTransactions = [];

      for (var project in projectsResponse) {
        final projectdata =
            project['projectdata'] as Map<String, dynamic>? ?? {};
        final payments = projectdata['payments'] as List<dynamic>? ?? [];

        for (var payment in payments) {
          allTransactions.add({
            'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
            'payment_type': _getPaymentType(payment['contract_type'] ?? '',
                payment['payment_structure'] ?? ''),
            'project_title': project['title'] ?? 'Unknown Project',
            'client_name':
                project['Contractee']?['full_name'] ?? 'Unknown Client',
            'payment_date': payment['date'] ?? DateTimeHelper.getLocalTimeISOString(),
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

  String _getPaymentType(String contractType, String paymentStructure) {
    if (paymentStructure.toLowerCase().contains('milestone')) {
      return 'Milestone';
    } else if (contractType.toLowerCase().contains('deposit') ||
        paymentStructure.toLowerCase().contains('deposit')) {
      return 'Deposit';
    } else if (paymentStructure.toLowerCase().contains('final')) {
      return 'Final';
    }
    return 'Payment';
  }

  List<Map<String, dynamic>> filterProjects(
    List<Map<String, dynamic>> allProjects,
    String searchQuery,
    String statusFilter,
  ) {
    return allProjects.where((project) {
      final matchesSearch = searchQuery.isEmpty ||
          (project['title']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (project['description']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (project['contractee']?['full_name']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

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
              false) ||
          (transaction['client_name']
                  ?.toString()
                  .toLowerCase()
                  .contains(query) ??
              false);
      final matchesType = selectedPaymentType == 'All' ||
          (transaction['payment_type']?.toString().toLowerCase() ==
              selectedPaymentType.toLowerCase());
      return matchesSearch && matchesType;
    }).toList();
  }
}
