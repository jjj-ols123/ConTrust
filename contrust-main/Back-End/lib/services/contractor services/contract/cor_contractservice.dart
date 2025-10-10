// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ContractorContractService {
  static Future<List<Map<String, dynamic>>> fetchContractTypes() async {
    return await FetchService().fetchContractTypes();
  }

  static Future<List<Map<String, dynamic>>> fetchCreatedContracts(String contractorId) async {
    return await FetchService().fetchCreatedContracts(contractorId);
  }

  static Future<void> saveContract({
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String contractType,
    required Map<String, String> fieldValues,
  }) async {
    await ContractService.saveContract(
      projectId: projectId,
      contractorId: contractorId,
      contractTypeId: contractTypeId,
      title: title,
      contractType: contractType,
      fieldValues: fieldValues,
    );
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
    await ContractService.updateContract(
      contractId: contractId,
      projectId: projectId,
      contractorId: contractorId,
      contractTypeId: contractTypeId,
      title: title,
      contractType: contractType,
      fieldValues: fieldValues,
    );
  }

  static Future<Map<String, dynamic>?> fetchProjectDetails(String projectId) async {
    return await FetchService().fetchProjectDetails(projectId);
  }

  static Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    return await FetchService().fetchContractorData(contractorId);
  }

  static Future<List<Map<String, dynamic>>> fetchContractorProjectInfo(String contractorId) async {
    return await FetchService().fetchContractorProjectInfo(contractorId);
  }

  static Future<Map<String, dynamic>> getContractById(String contractId) async {
    return await ContractService.getContractById(contractId);
  }


  static Future<Map<String, dynamic>> signContract({
    required String contractId,
    required String userId,
    required Uint8List signatureBytes,
    required String userType,
  }) async {
    return await ContractService.signContract(
      contractId: contractId,
      userId: userId,
      signatureBytes: signatureBytes,
      userType: userType,
    );
  }

  static Future<bool> verifySignature({
    required String contractId,
    required String userType,
  }) async {
    return await ContractService.verifySignature(
      contractId: contractId,
      userType: userType,
    );
  }

  static Future<Map<String, dynamic>> downloadContractPdfWithProgress({
    required String contractId,
    String? customFileName,
    bool saveToDevice = false,
  }) async {
    return await ContractService.downloadContractPdfWithProgress(
      contractId: contractId,
      customFileName: customFileName,
      saveToDevice: saveToDevice,
    );
  }

  static Future<String> getContractPdfPreviewUrl({
    required String contractId,
    int expiryHours = 24,
  }) async {
    return await ContractService.getContractPdfPreviewUrl(
      contractId: contractId,
      expiryHours: expiryHours,
    );
  }

  static Future<Map<String, dynamic>> validateContractPdf(String contractId) async {
    return await ContractService.validateContractPdf(contractId);
  }

  static Future<Map<String, dynamic>> downloadMultipleContracts({
    required List<String> contractIds,
    String? archiveName,
  }) async {
    return await ContractService.downloadMultipleContracts(
      contractIds: contractIds,
      archiveName: archiveName,
    );
  }

  static Future<void> sendContractToContractee({
    required String contractId,
    required String contracteeId,
    required String message,
  }) async {
    await ContractService.sendContractToContractee(
      contractId: contractId,
      contracteeId: contracteeId,
      message: message,
    );
  }

  static Future<void> deleteContract({required String contractId}) async {
    await ContractService.deleteContract(contractId: contractId);
  }

  static String formatDate(String? dateString) {
    return ContractService.formatDate(dateString);
  }

  static Future<String?> getSignedUrl(String signaturePath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('contracts')
          .createSignedUrl(signaturePath, 60 * 60);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }
}
