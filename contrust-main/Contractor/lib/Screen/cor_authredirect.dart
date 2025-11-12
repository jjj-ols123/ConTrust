// ignore_for_file: use_build_context_synchronously, avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
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
      final supabase = Supabase.instance.client;
      
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final uri = Uri.base;
      final hash = uri.fragment;
      final hashParams = hash.isNotEmpty ? Uri.splitQueryString(hash) : <String, String>{};
      final queryParams = uri.queryParameters;
      
      final isPasswordReset = hashParams['type'] == 'recovery' && 
                             !hashParams.containsKey('refresh_token') ||
                             queryParams['type'] == 'recovery' && 
                             !queryParams.containsKey('refresh_token') ||
                             (hashParams.containsKey('access_token') && hashParams['type'] == 'recovery' && !hashParams.containsKey('refresh_token'));
      
      if (isPasswordReset) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          if (kIsWeb && hash.isNotEmpty) {
            try {
              final baseUrl = html.window.location.origin;
              final hashWithPrefix = hash.startsWith('#') ? hash : '#$hash';
              html.window.location.href = '$baseUrl/auth/reset-password$hashWithPrefix';
              return;
            } catch (e) {
              //
            }
          }
          context.go('/auth/reset-password');
        }
        return;
      }
      
      Session? session;
      
      Uri urlToUse = uri;
      if (!kIsWeb && hash.isNotEmpty) {
        final urlString = uri.toString();
        if (!urlString.contains('#')) {
          urlToUse = Uri.parse('$urlString#$hash');
        } else {
          urlToUse = uri;
        }
      } else if (kIsWeb && hash.isNotEmpty) {
        try {
          urlToUse = Uri.parse(html.window.location.href);
        } catch (e) {
          //
        }
      }
      
      try {
        final response = await supabase.auth.getSessionFromUrl(urlToUse, storeSession: true);
        session = response.session;
      } catch (e) {
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
        final authState = supabase.auth.onAuthStateChange;
        final completer = Completer<Session?>();
        late StreamSubscription sub;
        
        sub = authState.listen((data) {
          if (data.session != null) {
            if (!completer.isCompleted) {
              completer.complete(data.session);
            }
            sub.cancel();
          }
        });
        
        try {
          session = await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              sub.cancel();
              return supabase.auth.currentSession;
            },
          );
        } catch (e) {
          sub.cancel();
          session = supabase.auth.currentSession;
        }
      }
      if (session == null) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication failed. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            context.go('/logincontractor');
          }
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

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contractorData != null) {
          context.go('/dashboard');
        } else {
          context.go('/logincontractor');
        }
      }
    } catch (e) {
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
