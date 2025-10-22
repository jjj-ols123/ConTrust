import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

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
      
      if ((response as List).isNotEmpty) {
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch unverified contractors: $e',
        module: 'Verify Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Get Unverified Contractors',
          'timestamp': DateTime.now().toIso8601String(),
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
          'timestamp': DateTime.now().toIso8601String(),
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
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  Future<void> verifyContractor(String contractorId, bool approve) async {
    try {
      await _supabase
          .from('Contractor')
          .update({'verified': approve})
          .eq('contractor_id', contractorId);

      await _supabase
          .from('Users')
          .update({'verified': approve})
          .eq('users_id', contractorId);

      if (!approve) {
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
          'timestamp': DateTime.now().toIso8601String(),
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
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }
}