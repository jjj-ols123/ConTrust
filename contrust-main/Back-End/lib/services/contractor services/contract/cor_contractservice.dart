// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_contractsignature.dart';
import 'dart:typed_data';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class ContractorContractService {
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  static Future<List<Map<String, dynamic>>> fetchContractTypes() async {
    try {
      return await FetchService().fetchContractTypes();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contract types: $e',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contract Types',
        },
      );
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCreatedContracts(String contractorId) async {
    try {
      return await FetchService().fetchCreatedContracts(contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch created contracts: $e',
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

  static Future<void> saveContract({
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String contractType,
    required Map<String, String> fieldValues,
  }) async {
    try {
      await ContractService.saveContract(
        projectId: projectId,
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        contractType: contractType,
        fieldValues: fieldValues,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to save contract: $e',
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
        errorMessage: 'Failed to update contract: $e',
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

  static Future<Map<String, dynamic>?> fetchProjectDetails(String projectId) async {
    try {
      return await FetchService().fetchProjectDetails(projectId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project details: $e',
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

  static Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      return await FetchService().fetchContractorData(contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor data: $e',
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

  static Future<List<Map<String, dynamic>>> fetchContractorProjectInfo(String contractorId) async {
    try {
      return await FetchService().fetchContractorProjectInfo(contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor project info: $e',
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

  static Future<Map<String, dynamic>> getContractById(String contractId) async {
    try {
      return await ContractService.getContractById(contractId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contract by ID: $e',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Contract by ID',
          'contract_id': contractId,
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
        errorMessage: 'Failed to sign contract: $e',
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
        errorMessage: 'Failed to verify signature: $e',
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
  }) async {
    try {
      return await ContractService.downloadContractPdfWithProgress(
        contractId: contractId,
        customFileName: customFileName,
        saveToDevice: saveToDevice,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download contract PDF: $e',
        module: 'Contractor Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Contract PDF',
          'contract_id': contractId,
        },
      );
      rethrow;
    }
  }

  static Future<String> getContractPdfPreviewUrl({
    required String contractId,
    int expiryHours = 24,
  }) async {
    try {
      return await ContractService.getContractPdfPreviewUrl(
        contractId: contractId,
        expiryHours: expiryHours,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contract PDF preview URL: $e',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Contract PDF Preview URL',
          'contract_id': contractId,
        },
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> validateContractPdf(String contractId) async {
    try {
      return await ContractService.validateContractPdf(contractId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to validate contract PDF: $e',
        module: 'Contractor Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Validate Contract PDF',
          'contract_id': contractId,
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
        errorMessage: 'Failed to download multiple contracts: $e',
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
        errorMessage: 'Failed to send contract to contractee: $e',
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
        errorMessage: 'Failed to delete contract: $e',
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
