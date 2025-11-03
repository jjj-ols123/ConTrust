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
      final response = await supabase.auth.getSessionFromUrl(Uri.base);
      final session = response.session;
      final user = session.user;
      final signInService = SignInGoogleContractor();
      await signInService.handleSignIn(context, user);

      if (!mounted || _hasRedirected) {
        return;
      }

      var refreshedSession = supabase.auth.currentSession;
      if (refreshedSession == null) {
        await Future.delayed(const Duration(seconds: 2));
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
      final contractorData = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', currentUser.id)
          .maybeSingle();

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contractorData != null) {
          context.go(next);
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}