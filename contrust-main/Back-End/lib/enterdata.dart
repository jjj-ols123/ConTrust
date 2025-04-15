import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnterDatatoDatabase {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> postProject({
    required String contracteeId,
    required String type,
    required String description,
    required String location,
    required String minBudget,
    required String maxBudget,
    required String duration,
    required String startDate,
    required BuildContext context,
  }) async {
    try {

      await checkContracteeId(contracteeId);

      await _supabase.from('Projects').upsert({
        'contractee_id': contracteeId,
        'type': type,
        'description': description,
        'location': location,
        'min_budget': minBudget,
        'max_budget': maxBudget,
        'status': 'pending',
        'duration': duration,
        'start_date': DateTime.parse(startDate),
      }, onConflict: 'contractee_id');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e is PostgrestException &&
            e.code == '23505' &&
            e.message.contains('unique_contractee_id')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only post one project')),
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

  Future<void> postBid({
    required String contractorId,
    required String projectId,
    required String bidAmount,
    required String message,
    required BuildContext context,
  }) async {
    try {
      await checkContractorId(contractorId);

      await _supabase.from('Bids').upsert({
        'contractor_id': contractorId,
        'project_id': projectId,
        'bid_amount': bidAmount,
        'message': message,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid created successfully!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        print('Error inserting data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inserting data: $e')),
        );
      }
      rethrow;
    }
  }

  Future<void> checkContracteeId(String userId) async {
    final response = await _supabase
        .from('Contractee')
        .select()
        .eq('contractee_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Contractee not found');
    }
  }

   Future<void> checkContractorId(String userId) async {
    final response = await _supabase
        .from('Contractor')
        .select()
        .eq('contractor_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Contractor not found');
    }
  }
}
