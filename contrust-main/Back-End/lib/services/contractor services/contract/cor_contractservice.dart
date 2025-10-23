// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/superadmin%20services/auditlogs_service.dart';
import 'package:backend/utils/be_contractsignature.dart';
import 'dart:typed_data';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractorContractService {
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();
  static final SuperAdminAuditService _auditService = SuperAdminAuditService();

  static Future<List<Map<String, dynamic>>> fetchContractTypes() async {
    try {
      return await FetchService().fetchContractTypes();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contract types: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contract Types',
        },
      );
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCreatedContracts(
      String contractorId) async {
    try {
      return await FetchService().fetchCreatedContracts(contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch created contracts: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Created Contracts',
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<void> uploadCustomContract({
    required String projectId,
    required String contractorId,
    required String contracteeId,
    required String title,
    required String contractType,
    required String pdfPath,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('Contracts').insert({
        'project_id': projectId,
        'contractor_id': contractorId,
        'contractee_id': contracteeId,
        'contract_type_id': 'd9d78420-7765-44d5-966c-6f0e0297c07d',
        'title': title,
        'pdf_url': pdfPath,
        'field_values': {},
        'status': 'draft',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _auditService.logAuditEvent(
        userId: contractorId,
        action: 'CUSTOM_CONTRACT_UPLOADED',
        details: 'Custom contract PDF uploaded',
        category: 'Contract',
        metadata: {
          'contractor_id': contractorId,
          'project_id': projectId,
          'contractee_id': contracteeId,
          'pdf_path': pdfPath,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to upload custom contract: ',
        module: 'Contractor Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Upload Custom Contract',
          'contractor_id': contractorId,
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  static Future<void> saveContract({
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String contractType,
    required Map<String, String> fieldValues,
    String? pdfPath,
  }) async {
    try {
      await ContractService.saveContract(
        projectId: projectId,
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        contractType: contractType,
        fieldValues: fieldValues,
        pdfPath: pdfPath,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to save contract: ',
        module: 'Contractor Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Save Contract',
          'contractor_id': contractorId,
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  static Future<void> updateContract({
    required String contractId,
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String contractType,
    required Map<String, String> fieldValues,
  }) async {
    try {
      await ContractService.updateContract(
        contractId: contractId,
        projectId: projectId,
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        contractType: contractType,
        fieldValues: fieldValues,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to update contract: ',
        module: 'Contractor Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Update Contract',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchProjectDetails(
      String projectId) async {
    try {
      return await FetchService().fetchProjectDetails(projectId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project details:',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Details',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchContractorData(
      String contractorId) async {
    try {
      return await FetchService().fetchContractorData(contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor data: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Data',
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchContractorProjectInfo(
      String contractorId) async {
    try {
      return await FetchService().fetchContractorProjectInfo(contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor project info: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Project Info',
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getContractById(String contractId, {String? contractorId}) async {
    try {
      return await ContractService.getContractById(contractId, contractorId: contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contract by ID: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Contract by ID',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signContract({
    required String contractId,
    required String userId,
    required Uint8List signatureBytes,
    required String userType,
  }) async {
    try {
      await SignatureCompletionHandler.signContractWithPdfGeneration(
        contractId: contractId,
        userId: userId,
        signatureBytes: signatureBytes,
        userType: userType,
      );
      return {};
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to sign contract: ',
        module: 'Contractor Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign Contract',
          'contract_id': contractId,
          'user_id': userId,
          'user_type': userType,
        },
      );
      rethrow;
    }
  }

  static Future<bool> verifySignature({
    required String contractId,
    required String userType,
  }) async {
    try {
      return await ContractService.verifySignature(
        contractId: contractId,
        userType: userType,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to verify signature: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Verify Signature',
          'contract_id': contractId,
          'user_type': userType,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> downloadContractPdfWithProgress({
    required String contractId,
    String? customFileName,
    bool saveToDevice = false,
    String? contractorId,
    String? contracteeId,
  }) async {
    try {
      return await ContractService.downloadContractPdfWithProgress(
        contractId: contractId,
        customFileName: customFileName,
        saveToDevice: saveToDevice,
        contractorId: contractorId,
        contracteeId: contracteeId,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download contract PDF: ',
        module: 'Contractor Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Contract PDF',
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      rethrow;
    }
  }

  static Future<String> getContractPdfPreviewUrl({
    required String contractId,
    int expiryHours = 24,
    String? contractorId,
    String? contracteeId,
  }) async {
    try {
      return await ContractService.getContractPdfPreviewUrl(
        contractId: contractId,
        expiryHours: expiryHours,
        contractorId: contractorId,
        contracteeId: contracteeId,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contract PDF preview URL: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Contract PDF Preview URL',
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> validateContractPdf(
    String contractId, {
    String? contractorId,
    String? contracteeId,
  }) async {
    try {
      return await ContractService.validateContractPdf(
        contractId,
        contractorId: contractorId,
        contracteeId: contracteeId,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to validate contract PDF: ',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Validate Contract PDF',
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> downloadMultipleContracts({
    required List<String> contractIds,
    String? archiveName,
  }) async {
    try {
      return await ContractService.downloadMultipleContracts(
        contractIds: contractIds,
        archiveName: archiveName,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download multiple contracts: ',
        module: 'Contractor Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Multiple Contracts',
          'contract_ids': contractIds,
        },
      );
      rethrow;
    }
  }

  static Future<void> sendContractToContractee({
    required String contractId,
    required String contracteeId,
    required String message,
  }) async {
    try {
      await ContractService.sendContractToContractee(
        contractId: contractId,
        contracteeId: contracteeId,
        message: message,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to send contract to contractee: ',
        module: 'Contractor Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Send Contract to Contractee',
          'contract_id': contractId,
          'contractee_id': contracteeId,
        },
      );
      rethrow;
    }
  }

  static Future<void> deleteContract({required String contractId}) async {
    try {
      await ContractService.deleteContract(contractId: contractId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete contract: ',
        module: 'Contractor Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Delete Contract',
          'contract_id': contractId,
        },
      );
      rethrow;
    }
  }

  static String formatDate(String? dateString) {
    return ContractService.formatDate(dateString);
  }
}
