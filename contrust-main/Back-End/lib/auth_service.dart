
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService { 
  final SupabaseClient _supabase = Supabase.instance.client; 

  //sign-in 
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password); 
  }

  //sign-up
  Future<AuthResponse> signUp({required String email, required String password, Map<String, dynamic>? data,}) async {
    return await _supabase.auth.signUp(email: email, password: password, data: data); 
  }

  //sign-out

  Future<void> signOut() async {
    await _supabase.auth.signOut(); 
  }

  //anonymous sign-in
  Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously(); 
  }

}