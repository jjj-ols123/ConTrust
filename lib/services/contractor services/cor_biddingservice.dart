import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class CorBiddingService {
  final _supabase = Supabase.instance.client;
  final _biddingService = BiddingService();
  final _userService = UserService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  Future<void> postBid({
    required String contractorId,
    required String projectId,
    required num bidAmount,
    required String message,
    required BuildContext context,
  }) async {
    try {
      await _userService.checkContractorId(contractorId);

      final projectResponse = await _supabase
          .from('Projects')
          .select('status')
          .eq('project_id', projectId)
          .single();

      if (projectResponse['status'] != 'pending') {
        throw Exception('This project is no longer accepting bids.');
      }


      final existingBid = await _supabase
          .from('Bids')
          .select('bid_id, status')
          .eq('project_id', projectId)
          .eq('contractor_id', contractorId)
          .neq('status', 'stopped')
          .maybeSingle();
      
      if (existingBid != null) {
        final bidStatus = existingBid['status'] as String?;
        if (bidStatus == 'rejected') {
          throw Exception('You cannot bid on the same project after your bid has been rejected.');
        } else if (bidStatus == 'accepted') {
          throw Exception('You have already been accepted for this project. You cannot submit another bid.');
        } else {
          throw Exception('You have already submitted a bid for this project. You cannot submit another bid.');
        }
      }

      await _supabase.from('Bids').insert({
        'contractor_id': contractorId,
        'project_id': projectId,
        'bid_amount': bidAmount,
        'message': message,
        'status': 'pending',
      });

      await _auditService.logAuditEvent(
        userId: contractorId,
        action: 'BID_POSTED',
        details: 'Contractor posted a bid for a project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'bid_amount': bidAmount,
          'contractor_id': contractorId,
        },
      );

      try {
        final projectResponse = await _supabase
            .from('Projects')
            .select('contractee_id, type')
            .eq('project_id', projectId)
            .single();

        if (projectResponse.isNotEmpty) {
          final contracteeId = projectResponse['contractee_id'];
          final projectType = projectResponse['type'];

          final contractorResponse = await _supabase
              .from('Contractor')
              .select('firm_name, profile_photo')
              .eq('contractor_id', contractorId)
              .single();

          final contractorName =
              contractorResponse['firm_name'] ?? 'Unknown Contractor';
          final contractorPhoto = contractorResponse['profile_photo'] ?? '';

          final notificationService = NotificationService();

          await notificationService.createNotification(
            receiverId: contracteeId,
            receiverType: 'contractee',
            senderId: contractorId,
            senderType: 'contractor',
            type: 'New Bid',
            message:
                '$contractorName submitted a bid of ₱$bidAmount for your $projectType project',
            information: {
              'bid_amount': bidAmount,
              'project_type': projectType,
              'contractor_name': contractorName,
              'contractor_photo': contractorPhoto,
            },
          );
        }
      } catch (e) {
        await _errorService.logError(
          errorMessage: 'Failed to send notification after posting bid: $e',
          module: 'Contractor Bidding Service',
          severity: 'Medium',
          extraInfo: {
            'operation': 'Post Bid - Send Notification',
            'project_id': projectId,
            'contractor_id': contractorId,
          },
        );
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Error sending notification');
        }
      }

      if (context.mounted) {
        ConTrustSnackBar.bidSubmitted(context);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to post bid: $e',
        module: 'Contractor Bidding Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Post Bid',
          'project_id': projectId,
          'contractor_id': contractorId,
        },
      );
      if (context.mounted) {
        if (e is PostgrestException && e.code == '23505') {
          ConTrustSnackBar.warning(context, 'You can only submit one bid per project.');
        } else if (e is Exception) {
          // Show the specific error message from the exception
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(12); // Remove "Exception: " prefix
          }
          ConTrustSnackBar.warning(context, errorMessage);
        } else {
          ConTrustSnackBar.bidError(context, 'Error posting bid');
        }
      }
      rethrow;
    }
  }

  Stream<Duration> getBiddingCountdownStream(
    DateTime createdAt,
    int durationInDays,
  ) async* {
    final endTime = createdAt.add(Duration(days: durationInDays));
    while (true) {
      final now = DateTime.now();
      final remaining = endTime.difference(now);
      if (remaining.isNegative) break;
      yield remaining;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<List<Map<String, dynamic>>> getContractorBids(String contractorId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('''
            *,
            project:project_id (
              type,
              description,
              title
            )
          ''')
          .eq('contractor_id', contractorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get contractor bids: $e',
        module: 'Contractor Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Contractor Bids',
          'contractor_id': contractorId,
        },
      );
      return [];
    }
  }

  Future<Map<String, dynamic>> loadBiddingData() async {
    try {
      final results = await Future.wait([
        loadContractorId(),
        loadProjects(),
        loadHighestBids(),
      ]);

      final contractorId = results[0] as String?;
      final projectsData = results[1] as Map<String, dynamic>;
      final highestBids = results[2] as Map<String, double>;

      final contractorBids = contractorId != null ? await getContractorBids(contractorId) : [];

      return {
        'contractorId': contractorId,
        'projects': projectsData['projects'],
        'contracteeInfo': projectsData['contracteeInfo'],
        'highestBids': highestBids,
        'contractorBids': contractorBids,
        'success': true,
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to load bidding data: $e',
        module: 'Contractor Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Load Bidding Data',
        },
      );
      return {
        'success': false,
        'error': 'Error loading bidding data: ',
        'contractorId': null,
        'projects': <Map<String, dynamic>>[],
        'contracteeInfo': <String, Map<String, dynamic>>{},
        'highestBids': <String, double>{},
        'contractorBids': <Map<String, dynamic>>[],
      };
    }
  }

  Future<String?> loadContractorId() async {
    try {
      return await _userService.getContractorId();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to load contractor ID: $e',
        module: 'Contractor Bidding Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Load Contractor ID',
        },
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> loadProjects() async {
    try {
      final response = await _supabase
          .from('Projects')
          .select(
            'project_id, title, type, description, location, duration, min_budget, max_budget, created_at, contractee_id',
          )
          .eq('status', 'pending')
          .neq('duration', 0);

      if (response.isEmpty) {
        return {
          'projects': <Map<String, dynamic>>[],
          'contracteeInfo': <String, Map<String, dynamic>>{},
        };
      }

      final projectsData = List<Map<String, dynamic>>.from(response);
      
      final contracteeIds = projectsData
          .map((p) => p['contractee_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();
      
      final contracteeInfoMap = <String, Map<String, dynamic>>{};
      
      if (contracteeIds.isNotEmpty) {
        try {
          final contracteeData = await _supabase
              .from('Contractee')
              .select('contractee_id, full_name, profile_photo')
              .inFilter('contractee_id', contracteeIds);
          
          for (var contractee in contracteeData) {
            contracteeInfoMap[contractee['contractee_id']] = {
              'full_name': contractee['full_name'] ?? 'Unknown Contractee',
              'profile_photo': contractee['profile_photo'],
              'contractee_id': contractee['contractee_id'],
            };
          }
          
          for (final contracteeId in contracteeIds) {
            if (contracteeId != null && !contracteeInfoMap.containsKey(contracteeId)) {
              contracteeInfoMap[contracteeId] = {
                'full_name': 'Unknown Contractee',
                'profile_photo': null,
                'contractee_id': contracteeId,
              };
            }
          }
        } catch (fetchError) {
          await _errorService.logError(
            errorMessage: 'Failed to batch fetch contractee data: $fetchError',
            module: 'Contractor Bidding Service',
            severity: 'Low',
            extraInfo: {
              'operation': 'Load Projects - Batch Fetch Contractee Data',
            },
          );
          for (final contracteeId in contracteeIds) {
            if (contracteeId != null) {
              contracteeInfoMap[contracteeId] = {
                'full_name': 'Unknown Contractee',
                'profile_photo': null,
                'contractee_id': contracteeId,
              };
            }
          }
        }
      }

      return {
        'projects': projectsData,
        'contracteeInfo': contracteeInfoMap,
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to load projects: $e',
        module: 'Contractor Bidding Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Load Projects',
        },
      );
      throw Exception('Failed to load projects: ');
    }
  }

  Future<Map<String, double>> loadHighestBids() async {
    try {
      return await _biddingService.getProjectHighestBids();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to load highest bids: ',
        module: 'Contractor Bidding Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Load Highest Bids',
        },
      );
      return <String, double>{};
    }
  }

  Future<bool> hasAlreadyBid(String projectId, String contractorId) async {
    try {
      // Check for any existing bid (including rejected) - only stopped bids allow re-bidding
      final response = await _supabase
          .from('Bids')
          .select('bid_id, status')
          .eq('project_id', projectId)
          .eq('contractor_id', contractorId)
          .neq('status', 'stopped')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check if already bid: ',
        module: 'Contractor Bidding Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Has Already Bid',
          'project_id': projectId,
          'contractor_id': contractorId,
        },
      );
      return false;
    }
  }

  Future<void> finalizeBidding(String projectId) async {
    return await _biddingService.finalizeBidding(projectId);
  }
}