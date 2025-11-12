// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class RealtimeSubscriptionService {
  static final RealtimeSubscriptionService _instance = RealtimeSubscriptionService._internal();
  factory RealtimeSubscriptionService() => _instance;
  RealtimeSubscriptionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  RealtimeChannel? subscribeToNotifications({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'notifications_$userId';
    
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to projects for contractee
  RealtimeChannel? subscribeToContracteeProjects({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'contractee_projects_$userId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('contractee_projects:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Projects',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'contractee_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to projects for contractor
  RealtimeChannel? subscribeToContractorProjects({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'contractor_projects_$userId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('contractor_projects:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Projects',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'contractor_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to bids for contractee's projects
  RealtimeChannel? subscribeToContracteeBids({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'contractee_bids_$userId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('contractee_bids:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Bids',
          callback: (payload) async {
            final bidProjectId = payload.newRecord['project_id'] ?? payload.oldRecord['project_id'];
            if (bidProjectId != null) {
              final userProjects = await _supabase
                  .from('Projects')
                  .select('project_id')
                  .eq('contractee_id', userId)
                  .eq('project_id', bidProjectId);
              
              if (userProjects.isNotEmpty) {
                onUpdate();
              }
            }
          },
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to bids for contractor
  RealtimeChannel? subscribeToContractorBids({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'contractor_bids_$userId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('contractor_bids:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Bids',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'contractor_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  RealtimeChannel? subscribeToProjectBids({
    required String projectId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'project_bids_$projectId';

    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('project_bids:$projectId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Bids',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'project_id',
            value: projectId,
          ),
          callback: (payload) {
            try {
              dynamic bidProjectId;
              try {
                bidProjectId = (payload.newRecord as Map?)?['project_id'] ?? 
                               (payload.oldRecord as Map?)?['project_id'];
              } catch (_) {
                bidProjectId = null;
              }
              
              if (bidProjectId == null || bidProjectId.toString() == projectId) {
                onUpdate();
              }
            } catch (e) {
              _errorService.logError(
                errorMessage: 'Error in real-time subscription callback for project bids: $e',
                module: 'Realtime Subscription Service',
                severity: 'Medium',
                extraInfo: {
                  'operation': 'Project Bids Subscription Callback',
                  'project_id': projectId,
                  'event_type': payload.eventType.toString(),
                },
              );
            }
          },
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to all projects (for browsing)
  RealtimeChannel? subscribeToAllProjects({
    required VoidCallback onUpdate,
  }) {
    const channelKey = 'all_projects';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('all_projects')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Projects',
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to users table changes
  RealtimeChannel? subscribeToUsers({
    required VoidCallback onUpdate,
  }) {
    const channelKey = 'users';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('users')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Users',
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to messages in a chat room
  RealtimeChannel? subscribeToMessages({
    required String chatRoomId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'messages_$chatRoomId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('messages:$chatRoomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chatroom_id',
            value: chatRoomId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to chat rooms for a user
  RealtimeChannel? subscribeToChatRooms({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'chatrooms_$userId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('chatrooms:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ChatRooms',
          callback: (payload) async {
            // Check if user is part of this chat room
            final chatRoomId = payload.newRecord['chatroom_id'] ?? payload.oldRecord['chatroom_id'];
            if (chatRoomId != null) {
              final chatRoom = await _supabase
                  .from('ChatRooms')
                  .select('*')
                  .eq('chatroom_id', chatRoomId)
                  .maybeSingle();
              
              if (chatRoom != null && 
                  (chatRoom['contractee_id'] == userId || chatRoom['contractor_id'] == userId)) {
                onUpdate();
              }
            }
          },
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to contracts for a user
  RealtimeChannel? subscribeToContracts({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'contracts_$userId';
    
    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();
    
    final channel = _supabase
        .channel('contracts:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Contracts',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            
            final contracteeId = newRecord['contractee_id'] ?? oldRecord['contractee_id'];
            final contractorId = newRecord['contractor_id'] ?? oldRecord['contractor_id'];
            
            if (contracteeId == userId || contractorId == userId) {
              onUpdate();
            }
          },
        )
        .subscribe();
    
    _channels[channelKey] = channel;
    return channel;
  }

  RealtimeChannel? subscribeToContractorVerification({
    required String contractorId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'contractor_verification_$contractorId';

    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();

    final channel = _supabase
        .channel('contractor_verification:$contractorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Contractor',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'contractor_id',
            value: contractorId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();

    _channels[channelKey] = channel;
    return channel;
  }

  /// Subscribe to user verification status changes
  RealtimeChannel? subscribeToUserVerification({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelKey = 'user_verification_$userId';

    // Unsubscribe existing channel if exists
    _channels[channelKey]?.unsubscribe();

    final channel = _supabase
        .channel('user_verification:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'users_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();

    _channels[channelKey] = channel;
    return channel;
  }

  void unsubscribeFromChannel(String channelKey) {
    _channels[channelKey]?.unsubscribe();
    _channels.remove(channelKey);
  }

  void unsubscribeFromUserChannels(String userId) {
    final userChannels = _channels.keys.where((key) => key.contains(userId)).toList();
    for (final channelKey in userChannels) {
      _channels[channelKey]?.unsubscribe();
      _channels.remove(channelKey);
    }
  }

  void unsubscribeFromAllChannels() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
  
  List<String> getActiveChannels() {
    return _channels.keys.toList();
  }
}