import 'package:flutter/material.dart';
import '../build/buildproj.dart';

class ProjectsManagementPage extends StatelessWidget {
  const ProjectsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: const ProjectsManagementTable(),
      ),
    );
  }
}