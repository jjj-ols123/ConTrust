// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'package:backend/services/be_user_service.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final bool isContractor;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.isContractor,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController firstController = TextEditingController();
  TextEditingController secondController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userData = await UserService().fetchUserData(
      widget.userId,
      isContractor: widget.isContractor,
    );

    if (userData != null) {
      setState(() {
        firstController.text = widget.isContractor
            ? userData['firm_name'] ?? ""
            : userData['full_name'] ?? "";
        secondController.text = widget.isContractor
            ? userData['bio'] ?? ""
            : userData['address'] ?? "";
      });
    }
  }

  Future<void> _updateProfile() async {
    final success = await UserService().updateUserProfile(
      widget.userId,
      firstController.text,
      secondController.text,
      isContractor: widget.isContractor,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
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
        title: const Text(
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
              controller: firstController,
              decoration: InputDecoration(
                labelText:
                    widget.isContractor ? "Firm Name" : "Full Name",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secondController,
              decoration: InputDecoration(
                labelText: widget.isContractor ? "Bio" : "Address",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
