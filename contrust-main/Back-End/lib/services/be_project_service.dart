import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/be_user_service.dart';

class ProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<void> postProject({
    required String contracteeId,
    required String title, 
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
      await _userService.checkContracteeId(contracteeId);

      await _supabase.from('Projects').upsert({
        'contractee_id': contracteeId,
        'type': type,
        'title': title,  
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inserting data')),
          );
        }
      }
      rethrow;
    }
  }

  Future<void> updateProjectStatus(String projectId, String status) async {
    await _supabase
        .from('Projects')
        .update({'status': status})
        .eq('project_id', projectId);
  }


  Future<Map<String, dynamic>?> getProjectDetails(String projectId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('*')
          .eq('project_id', projectId)
          .single();
      return response;
    } catch (error) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsByContractee(String contracteeId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('*')
          .eq('contractee_id', contracteeId);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      return [];
    }
  }

  Future<void> finalizeContractAgreement({
    required String projectId,
    required String contractId,
    required String contractTypeId,
    required String contracteeId,
    required String contractorId,
    required Map<String, dynamic> terms,
    required String contracteeSignature,
    required String contractorSignature,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase
        .from('Projects')
        .update({'status': 'active'})
        .eq('project_id', projectId);

    await _supabase
        .from('Contracts')
        .update({
          'status': 'active',
          'contractee_signature': contracteeSignature,
          'contractor_signature': contractorSignature,
          'signed_at': now,
          'updated_at': now,
          'terms': terms,
        })
        .eq('contract_id', contractId);

    await _supabase
        .from('ContractDetails')
        .update({'contract_type_id': contractTypeId})
        .eq('contract_id', contractId);

    await _supabase
        .from('ContractTypes')
        .update({'updated_at': now})
        .eq('contract_type_id', contractTypeId);
  }

  Future<void> completeProject(String projectId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    await _supabase
        .from('Projects')
        .update({
          'status': 'completed',
          'completed_at': now,
        })
        .eq('project_id', projectId);
  }

  Future<void> cancelProject(String projectId, String reason) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    await _supabase
        .from('Projects')
        .update({
          'status': 'cancelled',
          'cancelled_at': now,
          'cancellation_reason': reason,
        })
        .eq('project_id', projectId);
  }

  Future<String?> getProjectId(String chatRoomId) async {
    final chatRoom = await _supabase
        .from('ChatRoom')
        .select('project_id')
        .eq('chatroom_id', chatRoomId)
        .maybeSingle();
    return chatRoom?['project_id'];
  }
}
