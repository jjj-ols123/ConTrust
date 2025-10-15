import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
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
        ConTrustSnackBar.error(context, 'Error creating account');
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
      ConTrustSnackBar.success(context, 'Account successfully created');
      Navigator.pop(context);
    } on AuthException {
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Error creating account');
    } catch (e) {
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Unexpected error');
    }
  }
}
