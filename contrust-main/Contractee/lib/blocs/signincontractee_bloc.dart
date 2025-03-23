// ignore_for_file: use_build_context_synchronously

import 'package:backend/auth_service.dart';
import 'package:backend/pagetransition.dart';
import 'package:contractee/pages/home_page.dart';
import 'package:flutter/material.dart';

class SignInContractee {
  void signInContractee(BuildContext modalContext, String email, String password,
      bool Function() validateFields) async {
    final authService = AuthService();

    if (!validateFields()) {
      return;
    }

    try {
      final signInResponse = await authService.signIn(
        email: email,
        password: password,
      );

      if (signInResponse.user == null) {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
        return; 
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];
      
      if (userType?.toLowerCase() != 'contractee') {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Not a contractee...'),
            backgroundColor: Colors.red,
          ),
        );
        return; 
      }

      Navigator.pop(modalContext); 

      transitionBuilder(modalContext, HomePage());

      Future.delayed(const Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged in'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}