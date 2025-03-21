// ignore_for_file: use_build_context_synchronously

import 'package:backend/auth_service.dart';
import 'package:backend/pagetransition.dart';
import 'package:contractor/Screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInContractor { 
  void signInContractor(
    BuildContext context,
    String email,
    String password,
    bool Function() validateFields,
  ) async {
    final authService = AuthService();

    if (!validateFields()) {
      return;
    }

    try {
      final signInResponse = await authService.signIn(
        email: email,
        password: password,
      );

      if (!context.mounted) return;

      if (signInResponse.user == null) {
        throw AuthException('Invalid email or password');
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];
      
      if (userType?.toLowerCase() != 'contractor') {
        throw AuthException('Access denied: Not a contractor');
        
      }

      if (signInResponse.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged in'),
            backgroundColor: Colors.green,
          ),
        );
          transitionBuilder(context, DashboardScreen());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging in'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PostgrestException catch (error) {

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );

    }
  }
}
