// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use
import 'package:backend/services/contractee services/cee_profileservice.dart';
import 'package:contractee/build/buildceeprofile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/utils/be_snackbar.dart';

class CeeProfilePage extends StatefulWidget {
  final String contracteeId;

  const CeeProfilePage({super.key, required this.contracteeId});

  @override
  _CeeProfilePageState createState() => _CeeProfilePageState();
}

class _CeeProfilePageState extends State<CeeProfilePage> {
  final supabase = Supabase.instance.client;

  String fullName = '';
  String email = '';
  String contactNumber = '';
  String address = '';
  String? profileImage;
  bool isLoading = true;
  bool isUploading = false;
  bool isUploadingPhoto = false;
  int completedProjectsCount = 0;
  int ongoingProjectsCount = 0;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  String selectedTab = 'About';

  bool isEditingFullName = false;
  bool isEditingContact = false;
  bool isEditingAddress = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController projectSearchController = TextEditingController();
  final TextEditingController transactionSearchController =
      TextEditingController();

  List<Map<String, dynamic>> projectHistory = [];
  List<Map<String, dynamic>> ongoingProjects = [];
  List<Map<String, dynamic>> allProjects = [];
  List<Map<String, dynamic>> filteredProjects = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  List<Map<String, dynamic>> reviews = [];

  String selectedProjectStatus = 'All';
  String selectedPaymentType = 'All';

  @override
  void initState() {
    super.initState();
    loadContracteeData();
    _loadTransactions();
    _loadReviews();
    projectSearchController.addListener(_filterProjects);
    transactionSearchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    contactController.dispose();
    addressController.dispose();
    projectSearchController.dispose();
    transactionSearchController.dispose();
    super.dispose();
  }

  Future<void> loadContracteeData() async {
    try {
      setState(() => isLoading = true);

      final result =
          await CeeProfileService().loadContracteeData(widget.contracteeId);
      final contracteeData = result['contracteeData'];

      // Fetch all projects (including cancelled)
      final allProjectsData = await supabase
          .from('Projects')
          .select(
              'project_id, title, type, status, created_at, description, contractor_id')
          .eq('contractee_id', widget.contracteeId)
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> uniqueProjects = {};
      for (var project in allProjectsData) {
        final projectId = project['project_id'];
        if (!uniqueProjects.containsKey(projectId)) {
          uniqueProjects[projectId] = project;
        }
      }

      // Sort projects: active/ongoing first, then by date
      final projectsList = uniqueProjects.values.toList();
      projectsList.sort((a, b) {
        final statusA = (a['status'] ?? '').toString().toLowerCase();
        final statusB = (b['status'] ?? '').toString().toLowerCase();

        // Define priority: active/ongoing at top
        int getPriority(String status) {
          if (status == 'active' || status == 'ongoing') return 0;
          if (status == 'pending') return 1;
          if (status == 'completed') return 2;
          if (status == 'cancelled') return 3;
          return 4;
        }

        final priorityDiff = getPriority(statusA) - getPriority(statusB);
        if (priorityDiff != 0) return priorityDiff;

        // If same priority, sort by date (newest first)
        final dateA =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        if (contracteeData != null) {
          // Get data directly from Contractee table (now includes email from Users table)
          fullName = contracteeData['full_name'] ?? "";
          contactNumber = contracteeData['phone_number'] ?? "";
          address = contracteeData['address'] ?? "";
          email = contracteeData['email'] ?? "";

          // Get profile image directly without cache-busting (like contractor profile)
          profileImage = contracteeData['profile_photo'];
        }

        completedProjectsCount = result['completedProjectsCount'];
        ongoingProjectsCount = result['ongoingProjectsCount'];
        projectHistory = result['projectHistory'];
        ongoingProjects = result['ongoingProjects'];
        allProjects = projectsList;
        filteredProjects = projectsList; // Initialize filtered list
        filteredTransactions =
            result['projectHistory']; 
        isLoading = false;
      });

      _updateControllers();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviewsWithNames = await CeeProfileService().loadReviews(widget.contracteeId);
      setState(() {
        reviews = reviewsWithNames;
      });
    } catch (e) {
      //
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await CeeProfileService().loadTransactions(widget.contracteeId);
      if (mounted) {
        setState(() {
          transactions = loadedTransactions;
          filteredTransactions = loadedTransactions;
        });
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(
          context,
          'Error loading transactions: $e',
        );
      }
    }
  }

  void _filterProjects() {
    final query = projectSearchController.text;
    setState(() {
      filteredProjects = CeeProfileService().filterProjects(
        allProjects,
        query,
        selectedProjectStatus,
      );
    });
  }

  void _filterTransactions() {
    final query = transactionSearchController.text;
    setState(() {
      filteredTransactions = CeeProfileService().filterTransactions(
        transactions,
        query,
        selectedPaymentType,
      );
    });
  }

  void _updateControllers() {
    fullNameController.text = fullName;
    if (contactNumber.isNotEmpty && !contactNumber.startsWith('+63')) {
      String digitsOnly = contactNumber.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.startsWith('0')) {
        digitsOnly = digitsOnly.substring(1);
      }
      contactController.text = '+63$digitsOnly';
    } else {
      contactController.text = contactNumber.isNotEmpty ? contactNumber : '+63';
    }
    addressController.text = address;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Column(
            children: [
              CeeProfileBuildMethods.buildHeader(context, 'My Profile'),
              Expanded(
                  child: CeeProfileBuildMethods.buildMobileLayout(
                    fullName: fullName,
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
                    onUploadPhoto: isUploadingPhoto ? null : _uploadProfilePhoto,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              CeeProfileBuildMethods.buildHeader(context, 'My Profile'),
              Expanded(
                child: CeeProfileBuildMethods.buildDesktopLayout(
                  fullName: fullName,
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
                  onUploadPhoto: isUploadingPhoto ? null : _uploadProfilePhoto,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMainContent() {
    return CeeProfileBuildMethods.buildMainContent(
      selectedTab,
      () => _buildAboutContent(),
      () => _buildHistoryContent(),
    );
  }

  Widget _buildAboutContent() {
    return CeeProfileBuildMethods.buildAbout(
      context: context,
      fullName: fullName,
      contactNumber: contactNumber,
      address: address,
      email: email,
      isEditingFullName: isEditingFullName,
      isEditingContact: isEditingContact,
      isEditingAddress: isEditingAddress,
      fullNameController: fullNameController,
      contactController: contactController,
      addressController: addressController,
      toggleEditFullName: () => _toggleEdit('fullName'),
      toggleEditContact: () => _toggleEdit('contact'),
      toggleEditAddress: () => _toggleEdit('address'),
      saveFullName: () => _saveField('fullName', fullNameController.text),
      saveContact: () => _saveField('contact', contactController.text),
      saveAddress: () => _saveField('address', addressController.text),
      contracteeId: widget.contracteeId,
    );
  }

  Widget _buildHistoryContent() {
    return CeeProfileBuildMethods.buildHistory(
      context: context,
      filteredProjects: filteredProjects,
      filteredTransactions: filteredTransactions,
      reviews: reviews,
      projectSearchController: projectSearchController,
      transactionSearchController: transactionSearchController,
      selectedProjectStatus: selectedProjectStatus,
      selectedPaymentType: selectedPaymentType,
      onProjectStatusChanged: (status) {
        setState(() {
          selectedProjectStatus = status;
          _filterProjects();
        });
      },
      onPaymentTypeChanged: (type) {
        setState(() {
          selectedPaymentType = type;
          _filterTransactions();
        });
      },
      onProjectTap: _showProjectDetails,
      getTimeAgo: _getTimeAgo,
    );
  }

  void _showProjectDetails(Map<String, dynamic> project) async {
    try {
      final projectId = project['project_id'];
      final projectDetails = await supabase
          .from('Projects')
          .select('*')
          .eq('project_id', projectId)
          .single();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => CeeProfileBuildMethods.buildProjectDetailsDialog(
            dialogContext,
            projectDetails,
            _getTimeAgo, 
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(
          context,
          'Error loading project details: $e',
        );
      }
    }
  }

  void _toggleEdit(String fieldType) {
    setState(() {
      switch (fieldType) {
        case 'fullName':
          isEditingFullName = !isEditingFullName;
          if (!isEditingFullName) fullNameController.text = fullName;
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
              contactController.text = '+63$digitsOnly';
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
              contactController.text = '+63$digitsOnly';
            }
          }
          break;
        case 'address':
          isEditingAddress = !isEditingAddress;
          if (!isEditingAddress) addressController.text = address;
          break;
      }
    });
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+63')) {
      return phone;
    }
    
    String digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }
    return '+63$digitsOnly';
  }

  Future<void> _saveField(String fieldType, String newValue) async {
    // Format phone number if it's the contact field
    final formattedValue = fieldType == 'contact' ? _formatPhone(newValue) : newValue;
    
    await CeeProfileService().handleSaveField(
      contracteeId: widget.contracteeId,
      fieldType: fieldType,
      newValue: formattedValue,
      context: context,
      onSuccess: () {
        setState(() {
          switch (fieldType) {
            case 'fullName':
              fullName = newValue;
              isEditingFullName = false;
              break;
            case 'contact':
              contactNumber = formattedValue;
              isEditingContact = false;
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

  Future<void> _uploadProfilePhoto() async {
    if (isUploadingPhoto) return;

    setState(() => isUploadingPhoto = true);

    try {
      if (profileImage != null && profileImage!.isNotEmpty) {
        final oldImageUrl = profileImage!.split('?').first;
        imageCache.evict(NetworkImage(oldImageUrl));
      }

      final newImageUrl = await CeeProfileService().uploadProfilePhoto(
        contracteeId: widget.contracteeId,
        context: context,
      );

      if (newImageUrl != null && mounted) {
        setState(() {
          profileImage = newImageUrl;
          isUploadingPhoto = false;
        });
      } else {
        setState(() => isUploadingPhoto = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploadingPhoto = false);
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
