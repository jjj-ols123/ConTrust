// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/utils/be_status.dart';

class ProfileBuildMethods {
  static Widget buildMainContent(String selectedTab, Function buildPortfolioContent, Function buildAboutContent, Function buildReviewsContent, Function buildClientHistoryContent) {
    switch (selectedTab) {
      case 'Portfolio':
        return buildPortfolioContent();
      case 'About':
        return buildAboutContent();
      case 'Reviews':
        return buildReviewsContent();
      case 'History':
        return buildClientHistoryContent();
      default:
        return buildPortfolioContent();
    }
  }

  static Widget buildMobileLayout({
    required String firmName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required double rating,
    required List<String> pastProjects,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
    required VoidCallback? onProfilePhotoUpload,
    required VoidCallback? onViewProfilePhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onViewProfilePhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          child: ClipOval(
                            child: (profileImage != null && profileImage.isNotEmpty)
                                ? Image.network(
                                    profileImage,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        profileUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.business,
                                            size: 35,
                                            color: Colors.grey.shade400,
                                          );
                                        },
                                      );
                                    },
                                  )
                                : Image.network(
                                    profileUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.business,
                                        size: 35,
                                        color: Colors.grey.shade400,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      if (onProfilePhotoUpload != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: onProfilePhotoUpload,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  firmName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$completedProjectsCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Projects',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${pastProjects.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          buildMobileNavigation(selectedTab, onTabChanged),
          const SizedBox(height: 16),
          mainContent,
        ],
      ),
    );
  }

  static Widget buildDesktopLayout({
    required String firmName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required double rating,
    required List<String> pastProjects,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
    required VoidCallback? onProfilePhotoUpload,
    required VoidCallback? onViewProfilePhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: onViewProfilePhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade100,
                                child: ClipOval(
                                  child: (profileImage != null && profileImage.isNotEmpty)
                                      ? Image.network(
                                          profileImage,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.network(
                                              profileUrl,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.business,
                                                  size: 40,
                                                  color: Colors.grey.shade400,
                                                );
                                              },
                                            );
                                          },
                                        )
                                      : Image.network(
                                          profileUrl,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.business,
                                              size: 40,
                                              color: Colors.grey.shade400,
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                            if (onProfilePhotoUpload != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: onProfilePhotoUpload,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        firmName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$completedProjectsCount',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'Projects',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'Rating',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${pastProjects.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'Photos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      buildNavigation('Portfolio', selectedTab == 'Portfolio', () => onTabChanged('Portfolio')),
                      buildNavigation('About', selectedTab == 'About', () => onTabChanged('About')),
                      buildNavigation('Reviews', selectedTab == 'Reviews', () => onTabChanged('Reviews')),
                      buildNavigation('History', selectedTab == 'History', () => onTabChanged('History')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              child: mainContent,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPortfolio({
    required String bio,
    required List<String> pastProjects,
    required bool isUploading,
    required VoidCallback uploadProjectPhoto,
    required BuildContext context,
    required Function(String) onViewPhoto, // add this
  }) {

    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade400,
                Colors.amber.shade700,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/bgloginscreen.jpg'),
                    fit: BoxFit.fill,
                  ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROJECTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    if (bio.isNotEmpty)
                      Text(
                        bio,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        Row(
          children: [
            TextButton.icon(
              onPressed: uploadProjectPhoto,
              icon: Icon(
                isUploading ? Icons.hourglass_empty : Icons.add,
                size: 16,
              ),
              label: Text(
                isUploading ? 'Uploading...' : 'Add Project Photo',
                style: const TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        if (pastProjects.isEmpty)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Projects Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photos of your projects to showcase your work',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 1200 ? 3 : screenWidth > 800 ? 2 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: screenWidth > 1200 ? 1.9: 1.7,
            ),
            itemCount: pastProjects.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => onViewPhoto(pastProjects[index]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber.shade50,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            pastProjects[index],
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                  size: 32,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.amber.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  static Widget buildAbout({
    required BuildContext context,
    required String firmName,
    required String bio,
    required String contactNumber,
    required String specialization,
    required String address,
    required bool isEditingFirmName,
    required bool isEditingBio,
    required bool isEditingContact,
    required bool isEditingAddress,
    required TextEditingController firmNameController,
    required TextEditingController bioController,
    required TextEditingController contactController,
    required TextEditingController addressController,
    required VoidCallback toggleEditFirmName,
    required VoidCallback toggleEditBio,
    required VoidCallback toggleEditContact,
    required VoidCallback toggleEditAddress,
    required VoidCallback saveFirmName,
    required VoidCallback saveBio,
    required VoidCallback saveContact,
    required VoidCallback saveAddress,
    required String contractorId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 28,
                ),
                const SizedBox(width: 16),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 32),
            
            buildContractorInfo(
              'Firm Name',
              firmName,
              Icons.business,
              isEditingFirmName,
              firmNameController,
              toggleEditFirmName,
              saveFirmName,
            ),
            const SizedBox(height: 24),
            
            buildContractorInfo(
              'Bio',
              bio,
              Icons.description,
              isEditingBio,
              bioController,
              toggleEditBio,
              saveBio,
            ),
            const SizedBox(height: 24),
            
            buildContractorInfo(
              'Contact Information',
              contactNumber,
              Icons.phone,
              isEditingContact,
              contactController,
              toggleEditContact,
              saveContact,
            ),
            const SizedBox(height: 24),
            
            // Specialization Section - Display as chips from JSONB
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.work, color: Colors.grey.shade800, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Specialization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSpecializationDisplay(specialization),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            buildContractorInfo(
              'Address',
              address,
              Icons.location_on,
              isEditingAddress,
              addressController,
              toggleEditAddress,
              saveAddress,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildReviewsContainer({
    required double rating,
    required int totalReviews,
    required Function getRatingPercentage,
    required Function buildRatingBar,
    required List<Map<String, dynamic>> allRatings,
    required Function buildReviewCard,
    required Function getTimeAgo,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
                blurRadius: isMobile ? 6 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rate,
                  color: Colors.amber.shade700,
                      size: isMobile ? 24 : 28,
                ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
                SizedBox(height: isMobile ? 20 : 32),
            
            Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                border: Border.all(color: Colors.amber.shade200),
              ),
                  child: isMobile 
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: isMobile ? 36 : 48,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3748),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (index) {
                                      if (index < rating.floor()) {
                                        return Icon(Icons.star, color: Colors.amber, size: isMobile ? 20 : 24);
                                      } else if (index < rating.ceil() && rating % 1 != 0) {
                                        return Icon(Icons.star_half, color: Colors.amber, size: isMobile ? 20 : 24);
                                      } else {
                                        return Icon(Icons.star_border, color: Colors.grey, size: isMobile ? 20 : 24);
                                      }
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Based on $totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              buildRatingBar('5 Stars', getRatingPercentage(5), Colors.green),
                              buildRatingBar('4 Stars', getRatingPercentage(4), Colors.lightGreen),
                              buildRatingBar('3 Stars', getRatingPercentage(3), Colors.yellow),
                              buildRatingBar('2 Stars', getRatingPercentage(2), Colors.orange),
                              buildRatingBar('1 Star', getRatingPercentage(1), Colors.red),
                            ],
                          ),
                        ],
                      )
                    : Row(
                children: [
                  Column(
                    children: [
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          if (index < rating.floor()) {
                            return const Icon(Icons.star, color: Colors.amber, size: 24);
                          } else if (index < rating.ceil() && rating % 1 != 0) {
                            return const Icon(Icons.star_half, color: Colors.amber, size: 24);
                          } else {
                            return const Icon(Icons.star_border, color: Colors.grey, size: 24);
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        buildRatingBar('5 Stars', getRatingPercentage(5), Colors.green),
                        buildRatingBar('4 Stars', getRatingPercentage(4), Colors.lightGreen),
                        buildRatingBar('3 Stars', getRatingPercentage(3), Colors.yellow),
                        buildRatingBar('2 Stars', getRatingPercentage(2), Colors.orange),
                        buildRatingBar('1 Star', getRatingPercentage(1), Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                SizedBox(height: isMobile ? 20 : 32),
            
            if (totalReviews == 0)
              Center(
                child: Container(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                            size: isMobile ? 48 : 64,
                        color: Colors.grey.shade400,
                      ),
                          SizedBox(height: isMobile ? 12 : 16),
                      Text(
                        'No Reviews Yet',
                        style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                          SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        'Complete projects to start receiving reviews from clients',
                        style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allRatings.length,
                itemBuilder: (context, index) {
                  final review = allRatings[index];
                  final reviewText = review['review'] as String? ?? 'No written review provided.';
                  final reviewRating = (review['rating'] as num?)?.toDouble() ?? 0.0;
                  final clientName = review['client_name'] as String? ?? 'Anonymous Client';
                  final createdAt = review['created_at'] != null
                      ? DateTime.parse(review['created_at']).toLocal()
                      : DateTime.now();
                  final timeAgo = getTimeAgo(createdAt);
                  
                  return buildReviewCard(
                    clientName,
                    reviewText,
                    reviewRating,
                    timeAgo,
                  );
                },
              ),
          ],
        ),
      ),
        );
      },
    );
  }

  static Widget buildRatingBar(String label, double percentage, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
    return Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 3 : 4),
      child: Row(
        children: [
          SizedBox(
                width: isMobile ? 50 : 60,
            child: Text(
              label,
                  style: TextStyle(fontSize: isMobile ? 11 : 12),
            ),
          ),
              SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Container(
                  height: isMobile ? 6 : 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(isMobile ? 3 : 4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                        borderRadius: BorderRadius.circular(isMobile ? 3 : 4),
                  ),
                ),
              ),
            ),
          ),
              SizedBox(width: isMobile ? 6 : 8),
          Text(
            '${(percentage * 100).toInt()}%',
                style: TextStyle(fontSize: isMobile ? 11 : 12),
          ),
        ],
      ),
        );
      },
    );
  }

  static Widget buildReviews(String clientName, String review, double rating, String timeAgo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
    return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                    radius: isMobile ? 18 : 20,
                backgroundColor: Colors.amber.shade100,
                child: Text(
                  clientName[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                        fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
                  SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                          style: TextStyle(
                        fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 13 : 14,
                      ),
                          overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                            size: isMobile ? 14 : 16,
                      );
                    }),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
              SizedBox(height: isMobile ? 8 : 12),
          Text(
            review,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
              height: 1.4,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  static Widget buildNavigation(String title, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.amber.shade700,
              ),
          ],
        ),
      ),
    );
  }
  
  static Widget buildMobileNavigation(String selectedTab, Function(String) onTabChanged) {
    final tabs = ['Portfolio', 'About', 'Reviews', 'History'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = selectedTab == tab;
          final isFirst = index == 0;
          final isLast = index == tabs.length - 1;
          
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTabChanged(tab),
                borderRadius: BorderRadius.only(
                  topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                  bottomLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                  topRight: isLast ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isActive ? Colors.amber.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                      bottomLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                      topRight: isLast ? const Radius.circular(12) : Radius.zero,
                      bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    border: isActive 
                        ? Border.all(color: Colors.amber.shade300, width: 2)
                        : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    child: Center(
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

   static Widget buildContractorInfo(
    String title,
    String content,
    IconData icon,
    bool isEditing,
    TextEditingController controller,
    VoidCallback onEdit,
    VoidCallback onSave,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (isEditing)
                Row(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onSave,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEditing)
            TextField(
              controller: controller,
              keyboardType: title == 'Contact Information' ? TextInputType.phone : TextInputType.text,
              maxLines: title == 'Bio' ? 3 : 1,
              inputFormatters: title == 'Contact Information' 
                ? [LengthLimitingTextInputFormatter(13)]
                : null,
              onChanged: title == 'Contact Information' 
                ? (value) {
                    if (!value.startsWith('+63')) {
                      controller.text = '+63';
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    }
                  }
                : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade500),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                height: 1.5,
              ),
            )
          else
            Text(
              content.isNotEmpty ? content : '',
              style: TextStyle(
                fontSize: 14,
                color: content.isNotEmpty ? const Color(0xFF2D3748) : Colors.grey.shade400,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildClientHistory({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredProjects,
    required List<Map<String, dynamic>> filteredTransactions,
    required TextEditingController projectSearchController,
    required TextEditingController transactionSearchController,
    required String selectedProjectStatus,
    required String selectedPaymentType,
    required Function(String) onProjectStatusChanged,
    required Function(String) onPaymentTypeChanged,
    required Function(Map<String, dynamic>) onProjectTap,
    required Function getTimeAgo,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildClientsSection(
                  context: context,
                  filteredProjects: filteredProjects,
                  projectSearchController: projectSearchController,
                  selectedProjectStatus: selectedProjectStatus,
                  onProjectStatusChanged: onProjectStatusChanged,
                  onProjectTap: onProjectTap,
                  getTimeAgo: getTimeAgo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTransactionsSection(
                  context: context,
                  filteredTransactions: filteredTransactions,
                  transactionSearchController: transactionSearchController,
                  selectedPaymentType: selectedPaymentType,
                  onPaymentTypeChanged: onPaymentTypeChanged,
                  getTimeAgo: getTimeAgo,
                ),
              ),
            ],
          );
        } else {
          return _buildMobileHistoryWithIndicator(
            context: context,
            constraints: constraints,
            filteredProjects: filteredProjects,
            projectSearchController: projectSearchController,
            selectedProjectStatus: selectedProjectStatus,
            onProjectStatusChanged: onProjectStatusChanged,
            onProjectTap: onProjectTap,
            filteredTransactions: filteredTransactions,
            transactionSearchController: transactionSearchController,
            selectedPaymentType: selectedPaymentType,
            onPaymentTypeChanged: onPaymentTypeChanged,
            getTimeAgo: getTimeAgo,
          );
        }
      },
    );
  }

  static Widget _buildClientsSection({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredProjects,
    required TextEditingController projectSearchController,
    required String selectedProjectStatus,
    required Function(String) onProjectStatusChanged,
    required Function(Map<String, dynamic>) onProjectTap,
    required Function getTimeAgo,
  }) {
    final sortedProjects = List<Map<String, dynamic>>.from(filteredProjects);
    sortedProjects.sort((a, b) {
      final statusA = (a['status'] ?? '').toString().toLowerCase();
      final statusB = (b['status'] ?? '').toString().toLowerCase();
      
      bool isActiveA = statusA != 'completed' && statusA != 'cancelled';
      bool isActiveB = statusB != 'completed' && statusB != 'cancelled';
      
      if (isActiveA && !isActiveB) return -1;
      if (!isActiveA && isActiveB) return 1;
      
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Client History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: projectSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedProjectStatus,
                items: ['All', 'Active', 'Completed', 'Cancelled', 'Pending']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => onProjectStatusChanged(value ?? 'All'),
                underline: Container(),
                icon: const Icon(Icons.filter_list, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No clients found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sortedProjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = sortedProjects[index];
                      return _buildClientHistoryCard(project, onProjectTap, getTimeAgo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTransactionsSection({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredTransactions,
    required TextEditingController transactionSearchController,
    required String selectedPaymentType,
    required Function(String) onPaymentTypeChanged,
    required Function getTimeAgo,
  }) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: transactionSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedPaymentType,
                items: ['All', 'Deposit', 'Final', 'Milestone']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => onPaymentTypeChanged(value ?? 'All'),
                underline: Container(),
                icon: const Icon(Icons.filter_list, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No transactions found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction, getTimeAgo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildClientsSectionWithFixedHeader({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredProjects,
    required TextEditingController projectSearchController,
    required String selectedProjectStatus,
    required Function(String) onProjectStatusChanged,
    required Function(Map<String, dynamic>) onProjectTap,
    required Function getTimeAgo,
  }) {
    final sortedProjects = List<Map<String, dynamic>>.from(filteredProjects);
    sortedProjects.sort((a, b) {
      final statusA = (a['status'] ?? '').toString().toLowerCase();
      final statusB = (b['status'] ?? '').toString().toLowerCase();
      bool isActiveA = statusA != 'completed' && statusA != 'cancelled';
      bool isActiveB = statusB != 'completed' && statusB != 'cancelled';
      if (isActiveA && !isActiveB) return -1;
      if (!isActiveA && isActiveB) return 1;
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Client History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: projectSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedProjectStatus,
                items: ['All', 'Active', 'Completed', 'Cancelled', 'Pending']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => onProjectStatusChanged(value ?? 'All'),
                underline: Container(),
                icon: const Icon(Icons.filter_list, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No clients found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sortedProjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = sortedProjects[index];
                      return _buildClientHistoryCard(project, onProjectTap, getTimeAgo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTransactionsSectionWithFixedHeader({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredTransactions,
    required TextEditingController transactionSearchController,
    required String selectedPaymentType,
    required Function(String) onPaymentTypeChanged,
    required Function getTimeAgo,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: transactionSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedPaymentType,
                items: ['All', 'Deposit', 'Final', 'Milestone']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => onPaymentTypeChanged(value ?? 'All'),
                underline: Container(),
                icon: const Icon(Icons.filter_list, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No transactions found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction, getTimeAgo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMobileHistoryWithIndicator({
    required BuildContext context,
    required BoxConstraints constraints,
    required List<Map<String, dynamic>> filteredProjects,
    required TextEditingController projectSearchController,
    required String selectedProjectStatus,
    required Function(String) onProjectStatusChanged,
    required Function(Map<String, dynamic>) onProjectTap,
    required List<Map<String, dynamic>> filteredTransactions,
    required TextEditingController transactionSearchController,
    required String selectedPaymentType,
    required Function(String) onPaymentTypeChanged,
    required Function getTimeAgo,
  }) {
    final PageController pageController = PageController();
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight * 0.5;
    const pageCount = 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: availableHeight,
          child: PageView(
            controller: pageController,
            children: [
              _buildClientsSectionWithFixedHeader(
                context: context,
                filteredProjects: filteredProjects,
                projectSearchController: projectSearchController,
                selectedProjectStatus: selectedProjectStatus,
                onProjectStatusChanged: onProjectStatusChanged,
                onProjectTap: onProjectTap,
                getTimeAgo: getTimeAgo,
              ),
              _buildTransactionsSectionWithFixedHeader(
                context: context,
                filteredTransactions: filteredTransactions,
                transactionSearchController: transactionSearchController,
                selectedPaymentType: selectedPaymentType,
                onPaymentTypeChanged: onPaymentTypeChanged,
                getTimeAgo: getTimeAgo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildHistoryPageIndicator(pageController, pageCount),
      ],
    );
  }

  static Widget _buildHistoryPageIndicator(PageController pageController, int pageCount) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        if (!pageController.hasClients) {
          return const SizedBox.shrink();
        }

        final currentPage = pageController.page ?? 0;
        final page = currentPage.round();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page == index ? Colors.amber.shade700 : Colors.grey.shade300,
              ),
            );
          }),
        );
      },
    );
  }

  static Widget _buildClientHistoryCard(
    Map<String, dynamic> project,
    Function(Map<String, dynamic>) onProjectTap,
    Function getTimeAgo,
  ) {
    final status = project['status']?.toString();
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);
    
    return InkWell(
      onTap: () => onProjectTap(project),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project['contractee']?['full_name'] ?? 'Unknown Client',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['type'] ?? 'No type',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (project['created_at'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Created ${getTimeAgo(DateTime.parse(project['created_at']))}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onProjectTap(project),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Details', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    Function getTimeAgo,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payment, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['project_title'] ?? 'Untitled',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['payment_type'] ?? 'Payment',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (transaction['date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    getTimeAgo(DateTime.parse(transaction['date'])),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₱${transaction['amount'] ?? 0}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  static Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  static String _getStatusLabel(String? status) {
    return ProjectStatus().getStatusLabel(status);
  }

  static Widget _buildSpecializationDisplay(String specialization) {
    // Handle specialization the same way as in cor_profile.dart
    // If empty or "No specialization", show text
    if (specialization.isEmpty || specialization == "No specialization") {
      return Text(
        'No specialization',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }
    
    // Split by comma and create chips
    // This matches the logic in cor_profile.dart where List is joined with ", "
    final specs = specialization.split(", ").where((spec) => spec.trim().isNotEmpty).toList();
    
    if (specs.isEmpty) {
      return Text(
        'No specialization',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specs.map((spec) {
        return Chip(
          label: Text(
            spec.trim(),
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: Colors.amber.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }).toList(),
    );
  }

  static void showPhotoDialog(BuildContext context, Map<String, dynamic> photo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey[900],
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      photo['photo_url'],
                      fit: BoxFit.contain,
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
