// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> functionConstraint(String contractorId, String contracteeId) async {
  final response = await Supabase.instance.client
      .from('Projects')
      .select('project_id')
      .eq('contractor_id', contractorId)
      .eq('contractee_id', contracteeId)
      .inFilter('status', ['awaiting_contract', 'active', 'awaiting_agreement', 'awaiting_signature'])
      .maybeSingle();
  return response != null;
} 

Future<bool> hasAlreadyBid(String contractorId, String projectId) async {
  final response = await Supabase.instance.client
      .from('Bids')
      .select('bid_id')
      .eq('contractor_id', contractorId)
      .eq('project_id', projectId)
      .maybeSingle();
  return response != null;
}

Future<Map<String, dynamic>?> hasExistingProjectWithContractor(String contracteeId, String contractorId) async {
  final existingProjectWithContractor = await Supabase.instance.client
      .from('Projects')
      .select('project_id, title, type, description, location, status, contractor_id')
      .eq('contractee_id', contracteeId)
      .eq('contractor_id', contractorId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  return existingProjectWithContractor;
}

Future<Map<String, dynamic>?> hasOngoingProject(String contracteeId) async {
  final ongoingProject = await Supabase.instance.client
        .from('Projects')
        .select('project_id')
        .eq('contractee_id', contracteeId)
        .not('contractor_id', 'is', null)
        .inFilter('status', ['awaiting_contract', 'active', 'awaiting_agreement', 'awaiting_signature'])
        .limit(1)
        .maybeSingle();
  return ongoingProject;
}

Future<Map<String, dynamic>?> hasPendingProject(String contracteeId) async {
  final pendingProject = await Supabase.instance.client
      .from('Projects')
      .select('project_id, title, type, description, location')
      .eq('contractee_id', contracteeId)
      .eq('status', 'pending')
      .limit(1)
      .maybeSingle();
  return pendingProject;
}

Future<Map<String, dynamic>?> hasExistingHireRequest(String contractorId, String contracteeId) async {
  try {
    final notifications = await Supabase.instance.client
        .from('Notifications')
        .select('notification_id, created_at, information, headline')
        .eq('receiver_id', contractorId)
        .eq('sender_id', contracteeId)
        .eq('headline', 'Hiring Request');

    for (final notification in notifications) {
      final info = notification['information'] as Map<String, dynamic>?;
      if (info != null && 
          info['action'] == 'hire_request' && 
          info['status'] == 'pending') {
        return notification;
      }
    }
    return null; 
  } catch (e) {
    return null;
  }
}

  Future<void> cancelOtherHireRequests(String projectId, String contracteeId, String acceptedNotificationId) async {
    try {
      final _supabase = Supabase.instance.client;

      final pendingRequests = await _supabase
          .from('Notifications')
          .select('notification_id, information, receiver_id')
          .eq('sender_id', contracteeId)
          .eq('headline', 'Hiring Request')
          .neq('notification_id', acceptedNotificationId);

      for (final request in pendingRequests) {
        final info = request['information'] as Map<String, dynamic>?;
        if (info != null && 
            info['project_id'] == projectId && 
            info['status'] == 'pending') {
          await _supabase
              .from('Notifications')
              .update({
                'information': {
                  ...info,
                  'status': 'cancelled',
                  'cancelled_reason': 'Project already has an accepted contractor',
                  'cancelled_at': DateTime.now().toIso8601String(),
                }
              })
              .eq('notification_id', request['notification_id']);
          await _supabase
              .from('Notifications')
              .insert({
                'receiver_id': request['receiver_id'],
                'receiver_type': 'contractor',
                'sender_id': contracteeId,
                'sender_type': 'contractee',
                'headline': 'Hiring Request Cancelled',
                'information': {
                  'project_id': projectId,
                  'action': 'hire_request_cancelled',
                  'timestamp': DateTime.now().toIso8601String(),
                },
                'is_read': false,
                'created_at': DateTime.now().toIso8601String(),
              });
          await _supabase
              .from('Notifications')
              .delete()
              .eq('notification_id', request['notification_id']);
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel other hire requests');
    }
  }
