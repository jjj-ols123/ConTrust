import 'package:backend/services/both%20services/be_user_service.dart';
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
    final supabase = Supabase.instance.client;

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

      if (userType == 'contractor') {
        final contractorData = {
          'contractor_id': signUpResponse.user!.id,
          'firm_name': data?['firmName'] ?? '',
          'contact_number': data?['contactNumber'],
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

        final insertResponse = await supabase
            .from('Contractor')
            .insert(contractorData)
            .select(); 

        if (insertResponse.isEmpty) {
          throw Exception("Error saving contractor data");
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
    } on AuthException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating account'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
