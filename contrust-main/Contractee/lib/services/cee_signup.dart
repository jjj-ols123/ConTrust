import 'package:backend/services/be_user_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpContractee {
  void signUpContractee(
    BuildContext context,
    String email,
    String password,
    String userType,
    Map<String, dynamic>? data,
    bool Function() validateFields,
  ) async {
  
    final supabase = Supabase.instance.client;
    int project = 0;

    if (!validateFields()) {
      return;
    }

    try {
      final signUpResponse = await UserService().signUp(
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

      if (userType == 'contractee') {
        final contracteeData = {
          'contractee_id': signUpResponse.user!.id,
          'full_name': data?['full_name'],
          'address': data?['address'] ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'project_history_count': project,
        };

        final insertResponse = await supabase
            .from('Contractee')
            .insert(contracteeData)
            .select(); 

        if (insertResponse.isEmpty) {
          throw Exception("Error saving contractee data");
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
