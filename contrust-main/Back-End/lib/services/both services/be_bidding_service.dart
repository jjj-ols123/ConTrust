// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiddingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  // For Both Users 

  Future<Map<String, double>> getProjectHighestBids() async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('project_id, bid_amount')
          .order('bid_amount', ascending: false);

      final Map<String, double> highestBids = {};

      for (final bid in response) {
        final projectId = bid['project_id'].toString();
        final amount = (bid['bid_amount'] as num).toDouble();

        if (!highestBids.containsKey(projectId)) {
          highestBids[projectId] = amount;
        }
      }

      return highestBids;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get project highest bids: ',
        module: 'Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Project Highest Bids',
        },
      );
      return {};
    }
  }

  //For Contractees 

  Future<void> acceptProjectBid(String projectId, String bidId) async {
    try {
      final bidResponse =
          await _supabase.from('Bids').select().eq('bid_id', bidId).single();

      if (bidResponse.isEmpty) return;

      final contractorId = bidResponse['contractor_id'];

      final projectResponse = await _supabase
          .from('Projects')
          .select()
          .eq('project_id', projectId)
          .single();

      if (projectResponse.isEmpty) return;

      final projectStatus = projectResponse['status'] as String?;
      if (projectStatus == 'stopped') {
        throw Exception('Cannot accept bids for a project with expired bidding period. Please update the project to restart bidding.');
      }

      if (projectStatus != 'pending') {
        throw Exception('This project is no longer accepting bids.');
      }

      await _supabase.from('Projects').update({
        'status': 'awaiting_contract',
        'bid_id': bidId,
        'contractor_id': contractorId,
      }).eq('project_id', projectId);

      final allBids =
          await _supabase.from('Bids').select().eq('project_id', projectId);

      final losingBidIds = allBids
          .where((bid) => bid['bid_id'] != bidId)
          .map((bid) => bid['bid_id'])
          .toList();

      if (losingBidIds.isNotEmpty) {
        await _supabase
            .from('Bids')
            .update({'status': 'rejected'}).inFilter('bid_id', losingBidIds);
      }

      await _supabase
          .from('Bids')
          .update({'status': 'accepted'}).eq('bid_id', bidId);

      await _auditService.logAuditEvent(
        action: 'BID_ACCEPTED',
        details: 'Contractee accepted a bid for the project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'bid_id': bidId,
          'contractor_id': contractorId,
        },
      );

      try {
        final messageService = MessageService();
        await messageService.getOrCreateChatRoom(
          contractorId: contractorId,
          contracteeId: projectResponse['contractee_id'],
          projectId: projectId,
        );
      } catch (e) {
        await _errorService.logError(
          errorMessage: 'Failed to create chat room after accepting bid: ',
          module: 'Bidding Service',
          severity: 'Medium',
          extraInfo: {
            'operation': 'Accept Project Bid - Create Chat Room',
            'project_id': projectId,
            'bid_id': bidId,
          },
        );
        rethrow;
      }

      try {
        final contracteeId = projectResponse['contractee_id'];
        final projectType = projectResponse['type'];

        final contracteeResponse = await _supabase
            .from('Contractee')
            .select('full_name, profile_photo')
            .eq('contractee_id', contracteeId)
            .single();

        final contracteeName = contracteeResponse['full_name'] ?? 'Unknown';
        final contracteePhoto = contracteeResponse['profile_photo'] ?? '';

        final notificationService = NotificationService();

        await notificationService.createNotification(
          receiverId: contractorId,
          receiverType: 'contractor',
          senderId: contracteeId,
          senderType: 'contractee',
          type: 'Bid Accepted',
          message:
              'Congratulations! Your bid for the $projectType project has been accepted. \nPlease proceed to Messages to discuss further details.',
          information: {
            'project_type': projectType,
            'bid_id': bidId,
            'full_name': contracteeName,
            'profile_photo': contracteePhoto,
          },
        );
      } catch (e) {
        await _errorService.logError(
          errorMessage: 'Failed to send notification after accepting bid: ',
          module: 'Bidding Service',
          severity: 'Medium',
          extraInfo: {
            'operation': 'Accept Project Bid - Send Notification',
            'project_id': projectId,
            'bid_id': bidId,
          },
        );
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to accept project bid: ',
        module: 'Bidding Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Accept Project Bid',
          'project_id': projectId,
          'bid_id': bidId,
        },
      );
      rethrow;
    }
  }

  Future<void> rejectBid(String bidId) async {
    try {
      final bidResponse = await _supabase
          .from('Bids')
          .select('status, project_id')
          .eq('bid_id', bidId)
          .single();

      final bidStatus = bidResponse['status'] as String?;
      if (bidStatus == 'stopped') {
        throw Exception('Cannot reject bids for a project with expired bidding period.');
      }

      await _supabase
          .from('Bids')
          .update({'status': 'rejected'})
          .eq('bid_id', bidId);

      await _auditService.logAuditEvent(
        action: 'BID_REJECTED',
        details: 'Bid rejected by contractee',
        category: 'Project',
        metadata: {
          'bid_id': bidId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to reject bid:',
        module: 'Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Reject Bid',
          'bid_id': bidId,
        },
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBidsForProject(String projectId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('''
            *,
            contractor:contractor_id (
              firm_name,
              profile_photo
            )
          ''')
          .eq('project_id', projectId)
          .order('bid_amount', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get bids for project: ',
        module: 'Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Bids for Project',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  Future<void> finalizeBidding(String projectId) async {
    try {
      final projectResponse = await _supabase
          .from('Projects')
          .select('status, contractee_id')
          .eq('project_id', projectId)
          .maybeSingle();

      if (projectResponse == null || projectResponse['status'] != 'pending') {
        return;
      }

      await _supabase.from('Projects').update({
        'status': 'stopped',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('project_id', projectId);

      await _supabase
          .from('Bids')
          .update({'status': 'stopped'})
          .eq('project_id', projectId)
          .eq('status', 'pending');

      await _auditService.logAuditEvent(
        action: 'BIDDING_FINALIZED',
        details: 'Bidding period expired for project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'reason': 'Duration expired',
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to finalize bidding: ',
        module: 'Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Finalize Bidding',
          'project_id': projectId,
        },
      );
    }
  }
}
