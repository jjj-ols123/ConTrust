// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String firmName = "Pau Construction Firm";
  String bio = "Specializes in:\n- House Construction\n- Roof\n- Swimming Pool";
  double rating = 4.5;
  List<Uint8List> pastProjects = [];
  Uint8List? profileImage;

  Future<void> pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        profileImage = bytes;
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        pastProjects.add(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine number of grid columns based on screen width
    int crossAxisCount = screenWidth > 1000
        ? 4 // Large screens
        : screenWidth > 600
            ? 3 // Medium screens (Tablets)
            : 2; // Small screens (Mobile)

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Home',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Image.asset('logo3.png', width: 100),
          ),
        ],
      ),
      body: SingleChildScrollView( // Make screen scrollable
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                width: double.infinity,
                child: Image.asset(
                  'bgloginscreen.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 5,
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: pickProfileImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade300,
                                child: profileImage != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          profileImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Construction Firm Name",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              firmName,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Bio",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              bio,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Rating:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: Colors.orange,
                                );
                              }),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/editprofile',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                "Edit Profile",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 5,
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Photos of Past Projects",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                double availableHeight = 
                                    MediaQuery.of(context).size.height * 0.4; // Set height dynamically

                                return SizedBox(
                                  height: pastProjects.isEmpty ? 50 : availableHeight,
                                  child: pastProjects.isEmpty
                                      ? Center(
                                          child: Text(
                                            "No project photos yet.",
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        )
                                      : GridView.builder(
                                          shrinkWrap: true, // Important: Prevent infinite height
                                          physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 1,
                                          ),
                                          itemCount: pastProjects.length,
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(
                                                pastProjects[index],
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                );
                              },
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: pickImage,
                              child: Text("Upload Project Photo"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
