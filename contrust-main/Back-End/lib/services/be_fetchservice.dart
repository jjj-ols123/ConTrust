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

  Future<Map<String, dynamic>?> fetchContracteeData(String contracteeId) async {
    try {
      final response = await _supabase
          .from('Contractee')
          .select()
          .eq('contractee_id', contracteeId)
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

  Future<String?> fetchContractorName(String projectId) async {
    final notification = await _supabase
        .from('Notifications')
        .select('information')
        .filter('information->>project_id', 'eq', projectId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return notification?['information']?['firm_name'];
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

  Future<String?> fetchProjectStatus(String chatRoomId) async {
    try {
      final chatRoomResponse = await _supabase
          .from('ChatRoom')
          .select('project_id')
          .eq('chatroom_id', chatRoomId)
          .maybeSingle();

      if (chatRoomResponse == null) {
        return null;
      }

      final projectId = chatRoomResponse['project_id'];

      if (projectId == null) {
        return null;
      }

      final projectResponse = await _supabase
          .from('Projects')
          .select('status, contractor_agree, contractee_agree')
          .eq('project_id', projectId)
          .maybeSingle();

      if (projectResponse == null) {
        return null;
      }

      final status = projectResponse['status'];
      final contractorAgreed = projectResponse['contractor_agree'] ?? false;
      final contracteeAgreed = projectResponse['contractee_agree'] ?? false;

      if (status == 'awaiting_contract' &&
          contractorAgreed &&
          contracteeAgreed) {
        return 'active';
      }

      return status;
    } catch (e) {
      return null;
    }
  }

  Future<String?> fetchChatRoomId(String projectId) async {
    final response = await _supabase
        .from('ChatRoom')
        .select('chatroom_id')
        .eq('project_id', projectId)
        .maybeSingle();
    return response?['chatroom_id'];
  }

  Future<Map<String, dynamic>?> fetchActiveProject(String contractorId) async {
    final response = await Supabase.instance.client
        .from('Projects')
        .select()
        .eq('contractor_id', contractorId)
        .eq('status', 'active')
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> fetchContractData(String contractId) async {
    final contract = await _supabase
        .from('Contracts')
        .select()
        .eq('contract_id', contractId)
        .single();
    return contract;
  }

  Future<List<Map<String, dynamic>>> fetchHiringRequestsForProject(
      String projectId) async {
    final response = await _supabase
        .from('Notifications')
        .select('receiver_id, information, headline')
        .eq('headline', 'Hiring Request')
        .filter('information->>project_id', 'eq', projectId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, String>> userTypeDecide({
    required String contractId,
    required String userType,
    required String action,
  }) async {
    final contract = await fetchContractData(contractId);

    String receiverId, receiverType, senderId, senderType, message;
    if (userType == 'contractor') {
      receiverId = contract?['contractee_id'];
      receiverType = 'contractee';
      senderId = contract?['contractor_id'];
      senderType = 'contractor';
      message = 'The $userType has $action';
    } else {
      receiverId = contract?['contractor_id'];
      receiverType = 'contractor';
      senderId = contract?['contractee_id'];
      senderType = 'contractee';
      message = 'The $userType has $action';
    }
    return {
      'receiverId': receiverId,
      'receiverType': receiverType,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
    };
  }

  Future<List<Map<String, dynamic>>> fetchProjectTasks(String projectId) async {
    try {
      final response = await _supabase
          .from('projecttasks')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectReports(
      String projectId) async {
    try {
      final response = await _supabase
          .from('projectreports')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectPhotos(
      String projectId) async {
    try {
      final response = await _supabase
          .from('projectphotos')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectCosts(String projectId) async {
    try {
      final response = await _supabase
          .from('projectcosts')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchProjectDetails(String projectId) async {
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
}
