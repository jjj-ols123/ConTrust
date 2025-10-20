// ignore_for_file: empty_catches

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:backend/services/both services/be_notification_service.dart';

class ContractService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final SuperAdminAuditService _auditService = SuperAdminAuditService();
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  //For Contractors

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
      final proj = await _supabase
          .from('Projects')
          .select('contractee_id')
          .eq('project_id', projectId)
          .single();
      final contracteeId = proj['contractee_id'] as String?;
      if (contracteeId == null) {
        throw Exception('Project has no contractee assigned');
      }

      final pdfBytes = await ContractPdfService.generateContractPdf(
        contractType: contractType,
        fieldValues: fieldValues,
        title: title,
      );

      final pdfPath = await ContractPdfService.uploadContractPdfToStorage(
        pdfBytes: pdfBytes,
        contractorId: contractorId,
        projectId: projectId,
        contracteeId: contracteeId,
      );

      await _supabase.from('Contracts').insert({
        'project_id': projectId,
        'contractor_id': contractorId,
        'contractee_id': contracteeId,
        'contract_type_id': contractTypeId,
        'title': title,
        'pdf_url': pdfPath,
        'field_values': fieldValues,
        'status': 'draft',
      });

      await _auditService.logAuditEvent(
        userId: contractorId,
        action: 'CONTRACT_SAVED',
        details: 'Contract saved as draft',
        category: 'Contract',
        metadata: {
          'project_id': projectId,
          'contractee_id': contracteeId,
          'contract_title': title,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to save contract: $e',
        module: 'Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Save Contract',
          'project_id': projectId,
          'contractor_id': contractorId,
        },
      );
      throw Exception('Failed to save contract: ');
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
      final proj = await _supabase
          .from('Projects')
          .select('contractee_id')
          .eq('project_id', projectId)
          .single();
      final contracteeId = proj['contractee_id'] as String?;
      if (contracteeId == null) {
        throw Exception('Project has no contractee assigned');
      }

      final pdfBytes = await ContractPdfService.generateContractPdf(
        contractType: contractType,
        fieldValues: fieldValues,
        title: title,
      );

      final pdfPath = await ContractPdfService.uploadContractPdfToStorage(
        pdfBytes: pdfBytes,
        contractorId: contractorId,
        projectId: projectId,
        contracteeId: contracteeId,
        contractId: contractId,
      );

      final currentContract = await _supabase
          .from('Contracts')
          .select('status')
          .eq('contract_id', contractId)
          .single();

      final currentStatus = currentContract['status'] as String?;

      final newStatus = (currentStatus == 'rejected') ? 'draft' : currentStatus;

      await _supabase.from('Contracts').update({
        'project_id': projectId,
        'contractor_id': contractorId,
        'contractee_id': contracteeId,
        'contract_type_id': contractTypeId,
        'title': title,
        'pdf_url': pdfPath,
        'field_values': fieldValues,
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('contract_id', contractId);

      await _auditService.logAuditEvent(
        userId: contractorId,
        action: 'CONTRACT_UPDATED',
        details: 'Contract updated',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
          'project_id': projectId,
          'new_status': newStatus,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to update contract: $e',
        module: 'Contract Service',
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

  static Future<void> sendContractToContractee({
    required String contractId,
    required String contracteeId,
    required String message,
  }) async {
    try {
      final contractData = await _supabase
          .from('Contracts')
          .select('*, contractor_id, project_id')
          .eq('contract_id', contractId)
          .single();

      final chatRoomData = await _supabase
          .from('ChatRoom')
          .select('chatroom_id')
          .eq('project_id', contractData['project_id'])
          .single();

      final currentStatus = contractData['status'] as String?;
      if (currentStatus != 'approved' &&
          currentStatus != 'rejected' &&
          currentStatus != 'signed') {
        await _supabase.from('Contracts').update({
          'status': 'sent',
          'sent_at': DateTime.now().toIso8601String(),
        }).eq('contract_id', contractId);
      }

      await _supabase.from('Projects').update({
        'status': 'awaiting_agreement',
      }).eq('project_id', contractData['project_id']);

      await _supabase.from('Messages').insert({
        'chatroom_id': chatRoomData['chatroom_id'],
        'sender_id': contractData['contractor_id'],
        'receiver_id': contracteeId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'message_type': 'contract',
        'contract_id': contractId,
        'contract_status': 'sent',
        'pdf_url': contractData['pdf_url'], 
      });

      await _supabase.from('ChatRoom').update({
        'last_message': '📄 Contract sent: $message',
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('chatroom_id', chatRoomData['chatroom_id']);

      await _auditService.logAuditEvent(
        userId: contractData['contractor_id'],
        action: 'CONTRACT_SENT',
        details: 'Contract sent to contractee',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
          'contractee_id': contracteeId,
          'project_id': contractData['project_id'],
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to send contract to contractee: $e',
        module: 'Contract Service',
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

  static Future<void> deleteContract({
    required String contractId,
  }) async {
    try {
      await _supabase.from('Contracts').delete().eq('contract_id', contractId);

      await _auditService.logAuditEvent(
        action: 'CONTRACT_DELETED',
        details: 'Contract deleted',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete contract: $e',
        module: 'Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Delete Contract',
          'contract_id': contractId,
        },
      );
      throw Exception('Error deleting contract: $e');
    }
  }

  static Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (status == 'approved' || status == 'rejected') {
        updateData['reviewed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('Contracts')
          .update(updateData)
          .eq('contract_id', contractId);

      if (status == 'approved' || status == 'rejected') {
        await _supabase
            .from('Messages')
            .update(
                {'contract_status': status == 'approved' ? 'approved' : status})
            .eq('contract_id', contractId)
            .eq('message_type', 'contract')
            .eq('contract_status', 'sent');
      }

      if (status == 'approved') {
        final contractData = await _supabase
            .from('Contracts')
            .select('project_id')
            .eq('contract_id', contractId)
            .single();

        await _supabase.from('Projects').update({
          'status': 'awaiting_signature',
        }).eq('project_id', contractData['project_id']);

      } else if (status == 'rejected') {
        final contractData = await _supabase
            .from('Contracts')
            .select('project_id, contractor_id, contractee_id')
            .eq('contract_id', contractId)
            .single();

        try {
          await NotificationService().createContractNotification(
            receiverId: contractData['contractor_id'],
            receiverType: 'contractor',
            senderId: contractData['contractee_id'],
            senderType: 'contractee',
            contractId: contractId,
            type: 'Contract Rejected',
            message: 'Your contract has been rejected by the contractee.',
          );
        } catch (notificationError) {
          rethrow;
        }
      }

      await _auditService.logAuditEvent(
        action: 'CONTRACT_STATUS_UPDATED',
        details: 'Contract status updated',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
          'new_status': status,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to update contract status: $e',
        module: 'Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Update Contract Status',
          'contract_id': contractId,
          'new_status': status,
        },
      );
      rethrow;
    }
  }

  static String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // For Both Users

  static Future<Map<String, dynamic>> getContractById(String contractId) async {
    try {
      return await _supabase
          .from('Contracts')
          .select('*')
          .eq('contract_id', contractId)
          .single();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contract by ID: $e',
        module: 'Contract Service',
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
      if (contractId.isEmpty || userId.isEmpty || signatureBytes.isEmpty) {
        throw Exception('Invalid signature data provided');
      }

      if (!['contractor', 'contractee'].contains(userType.toLowerCase())) {
        throw Exception('Invalid user type. Must be contractor or contractee');
      }

      if (signatureBytes.length > 5 * 1024 * 1024) {
        throw Exception('Signature image too large. Maximum size is 5MB');
      }

      final contractData = await _supabase
          .from('Contracts')
          .select('status, contractor_id, contractee_id, project_id')
          .eq('contract_id', contractId)
          .single();

      final contractStatus = contractData['status'] as String?;
      if (contractStatus == 'cancelled' || contractStatus == 'expired') {
        throw Exception('Cannot sign a $contractStatus contract');
      }

      final contractorId = contractData['contractor_id'] as String?;
      final contracteeId = contractData['contractee_id'] as String?;

      if (userType.toLowerCase() == 'contractor' && contractorId != userId) {
        throw Exception('User not authorized to sign as contractor');
      }
      if (userType.toLowerCase() == 'contractee' && contracteeId != userId) {
        throw Exception('User not authorized to sign as contractee');
      }
      final existingSignature = userType.toLowerCase() == 'contractor'
          ? contractData['contractor_signature_url']
          : contractData['contractee_signature_url'];

      final fileName = '${userType.toLowerCase()}_${contractId}_$userId.png';
      final timestamp = DateTime.now().toIso8601String();

      String? uploadPath;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final storageResponse = await _supabase.storage
              .from('signatures')
              .uploadBinary(fileName, signatureBytes,
                  fileOptions: const FileOptions(upsert: true));

          if (storageResponse.isNotEmpty) {
            uploadPath = storageResponse;
            break;
          }
        } catch (uploadError) {
          if (attempt == 2) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }

      if (uploadPath == null || uploadPath.isEmpty) {
        throw Exception("Failed to upload signature after multiple attempts");
      }

      final updateData = userType.toLowerCase() == 'contractor'
          ? {
              'contractor_signature_url': fileName,
              'contractor_signed_at': timestamp,
            }
          : {
              'contractee_signature_url': fileName,
              'contractee_signed_at': timestamp,
            };

      await _supabase
          .from('Contracts')
          .update(updateData)
          .eq('contract_id', contractId);

      try {
        final notifInfo = await FetchService().userTypeDecide(
          contractId: contractId,
          userType: userType,
          action: 'signed',
        );

        await NotificationService().createContractNotification(
          receiverId: notifInfo['receiverId']!,
          receiverType: notifInfo['receiverType']!,
          senderId: notifInfo['senderId']!,
          senderType: notifInfo['senderType']!,
          contractId: contractId,
          type: 'Contract Signed',
          message: notifInfo['message']!,
        );
      } catch (notificationError) {}

      await Future.delayed(const Duration(milliseconds: 200));

      final updatedContract = await _supabase
          .from('Contracts')
          .select(
              'project_id, contractor_signature_url, contractee_signature_url, status, contractor_signed_at, contractee_signed_at')
          .eq('contract_id', contractId)
          .single();

      final hasContractorSignature =
          (updatedContract['contractor_signature_url'] as String?)
                  ?.isNotEmpty ??
              false;
      final hasContracteeSignature =
          (updatedContract['contractee_signature_url'] as String?)
                  ?.isNotEmpty ??
              false;
      final currentStatus = updatedContract['status'] as String? ?? '';

      bool contractActivated = false;
      String? activationError;

      if (hasContractorSignature &&
          hasContracteeSignature &&
          currentStatus == 'approved') {
        try {
          await _supabase.from('Contracts').update({
            'status': 'active',
          }).eq('contract_id', contractId);
          await _supabase
              .from('Messages')
              .update({'contract_status': 'active'})
              .eq('contract_id', contractId)
              .eq('message_type', 'contract');

          final projectId = updatedContract['project_id'];
          if (projectId != null) {
            await _supabase.from('Projects').update({
              'status': 'active',
            }).eq('project_id', projectId);
          } else {
          }

          contractActivated = true;

          try {
            await NotificationService().createContractNotification(
              receiverId: contractorId!,
              receiverType: 'contractor',
              senderId: 'system',
              senderType: 'system',
              contractId: contractId,
              type: 'Contract Activated',
              message:
                  'The project is now active. Proceed to Project Management Page.',
            );

            await NotificationService().createContractNotification(
              receiverId: contracteeId!,
              receiverType: 'contractee',
              senderId: 'system',
              senderType: 'system',
              contractId: contractId,
              type: 'Contract Activated',
              message:
                  'The project is now active. Proceed to Project Management Page.',
            );
          } catch (activationNotifError) {
          }
        } catch (activationErr) {
          activationError = activationErr.toString();
        }
      }

      await _auditService.logAuditEvent(
        userId: userId,
        action: 'CONTRACT_SIGNED',
        details: '$userType signed the contract',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
          'user_type': userType,
          'contract_activated': contractActivated,
        },
      );

      return {
        'success': true,
        'message': existingSignature != null
            ? 'Signature updated successfully'
            : 'Contract signed successfully',
        'signature_url': fileName,
        'signed_at': timestamp,
        'contract_activated': contractActivated,
        'both_parties_signed': hasContractorSignature && hasContracteeSignature,
        'activation_error': activationError,
        'user_type': userType.toLowerCase(),
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to sign contract: $e',
        module: 'Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign Contract',
          'contract_id': contractId,
          'user_id': userId,
          'user_type': userType,
        },
      );
      throw Exception('$e');
    }
  }

  static Future<bool> verifySignature({
    required String contractId,
    required String userType,
  }) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('contractor_signature_url, contractee_signature_url')
          .eq('contract_id', contractId)
          .single();

      final signaturePath = userType.toLowerCase() == 'contractor'
          ? contract['contractor_signature_url']
          : contract['contractee_signature_url'];

      if (signaturePath == null || signaturePath.isEmpty) {
        return false;
      }

      try {
        final files = await _supabase.storage.from('signatures').list();

        return files.any((file) => file.name == signaturePath);
      } catch (e) {
        return false;
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to verify signature: $e',
        module: 'Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Verify Signature',
          'contract_id': contractId,
          'user_type': userType,
        },
      );
      return false;
    }
  }

  static Future<String?> getSignatureUrl({
    required String contractId,
    required String userType,
  }) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('contractor_signature_url, contractee_signature_url')
          .eq('contract_id', contractId)
          .single();

      final signaturePath = userType.toLowerCase() == 'contractor'
          ? contract['contractor_signature_url']
          : contract['contractee_signature_url'];

      if (signaturePath == null || signaturePath.isEmpty) {
        return null;
      }

      final signedUrl = await _supabase.storage
          .from('signatures')
          .createSignedUrl(signaturePath, 60 * 60 * 2);

      return signedUrl;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get signature URL: $e',
        module: 'Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Signature URL',
          'contract_id': contractId,
          'user_type': userType,
        },
      );
      return null;
    }
  }

  static Future<Map<String, dynamic>> downloadContractPdfWithProgress({
    required String contractId,
    String? customFileName,
    bool saveToDevice = false,
  }) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('pdf_url, title, created_at, status')
          .eq('contract_id', contractId)
          .single();

      final pdfPath = contract['pdf_url'] as String?;
      if (pdfPath == null || pdfPath.isEmpty) {
        throw Exception('No PDF file found for this contract');
      }

      final contractTitle = contract['title'] as String? ?? 'Contract';
      final contractStatus = contract['status'] as String? ?? 'unknown';

      if (contractStatus == 'cancelled') {
        throw Exception('Cannot download cancelled contract');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ??
          '${contractTitle.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp.pdf';

      Uint8List? pdfBytes;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          pdfBytes =
              await _supabase.storage.from('contracts').download(pdfPath);
          break;
        } catch (downloadError) {
          if (attempt == 2) rethrow;
          await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
        }
      }

      if (pdfBytes == null) {
        throw Exception('Failed to download PDF after multiple attempts');
      }

      if (pdfBytes.length < 100) {
        throw Exception('Downloaded file appears to be corrupted');
      }

      dynamic savedFile;
      String? filePath;

      if (saveToDevice) {
        try {
          savedFile = await ContractPdfService.saveToDevice(pdfBytes, fileName);
          if (!kIsWeb && savedFile is File) {
            filePath = savedFile.path;
          } else if (kIsWeb) {
            filePath = fileName;
            savedFile = true;
          }
        } catch (saveError) {}
      }

      return {
        'success': true,
        'pdf_bytes': pdfBytes,
        'file_size': pdfBytes.length,
        'file_name': fileName,
        'contract_title': contractTitle,
        'download_time': DateTime.now().toIso8601String(),
        'saved_to_device': savedFile != null,
        'file_path': filePath,
        'contract_status': contractStatus,
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download contract PDF: $e',
        module: 'Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Contract PDF',
          'contract_id': contractId,
        },
      );
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  static Future<String> getContractPdfPreviewUrl({
    required String contractId,
    int expiryHours = 24,
  }) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('pdf_url, status')
          .eq('contract_id', contractId)
          .single();

      final pdfPath = contract['pdf_url'] as String?;
      if (pdfPath == null || pdfPath.isEmpty) {
        throw Exception('No PDF file found for this contract');
      }

      final contractStatus = contract['status'] as String? ?? 'unknown';
      if (contractStatus == 'cancelled') {
        throw Exception('Cannot preview cancelled contract');
      }

      final signedUrl = await _supabase.storage
          .from('contracts')
          .createSignedUrl(pdfPath, expiryHours * 60 * 60);

      return signedUrl;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contract PDF preview URL: $e',
        module: 'Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Contract PDF Preview URL',
          'contract_id': contractId,
        },
      );
      throw Exception('Failed to generate preview URL: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> validateContractPdf(
      String contractId) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('pdf_url, title, created_at, updated_at')
          .eq('contract_id', contractId)
          .single();

      final pdfPath = contract['pdf_url'] as String?;
      if (pdfPath == null || pdfPath.isEmpty) {
        return {
          'is_valid': false,
          'error': 'No PDF file found',
          'can_download': false,
        };
      }

      try {
        final files = await _supabase.storage
            .from('contracts')
            .list(path: pdfPath.split('/').first);

        final fileName = pdfPath.split('/').last;
        final fileExists = files.any((file) => file.name == fileName);

        if (!fileExists) {
          return {
            'is_valid': false,
            'error': 'PDF file not found in storage',
            'can_download': false,
          };
        }

        final fileInfo = files.firstWhere((file) => file.name == fileName);

        return {
          'is_valid': true,
          'can_download': true,
          'file_size': fileInfo.metadata?['size'] ?? 0,
          'file_name': fileName,
          'created_at': contract['created_at'],
          'updated_at': contract['updated_at'],
          'last_modified': fileInfo.updatedAt,
        };
      } catch (e) {
        return {
          'is_valid': false,
          'error': 'Unable to validate PDF file: ${e.toString()}',
          'can_download': false,
        };
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to validate contract PDF: $e',
        module: 'Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Validate Contract PDF',
          'contract_id': contractId,
        },
      );
      return {
        'is_valid': false,
        'error': 'Contract validation failed: ${e.toString()}',
        'can_download': false,
      };
    }
  }

  static Future<Map<String, dynamic>> downloadMultipleContracts({
    required List<String> contractIds,
    String? archiveName,
  }) async {
    try {
      if (contractIds.isEmpty) {
        throw Exception('No contracts specified for download');
      }

      if (contractIds.length > 10) {
        throw Exception('Maximum 10 contracts can be downloaded at once');
      }

      final downloadResults = <Map<String, dynamic>>[];
      final failedDownloads = <String>[];

      for (final contractId in contractIds) {
        try {
          final result = await downloadContractPdfWithProgress(
            contractId: contractId,
            saveToDevice: false,
          );
          downloadResults.add({
            'contract_id': contractId,
            'success': true,
            'data': result,
          });
        } catch (e) {
          failedDownloads.add(contractId);
          downloadResults.add({
            'contract_id': contractId,
            'success': false,
            'error': e.toString(),
          });
        }
      }

      final successfulDownloads =
          downloadResults.where((r) => r['success'] == true).toList();

      return {
        'total_requested': contractIds.length,
        'successful_downloads': successfulDownloads.length,
        'failed_downloads': failedDownloads.length,
        'download_results': downloadResults,
        'failed_contract_ids': failedDownloads,
        'download_time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download multiple contracts: $e',
        module: 'Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Multiple Contracts',
          'contract_ids': contractIds,
        },
      );
      throw Exception('Bulk download failed: ${e.toString()}');
    }
  }
}
