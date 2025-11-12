// ignore_for_file: use_build_context_synchronously, avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
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
      debugPrint('[AuthRedirect Contractee] handling OAuth redirect...');
      final supabase = Supabase.instance.client;
      
      // On mobile, wait a bit for the deep link to be fully processed
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final uri = Uri.base;
      final hash = uri.fragment;
      final hashParams = hash.isNotEmpty ? Uri.splitQueryString(hash) : <String, String>{};
      final queryParams = uri.queryParameters;
      
      debugPrint('[AuthRedirect Contractee] Initial URI: ${uri.toString()}');
      debugPrint('[AuthRedirect Contractee] Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      debugPrint('[AuthRedirect Contractee] Fragment: $hash');
      debugPrint('[AuthRedirect Contractee] Query params: $queryParams');
      debugPrint('[AuthRedirect Contractee] Hash params: $hashParams');
      
      // Check for password reset flow
      final isPasswordReset = hashParams['type'] == 'recovery' && 
                             !hashParams.containsKey('refresh_token') ||
                             queryParams['type'] == 'recovery' && 
                             !queryParams.containsKey('refresh_token') ||
                             (hashParams.containsKey('access_token') && hashParams['type'] == 'recovery' && !hashParams.containsKey('refresh_token'));
      
      if (isPasswordReset) {
        debugPrint('[AuthRedirect Contractee] Detected password reset flow, redirecting to /auth/reset-password');
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          if (kIsWeb && hash.isNotEmpty) {
            try {
              final baseUrl = html.window.location.origin;
              final hashWithPrefix = hash.startsWith('#') ? hash : '#$hash';
              html.window.location.href = '$baseUrl/auth/reset-password$hashWithPrefix';
              return;
            } catch (e) {
              debugPrint('[AuthRedirect Contractee] Error setting location with hash: $e');
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
          debugPrint('[AuthRedirect Contractee] Mobile - Added hash to URL: ${urlToUse.toString()}');
        }
      } else if (kIsWeb && hash.isNotEmpty) {
        // On web, use the full href to ensure hash is included
        try {
          urlToUse = Uri.parse(html.window.location.href);
          debugPrint('[AuthRedirect Contractee] Web - Using full href: ${urlToUse.toString()}');
        } catch (e) {
          debugPrint('[AuthRedirect Contractee] Error parsing full href: $e');
        }
      }
      
      debugPrint('[AuthRedirect Contractee] Using URL: ${urlToUse.toString()}');
      debugPrint('[AuthRedirect Contractee] Hash: $hash');
      debugPrint('[AuthRedirect Contractee] Query params: ${urlToUse.queryParameters}');
      debugPrint('[AuthRedirect Contractee] Fragment: ${urlToUse.fragment}');
      
      try {
        final response = await supabase.auth.getSessionFromUrl(urlToUse, storeSession: true);
        session = response.session;
        debugPrint('[AuthRedirect Contractee] getSessionFromUrl succeeded');
      } catch (e) {
        debugPrint('[AuthRedirect Contractee] getSessionFromUrl failed, trying current session: $e');
        session = supabase.auth.currentSession;
      }

      // If no session from URL, wait a bit and try current session (for mobile deep links)
      if (session == null) {
        await Future.delayed(const Duration(seconds: 1));
        session = supabase.auth.currentSession;
        debugPrint('[AuthRedirect Contractee] After 1s delay, session: ${session != null}');
      }

      // If still no session, wait a bit more (for async auth state changes)
      if (session == null) {
        await Future.delayed(const Duration(seconds: 2));
        session = supabase.auth.currentSession;
        debugPrint('[AuthRedirect Contractee] After 2s delay, session: ${session != null}');
      }
      
      // Try one more time with auth state listener
      if (session == null) {
        debugPrint('[AuthRedirect Contractee] Still no session, waiting for auth state change...');
        
        // Try to get session from auth state with timeout
        final authState = supabase.auth.onAuthStateChange;
        final completer = Completer<Session?>();
        late StreamSubscription sub;
        
        sub = authState.listen((data) {
          debugPrint('[AuthRedirect Contractee] Auth state changed: ${data.event}, hasSession: ${data.session != null}');
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
              debugPrint('[AuthRedirect Contractee] Auth state listener timeout after 5s');
              sub.cancel();
              return supabase.auth.currentSession;
            },
          );
        } catch (e) {
          debugPrint('[AuthRedirect Contractee] Auth state listener error: $e');
          sub.cancel();
          session = supabase.auth.currentSession;
        }
      }

      // Final check - if still no session after all attempts, redirect to login
      if (session == null) {
        debugPrint('[AuthRedirect Contractee] No session after all attempts. Redirecting to login.');
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
            context.go('/login');
          }
        }
        return;
      }

      final user = session.user;
      debugPrint('[AuthRedirect Contractee] session user: ${user.id}');

      // Proceed directly; backend post-login handling will run server-side

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
          debugPrint('[AuthRedirect Contractee] no refreshed session -> /login');
          context.go('/login');
        }
        return;
      }

      final currentUser = refreshedSession.user;

      final contracteeData = await supabase
          .from('Contractee')
          .select()
          .eq('contractee_id', currentUser.id)
          .maybeSingle();
      debugPrint('[AuthRedirect Contractee] contractee row exists: ${contracteeData != null}');

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contracteeData != null) {
          debugPrint('[AuthRedirect Contractee] navigate -> /home');
          context.go('/home');
        } else {
          debugPrint('[AuthRedirect Contractee] navigate -> /login');
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('[AuthRedirect Contractee] Error in contractee auth redirect: $e');
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