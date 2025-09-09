// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:backend/services/be_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/be_user_service.dart';

class BiddingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<void> postBid({
    required String contractorId,
    required String projectId,
    required num bidAmount,
    required String message,
    required BuildContext context,
  }) async {
    try {
      await _userService.checkContractorId(contractorId);

      await _supabase.from('Bids').upsert({
        'contractor_id': contractorId,
        'project_id': projectId,
        'bid_amount': bidAmount,
        'message': message,
        'status': 'pending',
      });

      try {
        final projectResponse = await _supabase
            .from('Projects')
            .select('contractee_id, type')
            .eq('project_id', projectId)
            .single();

        if (projectResponse.isNotEmpty) {
          final contracteeId = projectResponse['contractee_id'];
          final projectType = projectResponse['type'];

          final contractorResponse = await _supabase
              .from('Contractor')
              .select('firm_name, profile_photo')
              .eq('contractor_id', contractorId)
              .single();

          final contractorName =
              contractorResponse['firm_name'] ?? 'Unknown Contractor';
          final contractorPhoto = contractorResponse['profile_photo'] ?? '';

          final notificationService = NotificationService();

          await notificationService.createNotification(
            receiverId: contracteeId,
            receiverType: 'contractee',
            senderId: contractorId,
            senderType: 'contractor',
            type: 'New Bid',
            message:
                '$contractorName submitted a bid of ₱$bidAmount for your $projectType project',
            information: {
              'bid_amount': bidAmount,
              'project_type': projectType,
              'contractor_name': contractorName,
              'contractor_photo': contractorPhoto,
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification')),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        if (e is PostgrestException && e.code == '23505') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only submit one bid per project.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error posting bid')),
          );
        }
      }
      rethrow;
    }
  }

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

  Future<int> getProjectBidCount(String projectId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('bid_id')
          .eq('project_id', projectId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

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
            'Congratulations! Your bid for the $projectType project has been accepted',
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

  Future<void> processBiddingDurationExpiry(String projectId) async {
    final bids = await _supabase
        .from('Bids')
        .select()
        .eq('project_id', projectId)
        .order('bid_amount', ascending: false);

    if (bids.isEmpty) return;

    final winningBid = bids.first;
    final bidWinnerId = winningBid['bid_id'];
    final contractorId = winningBid['contractor_id'];

    final projectResponse = await _supabase
        .from('Projects')
        .select()
        .eq('project_id', projectId)
        .single();

    if (projectResponse.isEmpty) return;

    await _supabase.from('Projects').update({
      'status': 'awaiting_contract',
      'bid_id': bidWinnerId,
      'contractor_id': contractorId,
    }).eq('project_id', projectId);

    final losingBidIds = bids.skip(1).map((bid) => bid['bid_id']).toList();
    if (losingBidIds.isNotEmpty) {
      await _supabase
          .from('Bids')
          .update({'status': 'expired'}).inFilter('bid_id', losingBidIds);
    }

    await _supabase
        .from('Bids')
        .update({'status': 'accepted'}).eq('bid_id', bidWinnerId);
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

  Stream<Duration> getBiddingCountdownStream(
    DateTime createdAt,
    int durationInDays,
  ) async* {
    final endTime = createdAt.add(Duration(days: durationInDays));
    while (true) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);
      if (remaining.isNegative) break;
      yield remaining;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

   static String formatNotificationTime(String? createdAt) {
    if (createdAt == null) return '';
    
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

}
