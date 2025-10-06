import 'package:supabase_flutter/supabase_flutter.dart';

class FetchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //For Contractees

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

  Future<String?> fetchChatRoomId(String projectId) async {
    final response = await _supabase
        .from('ChatRoom')
        .select('chatroom_id')
        .eq('project_id', projectId)
        .maybeSingle();
    return response?['chatroom_id'];
  }

  //For Both Users

  Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('*')
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
          .select('*')
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

  Future<List<Map<String, dynamic>>> fetchProjectTasks(String projectId) async {
    try {
      final response = await _supabase
          .from('ProjectTasks')
          .select('task_id, project_id, task, done, created_at')
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
          .from('ProjectReports')
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
          .from('ProjectPhotos')
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
          .from('ProjectMaterials')
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
          .maybeSingle()
          .order('created_at', ascending: false);

      return response;
    } catch (error) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProjectDetailsByChatRoom(String chatRoomId) async {
    try {
      final chatRoomResponse = await _supabase
          .from('ChatRoom')
          .select('project_id')
          .eq('chatroom_id', chatRoomId)
          .maybeSingle();

      if (chatRoomResponse == null || chatRoomResponse['project_id'] == null) {
        return null;
      }

      final projectId = chatRoomResponse['project_id'];

      final projectResponse = await _supabase
          .from('Projects')
          .select('*')
          .eq('project_id', projectId)
          .maybeSingle();

      return projectResponse;
    } catch (error) {
      return null;
    }
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

  //For Contractors

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
            pdf_url, 
            status, 
            created_at, 
            updated_at,
            sent_at,
            reviewed_at,
            contractor_signed_at,
            contractee_signed_at,
            project:Projects(type, description, title)
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
          .select('*')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      return [];
    }
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

  Future<Map<String, dynamic>?> fetchContracteeFromProject(
      String projectId) async {
    try {
      final response = await _supabase.from('Projects').select('''
          contractee_id,
          contractee:"Contractee"(
            full_name,
            profile_photo,
            contractee_id
          )
        ''').eq('project_id', projectId).single();

      return response['contractee'];
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractorActiveProjects(String contractorId) async {
    try {
      final res = await _supabase
          .from('Projects')
          .select('project_id,title,status')
          .eq('contractor_id', contractorId)
          .inFilter('status', ['active', 'ongoing'])
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRatings(String contractorId) async {
    try {
      final response = await Supabase.instance.client
          .from('ContractorRatings')
          .select('rating, review, created_at, contractee_id')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  // Contract-specific fetch methods for PDF system

  Future<List<Map<String, dynamic>>> fetchContractsForContractee(
      String contracteeId) async {
    try {
      final response = await _supabase
          .from('Contracts')
          .select('''
            contract_id,
            project_id,
            contract_type_id,
            title,
            pdf_url,
            status,
            created_at,
            updated_at,
            sent_at,
            reviewed_at,
            contractor_signed_at,
            contractee_signed_at,
            project:Projects(type, description, title),
            contractor:Projects!inner(contractor_id, contractor:Contractor(firm_name, profile_photo))
          ''')
          .eq('contractee_id', contracteeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchContractWithDetails(String contractId) async {
    try {
      final response = await _supabase
          .from('Contracts')
          .select('''
            *,
            project:Projects(*),
            contractor:Projects!inner(contractor:Contractor(*)),
            contractee:Contractee(*),
            contract_type:ContractTypes(*)
          ''')
          .eq('contract_id', contractId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Helper method to check for existing hire requests
  Future<Map<String, dynamic>?> hasExistingHireRequest(
      String contractorId, String contracteeId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select('notification_id, information')
          .eq('headline', 'Hiring Request')
          .eq('receiver_id', contractorId)
          .eq('sender_id', contracteeId)
          .filter('information->>status', 'eq', 'pending')
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}