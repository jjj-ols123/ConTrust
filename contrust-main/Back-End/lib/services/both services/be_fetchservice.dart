import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class FetchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  //For Contractees

  Future<List<Map<String, dynamic>>> fetchContractors({String? projectType}) async {
    try {
      final query = _supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo, bio, rating, specialization')
          .eq('verified', true);
      
      if (projectType != null && projectType.isNotEmpty) {
        final response = await query;
        final allContractors = List<Map<String, dynamic>>.from(response);
      
        final scoredContractors = allContractors.map((contractor) {
          final specs = contractor['specialization'];
          int matchScore = 0;
          
          if (specs != null) {
            List<String> specList = [];
            if (specs is List) {
              specList = specs.map((e) => e.toString().toLowerCase()).toList();
            } else if (specs is String) {
              specList = [specs.toLowerCase()];
            }
            
            final projectTypeLower = projectType.toLowerCase();
            
            if (specList.contains(projectTypeLower)) {
              matchScore = 10;
            } else {
              for (String spec in specList) {
                if (spec.contains(projectTypeLower) || projectTypeLower.contains(spec)) {
                  matchScore = 5;
                  break;
                }
              }
            }
          }
          
          return {
            ...contractor,
            '_matchScore': matchScore,
          };
        }).toList();
        
        double parseRating(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          final parsed = double.tryParse(value.toString());
          return parsed ?? 0.0;
        }

        scoredContractors.sort((a, b) {
          final scoreA = a['_matchScore'] as int;
          final scoreB = b['_matchScore'] as int;
          
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          }
          
          final ratingA = parseRating(a['rating']);
          final ratingB = parseRating(b['rating']);
          return ratingB.compareTo(ratingA);
        });
        
        return scoredContractors;
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractors: $e',
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
        errorMessage: 'Failed to fetch chat room ID: $e',
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

  Future<List<String>> fetchAllContractorSpecializations() async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('specialization');
      
      Set<String> uniqueSpecializations = {};
      
      for (var contractor in response) {
        final specs = contractor['specialization'];
        if (specs != null) {
          if (specs is List) {
            for (var spec in specs) {
              if (spec != null && spec.toString().trim().isNotEmpty) {
                uniqueSpecializations.add(spec.toString().trim());
              }
            }
          } else if (specs is String && specs.trim().isNotEmpty) {
            uniqueSpecializations.add(specs.trim());
          }
        }
      }
      
      final sortedSpecs = uniqueSpecializations.toList()..sort();
      return sortedSpecs;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor specializations: ${e.toString()}',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch All Contractor Specializations',
        },
      );
      return [];
    }
  }

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
            'project_id, type, title, description, duration, min_budget, max_budget, created_at, status, start_date, location, projectdata',
          )
          .eq('contractee_id', userId)
          .neq('status', 'cancelled')
          .neq('status', 'stopped')
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
      final response = await _supabase
          .from('ChatRoom')
          .select('''
            project_id,
            project:Projects(status)
          ''')
          .eq('chatroom_id', chatRoomId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final project = response['project'];
      if (project == null) {
        return null;
      }

      final status = project['status'] as String?;
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
          .select('task_id, project_id, task, done, created_at, task_done, expect_finish, expect_finish')
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
          .select('report_id, project_id, content, author_id, created_at, pdf_url, period_type, title')
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
          .select('photo_id, project_id, photo_url, uploader_id, description, created_at')
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

  Stream<List<Map<String, dynamic>>> streamCreatedContracts(
      String contractorId) {
    try {
      return _supabase
          .from('Contracts')
          .stream(primaryKey: ['contract_id'])
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false)
          .asyncMap((List<Map<String, dynamic>> contracts) async {
            final enrichedContracts = <Map<String, dynamic>>[];
            
            if (contracts.isEmpty) {
              return enrichedContracts;
            }
            
            final projectIds = contracts
                .map((c) => c['project_id'] as String?)
                .where((id) => id != null && id.isNotEmpty)
                .toSet()
                .toList();
            
            final Map<String, Map<String, dynamic>> projectInfoMap = {};
            if (projectIds.isNotEmpty) {
              try {
                final projects = await _supabase
                    .from('Projects')
                    .select('project_id, type, description, title')
                    .inFilter('project_id', projectIds);
                
                for (var project in projects) {
                  projectInfoMap[project['project_id']] = {
                    'type': project['type'],
                    'description': project['description'],
                    'title': project['title'],
                  };
                }
              } catch (e) {
                // If batch fetch fails, projectInfoMap remains empty
              }
            }
            
            for (final contract in contracts) {
              final projectId = contract['project_id'] as String?;
              final enrichedContract = Map<String, dynamic>.from(contract);
              
              if (projectId != null && projectInfoMap.containsKey(projectId)) {
                enrichedContract['project'] = projectInfoMap[projectId];
              } else {
                enrichedContract['project'] = null;
              }
              
              enrichedContracts.add(enrichedContract);
            }
            
            return enrichedContracts;
          });
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream created contracts: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Created Contracts',
          'contractor_id': contractorId,
        },
      );
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> streamCompletedProjects() {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Stream.value([]);

      return _supabase
          .from('Projects')
          .stream(primaryKey: ['contractor_id', 'project_id'])
          .handleError((error) {
            _errorService.logError(
              errorMessage: 'Realtime stream error for completed projects: $error',
              module: 'Fetch Service',
              severity: 'Medium',
              extraInfo: {'user_id': userId, 'error_type': error.runtimeType.toString()},
            );
          })
          .map((List<Map<String, dynamic>> projects) {
            return projects.where((project) => 
              project['contractor_id'] == userId && 
              project['status'] == 'completed'
            ).toList()..sort((a, b) {
              final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
              final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });
          })
          .asyncMap((List<Map<String, dynamic>> projects) async {
            final enrichedProjects = <Map<String, dynamic>>[];
            
            final contracteeIds = projects
                .map((p) => p['contractee_id'] as String?)
                .where((id) => id != null && id.isNotEmpty)
                .toSet()
                .toList();
            
            final Map<String, Map<String, dynamic>> contracteeInfoMap = {};
            if (contracteeIds.isNotEmpty) {
              try {
                final contractees = await _supabase
                    .from('Contractee')
                    .select('contractee_id, full_name')
                    .inFilter('contractee_id', contracteeIds);
                
                for (var contractee in contractees) {
                  contracteeInfoMap[contractee['contractee_id']] = {
                    'full_name': contractee['full_name'],
                  };
                }
              } catch (e) {
                //
              }
            }
            
            for (final project in projects) {
              final contracteeId = project['contractee_id'] as String?;
              final enrichedProject = Map<String, dynamic>.from(project);
              
              if (contracteeId != null && contracteeInfoMap.containsKey(contracteeId)) {
                enrichedProject['contractee'] = contracteeInfoMap[contracteeId];
              } else {
                enrichedProject['contractee'] = null;
              }
              
              enrichedProjects.add(enrichedProject);
            }
            
            return enrichedProjects;
          });
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream completed projects: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Completed Projects',
        },
      );
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> streamContractorActiveProjects(String contractorId) {
    try {

      return _supabase
          .from('Projects')
          .stream(primaryKey: ['contractor_id', 'project_id'])
          .handleError((error) {
            _errorService.logError(
              errorMessage: 'Realtime stream error for active projects: $error',
              module: 'Fetch Service',
              severity: 'Medium',
              extraInfo: {'contractor_id': contractorId, 'error_type': error.runtimeType.toString()},
            );
          })
          .map((List<Map<String, dynamic>> projects) {
            return projects.where((project) => 
              project['contractor_id'] == contractorId && 
              (project['status'] == 'active' || project['status'] == 'ongoing')
            ).toList()..sort((a, b) {
              final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
              final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });
          });
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream contractor active projects: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Contractor Active Projects',
          'contractor_id': contractorId,
        },
      );
      return Stream.value([]);
    }
  }

  Stream<Map<String, dynamic>> streamProjectData(String projectId) {
    try {
      return _supabase
          .from('Projects')
          .stream(primaryKey: ['project_id'])
          .map((List<Map<String, dynamic>> projects) {
            final project = projects.firstWhere(
              (p) => p['project_id'] == projectId,
              orElse: () => <String, dynamic>{},
            );
            return project;
          })
          .where((project) => project.isNotEmpty);
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream project data: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Project Data',
          'project_id': projectId,
        },
      );
      return Stream.value(<String, dynamic>{});
    }
  }

  Stream<List<Map<String, dynamic>>> streamBiddingProjects() {
    try {
      return _supabase
          .from('Projects')
          .stream(primaryKey: ['project_id'])
          .map((List<Map<String, dynamic>> projects) {
            final filtered = projects.where((project) {
              final status = project['status'];
              if (status != 'pending' && status != 'open') {
                return false;
              }

              // Only include true bidding projects
              final projectData = project['projectdata'] as Map<String, dynamic>?;
              final hiringType = projectData?['hiring_type'] ?? 'bidding';
              if (hiringType == 'direct_hire') {
                return false;
              }

              return true;
            }).toList();

            final withPhotoUrls = filtered.map((p) {
              final project = Map<String, dynamic>.from(p);
              final dynamic raw = project['photo_url'];
              if (raw != null && raw.toString().isNotEmpty) {
                final rawString = raw.toString();
                if (rawString.startsWith('data:') || rawString.startsWith('http')) {
                  project['photo_url'] = rawString;
                } else {
                  try {
                    // Convert storage path to public URL
                    project['photo_url'] = _supabase.storage
                        .from('projectphotos')
                        .getPublicUrl(rawString);
                  } catch (_) {
                    // If conversion fails, try to use as-is or set to empty
                    project['photo_url'] = rawString;
                  }
                }
              } else {
                project['photo_url'] = null;
              }
              return project;
            }).toList();

            withPhotoUrls.sort((a, b) {
              final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
              final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });

            return withPhotoUrls;
          });
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream bidding projects: ',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Bidding Projects',
        },
      );
      return Stream.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractorProjectInfo(
      String contractorId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('project_id, title, type, description, duration, min_budget, max_budget, created_at, status, start_date, location, projectdata, contractee_id')
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
          .select('contract_id, contractor_id, contractee_id, project_id, status, title, pdf_url, created_at, updated_at, field_values')
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
          .select('receiver_id, sender_id, information, headline')
          .eq('headline', 'Hiring Request')
          .filter('information->>project_id', 'eq', projectId);

      final requests = List<Map<String, dynamic>>.from(response);

      final contractorIds = requests
          .map((r) => r['receiver_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      
      final Map<String, String> emailMap = {};
      if (contractorIds.isNotEmpty) {
        try {
          final users = await _supabase
              .from('Users')
              .select('users_id, email')
              .inFilter('users_id', contractorIds);
          
          for (var user in users) {
            emailMap[user['users_id']] = user['email'] ?? '';
          }
        } catch (e) {
          await _errorService.logError(
            errorMessage: 'Error batch fetching contractor emails for hiring requests: $e',
            module: 'Fetch Service',
            severity: 'Low',
            extraInfo: {
              'operation': 'Batch Fetch Contractor Emails for Hiring Requests',
              'contractor_ids': contractorIds,
            },
          );
        }
      }
      
      // Add contractor email to each request's information
      for (var request in requests) {
        final contractorId = request['receiver_id'] as String?;
        if (contractorId != null && emailMap.containsKey(contractorId)) {
          final info = Map<String, dynamic>.from(request['information'] ?? {});
          info['email'] = emailMap[contractorId];
          request['information'] = info;
        }
      }
      
      return requests;
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

  Future<List<Map<String, dynamic>>> fetchContractorCompletedProjects(String contractorId) async {
    try {
      final res = await _supabase
          .from('Projects')
          .select('project_id,title,status')
          .eq('contractor_id', contractorId)
          .eq('status', 'completed') 
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor completed projects: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Completed Projects',
          'contractor_id': contractorId,
        },
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContractorProjectsIncludingCompleted(String contractorId) async {
    try {
      final res = await _supabase
          .from('Projects')
          .select('project_id,title,status')
          .eq('contractor_id', contractorId)
          .inFilter('status', ['active', 'ongoing', 'completed']) 
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contractor projects including completed: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Projects Including Completed',
          'contractor_id': contractorId,
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
R            project:Projects!Contracts_project_id_fkey(project_id, type, description, title),
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

  Stream<List<Map<String, dynamic>>> streamContractsForProject(String projectId) {
    try {
      return _supabase
          .from('Contracts')
          .stream(primaryKey: ['contract_id'])
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .map((rows) => List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream contracts for project: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Contracts For Project',
          'project_id': projectId,
        },
      );
      return Stream.value([]);
    }
  }

  Stream<Map<String, dynamic>?> streamContractById(String contractId) {
    try {
      return _supabase
          .from('Contracts')
          .stream(primaryKey: ['contract_id'])
          .eq('contract_id', contractId)
          .map((rows) {
            if (rows.isEmpty) return null;
            return Map<String, dynamic>.from(rows.first);
          });
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to stream contract by id: $e',
        module: 'Fetch Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Stream Contract By Id',
          'contract_id': contractId,
        },
      );
      return Stream.value(null);
    }
  }

  Stream<List<Map<String, dynamic>>> streamProjectMaterials(String contractorId) {
    try {
      return _supabase
          .from('ProjectMaterials')
          .stream(primaryKey: ['material_id'])
          .map((data) => List<Map<String, dynamic>>.from(data))
          .map((materials) => materials.where((material) => 
              material['contractor_id'] == contractorId).toList())
          .map((materials) => materials..sort((a, b) => 
              DateTime.parse(b['created_at'] ?? '').compareTo(
                DateTime.parse(a['created_at'] ?? ''))));
    } catch (e) {
      _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to stream project materials: $e',
        module: 'FetchService',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Stream Project Materials',
          'contractor_id': contractorId,
        },
      );
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> streamSpecificProjectMaterials(String contractorId, String projectId) {
    try {
      return _supabase
          .from('ProjectMaterials')
          .stream(primaryKey: ['material_id'])
          .map((data) => List<Map<String, dynamic>>.from(data))
          .map((materials) => materials.where((material) => 
              material['contractor_id'] == contractorId && 
              material['project_id'] == projectId).toList())
          .map((materials) => materials..sort((a, b) => 
              DateTime.parse(b['created_at'] ?? '').compareTo(
                DateTime.parse(a['created_at'] ?? ''))));
    } catch (e) {
      _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to stream specific project materials: $e',
        module: 'FetchService',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Stream Specific Project Materials',
          'contractor_id': contractorId,
          'project_id': projectId,
        },
      );
      return Stream.value([]);
    }
  }
}