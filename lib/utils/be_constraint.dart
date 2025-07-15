import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> functionConstraint(String contractorId, String contracteeId) async {
  final response = await Supabase.instance.client
      .from('Projects')
      .select('project_id')
      .eq('contractor_id', contractorId)
      .eq('contractee_id', contracteeId)
      .inFilter('status', ['awaiting_contract', 'active'])
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

Future<Map<String, dynamic>?> hasExistingProject(String contracteeId) async {
  final existingProject = await Supabase.instance.client
      .from('Projects')
      .select('project_id, title, type, description, location, status')
      .eq('contractee_id', contracteeId)
      .eq('status', 'pending') 
      .order('created_at', ascending: false) 
      .limit(1)
      .maybeSingle();

  return existingProject;
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
          .select('notification_id, information')
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
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel other hire requests');
    }
  }
