// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> functionConstraint(String contractorId, String contracteeId) async {
  final response = await Supabase.instance.client
      .from('Projects')
      .select('project_id')
      .eq('contractor_id', contractorId)
      .eq('contractee_id', contracteeId)
      .inFilter('status', ['awaiting_contract', 'active', 'awaiting_agreement', 'awaiting_signature', 'cancellation_requested_by_contractee', 'cancelled', 'completed']);

  return response.isNotEmpty;
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
      .select('project_id, title, type, description, location, status, contractor_id, min_budget, max_budget, start_date, projectdata')
      .eq('contractee_id', contracteeId)
      .eq('contractor_id', contractorId)
      .inFilter('status', ['awaiting_contract', 'active', 'awaiting_agreement', 'awaiting_signature', 'cancellation_requested_by_contractee'])
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  return existingProjectWithContractor;
}

Future<Map<String, dynamic>?> hasOngoingProject(String contracteeId) async {
  final ongoingProject = await Supabase.instance.client
        .from('Projects')
        .select('project_id, contractor_id, title, status')
        .eq('contractee_id', contracteeId)
        .not('contractor_id', 'is', null)
        .neq('status', 'cancelled')
        .inFilter('status', ['awaiting_contract', 'active', 'awaiting_agreement', 'awaiting_signature'])
        .limit(1)
        .maybeSingle();
  return ongoingProject;
}

Future<Map<String, dynamic>?> hasOngoingProjectAsContractor(String contractorId) async {
  final ongoingProject = await Supabase.instance.client
        .from('Projects')
        .select('project_id, contractee_id, title, status')
        .eq('contractor_id', contractorId)
        .neq('status', 'cancelled')
        .inFilter('status', ['awaiting_contract', 'active', 'awaiting_agreement', 'awaiting_signature'])
        .limit(1)
        .maybeSingle();
  return ongoingProject;
}

Future<Map<String, dynamic>?> hasPendingProject(String contracteeId) async {
  final pendingProject = await Supabase.instance.client
      .from('Projects')
      .select('project_id, title, type, description, location, min_budget, max_budget, start_date, duration, projectdata')
      .eq('contractee_id', contracteeId)
      .eq('status', 'pending')
      .limit(1)
      .maybeSingle();
  return pendingProject;
}

Future<Map<String, dynamic>?> hasPendingHireRequest(String contracteeId, String contractorId) async {
  // Check notifications for pending hire requests to this specific contractor
  try {
    final notifications = await Supabase.instance.client
        .from('Notifications')
        .select('notification_id, information')
        .eq('headline', 'Hiring Request')
        .eq('sender_id', contracteeId)
        .eq('receiver_id', contractorId)
        .filter('information->>status', 'eq', 'pending');

    if (notifications.isNotEmpty) {
      final notification = notifications.first;
      final info = notification['information'] as Map<String, dynamic>?;
      final projectId = info?['project_id'];
      
      if (projectId != null) {
        // Get the project details
        final project = await Supabase.instance.client
            .from('Projects')
            .select('project_id, title, type, description, location, min_budget, max_budget, start_date, projectdata')
            .eq('project_id', projectId)
            .eq('status', 'pending')
            .filter('projectdata->>hiring_type', 'eq', 'direct_hire')
            .maybeSingle();
        
        return project;
      }
    }
    
    return null;
  } catch (e) {
    return null;
  }
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
      var info = notification['information'];
      if (info is String) {
        try {
          info = jsonDecode(info);
        } catch (_) {
          info = null;
        }
      }
      final infoMap = info is Map ? Map<String, dynamic>.from(info) : null;
      if (infoMap != null &&
          infoMap['action'] == 'hire_request' &&
          infoMap['status'] == 'pending') {
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
                'headline': 'Hiring Request Cancelled',
                'information': {
                  ...info,
                  'status': 'cancelled',
                  'cancelled_reason': 'Project already has an accepted contractor',
                  'cancelled_at': DateTime.now().toIso8601String(),
                }
              })
              .eq('notification_id', request['notification_id']);
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel other hire requests');
    }
  }

Future<bool> hasContractorDeclinedProject(String contracteeId, String contractorId, String projectId) async {
  try {

    final declinedRequests = await Supabase.instance.client
        .from('Notifications')
        .select('notification_id, information')
        .eq('sender_id', contracteeId)
        .eq('receiver_id', contractorId)
        .eq('headline', 'Hiring Request');

    for (final request in declinedRequests) {
      final info = request['information'] as Map<String, dynamic>?;
      if (info != null && 
          info['project_id'] == projectId && 
          info['status'] == 'declined') {
        return true;
      }
    }
    
    return false;
  } catch (e) {
    return false;
  }
}
