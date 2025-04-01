// ignore_for_file: use_build_context_synchronously

import 'package:backend/auth_service.dart';
import 'package:backend/pagetransition.dart';
import 'package:flutter/material.dart';

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

      if (signInResponse.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];

      if (userType?.toLowerCase() != 'contractor') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not a contractee...'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged in'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(milliseconds: 1000), () {
        transitionBuilder(context, getScreenFromRoute(context, '/dashboard'), replace: true);

      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
