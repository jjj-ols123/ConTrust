// ignore_for_file: unnecessary_type_check

import 'package:backend/services/projectbidding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FetchClass {
  final supabase = Supabase.instance.client;
  final projectbidding = ProjectBidding();

  Future<List<Map<String, dynamic>>> fetchContractors() async {
    try {
      final response = await supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await supabase
          .from('Projects')
          .select(
            'project_id, type, description, duration, min_budget, max_budget, created_at, status',
          )
          .eq('contractee_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, double>> fetchHighestBids() async {
    final highestBidsData = await projectbidding.projectHighestBid();
    return highestBidsData;
  }

  Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      final response = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', contractorId)
          .single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveProjects() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await supabase
          .from('Projects')
          .select(
            'project_id, type, description, duration, min_budget, max_budget, created_at, status, contractee:Contractee(full_name)',
          )
          .eq('contractor_id', userId)
          .eq('status', 'active');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCompletedProjects() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await supabase
          .from('Projects')
          .select('project_id, type, description, status, contractee:Contractee(full_name)')
          .eq('contractor_id', userId)
          .eq('status', 'completed');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
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
  
}
