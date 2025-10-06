// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
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
      if (kIsWeb) {
        showDialog(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 600, 
              height: 1000, 
              child: LoginPage(modalContext: dialogContext),
            ),
          ),
        );
      } else {
        showModalBottomSheet(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (modalContext) => LoginPage(modalContext: modalContext),
        );
      }
    }
  }
}