import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class CorBiddingService {
  final _supabase = Supabase.instance.client;
  final _biddingService = BiddingService();
  final _userService = UserService();
  final _fetchService = FetchService();


  Future<void> postBid({
    required String contractorId,
    required String projectId,
    required num bidAmount,
    required String message,
    required BuildContext context,
  }) async {
    try {
      await _userService.checkContractorId(contractorId);

      await _supabase.from('Bids').upsert({
        'contractor_id': contractorId,
        'project_id': projectId,
        'bid_amount': bidAmount,
        'message': message,
        'status': 'pending',
      });

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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error sending notification')),
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid created successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error posting bid')),
          );
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

      return {
        'contractorId': contractorId,
        'projects': projectsData['projects'],
        'contracteeInfo': projectsData['contracteeInfo'],
        'highestBids': highestBids,
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error loading bidding data: $e',
        'contractorId': null,
        'projects': <Map<String, dynamic>>[],
        'contracteeInfo': <String, Map<String, dynamic>>{},
        'highestBids': <String, double>{},
      };
    }
  }

  Future<String?> loadContractorId() async {
    try {
      return await _userService.getContractorId();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> loadProjects() async {
    try {
      final response = await _supabase
          .from('Projects')
          .select(
            'project_id, type, description, location, duration, min_budget, max_budget, created_at, contractee_id',
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
      final contracteeInfoMap = <String, Map<String, dynamic>>{};

      for (final project in projectsData) {
        try {
          final contracteeId = project['contractee_id'];
          
          if (contracteeId != null && !contracteeInfoMap.containsKey(contracteeId)) {
            try {
              final contracteeData = await _fetchService.fetchContracteeData(contracteeId);
              
              if (contracteeData != null) {
                contracteeInfoMap[contracteeId] = {
                  'full_name': contracteeData['full_name'] ?? 'Unknown',
                  'profile_photo': contracteeData['profile_photo'],
                  'contractee_id': contracteeData['contractee_id'],
                };
              } else {
                contracteeInfoMap[contracteeId] = {
                  'full_name': 'Unknown Contractee',
                  'profile_photo': null,
                  'contractee_id': contracteeId,
                };
              }
            } catch (fetchError) {
              contracteeInfoMap[contracteeId] = {
                'full_name': 'Unknown Contractee',
                'profile_photo': null,
                'contractee_id': contracteeId,
              };
            }
          }
        } catch (e) {
          continue;
        }
      }

      return {
        'projects': projectsData,
        'contracteeInfo': contracteeInfoMap,
      };
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  Future<Map<String, double>> loadHighestBids() async {
    try {
      return await _biddingService.getProjectHighestBids();
    } catch (e) {
      return <String, double>{};
    }
  }

  Future<bool> hasAlreadyBid(String projectId, String contractorId) async {
    try {
      final response = await _supabase
          .from('Bids')
          .select('bid_id')
          .eq('project_id', projectId)
          .eq('contractor_id', contractorId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }
}