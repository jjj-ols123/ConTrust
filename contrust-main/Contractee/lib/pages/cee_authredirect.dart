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
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    _handleAuthRedirect();
  }

  Future<void> _handleAuthRedirect() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        await Future.delayed(const Duration(seconds: 2));
        final newSession = supabase.auth.currentSession;
        if (newSession == null) {
          if (mounted && !_hasRedirected) {
            _hasRedirected = true;
            context.go('/');
          }
          return;
        }
      }
      
      final user = session?.user ?? supabase.auth.currentSession?.user;
      if (user == null) {
        if (mounted && !_hasRedirected) {
          _hasRedirected = true;
          context.go('/');
        }
        return;
      }

      final contracteeData = await supabase
          .from('Contractee')
          .select()
          .eq('contractee_id', user.id)
          .maybeSingle();

      final contractorData = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', user.id)
          .maybeSingle();

      if (mounted && !_hasRedirected) {
        _hasRedirected = true;
        if (contracteeData != null) {
          context.go('/home');
        } else if (contractorData != null) {
          context.go('/dashboard');
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
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber),  
      ),
    );
  }
}