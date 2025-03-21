import 'package:backend/auth_service.dart';
import 'package:backend/pagetransition.dart';
import 'package:contractor/Screen/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpContractor {
  void signUpUser( 
    BuildContext context,
    String email,
    String password,
    Map<String, dynamic>? data,
    bool Function() validateFields,
  ) async {
    final authService = AuthService();

    if (!validateFields()) {
      return;
    }

    try {
      final signUpResponse = await authService.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (!context.mounted) return;

      if (signUpResponse.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account successfully created'),
            backgroundColor: Colors.green,
          ),
        );
        transitionBuilder(context, LoginScreen());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error creating account'),
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
