// ignore_for_file: use_build_context_synchronously

import 'package:backend/auth_service.dart';
import 'package:contractee/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        throw AuthException('Invalid email or password');
      }

      final userProfile = await authService.getUserProfile(signInResponse.user!.id);
      final userType = userProfile?['user_type'];

      if (userType != 'contractee') {
        throw AuthException('Access denied: Not a contractee');
      }


      Navigator.pop(modalContext); 

      Navigator.pushReplacement(
        modalContext,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged in'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } on PostgrestException catch (error) {
      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
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