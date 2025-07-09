import 'package:supabase_flutter/supabase_flutter.dart';

class FetchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchContractors() async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo, bio');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', contractorId)
          .single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('Projects')
          .select(
            'project_id, type, title, description, duration, min_budget, max_budget, created_at, status',
          )
          .eq('contractee_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableProjects() async {
    try {
      final response = await _supabase.from('Projects').select('''
            project_id, 
            type, 
            description, 
            duration, 
            min_budget, 
            max_budget, 
            created_at, 
            status,
            location,
            contractee:Contractee(full_name, profile_photo)
          ''').eq('status', 'pending').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('Projects')
          .select('''
            project_id, 
            type, 
            description, 
            duration, 
            min_budget, 
            max_budget, 
            created_at, 
            status,
            contractee:Contractee(full_name)
          ''')
          .eq('contractor_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCompletedProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('Projects')
          .select('''
            project_id, 
            type, 
            description, 
            status,
            contractee:Contractee(full_name)
          ''')
          .eq('contractor_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchBidsForProject(
      String projectId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('''
            bid_id, 
            contractor_id, 
            bid_amount, 
            message, 
            created_at, 
            status,
            contractor:Contractor(firm_name, profile_photo, rating)
          ''')
          .eq('project_id', projectId)
          .order('bid_amount', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractTypes() async {
    try {
      final response = await _supabase
          .from('ContractTypes')
          .select(
              'contract_type_id, template_name, template_content, template_description')
          .order('template_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCreatedContracts(
      String contractorId) async {
    try {
      final projectsResponse = await _supabase
          .from('Projects')
          .select('project_id')
          .eq('contractor_id', contractorId);

      final projectIds =
          projectsResponse.map((project) => project['project_id']).toList();

      if (projectIds.isEmpty) return [];

      final response = await _supabase
          .from('Contracts')
          .select('''
            contract_id, 
            project_id, 
            contract_type_id, 
            title, 
            content, 
            total_amount, 
            status, 
            created_at, 
            updated_at,
            project:Projects(type, description)
          ''')
          .inFilter('project_id', projectIds)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractorProjectInfo(
      String contractorId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('project_id, contractee_id, description, type, status')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<String?> fetchProjectStatus(String projectId) async {
    try {
      final project = await _supabase
          .from('Projects')
          .select('status')
          .eq('project_id', projectId)
          .maybeSingle();

      return project?['status'];
    } catch (e) {
      return null;
    }
  }
}
