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
      debugPrint('[AuthRedirect Contractor] handling OAuth redirect...');
      final supabase = Supabase.instance.client;
      
      // On mobile, wait a bit for the deep link to be fully processed
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final uri = Uri.base;
      final hash = uri.fragment;
      final hashParams = hash.isNotEmpty ? Uri.splitQueryString(hash) : <String, String>{};
      final queryParams = uri.queryParameters;
      
      debugPrint('[AuthRedirect Contractor] Initial URI: ${uri.toString()}');
      debugPrint('[AuthRedirect Contractor] Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      debugPrint('[AuthRedirect Contractor] Fragment: $hash');
      debugPrint('[AuthRedirect Contractor] Query params: $queryParams');
      debugPrint('[AuthRedirect Contractor] Hash params: $hashParams');
      
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
      
      // For mobile, try to get the full URL including hash if available
      Uri urlToUse = uri;
      if (!kIsWeb && hash.isNotEmpty) {
        // On mobile, ensure hash is included in the URL
        final urlString = uri.toString();
        if (!urlString.contains('#')) {
          urlToUse = Uri.parse('$urlString#$hash');
          debugPrint('[AuthRedirect Contractor] Mobile - Added hash to URL: ${urlToUse.toString()}');
        } else {
          urlToUse = uri;
          debugPrint('[AuthRedirect Contractor] Mobile - Using URL with hash: ${urlToUse.toString()}');
        }
      } else if (kIsWeb && hash.isNotEmpty) {
        // On web, use the full href to ensure hash is included
        try {
          urlToUse = Uri.parse(html.window.location.href);
          debugPrint('[AuthRedirect Contractor] Web - Using full href: ${urlToUse.toString()}');
        } catch (e) {
          debugPrint('[AuthRedirect Contractor] Error parsing full href: $e');
        }
      }
      
      debugPrint('[AuthRedirect Contractor] Using URL: ${urlToUse.toString()}');
      debugPrint('[AuthRedirect Contractor] Hash: $hash');
      debugPrint('[AuthRedirect Contractor] Query params: ${urlToUse.queryParameters}');
      debugPrint('[AuthRedirect Contractor] Fragment: ${urlToUse.fragment}');
      
      try {
        final response = await supabase.auth.getSessionFromUrl(urlToUse, storeSession: true);
        session = response.session;
        debugPrint('[AuthRedirect Contractor] getSessionFromUrl succeeded');
      } catch (e) {
        debugPrint('[AuthRedirect Contractor] getSessionFromUrl failed, trying current session: $e');
        session = supabase.auth.currentSession;
      }

      // If no session from URL, wait a bit and try current session (for mobile deep links)
      if (session == null) {
        await Future.delayed(const Duration(seconds: 1));
        session = supabase.auth.currentSession;
        debugPrint('[AuthRedirect Contractor] After 1s delay, session: ${session != null}');
      }

      // If still no session, wait a bit more (for async auth state changes)
      if (session == null) {
        await Future.delayed(const Duration(seconds: 2));
        session = supabase.auth.currentSession;
        debugPrint('[AuthRedirect Contractor] After 2s delay, session: ${session != null}');
      }
      
      // Try one more time with auth state listener
      if (session == null) {
        debugPrint('[AuthRedirect Contractor] Still no session, waiting for auth state change...');
        
        // Try to get session from auth state with timeout
        final authState = supabase.auth.onAuthStateChange;
        final completer = Completer<Session?>();
        late StreamSubscription sub;
        
        sub = authState.listen((data) {
          debugPrint('[AuthRedirect Contractor] Auth state changed: ${data.event}, hasSession: ${data.session != null}');
          if (data.session != null) {
            if (!completer.isCompleted) {
              completer.complete(data.session);
            }
            sub.cancel();
          }
        });
        
        // Wait for auth state change with timeout
        try {
          session = await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('[AuthRedirect Contractor] Auth state listener timeout after 5s');
              sub.cancel();
              return supabase.auth.currentSession;
            },
          );
        } catch (e) {
          debugPrint('[AuthRedirect Contractor] Auth state listener error: $e');
          sub.cancel();
          session = supabase.auth.currentSession;
        }
      }

      // Final check - if still no session after all attempts, redirect to login
      if (session == null) {
        debugPrint('[AuthRedirect Contractor] No session after all attempts. Redirecting to login.');
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          // Show error message before redirecting
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
