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
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    final next = Uri.base.queryParameters['next'] ?? '/dashboard';
    try {
      final supabase = Supabase.instance.client;
      
      Session? session;
      try {
        final response = await supabase.auth.getSessionFromUrl(Uri.base);
        session = response.session;
      } catch (e) {
        debugPrint('getSessionFromUrl failed, trying current session: $e');
        session = supabase.auth.currentSession;
      }

      if (session == null) {
        await Future.delayed(const Duration(seconds: 1));
        session = supabase.auth.currentSession;
      }

      if (session == null) {
        await Future.delayed(const Duration(seconds: 2));
        session = supabase.auth.currentSession;
      }

      if (session == null) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          context.go('/');
        }
        return;
      }

      final user = session.user;

      final signInService = SignInGoogleContractor();
      await signInService.handleSignIn(context, user);

      if (!mounted || _hasRedirected) {
        return;
      }

      var refreshedSession = supabase.auth.currentSession;
      if (refreshedSession == null) {
        await Future.delayed(const Duration(seconds: 1));
        refreshedSession = supabase.auth.currentSession;
      }

      if (refreshedSession == null) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          context.go('/');
        }
        return;
      }

      final currentUser = refreshedSession.user;

      final userDataResults = await Future.wait([
        supabase
            .from('Contractor')
            .select()
            .eq('contractor_id', currentUser.id)
            .maybeSingle(),
        supabase
            .from('Contractee')
            .select()
            .eq('contractee_id', currentUser.id)
            .maybeSingle(),
      ]);

      final contractorData = userDataResults[0];
      final contracteeData = userDataResults[1];

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contractorData != null) {
          context.go(next);
        } else if (contracteeData != null) {
          context.go('/home');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      debugPrint('Error in contractor auth redirect: $e');
      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        context.go('/');
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