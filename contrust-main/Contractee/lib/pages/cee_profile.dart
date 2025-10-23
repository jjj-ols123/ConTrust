// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use
import 'package:backend/services/contractee services/cee_profileservice.dart';
import 'package:contractee/build/buildceeprofile.dart';
import 'package:flutter/material.dart';

class CeeProfilePage extends StatefulWidget {
  final String contracteeId;

  const CeeProfilePage({super.key, required this.contracteeId});

  @override
  _CeeProfilePageState createState() => _CeeProfilePageState();
}

class _CeeProfilePageState extends State<CeeProfilePage> {
  String firstName = '';
  String lastName = '';
  String bio = '';
  String contactNumber = '';
  String address = '';
  String? profileImage;
  bool isLoading = true;
  bool isUploading = false;
  int completedProjectsCount = 0;
  int ongoingProjectsCount = 0;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  String selectedTab = 'Projects'; 

  bool isEditingBio = false;
  bool isEditingContact = false;
  bool isEditingFirstName = false;
  bool isEditingLastName = false;
  bool isEditingAddress = false;
  
  final TextEditingController bioController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  List<Map<String, dynamic>> projectHistory = [];
  List<Map<String, dynamic>> ongoingProjects = [];

  @override
  void initState() {
    super.initState();
    loadContracteeData();
  }

  @override
  void dispose() {
    bioController.dispose();
    contactController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> loadContracteeData() async {
    try {
      setState(() => isLoading = true);
      
      final result = await CeeProfileService().loadContracteeData(widget.contracteeId);
      final contracteeData = result['contracteeData'];
      
      setState(() {
        if (contracteeData != null) {
          firstName = contracteeData['first_name'] ?? "No first name";
          lastName = contracteeData['last_name'] ?? "No last name";
          bio = contracteeData['bio'] ?? "No bio available";
          contactNumber = contracteeData['contact_number'] ?? "No contact number";
          address = contracteeData['address'] ?? "No address provided";
          profileImage = contracteeData['profile_photo'];
        }
        
        completedProjectsCount = result['completedProjectsCount'];
        ongoingProjectsCount = result['ongoingProjectsCount'];
        projectHistory = result['projectHistory'];
        ongoingProjects = result['ongoingProjects'];
        isLoading = false;
      });
      
      _updateControllers();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _updateControllers() {
    bioController.text = bio;
    contactController.text = contactNumber;
    firstNameController.text = firstName;
    lastNameController.text = lastName;
    addressController.text = address;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Colors.amber,)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.amber.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.amber.shade200, width: 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_outline, color: Colors.amber.shade700, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadContracteeData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  
                  if (isMobile) {
                    return SingleChildScrollView(
                      child: CeeProfileBuildMethods.buildMobileLayout(
                        firstName: firstName,
                        lastName: lastName,
                        profileImage: profileImage,
                        profileUrl: profileUrl,
                        completedProjectsCount: completedProjectsCount,
                        ongoingProjectsCount: ongoingProjectsCount,
                        selectedTab: selectedTab,
                        onTabChanged: (String tab) {
                          setState(() {
                            selectedTab = tab;
                          });
                        },
                        mainContent: _buildMainContent(),
                      ),
                    );
                  } else {
                    return CeeProfileBuildMethods.buildDesktopLayout(
                      firstName: firstName,
                      lastName: lastName,
                      profileImage: profileImage,
                      profileUrl: profileUrl,
                      completedProjectsCount: completedProjectsCount,
                      ongoingProjectsCount: ongoingProjectsCount,
                      selectedTab: selectedTab,
                      onTabChanged: (String tab) {
                        setState(() {
                          selectedTab = tab;
                        });
                      },
                      mainContent: _buildMainContent(),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return CeeProfileBuildMethods.buildMainContent(
      selectedTab,
      () => _buildProjectsContent(),
      () => _buildAboutContent(),
      () => _buildHistoryContent(),
    );
  }

  Widget _buildProjectsContent() {
    return CeeProfileBuildMethods.buildProjects(
      ongoingProjects: ongoingProjects,
      getTimeAgo: _getTimeAgo,
    );
  }

  Widget _buildAboutContent() {
    return CeeProfileBuildMethods.buildAbout(
      context: context,
      firstName: firstName,
      lastName: lastName,
      bio: bio,
      contactNumber: contactNumber,
      address: address,
      isEditingFirstName: isEditingFirstName,
      isEditingLastName: isEditingLastName,
      isEditingBio: isEditingBio,
      isEditingContact: isEditingContact,
      isEditingAddress: isEditingAddress,
      firstNameController: firstNameController,
      lastNameController: lastNameController,
      bioController: bioController,
      contactController: contactController,
      addressController: addressController,
      toggleEditFirstName: () => _toggleEdit('firstName'),
      toggleEditLastName: () => _toggleEdit('lastName'),
      toggleEditBio: () => _toggleEdit('bio'),
      toggleEditContact: () => _toggleEdit('contact'),
      toggleEditAddress: () => _toggleEdit('address'),
      saveFirstName: () => _saveField('firstName', firstNameController.text),
      saveLastName: () => _saveField('lastName', lastNameController.text),
      saveBio: () => _saveField('bio', bioController.text),
      saveContact: () => _saveField('contact', contactController.text),
      saveAddress: () => _saveField('address', addressController.text),
      contracteeId: widget.contracteeId,
    );
  }

  Widget _buildHistoryContent() {
    return CeeProfileBuildMethods.buildHistory(
      projectHistory: projectHistory,
      getTimeAgo: _getTimeAgo,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    return CeeProfileService().getTimeAgo(dateTime);
  }

  void _toggleEdit(String fieldType) {
    setState(() {
      switch (fieldType) {
        case 'bio':
          isEditingBio = !isEditingBio;
          if (!isEditingBio) bioController.text = bio; 
          break;
        case 'contact':
          isEditingContact = !isEditingContact;
          if (!isEditingContact) contactController.text = contactNumber;
          break;
        case 'firstName':
          isEditingFirstName = !isEditingFirstName;
          if (!isEditingFirstName) firstNameController.text = firstName;
          break;
        case 'lastName':
          isEditingLastName = !isEditingLastName;
          if (!isEditingLastName) lastNameController.text = lastName;
          break;
        case 'address':
          isEditingAddress = !isEditingAddress;
          if (!isEditingAddress) addressController.text = address;
          break;
      }
    });
  }

  Future<void> _saveField(String fieldType, String newValue) async {
    await CeeProfileService().handleSaveField(
      contracteeId: widget.contracteeId,
      fieldType: fieldType,
      newValue: newValue,
      context: context,
      onSuccess: () {
        setState(() {
          switch (fieldType) {
            case 'bio':
              bio = newValue;
              isEditingBio = false;
              break;
            case 'contact':
              contactNumber = newValue;
              isEditingContact = false;
              break;
            case 'firstName':
              firstName = newValue;
              isEditingFirstName = false;
              break;
            case 'lastName':
              lastName = newValue;
              isEditingLastName = false;
              break;
            case 'address':
              address = newValue;
              isEditingAddress = false;
              break;
          }
        });
      },
    );
  }
}