// ignore_for_file: use_build_context_synchronously

import 'package:backend/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpContractor {
  void signUpContractor(
    BuildContext context,
    String email,
    String password,
    String userType,
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

      if (signUpResponse.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error creating account'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (userType == 'contractor') {
        final contractorData = {
          'contractor_id': signUpResponse.user!.id,
          'firm_name': data?['firmName'],
          'contact_number': data?['contactNumber'],
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

        try {
          await Supabase.instance.client
              .from('Contractor')
              .insert(contractorData);
        } catch (e) {
          try {
            await Supabase.instance.client.auth.admin.deleteUser(
              signUpResponse.user!.id,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error Deleting Account'),
              backgroundColor: Colors.red,
            ),
          );
          }

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving contractor data: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account successfully created'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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