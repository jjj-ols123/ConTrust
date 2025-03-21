import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn({
      required String email, 
      required String password
  }) async {
    return await _supabase.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _supabase.auth
        .signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async { 
    final response = await Supabase.instance.client
      .rpc('get_auth_user', params: {'user_id': userId})
      .single();

    return response;
  }
}
