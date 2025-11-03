// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRedirectPage extends StatefulWidget {
  const AuthRedirectPage({super.key});

  @override
  State<AuthRedirectPage> createState() => _AuthRedirectPageState();
}

class _AuthRedirectPageState extends State<AuthRedirectPage> {
  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    final next = Uri.base.queryParameters['next'] ?? '/dashboard';

    // Debug logging
    print('AuthRedirect - Current URL: ${Uri.base}');
    print('AuthRedirect - Next parameter: $next');
    print('AuthRedirect - Query parameters: ${Uri.base.queryParameters}');

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(Uri.base);

      if (!mounted) return;
      print('AuthRedirect - Redirecting to: $next');
      context.go(next);
    } catch (e) {
      print('AuthRedirect - Error: $e');
      if (!mounted) return;
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}