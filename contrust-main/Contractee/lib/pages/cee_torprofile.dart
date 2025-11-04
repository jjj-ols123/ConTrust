// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/build/buildtorprofile.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:backend/services/contractee services/cee_torprofileservice.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractorProfileScreen extends StatefulWidget {
  final String contractorName;

  const ContractorProfileScreen({super.key, required this.contractorName});

  @override
  _ContractorProfileScreenState createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen> {
  late String firmName = "No firm name";
  late String bio = "No bio available";
  late String contactNumber = "No contact number";
  late String specialization = "No specialization";
  late String address = "";
  late double rating = 0.0;
  late List<String> pastProjects = [];
  late String? profileImage = profileUrl;
  bool isLoading = true;
  bool isHiring = false;
  bool hasAgreementWithThisContractor = false;
  String? existingProjectId;
  int completedProjectsCount = 0;
  bool canRate = false;
  double userRating = 0.0;
  bool hasRated = false;
  String selectedTab = 'Portfolio';
  List<Map<String, dynamic>> allRatings = [];
  int totalReviews = 0;
  bool hasActiveProject = false;
  bool hasPendingHireRequest = false;
  bool hasPendingBiddingProject = false;
  late String contractorId;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  @override
  void initState() {
    super.initState();
    _loadContractorData();
    _checkAgreementWithContractor();
    _checkOngoingProjects();
    _checkPendingBiddingProject();
  }

  Future<void> _loadContractorData() async {
    try {
      final contractorData =
          await FetchService().fetchContractorDataByName(widget.contractorName);

      if (contractorData != null) {
        final fetchedContractorId = contractorData['contractor_id'];
        if (fetchedContractorId != null) {
          contractorId = fetchedContractorId;

          final completedProjects = await Supabase.instance.client
              .from('Projects')
              .select('project_id')
              .eq('contractor_id', contractorId)
              .eq('status', 'completed');

          final reviews =
              await TorProfileService.getContractorReviews(contractorId);

          setState(() {
            firmName = contractorData['firm_name'] ?? "No firm name";
            bio = contractorData['bio'] ?? "No bio available";
            contactNumber =
                contractorData['contact_number'] ?? "No contact number";
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
            address = contractorData['address'] ?? "";
            rating = contractorData['rating']?.toDouble() ?? 0.0;
            final photo = contractorData['profile_photo'];
            profileImage =
                (photo == null || photo.isEmpty) ? profileUrl : photo;
            pastProjects = List<String>.from(
              contractorData['past_projects'] ?? [],
            );
            completedProjectsCount = completedProjects.length;
            allRatings = reviews;
            totalReviews = reviews.length;
            isLoading = false;
          });
          await _checkPendingHireRequest();
        } else {
          _setFailedToLoadState();
        }
      } else {
        _setFailedToLoadState();
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to load contractor data $e');
      }
      setState(() => isLoading = false);
    }
  }

  void _setFailedToLoadState() {
    setState(() {
      firmName = "Failed to load contractor";
      bio = "No bio available";
      contactNumber = "No contact number";
      specialization = "No specialization";
      address = "";
      rating = 0.0;
      profileImage = profileUrl;
      pastProjects = [];
      completedProjectsCount = 0;
      allRatings = [];
      totalReviews = 0;
      isLoading = false;
    });
  }

  Future<void> _checkAgreementWithContractor() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final existingProject =
        await hasExistingProjectWithContractor(currentUserId, contractorId);
    setState(() {
      hasAgreementWithThisContractor = existingProject != null;
      existingProjectId = existingProject?['project_id'];
    });

    await _checkRatingEligibility();
    await _checkPendingHireRequest();
  }

  Future<void> _notifyContractor() async {
    setState(() => isHiring = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      final actionTaken = await HireModal.show(
        context: context,
        contracteeId: currentUserId,
        contractorId: contractorId,
      );

      if (actionTaken && mounted) {
  ConTrustSnackBar.success(context, 'Hire request sent successfully!');
  await _checkPendingHireRequest();

  context.go('/home');
      }
    } finally {
      if (mounted) {
        setState(() => isHiring = false);
      }
    }
  }

  Future<void> _checkOngoingProjects() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final ongoingProject = await hasOngoingProject(currentUserId);
    setState(() {
      hasActiveProject = ongoingProject != null;
    });
  }

  Future<void> _checkPendingHireRequest() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      final notifications = await Supabase.instance.client
          .from('Notifications')
          .select('notification_id, information')
          .eq('headline', 'Hiring Request')
          .eq('sender_id', currentUserId)
          .eq('receiver_id', contractorId)
          .filter('information->>status', 'eq', 'pending');

      setState(() {
        hasPendingHireRequest = notifications.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        hasPendingHireRequest = false;
      });
    }
  }

  Future<void> _checkPendingBiddingProject() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      final pendingBiddingProject = await Supabase.instance.client
          .from('Projects')
          .select('project_id, title, projectdata')
          .eq('contractee_id', currentUserId)
          .eq('status', 'pending')
          .or('projectdata->>hiring_type.eq.bidding,projectdata.is.null')
          .limit(1)
          .maybeSingle();

      setState(() {
        hasPendingBiddingProject = pendingBiddingProject != null;
      });
    } catch (e) {
      setState(() {
        hasPendingBiddingProject = false;
      });
    }
  }

  Future<void> _checkRatingEligibility() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final result = await TorProfileService.checkRatingEligibility(
        contractorId, currentUserId);
    setState(() {
      canRate = result['canRate'];
      hasRated = result['hasRated'];
      userRating = result['userRating'];
    });
  }

  Future<void> _submitRating(double rating, String reviewText) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      await TorProfileService.submitRating(
          contractorId, currentUserId, rating, hasRated, reviewText);
      await _loadContractorData();
      await _checkRatingEligibility();
      if (mounted) {
        ConTrustSnackBar.success(
            context,
            hasRated
                ? 'Rating updated successfully!'
                : 'Rating submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error submitting rating: $e ');
      }
    }
  }

  double getRatingPercentage(int star) {
    if (allRatings.isEmpty) return 0.0;
    final count =
        allRatings.where((r) => (r['rating'] as num).toInt() == star).length;
    return count / allRatings.length;
  }

  String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  Future<void> _showRatingDialog() async {
    double tempRating = userRating;
    String reviewText = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasRated ? 'Update Rating' : 'Rate This Contractor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasRated
                                ? 'Update your rating for $firmName'
                                : 'How would you rate your experience with $firmName?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    tempRating = index + 1.0;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    index < tempRating.floor()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${tempRating.toStringAsFixed(1)} stars',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            maxLines: 3,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              labelText: 'Write a review (optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Share your experience...',
                            ),
                            onChanged: (value) {
                              reviewText = value;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _submitRating(tempRating, reviewText);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: Text(hasRated
                                      ? 'Update Rating'
                                      : 'Submit Rating'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.go('/home'),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadContractorData();
                await _checkOngoingProjects();
                await _checkPendingHireRequest();
                await _checkPendingBiddingProject();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 768;
                    final mainContent = TorProfileBuildMethods.buildMainContent(
                      selectedTab,
                      () => TorProfileBuildMethods.buildPortfolio(
                        bio: bio,
                        pastProjects: pastProjects,
                        context: context,
                        onViewPhoto: (url) =>
                            TorProfileBuildMethods.showPhotoDialog(
                                context, {'photo_url': url}),
                      ),
                      () => TorProfileBuildMethods.buildAbout(
                        context: context,
                        firmName: firmName,
                        bio: bio,
                        contactNumber: contactNumber,
                        specialization: specialization,
                        address: address,
                      ),
                      () => TorProfileBuildMethods.buildReviewsContainer(
                        rating: rating,
                        totalReviews: totalReviews,
                        getRatingPercentage: getRatingPercentage,
                        buildRatingBar: TorProfileBuildMethods.buildRatingBar,
                        allRatings: allRatings,
                        buildReviewCard: TorProfileBuildMethods.buildReviews,
                        getTimeAgo: getTimeAgo,
                        canRate: canRate,
                        hasRated: hasRated,
                        userRating: userRating,
                        onRate: _showRatingDialog,
                      ),
                    );

                    if (isMobile) {
                      return TorProfileBuildMethods.buildMobileLayout(
                        firmName: firmName,
                        profileImage: profileImage,
                        completedProjectsCount: completedProjectsCount,
                        rating: rating,
                        pastProjects: pastProjects,
                        selectedTab: selectedTab,
                        onTabChanged: (tab) =>
                            setState(() => selectedTab = tab),
                        mainContent: mainContent,
                        onViewProfilePhoto: () =>
                            TorProfileBuildMethods.showPhotoDialog(context,
                                {'photo_url': profileImage ?? profileUrl}),
                      );
                    } else {
                      return TorProfileBuildMethods.buildDesktopLayout(
                        firmName: firmName,
                        profileImage: profileImage,
                        completedProjectsCount: completedProjectsCount,
                        rating: rating,
                        pastProjects: pastProjects,
                        selectedTab: selectedTab,
                        onTabChanged: (tab) =>
                            setState(() => selectedTab = tab),
                        mainContent: mainContent,
                        onViewProfilePhoto: () =>
                            TorProfileBuildMethods.showPhotoDialog(context,
                                {'photo_url': profileImage ?? profileUrl}),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: hasAgreementWithThisContractor
              ? ElevatedButton(
                  onPressed: isHiring
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 400),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.grey.shade50],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade700,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.cancel,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Cancel Agreement',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            icon: const Icon(Icons.close,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Are you sure you want to request cancellation?',
                                            style: TextStyle(fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('No'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red[600],
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                  ),
                                                  child: const Text('Yes'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          if (confirm == true && existingProjectId != null) {
                            await ProjectService().cancelAgreement(
                              existingProjectId!,
                              Supabase.instance.client.auth.currentUser!.id,
                            );
                            ConTrustSnackBar.success(
                                context, 'Cancellation request sent.');
                            setState(() {
                              isHiring = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "CANCEL AGREEMENT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : Tooltip(
                  message: hasPendingHireRequest
                      ? "You already have a pending hire request to this contractor"
                      : hasActiveProject
                          ? "You have an active project. Complete it before hiring another contractor."
                          : hasPendingBiddingProject
                              ? "You have a project up for bidding. Complete the bidding process first."
                              : "Send a hiring request to this contractor",
                  child: ElevatedButton(
                    onPressed: (isHiring ||
                            hasActiveProject ||
                            hasPendingHireRequest ||
                            hasPendingBiddingProject)
                        ? null
                        : _notifyContractor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (hasActiveProject ||
                              hasPendingHireRequest ||
                              hasPendingBiddingProject)
                          ? Colors.grey[400]
                          : Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasPendingHireRequest
                          ? "HIRE REQUEST PENDING"
                          : hasActiveProject
                              ? "CANNOT HIRE - ACTIVE PROJECT"
                              : hasPendingBiddingProject
                                  ? "CANNOT HIRE - PROJECT UP FOR BIDDING"
                                  : "HIRE THIS CONTRACTOR",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
