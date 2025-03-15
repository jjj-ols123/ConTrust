import 'package:backend/auth_service.dart';
import 'package:contractor/Screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInContractee { 
  
  void signInUser(BuildContext context, String email, String password, bool Function() validateFields) async {
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

      if (signInResponse.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged in'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      ); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging in'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    on PostgrestException catch (error) {
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