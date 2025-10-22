import 'package:flutter/material.dart';
import 'package:superadmin/build/buildverify.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: VerificationManagementTable(),
      backgroundColor: Colors.white,
    );
  }
}