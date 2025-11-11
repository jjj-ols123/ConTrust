import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TorProfileService {
  static Future<Map<String, dynamic>> checkRatingEligibility(
      String contractorId, String contracteeId) async {
    try {
      final projects = await Supabase.instance.client
          .from('Projects')
          .select('project_id, status')
          .eq('contractor_id', contractorId)
          .eq('contractee_id', contracteeId)
          .inFilter('status', ['active', 'completed']);

      if (projects.isNotEmpty) {
        return {
          'canRate': true,
          'hasRated': false,
          'userRating': 0.0,
          'review': null,
        };
      } else {
        return {
          'canRate': false,
          'hasRated': false,
          'userRating': 0.0,
        };
      }
    } catch (e) {
      return {
        'canRate': false,
        'hasRated': false,
        'userRating': 0.0,
      };
    }
  }

  static Future<void> submitRating(
    String contractorId,
    String contracteeId,
    double rating,
    String reviewText,
  ) async {
    try {
      final timestamp = DateTimeHelper.getLocalTimeISOString();
      await Supabase.instance.client.from('ContractorRatings').insert({
        'contractor_id': contractorId,
        'contractee_id': contracteeId,
        'rating': rating,
        'review': reviewText,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await updateContractorAverageRating(contractorId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateContractorAverageRating(String contractorId) async {
    try {
      final ratings = await Supabase.instance.client
          .from('ContractorRatings')
          .select('rating')
          .eq('contractor_id', contractorId);

      if (ratings.isNotEmpty) {
        final totalRating = ratings.fold<double>(
            0, (sum, rating) => sum + (rating['rating'] as num).toDouble());
        final averageRating = totalRating / ratings.length;

        await Supabase.instance.client.from('Contractor').update(
            {'rating': averageRating}).eq('contractor_id', contractorId);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getOrCreateChatRoom({
    required String contractorId,
    required String contracteeId,
  }) async {
    final supabase = Supabase.instance.client;
    final project = await supabase
        .from('Projects')
        .select('project_id')
        .eq('contractor_id', contractorId)
        .eq('contractee_id', contracteeId)
        .order('created_at', ascending: false)
        .maybeSingle();
    final projectId = project?['project_id'];
    if (projectId == null) {
      return null;
    }
    final existingChatroom = await supabase
        .from('ChatRoom')
        .select('chatroom_id')
        .eq('contractor_id', contractorId)
        .eq('contractee_id', contracteeId)
        .eq('project_id', projectId)
        .maybeSingle();
    if (existingChatroom != null) {
      return existingChatroom['chatroom_id'] as String?;
    } else {
      final response = await supabase
          .from('ChatRoom')
          .insert({
            'contractor_id': contractorId,
            'contractee_id': contracteeId,
            'project_id': projectId,
          })
          .select('chatroom_id')
          .single();
      return response['chatroom_id'] as String?;
    }
  }

  static Future<List<Map<String, dynamic>>> getContractorReviews(String contractorId) async {
    final response = await Supabase.instance.client
        .from('ContractorRatings')
        .select('rating, review, created_at, Contractee!inner(full_name)')
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false);

    return (response as List).map((review) => {
      'rating': (review['rating'] as num).toDouble(),
      'review': review['review'],
      'created_at': review['created_at'],
      'client_name': review['Contractee']?['full_name'] ?? 'Anonymous',
    }).toList();
  }
}
