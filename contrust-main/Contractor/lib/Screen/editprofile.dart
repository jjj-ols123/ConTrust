// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:contractor/blocs/userprofile.dart';
import 'package:flutter/material.dart';


class EditProfileScreen extends StatefulWidget {
  final String contractorId;

  const EditProfileScreen({super.key, required this.contractorId});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService userService = UserService();
  TextEditingController firmController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContractorData();
  }

  Future<void> _fetchContractorData() async {
    final contractorData = await userService.fetchContractorData(
      widget.contractorId,
    );
    if (contractorData != null) {
      setState(() {
        firmController.text = contractorData['firm_name'] ?? "";
        bioController.text = contractorData['bio'] ?? "";
      });
    }
  } 

  Future<void> _updateProfile() async {
    bool success = await userService.updateContractorProfile(
      widget.contractorId,
      firmController.text,
      bioController.text,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile Updated Successfully")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: firmController,
              decoration: InputDecoration(
                labelText: "Firm Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: bioController,
              decoration: InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
