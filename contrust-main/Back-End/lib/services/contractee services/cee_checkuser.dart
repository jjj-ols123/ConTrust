// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckUserLogin {
  static void isLoggedIn({
    required BuildContext context,
    required VoidCallback onAuthenticated,
  }) async {

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      onAuthenticated();
    } else {
      if (context.mounted) context.go('/login');
    }
  }
}