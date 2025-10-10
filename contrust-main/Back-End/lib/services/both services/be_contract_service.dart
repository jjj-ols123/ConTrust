// ignore_for_file: empty_catches

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
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

    await _supabase.from('Contracts').update(updateData).eq('contract_id', contractId);

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







  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'under_review':
        return Icons.visibility;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'signed':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'signed':
        return Colors.purple;
      default:
        return Colors.grey;
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

  static Future<void> signContract({
    required String contractId,
    required String userId,
    required Uint8List signatureBytes,
    required String userType, 
  }) async {
    try {
      final fileName = '${userType}_${contractId}_$userId.png';
      
      final storageResponse = await _supabase.storage
          .from('signatures')
          .uploadBinary(fileName, signatureBytes, fileOptions: const FileOptions(upsert: true));

      if (storageResponse.isEmpty) {
        throw Exception("Failed to upload signature to storage");
      }

      final updateData = userType == 'contractor'
          ? {
              'contractor_signature_url': fileName,
              'contractor_signed_at': DateTime.now().toIso8601String(),
            }
          : {
              'contractee_signature_url': fileName,
              'contractee_signed_at': DateTime.now().toIso8601String(),
            };

      await _supabase.from('Contracts').update(updateData).eq('contract_id', contractId);

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

      await Future.delayed(const Duration(milliseconds: 100));
      
      final contract = await _supabase
          .from('Contracts')
          .select('project_id, contractor_signature_url, contractee_signature_url, status')
          .eq('contract_id', contractId)
          .single();

      final hasContractorSignature = (contract['contractor_signature_url'] as String?)?.isNotEmpty ?? false;
      final hasContracteeSignature = (contract['contractee_signature_url'] as String?)?.isNotEmpty ?? false;
      final currentStatus = contract['status'] as String? ?? '';

      if (hasContractorSignature && hasContracteeSignature && currentStatus != 'active') {
        try {
          await _supabase.from('Contracts').update({
            'status': 'active',
          }).eq('contract_id', contractId);

          final projectId = contract['project_id'];
          if (projectId != null) {
            await _supabase.from('Projects').update({
              'status': 'active',
              'start_date': DateTime.now().toIso8601String(),
            }).eq('project_id', projectId);
          }

        } catch (activationError) {
        }
      }

    } catch (e) {
      throw Exception('Failed to sign contract');
    }
  }
}
