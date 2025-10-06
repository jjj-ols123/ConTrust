// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:contractee/pages/cee_messages.dart';
import 'package:backend/services/contractee services/cee_torprofileservice.dart';
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
  late String firmName;
  late String bio;
  late String contactNumber;
  late String specialization;
  late double rating;
  late List<String> pastProjects;
  late String? profileImage;
  bool isLoading = true;
  bool isHiring = false;
  bool hasAgreementWithThisContractor = false;
  String? existingProjectId;
  int completedProjectsCount = 0;
  bool canRate = false;
  double userRating = 0.0;
  bool hasRated = false;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  @override
  void initState() {
    super.initState();
    _loadContractorData();
    _checkAgreementWithContractor();
  }

  Future<void> _loadContractorData() async {
    try {
      final contractorData =
          await FetchService().fetchContractorData(widget.contractorId);

      final completedProjects = await Supabase.instance.client
          .from('Projects')
          .select('project_id')
          .eq('contractor_id', widget.contractorId)
          .eq('status', 'completed');

      if (contractorData != null) {
        setState(() {
          firmName = contractorData['firm_name'] ?? "No firm name";
          bio = contractorData['bio'] ?? "No bio available";
          contactNumber =
              contractorData['contact_number'] ?? "No contact number";
          specialization =
              contractorData['specialization'] ?? "No specialization";
          rating = contractorData['rating']?.toDouble() ?? 0.0;
          final photo = contractorData['profile_photo'];
          profileImage = (photo == null || photo.isEmpty) ? profileUrl : photo;
          pastProjects = List<String>.from(
            contractorData['past_projects'] ?? [],
          );
          completedProjectsCount = completedProjects.length;
          isLoading = false;
        });
      } else {
        setState(() {
          completedProjectsCount = completedProjects.length;
          isLoading = false;
        });
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

  Future<void> _checkAgreementWithContractor() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final existingProject = await hasExistingProjectWithContractor(
        currentUserId, widget.contractorId);
    setState(() {
      hasAgreementWithThisContractor = existingProject != null;
      existingProjectId = existingProject?['project_id'];
    });

    await _checkRatingEligibility();
  }

  Future<void> _notifyContractor() async {
    setState(() => isHiring = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      await HireModal.show(
        context: context,
        contracteeId: currentUserId,
        contractorId: widget.contractorId,
      );
    } finally {
      if (mounted) {
        setState(() => isHiring = false);
      }
    }
  }

  Future<void> _checkRatingEligibility() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final result = await TorProfileService.checkRatingEligibility(
        widget.contractorId, currentUserId);
    setState(() {
      canRate = result['canRate'];
      hasRated = result['hasRated'];
      userRating = result['userRating'];
    });
  }

  Future<void> _submitRating(double rating) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      await TorProfileService.submitRating(
          widget.contractorId, currentUserId, rating, hasRated);
      await _loadContractorData();
      await _checkRatingEligibility();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasRated
                ? 'Rating updated successfully!'
                : 'Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRatingDialog() async {
    double tempRating = userRating;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(hasRated ? 'Update Rating' : 'Rate This Contractor'),
            content: Column(
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
                        padding: const EdgeInsets.symmetric(horizontal: 4),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _submitRating(tempRating);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
                child: Text(hasRated ? 'Update Rating' : 'Submit Rating'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 24);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 24);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 24);
        }
      }),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    if (isLoading) {
      return Scaffold(
        appBar: ConTrustAppBar(
          headline: 'Contractor Profile',
        ),
        drawer: const MenuDrawerContractee(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: ConTrustAppBar(
        headline: 'Contractor Profile',
      ),
      drawer: const MenuDrawerContractee(),
      body: RefreshIndicator(
        onRefresh: _loadContractorData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'bgloginscreen.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(Icons.message, color: Colors.white, size: 32),
                        tooltip: 'Message Contractor',
                        onPressed: () async {
                          final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
                          final chatRoomId = await TorProfileService.getOrCreateChatRoom(
                            contractorId: widget.contractorId,
                            contracteeId: currentUserId,
                          );
                          if (chatRoomId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You should have a project with this contractor to chat.'),
                              ),
                            );
                            return;
                          }
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
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: (profileImage != null &&
                                      profileImage!.isNotEmpty)
                                  ? NetworkImage(profileImage!)
                                  : NetworkImage(profileUrl),
                              child: (profileImage == null ||
                                      profileImage!.isEmpty)
                                  ? const Icon(Icons.business,
                                      size: 40, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firmName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildRatingStars(rating),
                                    const SizedBox(width: 8),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'About Us',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              bio,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.phone,
                                    color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Contact: $contactNumber',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.work,
                                    color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Specialization: $specialization',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.photo_library,
                                    color: Colors.purple.shade600, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Past Projects',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (pastProjects.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No project photos available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This contractor hasn\'t uploaded any project photos yet',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: pastProjects.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        pastProjects[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.error_outline,
                                              color: Colors.grey.shade400,
                                              size: 32,
                                            ),
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.analytics,
                                    color: Colors.green.shade600, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Performance Stats',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.star,
                                    title: 'Rating',
                                    value: rating.toStringAsFixed(1),
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.work,
                                    title: 'Completed Projects',
                                    value: '$completedProjectsCount',
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            if (canRate) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          hasRated
                                              ? 'Your Rating'
                                              : 'Rate This Contractor',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasRated) ...[
                                      const SizedBox(height: 8),
                                      _buildRatingStars(userRating),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${userRating.toStringAsFixed(1)} stars',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _showRatingDialog,
                                      icon: Icon(
                                          hasRated ? Icons.edit : Icons.star),
                                      label: Text(hasRated
                                          ? 'Update Rating'
                                          : 'Rate Now'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star_border,
                                            color: Colors.grey, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Rating Unavailable',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You can rate this contractor after completing a project together',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text('Cancel Agreement'),
                                            content: const Text(
                                                'Are you sure you want to request cancellation?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Yes',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true &&
                                            existingProjectId != null) {
                                          await ProjectService()
                                              .cancelAgreement(
                                            existingProjectId!,
                                            Supabase.instance.client.auth
                                                .currentUser!.id,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Cancellation request sent.')),
                                          );
                                          setState(() {
                                            isHiring = false;
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                            : ElevatedButton(
                                onPressed: isHiring ? null : _notifyContractor,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
