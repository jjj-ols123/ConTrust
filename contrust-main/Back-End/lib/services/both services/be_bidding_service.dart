// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class BiddingService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      return {};
    }
  }

  //For Contractees 

  Future<void> acceptProjectBid(String projectId, String bidId) async {
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

    try {
      final messageService = MessageService();
      await messageService.getOrCreateChatRoom(
        contractorId: contractorId,
        contracteeId: projectResponse['contractee_id'],
        projectId: projectId,
      );
    } catch (e) {
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
      
    }
  }

  Future<void> deleteBid(String bidId) async {
    await _supabase.from('Bids').delete().eq('bid_id', bidId);
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
      return [];
    }
  }
}
