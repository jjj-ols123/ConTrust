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
      'min_budget': int.parse(minBudget),
      'max_budget': int.parse(maxBudget),
      'status': 'pending',
      'duration': int.parse(duration),
      'start_date': startDate,
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
        print('Error inserting data: $e'); // <-- helpful for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inserting data: $e')),
        );
      }
    }
    rethrow;
  }
}


  Future<void> checkContracteeId(String userId) async {
    final response = await _supabase
        .from('Contractee')
        .upsert({'contractee_id': userId}, onConflict: 'contractee_id');

    if (response is PostgrestException) {
      throw response;
    }
  }
}
