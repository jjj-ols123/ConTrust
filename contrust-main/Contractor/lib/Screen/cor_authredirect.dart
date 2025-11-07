// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/contractor services/cor_signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/build/html_stub.dart' if (dart.library.html) 'dart:html' as html show window;

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
      
      final uri = Uri.base;
      final hash = uri.fragment;
      final hashParams = hash.isNotEmpty ? Uri.splitQueryString(hash) : <String, String>{};
      final queryParams = uri.queryParameters;
      
      final isPasswordReset = hashParams['type'] == 'recovery' || 
                             queryParams['type'] == 'recovery' ||
                             hashParams.containsKey('access_token') && hashParams['type'] == 'recovery';
      
      if (isPasswordReset) {
        debugPrint('[AuthRedirect Contractor] Detected password reset flow, redirecting to /auth/reset-password');
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          if (kIsWeb && hash.isNotEmpty) {
            try {
              final baseUrl = html.window.location.origin;
              final hashWithPrefix = hash.startsWith('#') ? hash : '#$hash';
              html.window.location.href = '$baseUrl/auth/reset-password$hashWithPrefix';
              return;
            } catch (e) {
              debugPrint('[AuthRedirect] Error setting location with hash: $e');
            }
          }
          context.go('/auth/reset-password');
        }
        return;
      }
      
      Session? session;
      try {
        final response = await supabase.auth.getSessionFromUrl(Uri.base, storeSession: true);
        session = response.session;
        debugPrint('[AuthRedirect Contractor] getSessionFromUrl succeeded');
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
          debugPrint('[AuthRedirect Contractor] no session -> /logincontractor');
          context.go('/logincontractor');
        }
        return;
      }

      final user = session.user;
      debugPrint('[AuthRedirect Contractor] session user: ${user.id}');

      final signInService = SignInGoogleContractor();
      debugPrint('[AuthRedirect Contractor] calling handleSignIn...');
      await signInService.handleSignIn(context, user);
      debugPrint('[AuthRedirect Contractor] handleSignIn finished');

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
