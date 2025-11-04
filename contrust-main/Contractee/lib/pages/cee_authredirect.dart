// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/contractee services/cee_signin.dart';
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
      final supabase = Supabase.instance.client;
      
      Session? session;
      try {
        final response = await supabase.auth.getSessionFromUrl(Uri.base);
        session = response.session;
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
          context.go('/login');
        }
        return;
      }

      final user = session.user;

      // Handle sign-in process
      final signInService = SignInGoogleContractee();
      await signInService.handleSignIn(context, user);

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
          context.go('/login');
        }
        return;
      }

      final currentUser = refreshedSession.user;

      // Check both Contractee and Contractor tables to determine user type
      final userDataResults = await Future.wait([
        supabase
            .from('Contractee')
            .select()
            .eq('contractee_id', currentUser.id)
            .maybeSingle(),
        supabase
            .from('Contractor')
            .select()
            .eq('contractor_id', currentUser.id)
            .maybeSingle(),
      ]);

      final contracteeData = userDataResults[0];
      final contractorData = userDataResults[1];

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contracteeData != null) {
          // User is a contractee, redirect to home
          context.go('/home');
        } else if (contractorData != null) {
          // User is a contractor, redirect to dashboard
          context.go('/dashboard');
        } else {
          // User not found in either table, redirect to login
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('Error in contractee auth redirect: $e');
      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        context.go('/login');
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