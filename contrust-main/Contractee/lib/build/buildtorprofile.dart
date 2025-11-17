// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/utils/be_contractformat.dart'; // added import

const String profileUrl =
    'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

class TorProfileBuildMethods {
  static Widget buildMainContent(String selectedTab, Function buildPortfolioContent, Function buildAboutContent, Function buildReviewsContent) {
    switch (selectedTab) {
      case 'Portfolio':
        return buildPortfolioContent();
      case 'About':
        return buildAboutContent();
      case 'Reviews':
        return buildReviewsContent();
      default:
        return buildPortfolioContent();
    }
  }

  static Widget buildMobileLayout({
    required String firmName,
    required String? profileImage,
    required int completedProjectsCount,
    required double rating,
    required List<String> pastProjects,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
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
                  child: Container(
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
                buildMobileNavigation(selectedTab, onTabChanged),
                const SizedBox(height: 16),
                mainContent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDesktopLayout({
    required String firmName,
    required String? profileImage,
    required int completedProjectsCount,
    required double rating,
    required List<String> pastProjects,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
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
                        child: Container(
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
                          ],
                        ),
                      ),
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
    required BuildContext context,
    required Function(String) onViewPhoto,
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
                      image: AssetImage('assets/bgloginscreen.jpg'),
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
                    'This contractor hasn\'t uploaded any project photos yet',
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
              childAspectRatio: screenWidth > 1200 ? 1.9 : 1.7,
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
              ],
            ),
            const SizedBox(height: 32),
            buildContractorInfo(
              'Firm Name',
              firmName,
              Icons.business,
            ),
            const SizedBox(height: 24),
            buildContractorInfo(
              'Bio',
              bio,
              Icons.description,
            ),
            const SizedBox(height: 24),
            buildContractorInfo(
              'Contact Information',
              contactNumber,
              Icons.phone,
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
                  if (specialization.isEmpty || specialization == "No specialization")
                    Text(
                      'No specialization',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: specialization.split(", ").map((spec) {
                        if (spec.trim().isEmpty) return const SizedBox.shrink();
                        return Chip(
                          label: Text(
                            spec.trim(),
                            style: const TextStyle(fontSize: 13),
                          ),
                          backgroundColor: Colors.amber.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            buildContractorInfo(
              'Address',
              address,
              Icons.location_on,
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
    String selectedFilter = 'All',
    required Function(String) onFilterChanged,
    required bool canRate,
    required bool hasRated,
    required double userRating,
    required VoidCallback onRate,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        const filterOptions = ['All', '5 Stars', '4 Stars', '3 Stars', '2 Stars', '1 Star'];
        final filteredReviews = allRatings.where((review) {
          if (selectedFilter == 'All') return true;
          final ratingValue = (review['rating'] as num?)?.toDouble() ?? 0.0;
          final requiredStars = int.tryParse(selectedFilter.split(' ').first) ?? 0;
          return ratingValue.round() == requiredStars;
        }).toList();

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
                SizedBox(width: isMobile ? 12 : 16),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: filterOptions.map((option) {
                        final isSelected = selectedFilter == option;
                        Widget label;
                        if (option == 'All') {
                          label = Text(
                            'All',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color:
                                  isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          );
                        } else {
                          final starsCount =
                              int.tryParse(option.split(' ').first) ?? 0;
                          label = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(starsCount, (_) {
                              return Icon(
                                Icons.star,
                                size: isMobile ? 14 : 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.amber.shade600,
                              );
                            }),
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.only(right: isMobile ? 6 : 8),
                          child: ChoiceChip(
                            label: label,
                            selected: isSelected,
                            onSelected: (_) => onFilterChanged(option),
                            selectedColor: Colors.amber.shade700,
                            backgroundColor: Colors.grey.shade100,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: isMobile ? 4 : 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
            if (canRate) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          hasRated ? 'Your Rating' : 'Rate This Contractor',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < userRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                      ),
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
                      onPressed: onRate,
                      icon: Icon(hasRated ? Icons.edit : Icons.star),
                      label: Text(hasRated ? 'Update Rating' : 'Rate Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
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
            else if (filteredReviews.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 32),
                  child: Text(
                    'No reviews for the selected filter yet.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReviews.length,
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  final reviewText = review['review'] as String? ?? 'No written review provided.';
                  final reviewRating = (review['rating'] as num?)?.toDouble() ?? 0.0;
                  final clientName = review['client_name'] as String? ?? 'Anonymous Client';

                  final createdAtStr = review['created_at']?.toString();
                  final timeDisplay = ContractStyle.formatDate(createdAtStr);

                  return buildReviewCard(
                    clientName,
                    reviewText,
                    reviewRating,
                    'Completed Project',
                    timeDisplay,
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

  static Widget buildReviews(String clientName, String review, double rating, String projectName, String timeAgo) {
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
                    Text(
                      projectName,
                      style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
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
          color: isActive ? Colors.amber.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildMobileNavigation(String selectedTab, Function(String) onTabChanged) {
    final tabs = ['Portfolio', 'About', 'Reviews'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = selectedTab == tab;
          final isFirst = index == 0;
          final isLast = index == tabs.length - 1;
          
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.amber.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                    bottomLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                    topRight: isLast ? const Radius.circular(8) : Radius.zero,
                    bottomRight: isLast ? const Radius.circular(8) : Radius.zero,
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? Colors.white : const Color(0xFF4B5563),
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
            ],
          ),
          const SizedBox(height: 12),
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