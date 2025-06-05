// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:backend/models/appbar.dart';
import 'package:backend/services/getuserdata.dart';
import 'package:backend/utils/pagetransition.dart';
import 'package:contractor/Screen/cor_editprofile.dart';
import 'package:backend/services/userprofile.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class ContractorUserProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorUserProfileScreen({super.key, required this.contractorId});

  @override
  _ContractorUserProfileScreenState createState() =>
      _ContractorUserProfileScreenState();
}

class _ContractorUserProfileScreenState
    extends State<ContractorUserProfileScreen> {
  final UserService userService = UserService();
  GetUserData getUserId = GetUserData();

  String firmName = "Firm Name";
  String bio = "No Bio";
  double rating = 4.5;
  List<Uint8List> pastProjects = [];
  String? profileImage;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  @override
  void initState() {
    super.initState();
    _loadContractorData();
  }

  Future<void> _loadContractorData() async {
    final contractorData = await userService.fetchUserData(
      widget.contractorId,
      isContractor: true,
    );
    if (contractorData != null) {
      setState(() {
        firmName = contractorData['firm_name'] ?? "No firm name";
        bio = contractorData['bio'] ?? "No bio available";
        rating = contractorData['rating'] ?? 4.5;
        profileImage = contractorData['profile_photo'];
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
    int crossAxisCount =
        screenWidth > 1000
            ? 4
            : screenWidth > 600
            ? 3
            : 2;

    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Profile"),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                width: double.infinity,
                child: Image.asset(
                  'assets/bgloginscreen.jpg',
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                                  ? NetworkImage(profileImage!)
                                  : NetworkImage(profileUrl),
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
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                String? contractorId =
                                    await getUserId.getContractorId();

                                transitionBuilder(
                                  context,
                                  EditProfileScreen(
                                    userId: contractorId ?? '',
                                    isContractor: true,
                                  ),
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
                                    MediaQuery.of(context).size.height * 0.4;
                                return SizedBox(
                                  height:
                                      pastProjects.isEmpty
                                          ? 50
                                          : availableHeight,
                                  child:
                                      pastProjects.isEmpty
                                          ? Center(
                                            child: Text(
                                              "No project photos yet.",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                          : GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      crossAxisCount,
                                                  crossAxisSpacing: 8,
                                                  mainAxisSpacing: 8,
                                                  childAspectRatio: 1,
                                                ),
                                            itemCount: pastProjects.length,
                                            itemBuilder: (context, index) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                              onPressed: () async {
                                Uint8List? imageBytes =
                                    await userService.pickImage();

                                if (imageBytes != null) {
                                  bool success = await userService
                                      .addPastProjectPhoto(
                                        widget.contractorId,
                                        imageBytes,
                                      );

                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Project photo uploaded successfully',
                                        ),
                                      ),
                                    );
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to upload project photo',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
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
