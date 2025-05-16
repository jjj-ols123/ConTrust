// ignore_for_file: unnecessary_type_check

import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectBidding {
  final supabase = Supabase.instance.client;

  Future<Map<String, double>> highestBid() async {
    try {
      final response = await supabase
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

  Future<List<Map<String, dynamic>>> fetchBids(String projectId) async {
    final response = await supabase
        .from('Bids')
        .select(
            'bid_id, contractor_id, bid_amount, message, created_at, contractor:Contractor(firm_name, profile_photo)')
        .eq('project_id', projectId)
        .order('bid_amount', ascending: false);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<void> durationBidding(String projectId) async {
    final bids = await supabase
        .from('Bids')
        .select()
        .eq('project_id', projectId)
        .order('amount', ascending: false);

    if (bids.isEmpty) return;

    final bidWinner = bids.first;
    final bidWinnerId = bidWinner['bid_id'];
    final contractorId = bidWinner['contractor_id'];

    final projectResponse = await supabase
        .from('Projects')
        .select()
        .eq('project_id', projectId)
        .single();

    if (projectResponse.isEmpty) return;

    await supabase.from('Projects').update({
      'status': 'active',
      'bid_id': bidWinnerId,
      'contractor_id': contractorId,
    }).eq('project_id', projectId);

    final losingBidIds = bids.skip(1).map((bid) => bid['bid_id']).toList();
    if (losingBidIds.isNotEmpty) {
      await supabase.from('Bids').delete().inFilter('bid_id', losingBidIds);
    }

    await supabase
        .from('Bids')
        .update({'status': 'active'}).eq('bid_id', bidWinnerId);
  }

  Future<void> acceptBidding(String projectId, String bidId) async {
    final bidResponse =
        await supabase
          .from('Bids')
          .select()
          .eq('bid_id', bidId)
          .single();

    if (bidResponse.isEmpty) return;

    final contractorId = bidResponse['contractor_id'];

    final projectResponse = await supabase
        .from('Projects')
        .select()
        .eq('project_id', projectId)
        .single();

    if (projectResponse.isEmpty) return;

    await supabase.from('Projects')
      .update({
        'status': 'active',
        'bid_id': bidId,
        'contractor_id': contractorId,
      }).eq('project_id', projectId);

    final allBids =
        await supabase
          .from('Bids')
          .select()
          .eq('project_id', projectId);

    final losingBidIds = allBids
        .where((bid) => bid['bid_id'] != bidId)
        .map((bid) => bid['bid_id'])
        .toList();

    if (losingBidIds.isNotEmpty) {
      await supabase.from('Bids').delete().inFilter('bid_id', losingBidIds);
    }

    await supabase
        .from('Projects')
        .update({'status': 'active'})
        .eq('bid_id', bidId);
  }

Future<void> deleteBid(String bidId) async {
    await supabase
      .from('Bids')
      .delete()
      .eq('bid_id', bidId);
}

  Duration getRemainingDuration(DateTime createdAt, int durationInDays) {
    final endTime = createdAt.add(Duration(days: durationInDays));
    final now = DateTime.now();
    return endTime.difference(now);
  }

  Stream<Duration> countdownStream(
    DateTime createdAt,
    int durationInDays,
  ) async* {
    final endTime = createdAt.add(Duration(days: durationInDays));
    while (true) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);
      if (remaining.isNegative) break;
      yield remaining;
      await Future.delayed(Duration(seconds: 1));
    }
  }
}
