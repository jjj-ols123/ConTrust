import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class FetchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  //For Contractees

  Future<List<Map<String, dynamic>>> fetchContractors() async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo, bio, rating');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractors: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractors',
        },
      );
      return [];
    }
  }

  Future<String?> fetchChatRoomId(String projectId) async {
    try {
      final response = await _supabase
          .from('ChatRoom')
          .select('chatroom_id')
          .eq('project_id', projectId)
          .maybeSingle();
      return response?['chatroom_id'];
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch chat room ID: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Chat Room ID',
          'project_id': projectId,
        },
      );
      return null;
    }
  }

  //For Both Users

  Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, specialization, bio, past_projects, contact_number, profile_photo, created_at, address, verified, rating')
          .eq('contractor_id', contractorId)
          .limit(1)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor data: ${e.toString()}',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Data',
          'contractor_id': contractorId,
        },
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchContractorDataByName(String contractorName) async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, specialization, bio, past_projects, contact_number, profile_photo, created_at, address, verified, rating')
          .eq('firm_name', contractorName)
          .limit(1)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor data by name: ${e.toString()}',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Data By Name',
          'contractor_name': contractorName,
        },
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchContracteeData(String contracteeId) async {
    try {
      final response = await _supabase
          .from('Contractee')
          .select('contractee_id, address, project_history_count, created_at, full_name, profile_photo, phone_number')
          .eq('contractee_id', contracteeId)
          .limit(1)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractee data: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractee Data',
          'contractee_id': contracteeId,
        },
      );
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
            'project_id, type, title, description, duration, min_budget, max_budget, created_at, status, start_date, location',
          )
          .eq('contractee_id', userId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch user projects: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch User Projects',
        },
      );
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
          .select('status')
          .eq('project_id', projectId)
          .maybeSingle();

      if (projectResponse == null) {
        return null;
      }

      final status = projectResponse['status'];

      return status;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project status: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Status',
          'chatroom_id': chatRoomId,
        },
      );
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
      await _errorService.logError(
        errorMessage: 'Failed to fetch project tasks: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Tasks',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectReports(
      String projectId) async {
    try {
      final response = await _supabase
          .from('ProjectReports')
          .select('report_id, project_id, content, author_id, created_at')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project reports:',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Reports',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectPhotos(
      String projectId) async {
    try {
      final response = await _supabase
          .from('ProjectPhotos')
          .select('photo_id, project_id, photo_url, uploader_id, created_at')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project photos:',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Photos',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectCosts(String projectId) async {
    try {
      final response = await _supabase
          .from('ProjectMaterials')
          .select('material_id, project_id, contractor_id, material_name, brand, unit, quantity, unit_price, notes, created_at')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project costs: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Costs',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchProjectDetails(String projectId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('project_id, contractee_id, contractor_id, title, type, description, location, min_budget, max_budget, status, duration, start_date, created_at, estimated_completion, contract_id, progress, projectdata')
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .maybeSingle();

      return response;
    } catch (error) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project details: $error',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Details',
          'project_id': projectId,
        },
      );
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
          .select('project_id, contractee_id, contractor_id, title, type, description, location, min_budget, max_budget, status, duration, start_date, created_at, estimated_completion, contract_id, progress, projectdata')
          .eq('project_id', projectId)
          .maybeSingle();

      return projectResponse;
    } catch (error) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project details by chat room: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Details by Chat Room',
          'chatroom_id': chatRoomId,
        },
      );
      return null;
    }
  }

  Future<Map<String, String>> userTypeDecide({
    required String contractId,
    required String userType,
    required String action,
  }) async {
    try {
      final contract = await fetchContractData(contractId);
      final projectId = contract?['project_id'];

      String receiverId, receiverType, senderId, senderType, message;
      String? senderName, projectTitle;

      if (userType == 'contractor') {
        receiverId = contract?['contractee_id'];
        receiverType = 'contractee';
        senderId = contract?['contractor_id'];
        senderType = 'contractor';

        final contractor = await _supabase
            .from('Contractor')
            .select('firm_name')
            .eq('contractor_id', senderId)
            .maybeSingle();
        senderName = contractor?['firm_name'] ?? 'Contractor';

        message = '$senderName has $action the contract';
      } else {
        receiverId = contract?['contractor_id'];
        receiverType = 'contractor';
        senderId = contract?['contractee_id'];
        senderType = 'contractee';

        final contractee = await _supabase
            .from('Contractee')
            .select('full_name')
            .eq('contractee_id', senderId)
            .maybeSingle();
        senderName = contractee?['full_name'] ?? 'Contractee';

        message = '$senderName has $action the contract';
      }

      if (projectId != null) {
        final project = await _supabase
            .from('Projects')
            .select('title')
            .eq('project_id', projectId)
            .maybeSingle();
        projectTitle = project?['title'];
        if (projectTitle != null) {
          message += ' for "$projectTitle"';
        }
      }

      return {
        'receiverId': receiverId,
        'receiverType': receiverType,
        'senderId': senderId,
        'senderType': senderType,
        'message': message,
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to decide user type: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'User Type Decide',
          'contract_id': contractId,
          'user_type': userType,
        },
      );
      rethrow;
    }
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
      await _errorService.logError(
        errorMessage: 'Failed to fetch completed projects: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Completed Projects',
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractTypes() async {
    try {
      final response = await _supabase
          .from('ContractTypes')
          .select(
              'contract_type_id, template_name, template_description')
          .order('template_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contract types: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contract Types',
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCreatedContracts(
      String contractorId) async {
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
            field_values,
            project:Projects!Contracts_project_id_fkey(type, description, title)
          ''')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch created contracts: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Created Contracts',
          'contractor_id': contractorId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractorProjectInfo(
      String contractorId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('project_id, title, type, description, duration, min_budget, max_budget, created_at, status, start_date, location')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

     final projects = List<Map<String, dynamic>>.from(response);
      
      projects.sort((a, b) {
        final statusA = a['status']?.toString().toLowerCase() ?? '';
        final statusB = b['status']?.toString().toLowerCase() ?? '';
        
        if (statusA == 'active' && statusB != 'active') return -1;
        if (statusA != 'active' && statusB == 'active') return 1;
        
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      return projects;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor project info: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Project Info',
          'contractor_id': contractorId,
        },
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchContractData(
    String contractId, {
    String? contractorId,
    String? contracteeId,
  }) async {
    try {
      final query = _supabase
          .from('Contracts')
          .select('contract_id, contractor_id, contractee_id, project_id, status, title, pdf_url, created_at, updated_at')
          .eq('contract_id', contractId);
      
      if (contractorId != null) {
        query.eq('contractor_id', contractorId);
      } else if (contracteeId != null) {
        query.eq('contractee_id', contracteeId);
      }
      
      final contract = await query.single();
      return contract;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contract data: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contract Data',
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchHiringRequestsForProject(
      String projectId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select('receiver_id, information, headline')
          .eq('headline', 'Hiring Request')
          .filter('information->>project_id', 'eq', projectId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch hiring requests for project: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Hiring Requests for Project',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchContracteeFromProject(
      String projectId) async {
    try {
      final response = await _supabase.from('Projects').select('''
          contractee_id,
          contractee:Contractee(
            full_name,
            profile_photo,
            contractee_id
          )
        ''').eq('project_id', projectId).single();

      return response['contractee'];
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractee from project: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractee from Project',
          'project_id': projectId,
        },
      );
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
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor active projects: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Active Projects',
          'contractor_id': contractorId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContracteeActiveProjects(String contracteeId) async {
    try {
      final res = await _supabase
          .from('Projects')
          .select('project_id,title,status')
          .eq('contractee_id', contracteeId)
          .inFilter('status', ['active', 'ongoing'])  
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractee active projects: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractee Active Projects',
          'contractee_id': contracteeId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRatings(String contractorId) async {
    try {
      final response = await _supabase
          .from('ContractorRatings')
          .select('rating, review, created_at, contractee_id')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch ratings: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Ratings',
          'contractor_id': contractorId,
        },
      );
      return [];
    }
  }

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
            contractor:Contractor(firm_name, profile_photo)  
          ''')
          .eq('contractee_id', contracteeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contracts for contractee: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contracts for Contractee',
          'contractee_id': contracteeId,
        },
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchContractWithDetails(
    String contractId, {
    String? contractorId,
    String? contracteeId,
  }) async {
    try {
      final query = _supabase
          .from('Contracts')
          .select('''
            contract_id, contractor_id, contractee_id, project_id, contract_type_id,
            title, status, created_at, updated_at, sent_at, reviewed_at,
            contractor_signature_url, contractee_signature_url,
            contractor_signed_at, contractee_signed_at,
            pdf_url, signed_pdf_url, field_values,
            project:Projects(project_id, type, description, title),
            contractor:Contractor(contractor_id, firm_name, profile_photo),  
            contractee:Contractee(contractee_id, full_name, profile_photo),
            contract_type:ContractTypes(contract_type_id, template_name, template_description)
          ''')
          .eq('contract_id', contractId);
        
      if (contractorId != null) {
        query.eq('contractor_id', contractorId);
      } else if (contracteeId != null) {
        query.eq('contractee_id', contracteeId);
      }
      
      final response = await query.single();

      return response;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contract with details: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contract with Details',
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      return null;
    }
  }

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
      await _errorService.logError(
        errorMessage: 'Failed to check existing hire request: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Has Existing Hire Request',
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractsForProject(
    String projectId, {
    String? contractorId,
    String? contracteeId,
  }) async {
    try {
      final query = _supabase
          .from('Contracts')
          .select('''
            contract_id, contractor_id, contractee_id, project_id, title, status, created_at, updated_at, pdf_url,
            contractee:Contractee(contractee_id, full_name, profile_photo)
          ''')
          .eq('project_id', projectId);
      
      if (contractorId != null || contracteeId != null) {
        final projectQuery = _supabase
            .from('Projects')
            .select('contractor_id, contractee_id')
            .eq('project_id', projectId);
        
        final project = await projectQuery.single();
        
        final isOwner = (contractorId != null && project['contractor_id'] == contractorId) ||
                       (contracteeId != null && project['contractee_id'] == contracteeId);
        
        if (!isOwner) {
          throw Exception('Unauthorized: User does not own this project');
        }
      }
      
      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contracts for project: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contracts for Project',
          'project_id': projectId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
      return [];
    }
  }
}