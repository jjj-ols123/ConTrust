// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use
import 'dart:async';
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
  String firmName = "Loading...";
  String bio = "Loading...";
  String contactNumber = "Loading...";
  String specialization = "Loading...";
  String address = "Loading...";
  String email = "";
  double rating = 0.0;
  List<String> pastProjects = [];
  String? profileImage;
  bool isLoading = true;
  bool isUploading = false;
  bool isUploadingProfile = false;
  int completedProjectsCount = 0;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  String selectedTab = 'Portfolio'; 

  bool isEditingBio = false;
  bool isEditingContact = false;
  bool isEditingFirmName = false;
  bool isEditingAddress = false;
  bool isEditingSpecialization = false;
  
  late TextEditingController bioController;
  late TextEditingController contactController;
  late TextEditingController firmNameController;
  late TextEditingController addressController;
  late TextEditingController specializationController;

  List<Map<String, dynamic>> completedProjects = [];
  List<Map<String, dynamic>> filteredProjects = [];
  List<Map<String, dynamic>> allProjects = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  late TextEditingController searchController;
  late TextEditingController transactionSearchController;

  Stream<List<Map<String, dynamic>>>? _completedProjectsStream;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;

  List<Map<String, dynamic>> allRatings = [];
  Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  int totalReviews = 0;
  String? _error;
  
  String selectedProjectStatus = 'All';
  String selectedPaymentType = 'All';

  @override
  void initState() {
    super.initState();
    loadContractorData().timeout(const Duration(seconds: 10)).catchError((e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
    _initializeStreams();
    _loadInitialProjects();
    bioController = TextEditingController();
    contactController = TextEditingController();
    firmNameController = TextEditingController();
    addressController = TextEditingController();
    specializationController = TextEditingController();
    searchController = TextEditingController();
    transactionSearchController = TextEditingController();
    searchController.addListener(_onSearchChanged);
    transactionSearchController.addListener(_filterTransactions);
    _loadTransactions();
  }

  void _initializeStreams() {
    _streamSubscription?.cancel();
    _completedProjectsStream = FetchService().streamCompletedProjects();
    _streamSubscription = _completedProjectsStream?.listen((data) {
      if (mounted) {
        setState(() {
          completedProjects = data;
          allProjects = data;
          filteredProjects = data;
          _applySearchFilter();
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    bioController.dispose();
    contactController.dispose();
    firmNameController.dispose();
    addressController.dispose();
    specializationController.dispose();
    searchController.removeListener(_onSearchChanged);
    transactionSearchController.removeListener(_filterTransactions);
    searchController.dispose();
    transactionSearchController.dispose();
    super.dispose();
  }

  Future<void> loadContractorData() async {
    try {
      setState(() {
        isLoading = true;
        _error = null;
      });
      
      final result = await CorProfileService().loadContractorData(widget.contractorId);
      final contractorData = result['contractorData'];
      
      if (mounted) {
        setState(() {
          if (contractorData != null) {
            firmName = contractorData['firm_name'] ?? "No firm name";
            bio = contractorData['bio'] ?? "No bio available";
            contactNumber = contractorData['contact_number'] ?? "No contact number";
            final specData = contractorData['specialization'];
            if (specData is List) {
              specialization = specData.isEmpty 
                  ? "No specialization" 
                  : specData.join(", ");
            } else if (specData is String) {
              specialization = specData.isEmpty ? "No specialization" : specData;
            } else {
              specialization = "No specialization";
            }
            address = contractorData['address'] ?? "No address provided";
            email = contractorData['email'] ?? "";
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
      }
      
      _updateControllers();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _updateControllers() {
    bioController.text = bio;
    if (contactNumber.isNotEmpty && !contactNumber.startsWith('+63')) {
      String digitsOnly = contactNumber.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.startsWith('0')) {
        digitsOnly = digitsOnly.substring(1);
      }
      if (!digitsOnly.startsWith('63')) {
        digitsOnly = '63$digitsOnly';
      }
      contactController.text = '+63${digitsOnly.substring(2)}';
    } else {
      contactController.text = contactNumber.isNotEmpty ? contactNumber : '+63';
    }
    firmNameController.text = firmName;
    addressController.text = address;
    specializationController.text = specialization;
  }

  void _onSearchChanged() {
    setState(() {
      _applySearchFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loadContractorData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Colors.amber,)),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Column(
        children: [


          FutureBuilder<bool>(
            future: _fetchVerified(),
            builder: (context, snapshot) {
              final isVerified = snapshot.data == true;
              if (snapshot.connectionState == ConnectionState.waiting || isVerified) {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Account pending verification. Some features are disabled until approval.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              );
            },
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
                        isUploadingProfilePhoto: isUploadingProfile,
                      ),
                    );
                  } else {
                    return ProfileBuildMethods.buildDesktopLayout(
                      firmName: firmName,
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
                      isUploadingProfilePhoto: isUploadingProfile,
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

  Future<bool> _fetchVerified() async {
    try {
      final resp = await FetchService().fetchContractorData(widget.contractorId);
      return resp?['verified'] == true;
    } catch (_) {
      return false;
    }
  }





  Widget _buildMainContent() {
    return ProfileBuildMethods.buildMainContent(
      selectedTab,
      () => _buildPortfolio(),
      () => _buildAboutContent(),
      () => _buildReviewsContent(),
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
      email: email,
      isEditingFirmName: isEditingFirmName,
      isEditingBio: isEditingBio,
      isEditingContact: isEditingContact,
      isEditingAddress: isEditingAddress,
      isEditingSpecialization: isEditingSpecialization,
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


  Future<void> _loadInitialProjects() async {
    try {
      final response = await FetchService().fetchCompletedProjects();
      if (mounted) {
        setState(() {
          completedProjects = response;
          allProjects = response;
          filteredProjects = response;
          _applySearchFilter();
        });
      }
    } catch (e) {
      //  
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await CorProfileService().loadTransactions(widget.contractorId);
      if (mounted) {
        setState(() {
          transactions = loadedTransactions;
          filteredTransactions = loadedTransactions;
        });
      }
    } catch (e) {
        //
    }
  }

  void _filterProjects() {
    final query = searchController.text;
    setState(() {
      filteredProjects = CorProfileService().filterProjects(
        allProjects,
        query,
        selectedProjectStatus,
      );
    });
  }

  void _filterTransactions() {
    final query = transactionSearchController.text;
    setState(() {
      filteredTransactions = CorProfileService().filterTransactions(
        transactions,
        query,
        selectedPaymentType,
      );
    });
  }

  void _applySearchFilter() {
    _filterProjects();
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

  Widget _buildReviewCard(String clientName, String review, double rating, String timeAgo) {
    return ProfileBuildMethods.buildReviews(clientName, review, rating, timeAgo);
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
          if (!isEditingContact) {
            // Reset to original value
            if (contactNumber.isNotEmpty && !contactNumber.startsWith('+63')) {
              String digitsOnly = contactNumber.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.startsWith('0')) {
                digitsOnly = digitsOnly.substring(1);
              }
              if (!digitsOnly.startsWith('63')) {
                digitsOnly = '63$digitsOnly';
              }
              contactController.text = '+63${digitsOnly.substring(2)}';
            } else {
              contactController.text = contactNumber.isNotEmpty ? contactNumber : '+63';
            }
          } else {
            // When starting to edit, ensure it starts with +63
            if (!contactController.text.startsWith('+63')) {
              String currentText = contactController.text;
              String digitsOnly = currentText.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.startsWith('0')) {
                digitsOnly = digitsOnly.substring(1);
              }
              if (!digitsOnly.startsWith('63')) {
                digitsOnly = '63$digitsOnly';
              }
              contactController.text = '+63${digitsOnly.substring(2)}';
            }
          }
          break;
        case 'firmName':
          isEditingFirmName = !isEditingFirmName;
          if (!isEditingFirmName) firmNameController.text = firmName;
          break;
        case 'address':
          isEditingAddress = !isEditingAddress;
          if (!isEditingAddress) addressController.text = address;
          break;
        case 'specialization':
          isEditingSpecialization = !isEditingSpecialization;
          if (!isEditingSpecialization) specializationController.text = specialization;
          break;
      }
    });
  }

  String _formatPhone(String phone) {
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }

    if (!digitsOnly.startsWith('63')) {
      digitsOnly = '63$digitsOnly';
    }

    return '+63${digitsOnly.substring(2)}';
  }

  Future<void> _saveField(String fieldType, String newValue) async {
    // Format phone number if it's the contact field
    final formattedValue = fieldType == 'contact' ? _formatPhone(newValue) : newValue;
    
    await CorProfileService().handleSaveField(
      contractorId: widget.contractorId,
      fieldType: fieldType,
      newValue: formattedValue,
      context: context,
      onSuccess: () {
        setState(() {
          switch (fieldType) {
            case 'bio':
              bio = newValue;
              isEditingBio = false;
              break;
            case 'contact':
              contactNumber = formattedValue;
              isEditingContact = false;
              break;
            case 'firmName':
              firmName = newValue;
              isEditingFirmName = false;
              break;
            case 'address':
              address = newValue;
              isEditingAddress = false;
              break;
            case 'specialization':
              specialization = newValue;
              isEditingSpecialization = false;
              break;
          }
        });
      },
    );
  }

}