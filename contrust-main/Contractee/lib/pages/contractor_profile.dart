// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

// ignore: depend_on_referenced_packages
import 'package:contractor/blocs/userprofile.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class ContractorProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorProfileScreen({super.key, required this.contractorId});

  @override
  _ContractorProfileScreenState createState() => _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen> {
  final UserService userService = UserService();

  String firmName = "Firm Name";
  String bio = "No Bio";
  double rating = 4.5;
  List<Uint8List> pastProjects = [];
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _loadContractorData();
  }

  Future<void> _loadContractorData() async {
    final contractorData = await userService.fetchContractorData(
      widget.contractorId,
    );
    if (contractorData != null) {
      setState(() {
        firmName = contractorData['firm_name'] ?? "No firm name";
        bio = contractorData['bio'] ?? "No bio available";
        rating = contractorData['rating'] ?? 4.5;
        profileImage = contractorData['profile_photo'] ?? 'default_image_url';
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load contractor data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // ignore: unused_local_variable
    int crossAxisCount =
        screenWidth > 1000
            ? 4
            : screenWidth > 600
            ? 3
            : 2;

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
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                width: double.infinity,
                child: Image.asset('bgloginscreen.jpg', fit: BoxFit.cover),
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
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade300,
                              child: profileImage != null
                                  ? ClipOval(
                                      child: Image.network(
                                        profileImage!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
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
                            Text(firmName, style: TextStyle(fontSize: 14)),
                            SizedBox(height: 10),
                            Text(
                              "Bio",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(bio, textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            Text(
                              "Rating:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.orange,
                                );
                              }),
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
