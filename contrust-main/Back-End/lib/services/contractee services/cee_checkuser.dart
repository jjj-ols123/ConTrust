// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contractee/pages/cee_login.dart'; 

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
      // Navigate to login page instead of showing as dialog/modal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }
}