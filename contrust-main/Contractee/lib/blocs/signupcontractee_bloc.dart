import 'package:backend/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpContractee {
  void signUpContractee(
    BuildContext context, 
    String email, 
    String password,
    Map<String, dynamic>? data, 
    bool Function() validateFields
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
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error creating account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on AuthException catch (error) {
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
