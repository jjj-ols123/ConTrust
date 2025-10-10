// ignore_for_file: empty_catches

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:backend/services/both services/be_notification_service.dart';

class ContractService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  //For Contractors

  static Future<void> saveContract({
    required String projectId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String contractType,
    required Map<String, String> fieldValues,
  }) async {
    final proj = await _supabase
        .from('Projects')
        .select('contractee_id')
        .eq('project_id', projectId)
        .single();
    final contracteeId = proj['contractee_id'] as String?;
    if (contracteeId == null) {
      throw Exception('Project has no contractee assigned');
    }

    // Generate PDF
    final pdfBytes = await ContractPdfService.generateContractPdf(
      contractType: contractType,
      fieldValues: fieldValues,
      title: title,
    );

    // Upload PDF to storage
    final pdfPath = await ContractPdfService.uploadContractPdf(
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
      'status': 'draft',
    });
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
    final proj = await _supabase
        .from('Projects')
        .select('contractee_id')
        .eq('project_id', projectId)
        .single();
    final contracteeId = proj['contractee_id'] as String?;
    if (contracteeId == null) {
      throw Exception('Project has no contractee assigned');
    }

    // Generate new PDF
    final pdfBytes = await ContractPdfService.generateContractPdf(
      contractType: contractType,
      fieldValues: fieldValues,
      title: title,
    );

    // Upload updated PDF to storage
    final pdfPath = await ContractPdfService.uploadContractPdf(
      pdfBytes: pdfBytes,
      contractorId: contractorId,
      projectId: projectId,
      contracteeId: contracteeId,
    );

    await _supabase.from('Contracts').update({
      'project_id': projectId,
      'contractor_id': contractorId,
      'contractee_id': contracteeId,
      'contract_type_id': contractTypeId,
      'title': title,
      'pdf_url': pdfPath,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('contract_id', contractId);
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

      await _supabase.from('Contracts').update({
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
      }).eq('contract_id', contractId);

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
      });

      await _supabase.from('ChatRoom').update({
        'last_message': '📄 Contract sent: $message',
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('chatroom_id', chatRoomData['chatroom_id']);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteContract({
    required String contractId,
  }) async {
    try {
      await _supabase.from('Contracts').delete().eq('contract_id', contractId);
    } catch (e) {
      throw Exception('Error deleting contract: $e');
    }
  }

  static Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
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

    if (status == 'approved') {
      final contractData = await _supabase
          .from('Contracts')
          .select('project_id')
          .eq('contract_id', contractId)
          .single();

      await _supabase.from('Projects').update({
        'status': 'awaiting_agreement',
      }).eq('project_id', contractData['project_id']);
    } else if (status == 'rejected') {
      final contractData = await _supabase
          .from('Contracts')
          .select('project_id')
          .eq('contract_id', contractId)
          .single();

      await _supabase.from('Projects').update({
        'status': 'awaiting_agreement',
      }).eq('project_id', contractData['project_id']);
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

  // PDF-specific helper methods

  static Future<String?> getContractPdfUrl(String contractId) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('pdf_url')
          .eq('contract_id', contractId)
          .single();

      final pdfPath = contract['pdf_url'] as String?;
      if (pdfPath == null) return null;

      return await ContractPdfService.getContractPdfUrl(pdfPath);
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> downloadContractPdf(String contractId) async {
    try {
      final contract = await _supabase
          .from('Contracts')
          .select('pdf_url')
          .eq('contract_id', contractId)
          .single();

      final pdfPath = contract['pdf_url'] as String?;
      if (pdfPath == null) return null;

      return await ContractPdfService.downloadContractPdf(pdfPath);
    } catch (e) {
      return null;
    }
  }

  // For Both Users

  static Future<Map<String, dynamic>> getContractById(String contractId) async {
    return await _supabase
        .from('Contracts')
        .select('*')
        .eq('contract_id', contractId)
        .single();
  }

  static Future<Map<String, dynamic>> signContract({
    required String contractId,
    required String userId,
    required Uint8List signatureBytes,
    required String userType,
  }) async {
    try {
      // Validate inputs
      if (contractId.isEmpty || userId.isEmpty || signatureBytes.isEmpty) {
        throw Exception('Invalid signature data provided');
      }

      if (!['contractor', 'contractee'].contains(userType.toLowerCase())) {
        throw Exception('Invalid user type. Must be contractor or contractee');
      }

      // Validate signature image size and format
      if (signatureBytes.length > 5 * 1024 * 1024) { // 5MB limit
        throw Exception('Signature image too large. Maximum size is 5MB');
      }

      // Get contract data for validation
      final contractData = await _supabase
          .from('Contracts')
          .select('status, contractor_id, contractee_id, project_id')
          .eq('contract_id', contractId)
          .single();

      final contractStatus = contractData['status'] as String?;
      if (contractStatus == 'cancelled' || contractStatus == 'expired') {
        throw Exception('Cannot sign a $contractStatus contract');
      }

      // Validate user is authorized to sign this contract
      final contractorId = contractData['contractor_id'] as String?;
      final contracteeId = contractData['contractee_id'] as String?;
      
      if (userType.toLowerCase() == 'contractor' && contractorId != userId) {
        throw Exception('User not authorized to sign as contractor');
      }
      if (userType.toLowerCase() == 'contractee' && contracteeId != userId) {
        throw Exception('User not authorized to sign as contractee');
      }

      // Check if user has already signed
      final existingSignature = userType.toLowerCase() == 'contractor' 
          ? contractData['contractor_signature_url'] 
          : contractData['contractee_signature_url'];
      
      final fileName = '${userType.toLowerCase()}_${contractId}_$userId.png';
      final timestamp = DateTime.now().toIso8601String();

      // Upload signature to storage with retry logic
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
          if (attempt == 2) throw uploadError;
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }

      if (uploadPath == null || uploadPath.isEmpty) {
        throw Exception("Failed to upload signature after multiple attempts");
      }

      // Update contract with signature data
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

      // Send notification to other party
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
      } catch (notificationError) {
        // Continue even if notification fails
      }

      // Check if both parties have signed and activate contract
      await Future.delayed(const Duration(milliseconds: 200));

      final updatedContract = await _supabase
          .from('Contracts')
          .select(
              'project_id, contractor_signature_url, contractee_signature_url, status, contractor_signed_at, contractee_signed_at')
          .eq('contract_id', contractId)
          .single();

      final hasContractorSignature =
          (updatedContract['contractor_signature_url'] as String?)?.isNotEmpty ?? false;
      final hasContracteeSignature =
          (updatedContract['contractee_signature_url'] as String?)?.isNotEmpty ?? false;
      final currentStatus = updatedContract['status'] as String? ?? '';

      bool contractActivated = false;
      String? activationError;

      if (hasContractorSignature && hasContracteeSignature && currentStatus != 'active') {
        try {
          await _supabase.from('Contracts').update({
            'status': 'active',
            'activated_at': DateTime.now().toIso8601String(),
          }).eq('contract_id', contractId);

          final projectId = updatedContract['project_id'];
          if (projectId != null) {
            await _supabase.from('Projects').update({
              'status': 'active',
              'start_date': DateTime.now().toIso8601String(),
            }).eq('project_id', projectId);
          }

          contractActivated = true;

          // Send contract activation notification to both parties
          try {
            await NotificationService().createContractNotification(
              receiverId: contractorId!,
              receiverType: 'contractor',
              senderId: 'system',
              senderType: 'system',
              contractId: contractId,
              type: 'Contract Activated',
              message: 'Contract has been fully signed and is now active',
            );

            await NotificationService().createContractNotification(
              receiverId: contracteeId!,
              receiverType: 'contractee',
              senderId: 'system',
              senderType: 'system',
              contractId: contractId,
              type: 'Contract Activated',
              message: 'Contract has been fully signed and is now active',
            );
          } catch (activationNotifError) {
            // Continue even if activation notifications fail
          }
        } catch (activationErr) {
          activationError = activationErr.toString();
        }
      }

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
      throw Exception('Failed to sign contract: ${e.toString()}');
    }
  }

  // Enhanced method to verify signature integrity
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

      // Check if signature file exists in storage
      try {
        final files = await _supabase.storage
            .from('signatures')
            .list();
        
        return files.any((file) => file.name == signaturePath);
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Method to get signature URL with validation
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
          .createSignedUrl(signaturePath, 60 * 60 * 2); // 2 hours

      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  // Enhanced PDF download methods

  static Future<Map<String, dynamic>> downloadContractPdfWithProgress({
    required String contractId,
    String? customFileName,
    bool saveToDevice = false,
  }) async {
    try {
      // Get contract data
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

      // Generate appropriate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 
          '${contractTitle.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp.pdf';

      // Download with retry logic
      Uint8List? pdfBytes;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          pdfBytes = await _supabase.storage
              .from('contracts')
              .download(pdfPath);
          break;
        } catch (downloadError) {
          if (attempt == 2) throw downloadError;
          await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
        }
      }

      if (pdfBytes == null) {
        throw Exception('Failed to download PDF after multiple attempts');
      }

      // Validate PDF file
      if (pdfBytes.length < 100) {
        throw Exception('Downloaded file appears to be corrupted');
      }

      dynamic savedFile;
      String? filePath;

      if (saveToDevice) {
        try {
          savedFile = await ContractPdfService.saveToDevice(pdfBytes, fileName);
          // For mobile, savedFile is a File with a path
          // For web, savedFile is void (download is triggered automatically)
          if (!kIsWeb && savedFile is File) {
            filePath = savedFile.path;
          } else if (kIsWeb) {
            // Web download was triggered automatically
            filePath = fileName; // Just use the filename for web
            savedFile = true; // Indicate successful web download
          }
        } catch (saveError) {
          // Continue without saving to device if it fails
        }
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

      // Create signed URL with specified expiry
      final signedUrl = await _supabase.storage
          .from('contracts')
          .createSignedUrl(pdfPath, expiryHours * 60 * 60);

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to generate preview URL: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> validateContractPdf(String contractId) async {
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

      // Check if file exists in storage
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

        // Try to get file info
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
      return {
        'is_valid': false,
        'error': 'Contract validation failed: ${e.toString()}',
        'can_download': false,
      };
    }
  }

  // Method to download multiple contracts as a ZIP
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

      // Download each contract
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

      final successfulDownloads = downloadResults.where((r) => r['success'] == true).toList();
      
      return {
        'total_requested': contractIds.length,
        'successful_downloads': successfulDownloads.length,
        'failed_downloads': failedDownloads.length,
        'download_results': downloadResults,
        'failed_contract_ids': failedDownloads,
        'download_time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Bulk download failed: ${e.toString()}');
    }
  }

  static Future<String?> getSignedUrl(String signaturePath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('signatures')
          .createSignedUrl(signaturePath, 60 * 60);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }
}
