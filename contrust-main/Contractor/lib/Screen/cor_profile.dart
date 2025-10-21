// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/contractor services/cor_profileservice.dart';
import 'package:flutter/material.dart';
import 'package:contractor/build/buildprofile.dart';

class ContractorUserProfileScreen extends StatefulWidget {
  final String contractorId;

  const ContractorUserProfileScreen({super.key, required this.contractorId});

  @override
  _ContractorUserProfileScreenState createState() =>
      _ContractorUserProfileScreenState();
}

class _ContractorUserProfileScreenState
    extends State<ContractorUserProfileScreen> {
  late String firmName;
  late String bio;
  late String contactNumber;
  late String specialization;
  late String address;
  late double rating;
  late List<String> pastProjects;
  late String? profileImage;
  bool isLoading = true;
  bool isUploading = false;
  bool isUploadingProfile = false;
  int completedProjectsCount = 0;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  String selectedTab = 'Portfolio'; 

  bool isEditingBio = false;
  bool isEditingContact = false;
  bool isEditingSpecialization = false;
  bool isEditingFirmName = false;
  bool isEditingAddress = false;
  
  late TextEditingController bioController;
  late TextEditingController contactController;
  late TextEditingController specializationController;
  late TextEditingController firmNameController;
  late TextEditingController addressController;

  List<Map<String, dynamic>> completedProjects = [];
  List<Map<String, dynamic>> filteredProjects = [];
  late TextEditingController searchController;

  List<Map<String, dynamic>> allRatings = [];
  Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    loadContractorData();
    _loadCompletedProjects();
    bioController = TextEditingController();
    contactController = TextEditingController();
    specializationController = TextEditingController();
    firmNameController = TextEditingController();
    addressController = TextEditingController();
    searchController = TextEditingController();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    bioController.dispose();
    contactController.dispose();
    specializationController.dispose();
    firmNameController.dispose();
    addressController.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadContractorData() async {
    try {
      setState(() => isLoading = true);
      
      final result = await CorProfileService().loadContractorData(widget.contractorId);
      final contractorData = result['contractorData'];
      
      setState(() {
        if (contractorData != null) {
          firmName = contractorData['firm_name'] ?? "No firm name";
          bio = contractorData['bio'] ?? "No bio available";
          contactNumber = contractorData['contact_number'] ?? "No contact number";
          specialization = contractorData['specialization'] ?? "No specialization";
          address = contractorData['address'] ?? "No address provided";
          rating = contractorData['rating']?.toDouble() ?? 0.0;
          profileImage = contractorData['profile_photo'];
          pastProjects = List<String>.from(
            contractorData['past_projects'] ?? [],
          );
        }
        
        completedProjectsCount = result['completedProjectsCount'];
        allRatings = result['allRatings'];
        ratingDistribution = result['ratingDistribution'];
        totalReviews = result['totalReviews'];
        isLoading = false;
      });
      
      _updateControllers();
      await _loadCompletedProjects();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _updateControllers() {
    bioController.text = bio;
    contactController.text = contactNumber;
    specializationController.text = specialization;
    firmNameController.text = firmName;
    addressController.text = address;
  }

  Future<void> _loadCompletedProjects() async {
    final projects = await FetchService().fetchCompletedProjects();
    setState(() {
      completedProjects = projects;
      filteredProjects = projects;
    });
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProjects = completedProjects.where((project) {
        final clientName = (project['contractee']?['full_name'] ?? '').toLowerCase();
        final type = (project['type'] ?? '').toLowerCase();
        final description = (project['description'] ?? '').toLowerCase();
        return clientName.contains(query) ||
            type.contains(query) ||
            description.contains(query);
      }).toList();
    });
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
            height: 60,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profile',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadContractorData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  
                  if (isMobile) {
                    return SingleChildScrollView(
                      child: ProfileBuildMethods.buildMobileLayout(
                        firmName: firmName,
                        specialization: specialization,
                        profileImage: profileImage,
                        profileUrl: profileUrl,
                        completedProjectsCount: completedProjectsCount,
                        rating: rating,
                        pastProjects: pastProjects,
                        selectedTab: selectedTab,
                        onTabChanged: (String tab) {
                          setState(() {
                            selectedTab = tab;
                          });
                        },
                        mainContent: _buildMainContent(),
                        onProfilePhotoUpload: () => CorProfileService().handleUploadProfilePhoto(
                          contractorId: widget.contractorId,
                          context: context,
                          setUploading: (loading) => setState(() => isUploadingProfile = loading),
                          onSuccess: loadContractorData,
                        ),
                        onViewProfilePhoto: () => ProfileBuildMethods.showPhotoDialog(
                          context,
                          {'photo_url': profileImage ?? profileUrl},
                        ),
                      ),
                    );
                  } else {
                    return ProfileBuildMethods.buildDesktopLayout(
                      firmName: firmName,
                      specialization: specialization,
                      profileImage: profileImage,
                      profileUrl: profileUrl,
                      completedProjectsCount: completedProjectsCount,
                      rating: rating,
                      pastProjects: pastProjects,
                      selectedTab: selectedTab,
                      onTabChanged: (String tab) {
                        setState(() {
                          selectedTab = tab;
                        });
                      },
                      mainContent: _buildMainContent(),
                      onProfilePhotoUpload: () => CorProfileService().handleUploadProfilePhoto(
                        contractorId: widget.contractorId,
                        context: context,
                        setUploading: (loading) => setState(() => isUploadingProfile = loading),
                        onSuccess: loadContractorData,
                      ),
                      onViewProfilePhoto: () => ProfileBuildMethods.showPhotoDialog(
                        context,
                        {'photo_url': profileImage ?? profileUrl},
                      ),
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
    return ProfileBuildMethods.buildMainContent(
      selectedTab,
      () => _buildPortfolio(),
      () => _buildAboutContent(),
      () => _buildReviewsContent(),
      () => _buildClientHistory(),
    );
  }

  Widget _buildPortfolio() {
    return ProfileBuildMethods.buildPortfolio(
      bio: bio,
      pastProjects: pastProjects,
      isUploading: isUploading,
      uploadProjectPhoto: () => CorProfileService().handleUploadProjectPhoto(
        contractorId: widget.contractorId,
        context: context,
        setUploading: (loading) => setState(() => isUploading = loading),
        onSuccess: loadContractorData,
      ),
      context: context,
      onViewPhoto: (String photoUrl) => ProfileBuildMethods.showPhotoDialog(
        context,
        {'photo_url': photoUrl},
      ),
    );
  }

  Widget _buildAboutContent() {
    return ProfileBuildMethods.buildAbout(
      context: context,
      firmName: firmName,
      bio: bio,
      contactNumber: contactNumber,
      specialization: specialization,
      address: address,
      isEditingFirmName: isEditingFirmName,
      isEditingBio: isEditingBio,
      isEditingContact: isEditingContact,
      isEditingSpecialization: isEditingSpecialization,
      isEditingAddress: isEditingAddress,
      firmNameController: firmNameController,
      bioController: bioController,
      contactController: contactController,
      specializationController: specializationController,
      addressController: addressController,
      toggleEditFirmName: () => _toggleEdit('firmName'),
      toggleEditBio: () => _toggleEdit('bio'),
      toggleEditContact: () => _toggleEdit('contact'),
      toggleEditSpecialization: () => _toggleEdit('specialization'),
      toggleEditAddress: () => _toggleEdit('address'),
      saveFirmName: () => _saveField('firmName', firmNameController.text),
      saveBio: () => _saveField('bio', bioController.text),
      saveContact: () => _saveField('contact', contactController.text),
      saveSpecialization: () => _saveField('specialization', specializationController.text),
      saveAddress: () => _saveField('address', addressController.text),
      contractorId: widget.contractorId,
    );
  }

  Widget _buildReviewsContent() {
    return ProfileBuildMethods.buildReviewsContainer(
      rating: rating,
      totalReviews: totalReviews,
      getRatingPercentage: _getRatingPercentage,
      buildRatingBar: _buildRatingBar,
      allRatings: allRatings,
      buildReviewCard: _buildReviewCard,
      getTimeAgo: _getTimeAgo,
    );
  }

  Widget _buildClientHistory() {
    return ProfileBuildMethods.buildClientHistory(
      filteredProjects: filteredProjects,
      searchController: searchController,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    return CorProfileService().getTimeAgo(dateTime);
  }

  double _getRatingPercentage(int stars) {
    return CorProfileService().getRatingPercentage(stars, totalReviews, ratingDistribution);
  }
  
  Widget _buildRatingBar(String label, double percentage, Color color) {
    return ProfileBuildMethods.buildRatingBar(label, percentage, color);
  }

  Widget _buildReviewCard(String clientName, String review, double rating, String projectName, String timeAgo) {
    return ProfileBuildMethods.buildReviews(clientName, review, rating, projectName, timeAgo);
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
        case 'specialization':
          isEditingSpecialization = !isEditingSpecialization;
          if (!isEditingSpecialization) specializationController.text = specialization;
          break;
        case 'firmName':
          isEditingFirmName = !isEditingFirmName;
          if (!isEditingFirmName) firmNameController.text = firmName;
          break;
        case 'address':
          isEditingAddress = !isEditingAddress;
          if (!isEditingAddress) addressController.text = address;
          break;
      }
    });
  }

  Future<void> _saveField(String fieldType, String newValue) async {
    await CorProfileService().handleSaveField(
      contractorId: widget.contractorId,
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
            case 'specialization':
              specialization = newValue;
              isEditingSpecialization = false;
              break;
            case 'firmName':
              firmName = newValue;
              isEditingFirmName = false;
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