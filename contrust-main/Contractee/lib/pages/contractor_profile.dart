// ignore_for_file: library_private_types_in_public_api

import 'package:backend/models/appbar.dart';
import 'package:backend/services/fetchmethods.dart';
import 'package:backend/services/userprofile.dart';
import 'package:contractee/pages/message_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractorProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorProfileScreen({super.key, required this.contractorId});

  @override
  _ContractorProfileScreenState createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen> {
  final UserService userService = UserService();
  final fetchClass = FetchClass();

  String firmName = "Firm Name";
  String bio = "No Bio";
  double rating = 4.5;
  List<String> pastProjects = [];
  String? profileImage;
  bool isLoading = true;
  bool isHiring = false;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  @override
  void initState() {
    super.initState();
    _loadContractorData();
  }

  Future<void> _loadContractorData() async {
    try {
      final contractorData =
          await fetchClass.fetchContractorData(widget.contractorId);
      if (contractorData != null) {
        setState(() {
          firmName = contractorData['firm_name'] ?? "No firm name";
          bio = contractorData['bio'] ?? "No bio available";
          rating = contractorData['rating']?.toDouble() ?? 4.5;
          final photo = contractorData['profile_photo'];
          profileImage = (photo == null || photo.isEmpty) ? profileUrl : photo;
          pastProjects = List<String>.from(
            contractorData['past_projects'] ?? [],
          );
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load contractor data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _hireContractor() async {
    setState(() => isHiring = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully initiated hiring process with $firmName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to hire contractor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isHiring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageButton = IconButton(
      icon: const Icon(Icons.message, color: Colors.black),
      tooltip: 'Message Contractor',
      onPressed: () {
        final currentUserId =
            Supabase.instance.client.auth.currentUser?.id ?? '';
        final chatRoomId = '${widget.contractorId}_$currentUserId';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePageContractee(
              chatRoomId: chatRoomId,
              contracteeId: currentUserId,
              contractorId: widget.contractorId,
              contractorName: firmName,
              contractorProfile: profileImage,
            ),
          ),
        );
      },
    );

    if (isLoading) {
      return Scaffold(
        appBar: ConTrustAppBar(
          headline: 'Contractor Profile',
          actions: [messageButton],
        ),
        drawer: const MenuDrawer(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    return Scaffold(
      appBar: ConTrustAppBar(
        headline: 'Contractor Profile',
        actions: [messageButton],
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey[200]),
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
                                    backgroundImage: (profileImage != null &&
                                            profileImage!.isNotEmpty)
                                        ? NetworkImage(profileImage!)
                                        : NetworkImage(profileUrl),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Construction Firm Name",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    firmName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
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
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Rating:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < rating.floor()
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
                          const SizedBox(height: 20),
                          Card(
                            elevation: 5,
                            color: Colors.amber.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Photos of Past Projects",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double availableHeight =
                                          MediaQuery.of(context).size.height *
                                              0.4;
                                      return SizedBox(
                                        height: pastProjects.isEmpty
                                            ? 50
                                            : availableHeight,
                                        child: pastProjects.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  "No project photos available.",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                            : GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
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
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      pastProjects[index],
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          Container(
                                                              color: Colors
                                                                  .grey[300]),
                                                    ),
                                                  );
                                                },
                                              ),
                                      );
                                    },
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
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isHiring ? null : _hireContractor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isHiring
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "HIRE THIS CONTRACTOR",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
