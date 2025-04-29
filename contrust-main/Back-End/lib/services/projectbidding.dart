import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, double>> highestBid() async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('Bids')
        .select('project_id, bid_amount');

    Map<String, double> highestBids = {};
 
    if (response.isNotEmpty) {
      for (var bid in response) {
        final projectId = bid['project_id'].toString();
        final bidAmount = double.tryParse(bid['bid_amount'].toString()) ?? 0.0;

        if (!highestBids.containsKey(projectId) || bidAmount > highestBids[projectId]!) {
          highestBids[projectId] = bidAmount;
        }
      }
    }
  
    return highestBids;
  } catch (e) {
      return {};
  }
}

Future<void> finalizeBidding(String projectId) async {
  final supabase = Supabase.instance.client;

  final bids = await supabase
      .from('Bids')
      .select()
      .eq('project_id', projectId)
      .order('amount', ascending: false);

  if (bids.isEmpty) return;

  final bidWinner = bids.first;
  final bidWinnerId = bidWinner['bid_id'];
  final contractorId = bidWinner['contractor_id'];

  final projectResponse =
      await supabase
          .from('Projects')
          .select()
          .eq('project_id', projectId)
          .single();

  if (projectResponse.isEmpty) return;

  await supabase
      .from('Projects')
      .update({
        'status': 'active',
        'accepted_bid_id': bidWinnerId,
        'contractor_id': contractorId,
      })
      .eq('project_id', projectId);

  final losingBidIds = bids.skip(1).map((bid) => bid['id']).toList();
  if (losingBidIds.isNotEmpty) {
    await supabase
      .from('Bids')
      .delete()
      .inFilter('id', losingBidIds);
  }

  await supabase
      .from('Bids')
      .update({'status': 'accepted'})
      .eq('bid_id', bidWinnerId);
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

