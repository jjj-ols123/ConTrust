// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class ProfileBuildMethods {
  static Widget buildMainContent(String selectedTab, Function buildPortfolioContent, Function buildAboutContent, Function buildReviewsContent, Function buildClientHistoryContent) {
    switch (selectedTab) {
      case 'Portfolio':
        return buildPortfolioContent();
      case 'About':
        return buildAboutContent();
      case 'Reviews':
        return buildReviewsContent();
      case 'Client History':
        return buildClientHistoryContent();
      default:
        return buildPortfolioContent();
    }
  }

  static Widget buildMobileLayout({
    required String firmName,
    required String specialization,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required double rating,
    required List<String> pastProjects,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
    required VoidCallback? onProfilePhotoUpload,
    required VoidCallback? onViewProfilePhoto, // add this
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
                          backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                              ? NetworkImage(profileImage)
                              : NetworkImage(profileUrl),
                          child: (profileImage == null || profileImage.isEmpty)
                              ? Icon(
                                  Icons.business,
                                  size: 35,
                                  color: Colors.grey.shade400,
                                )
                              : null,
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
                const SizedBox(height: 6),
                Text(
                  specialization,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
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
    required String specialization,
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
                                backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                                    ? NetworkImage(profileImage)
                                    : NetworkImage(profileUrl),
                                child: (profileImage == null || profileImage.isEmpty)
                                    ? Icon(
                                        Icons.business,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      )
                                    : null,
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
                      const SizedBox(height: 8),
                      Text(
                        specialization,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
                      buildNavigation('Client History', selectedTab == 'Client History', () => onTabChanged('Client History')),
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
                    Text(
                      bio.isNotEmpty ? bio : 'Building Excellence Since Day One',
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
    required bool isEditingSpecialization,
    required bool isEditingAddress,
    required TextEditingController firmNameController,
    required TextEditingController bioController,
    required TextEditingController contactController,
    required TextEditingController specializationController,
    required TextEditingController addressController,
    required VoidCallback toggleEditFirmName,
    required VoidCallback toggleEditBio,
    required VoidCallback toggleEditContact,
    required VoidCallback toggleEditSpecialization,
    required VoidCallback toggleEditAddress,
    required VoidCallback saveFirmName,
    required VoidCallback saveBio,
    required VoidCallback saveContact,
    required VoidCallback saveSpecialization,
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
            
            buildContractorInfo(
              'Specialization',
              specialization,
              Icons.work,
              isEditingSpecialization,
              specializationController,
              toggleEditSpecialization,
              saveSpecialization,
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
                  Icons.star_rate,
                  color: Colors.amber.shade700,
                  size: 28,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
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
            const SizedBox(height: 32),
            
            if (totalReviews == 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Reviews Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete projects to start receiving reviews from clients',
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
                      ? DateTime.parse(review['created_at'])
                      : DateTime.now();
                  final timeAgo = getTimeAgo(createdAt);
                  
                  return buildReviewCard(
                    clientName,
                    reviewText,
                    reviewRating,
                    'Completed Project',
                    timeAgo,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildRatingBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget buildReviews(String clientName, String review, double rating, String projectName, String timeAgo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.amber.shade100,
                child: Text(
                  clientName[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      projectName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
                        size: 16,
                      );
                    }),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
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
    final tabs = ['Portfolio', 'About', 'Reviews', 'Client History'];
    
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
              maxLines: title == 'Bio' ? 3 : 1,
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
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildClientHistory({
    required List<Map<String, dynamic>> filteredProjects,
    required TextEditingController searchController,
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
                Icon(Icons.history, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Client History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                hintText: 'Search clients or projects...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.amber.shade400),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            if (filteredProjects.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No completed projects found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.amber.shade700,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project['contractee']?['full_name'] ?? 'Unknown Client',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project['type'] ?? 'Project Type',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project['description'] ?? 'No description available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
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
