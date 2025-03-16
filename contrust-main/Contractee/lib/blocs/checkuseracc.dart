// ignore_for_file: unused_element

import 'package:contractee/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckUserLogin { 
  
  void checkUserLogin(BuildContext context) {

    if (!isLoggedIn()) {
      showModalBottomSheet(
        shape: CircleBorder(),
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => LoginPage(modalContext: modalContext),
      );
  }
  }

  bool isLoggedIn() {
    final supabase = Supabase.instance.client;
    return supabase.auth.currentUser != null;
  }

}