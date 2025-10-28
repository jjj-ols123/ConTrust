// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use
import 'package:backend/services/contractee services/cee_profileservice.dart';
import 'package:contractee/build/buildceeprofile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CeeProfilePage extends StatefulWidget {
  final String contracteeId;

  const CeeProfilePage({super.key, required this.contracteeId});

  @override
  _CeeProfilePageState createState() => _CeeProfilePageState();
}

class _CeeProfilePageState extends State<CeeProfilePage> {
  final supabase = Supabase.instance.client;
  
  String fullName = '';
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

  List<Map<String, dynamic>> projectHistory = [];
  List<Map<String, dynamic>> ongoingProjects = [];
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadContracteeData();
    _loadTransactions();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    contactController.dispose();
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
          fullName = contracteeData['full_name'] ?? "No name";
          contactNumber = contracteeData['phone_number'] ?? "No contact number";
          address = contracteeData['address'] ?? "No address provided";
          
          // Add cache-busting parameter to profile image
          final String? rawProfileImage = contracteeData['profile_photo'];
          if (rawProfileImage != null && rawProfileImage.isNotEmpty) {
            profileImage = '$rawProfileImage?t=${DateTime.now().millisecondsSinceEpoch}';
          } else {
            profileImage = null;
          }
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
    fullNameController.text = fullName;
    contactController.text = contactNumber;
    addressController.text = address;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    return RefreshIndicator(
      onRefresh: loadContracteeData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          
          if (isMobile) {
            return SingleChildScrollView(
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
            );
          } else {
            return CeeProfileBuildMethods.buildDesktopLayout(
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
            );
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return CeeProfileBuildMethods.buildMainContent(
      selectedTab,
      () => _buildProjectsContent(),
      () => _buildAboutContent(),
      () => _buildHistoryContent(),
      () => _buildTransactionsContent(),
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
      fullName: fullName,
      contactNumber: contactNumber,
      address: address,
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
      projectHistory: projectHistory,
      getTimeAgo: _getTimeAgo,
    );
  }

  Widget _buildTransactionsContent() {
    return CeeProfileBuildMethods.buildTransactions(
      transactions: transactions,
    );
  }

  Future<void> _loadTransactions() async {
    try {
      final projectsResponse = await supabase
          .from('Projects')
          .select('''
            project_id,
            title,
            projectdata,
            contractor_id,
            Contractor!inner(firm_name)
          ''')
          .eq('contractee_id', widget.contracteeId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allTransactions = [];

      for (var project in projectsResponse) {
        final projectdata = project['projectdata'] as Map<String, dynamic>? ?? {};
        final payments = projectdata['payments'] as List<dynamic>? ?? [];
        
        for (var payment in payments) {
          allTransactions.add({
            'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
            'payment_type': _getPaymentType(payment['contract_type'] ?? '', payment['payment_structure'] ?? ''),
            'project_title': project['title'] ?? 'Unknown Project',
            'contractor_name': project['Contractor']?['firm_name'] ?? 'Unknown Contractor',
            'payment_date': payment['date'] ?? DateTime.now().toIso8601String(),
            'reference': payment['reference'] ?? payment['payment_id'] ?? '',
          });
        }
      }

      allTransactions.sort((a, b) {
        final dateA = DateTime.parse(a['payment_date']);
        final dateB = DateTime.parse(b['payment_date']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          transactions = allTransactions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          transactions = [];
        });
      }
    }
  }

  String _getPaymentType(String contractType, String paymentStructure) {
    if (contractType == 'lump_sum') {
      return 'Full Payment';
    } else if (contractType == 'percentage_based') {
      return 'Milestone Payment';
    } else if (contractType == 'custom') {
      if (paymentStructure.toLowerCase().contains('down')) {
        return 'Down Payment';
      } else if (paymentStructure.toLowerCase().contains('final')) {
        return 'Final Payment';
      } else if (paymentStructure.toLowerCase().contains('milestone')) {
        return 'Milestone Payment';
      }
      return 'Contract Payment';
    }
    return 'Payment';
  }

  String _getTimeAgo(DateTime dateTime) {
    return CeeProfileService().getTimeAgo(dateTime);
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
          if (!isEditingContact) contactController.text = contactNumber;
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
            case 'fullName':
              fullName = newValue;
              isEditingFullName = false;
              break;
            case 'contact':
              contactNumber = newValue;
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
      // Clear the image cache for the old profile image
      if (profileImage != null && profileImage!.isNotEmpty) {
        final oldImageUrl = profileImage!.split('?').first; // Remove query params
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
        // Reload data to ensure persistence
        await loadContracteeData();
      } else {
        setState(() => isUploadingPhoto = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploadingPhoto = false);
      }
    }
  }
}