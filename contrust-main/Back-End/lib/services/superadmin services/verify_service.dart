import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/both services/be_notification_service.dart';

class VerifyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  Future<List<Map<String, dynamic>>> getUnverifiedContractors() async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, contact_number, created_at, verified')
          .or('verified.eq.false,verified.is.null')
          .order('created_at', ascending: false);
      
      final filtered = (response as List).where((contractor) {
        final verified = contractor['verified'];
        return verified == null || verified == false;
      }).toList();
      
      return List<Map<String, dynamic>>.from(filtered);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch unverified contractors: $e',
        module: 'Verify Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Get Unverified Contractors',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVerificationDocs(String contractorId) async {
    try {
      final response = await _supabase
          .from('Verification')
          .select('verify_id, contractor_id, doc_url, uploaded_at, file_type')
          .eq('contractor_id', contractorId)
          .order('uploaded_at', ascending: true);
      
      final docs = List<Map<String, dynamic>>.from(response);
      
      
      for (var doc in docs) {
        final docUrl = doc['doc_url'] as String?;
        
        if (docUrl != null && docUrl.contains('/verification/contractor/')) {
          final fixedUrl = docUrl.replaceAll('/verification/contractor/', '/verification/');
          doc['doc_url'] = fixedUrl;
        }
      }
      
      return docs;
    } catch (e) { 
      await _errorService.logError(
        errorMessage: 'Failed to fetch verification documents: $e',
        module: 'Verify Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Verification Docs',
          'contractor_id': contractorId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      rethrow;
    }
  }

  Future<String> getVerificationDocUrl(String contractorId, String fileName) async {
    try {
      String cleanFileName = fileName;
      if (fileName.startsWith('contractor/')) {
        cleanFileName = fileName.substring('contractor/'.length);
      }
      
      final url = _supabase.storage
          .from('verification')
          .getPublicUrl(cleanFileName);
      return url;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get verification doc URL: $e',
        module: 'Verify Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Verification Doc URL',
          'contractor_id': contractorId,
          'file_name': fileName,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      rethrow;
    }
  }

  Future<void> verifyContractor(String contractorId, bool approve) async {
    try {
      // Get contractor details for notification
      final contractorData = await _supabase
          .from('Contractor')
          .select('firm_name')
          .eq('contractor_id', contractorId)
          .maybeSingle();
      
      final firmName = contractorData?['firm_name'] ?? 'Your account';

      await _supabase
          .from('Contractor')
          .update({'verified': approve})
          .eq('contractor_id', contractorId);

      await _supabase
          .from('Users')
          .update({'verified': approve})
          .eq('users_id', contractorId);

      if (approve) {
        // Send approval notification to contractor
        try {
          await NotificationService().createNotification(
            receiverId: contractorId,
            receiverType: 'contractor',
            senderId: 'system',
            senderType: 'system',
            type: 'Account Verified',
            message: 'Congratulations! Your contractor account "$firmName" has been verified and approved. You can now access all platform features.',
          );

          await NotificationService().sendEmailNotification(
            receiverId: contractorId,
            type: 'Account Verified',
            message:
                'Congratulations! Your contractor account "$firmName" has been verified and approved. You can now access all platform features.',
            subject: 'ConTrust - Account Verified',
            title: 'Your Contractor Account Has Been Verified',
            previewText:
                'Your contractor account "$firmName" has been verified and approved.',
          );
        } catch (e) {
          // Log notification error but don't fail the verification
          await _errorService.logError(
            errorMessage: 'Failed to send approval notification: $e',
            module: 'Verify Service',
            severity: 'Low',
            extraInfo: {
              'operation': 'Send Approval Notification',
              'contractor_id': contractorId,
              'timestamp': DateTimeHelper.getLocalTimeISOString(),
            },
          );
        }
      } else {
        // Send rejection notification to contractor
        try {
          await NotificationService().createNotification(
            receiverId: contractorId,
            receiverType: 'contractor',
            senderId: 'system',
            senderType: 'system',
            type: 'Account Verification Rejected',
            message: 'Your contractor account verification has been rejected. Please review your submitted documents and contact support if you have questions.',
          );

          await NotificationService().sendEmailNotification(
            receiverId: contractorId,
            type: 'Account Verification Rejected',
            message:
                'Your contractor account verification has been rejected. Please review your submitted documents and contact support if you have questions.',
            subject: 'ConTrust - Account Verification Result',
            title: 'Your Account Verification Was Rejected',
            previewText:
                'Your contractor account verification has been rejected. Please review your submitted documents.',
          );
        } catch (e) {
          // Log notification error but don't fail the verification
          await _errorService.logError(
            errorMessage: 'Failed to send rejection notification: $e',
            module: 'Verify Service',
            severity: 'Low',
            extraInfo: {
              'operation': 'Send Rejection Notification',
              'contractor_id': contractorId,
              'timestamp': DateTimeHelper.getLocalTimeISOString(),
            },
          );
        }

        // Delete verification files and records if rejected
        final files = await _supabase.storage
            .from('verification')
            .list(path: contractorId);
        
        if (files.isNotEmpty) {
          final filePaths = files.map((file) => '$contractorId/${file.name}').toList();
          await _supabase.storage
              .from('verification')
              .remove(filePaths);
        }
        
        await _supabase
            .from('Verification')
            .delete()
            .eq('contractor_id', contractorId);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to verify contractor: $e',
        module: 'Verify Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Verify Contractor',
          'contractor_id': contractorId,
          'approve': approve,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getContractorDetails(String contractorId) async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, contact_number, email, address, created_at, verified')
          .eq('contractor_id', contractorId)
          .maybeSingle();
      return response;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contractor details: $e',
        module: 'Verify Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Contractor Details',
          'contractor_id': contractorId,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      rethrow;
    }
  }
}