// ignore_for_file: avoid_print, file_names

import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> getContractorId() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null; 
  try {
    final response = await Supabase.instance.client
        .from('Contractor')
        .select('contractor_id')
        .eq('contractor_id', user.id) 
        .maybeSingle();

    return response?['contractor_id'] as String?;
  } catch (error) {
    print("Error fetching contractor ID: $error");
    return null;
  }
}
