// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/contractor services/cor_signin.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRedirectPage extends StatefulWidget {
  const AuthRedirectPage({super.key});

  @override
  State<AuthRedirectPage> createState() => _AuthRedirectPageState();
}

class _AuthRedirectPageState extends State<AuthRedirectPage> {
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    _handleAuthRedirect();
  }

  Future<void> _handleAuthRedirect() async {
    try {
      debugPrint('[AuthRedirect Contractor] handling OAuth redirect...');
      final supabase = Supabase.instance.client;
      
      Session? session;
      try {
        final response = await supabase.auth.getSessionFromUrl(Uri.base, storeSession: true);
        session = response.session;
        debugPrint('[AuthRedirect Contractor] getSessionFromUrl succeeded');
      } catch (e) {
        // If getSessionFromUrl fails, try to get current session
        debugPrint('getSessionFromUrl failed, trying current session: $e');
        session = supabase.auth.currentSession;
      }

      // If no session from URL, wait a bit and try current session
      if (session == null) {
        await Future.delayed(const Duration(seconds: 1));
        session = supabase.auth.currentSession;
      }

      // If still no session, wait a bit more (for async auth state changes)
      if (session == null) {
        await Future.delayed(const Duration(seconds: 2));
        session = supabase.auth.currentSession;
      }

      if (session == null) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          debugPrint('[AuthRedirect Contractor] no session -> /logincontractor');
          context.go('/logincontractor');
        }
        return;
      }

      final user = session.user;
      debugPrint('[AuthRedirect Contractor] session user: ${user.id}');

      // Handle sign-in process
      final signInService = SignInGoogleContractor();
      debugPrint('[AuthRedirect Contractor] calling handleSignIn...');
      await signInService.handleSignIn(context, user);
      debugPrint('[AuthRedirect Contractor] handleSignIn finished');

      if (!mounted || _hasRedirected) {
        return;
      }

      // Refresh session after sign-in handling
      var refreshedSession = supabase.auth.currentSession;
      if (refreshedSession == null) {
        await Future.delayed(const Duration(seconds: 1));
        refreshedSession = supabase.auth.currentSession;
      }

      if (refreshedSession == null) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          debugPrint('[AuthRedirect Contractor] no refreshed session -> /logincontractor');
          context.go('/logincontractor');
        }
        return;
      }

      final currentUser = refreshedSession.user;

      final contractorData = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', currentUser.id)
          .maybeSingle();
      debugPrint('[AuthRedirect Contractor] contractor row exists: ${contractorData != null}');

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contractorData != null) {
          debugPrint('[AuthRedirect Contractor] navigate -> /dashboard');
          context.go('/dashboard');
        } else {
          debugPrint('[AuthRedirect Contractor] navigate -> /logincontractor');
          context.go('/logincontractor');
        }
      }
    } catch (e) {
      debugPrint('Error in contractor auth redirect: $e');
      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        context.go('/logincontractor');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber),  
      ),
    );
  }
}
