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
          print('Error inserting data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inserting data: $e')),
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
    final bidResponse = await _supabase
        .from('Bids')
        .select()
        .eq('bid_id', bidId)
        .single();

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

    final allBids = await _supabase
        .from('Bids')
        .select()
        .eq('project_id', projectId);

    final losingBidIds = allBids
        .where((bid) => bid['bid_id'] != bidId)
        .map((bid) => bid['bid_id'])
        .toList();

    if (losingBidIds.isNotEmpty) {
      await _supabase
          .from('Bids')
          .update({'status': 'rejected'})
          .inFilter('bid_id', losingBidIds);
    }

    await _supabase
        .from('Bids')
        .update({'status': 'accepted'})
        .eq('bid_id', bidId);

    await _supabase
        .from('Projects')
        .update({'status': 'awaiting_contract'})
        .eq('project_id', projectId);
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
          .update({'status': 'expired'})
          .inFilter('bid_id', losingBidIds);
    }

    await _supabase
        .from('Bids')
        .update({'status': 'accepted'})
        .eq('bid_id', bidWinnerId);
  }

  Future<void> deleteBid(String bidId) async {
    await _supabase
        .from('Bids')
        .delete()
        .eq('bid_id', bidId);
  }

  Future<void> cancelAllProjectBids(String projectId) async {
    await _supabase
        .from('Bids')
        .update({'status': 'cancelled'})
        .eq('project_id', projectId);
  }

  Future<void> updateBidStatus(String bidId, String status) async {
    await _supabase
        .from('Bids')
        .update({'status': status})
        .eq('bid_id', bidId);
  }

  Future<void> acceptBid(String bidId, String projectId, String contractorId) async {
    await updateBidStatus(bidId, 'accepted');

    await _supabase
        .from('Projects')
        .update({
          'contractor_id': contractorId,
          'status': 'in_progress',
        })
        .eq('project_id', projectId);

    await _supabase
        .from('Bids')
        .update({'status': 'rejected'})
        .neq('bid_id', bidId)
        .eq('project_id', projectId);
  }
 
  Future<List<Map<String, dynamic>>> getBidsForProject(String projectId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('''
            *,
            Contractor:contractor_id (
              firm_name,
              rating,
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

  Future<List<Map<String, dynamic>>> getBidsByContractor(String contractorId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('''
            *,
            Projects:project_id (
              type,
              description,
              location,
              status
            )
          ''')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Duration getRemainingBiddingDuration(DateTime createdAt, int durationInDays) {
    final endTime = createdAt.add(Duration(days: durationInDays));
    final now = DateTime.now();
    return endTime.difference(now);
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

  String getFormattedTimeRemaining(DateTime createdAt, int durationInDays) {
    final remaining = getRemainingBiddingDuration(createdAt, durationInDays);
    
    if (remaining.isNegative) {
      return "Expired";
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (days > 0) {
      return "${days}d ${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
  
  bool isValidBidAmount(double bidAmount, double minBudget, double maxBudget) {
    return bidAmount >= minBudget && bidAmount <= maxBudget;
  }
}
