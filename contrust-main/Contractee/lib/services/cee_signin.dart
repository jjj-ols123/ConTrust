// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/be_user_service.dart';
import 'package:flutter/material.dart';

class SignInContractee {
  void signInContractee(BuildContext modalContext, String email,
      String password, bool Function() validateFields) async {
    if (!validateFields()) {
      return;
    }

    try {
      final signInResponse = await UserService().signIn(
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

      Navigator.pushNamedAndRemoveUntil(
        modalContext,
        '/home',
        (route) => false,
      );

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
          content: Text('Error logging in'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
