import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/getuserdata.dart';

class EnterDatatoDatabase {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GetUserData _getUserData = GetUserData();

  Future<void> postProject({
    required String contracteeId,
    required String type,
    required String description,
    required String location,
    required String minBudget,
    required String maxBudget,
    required String duration,
    required DateTime startDate,
    required BuildContext context,
  }) async {
    try {

      await _getUserData.checkContracteeId(contracteeId);

      await _supabase.from('Projects').upsert({
        'contractee_id': contracteeId,
        'type': type,
        'description': description,
        'location': location,
        'min_budget': minBudget,
        'max_budget': maxBudget,
        'status': 'pending',
        'duration': duration,
        'start_date': startDate.toIso8601String(),
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
    required num bidAmount,
    required String message,
    required BuildContext context,
  }) async {
    try {
      await _getUserData.checkContractorId(contractorId);

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
}
