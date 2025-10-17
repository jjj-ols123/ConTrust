import 'package:flutter/material.dart';
import 'package:superadmin/build/builduser.dart';

class UsersManagementPage extends StatelessWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: const UsersManagementTable(),
      ),
    );
  }
}