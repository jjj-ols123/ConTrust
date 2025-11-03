// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _ProjectStatusHelper {
  static String getStatusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'awaiting_contract':
        return 'Contract Pending';
      case 'awaiting_agreement':
        return 'Awaiting Agreement';
      case 'awaiting_signature':
        return 'Awaiting Signature';
      case 'cancellation_requested_by_contractee':
        return 'Cancellation Requested';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'stopped':
        return 'Stopped';
      case 'closed':
        return 'Closed';
      case 'ended':
        return 'Ended';
      default:
        return 'Unknown';
    }
  }

  static Color getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'awaiting_contract':
        return Colors.blue;
      case 'awaiting_agreement':
        return Colors.purple;
      case 'awaiting_signature':
        return Colors.deepPurple;
      case 'cancellation_requested_by_contractee':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.teal;
      case 'stopped':
        return Colors.grey;
      case 'closed':
        return Colors.redAccent;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'pending':
        return Icons.pending;
      case 'awaiting_contract':
      case 'awaiting_agreement':
      case 'awaiting_signature':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      case 'stopped':
      case 'closed':
      case 'ended':
        return Icons.stop_circle;
      default:
        return Icons.circle;
    }
  }
}

class CeeProfileBuildMethods {
  static Widget buildHeader(BuildContext context, String title) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.handyman_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
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
    );
  }

  static Widget buildMainContent(String selectedTab, Function buildAboutContent, Function buildHistoryContent) {
    switch (selectedTab) {
      case 'About':
        return buildAboutContent();
      case 'History':
        return buildHistoryContent();
      default:
        return buildAboutContent();
    }
  }

  static Widget buildMobileLayout({
    required String fullName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
    required VoidCallback? onUploadPhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade700, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey.shade100,
                        child: ClipOval(
                          child: (profileImage != null && profileImage.isNotEmpty)
                              ? Image.network(
                                  profileImage,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      profileUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.person, size: 40, color: Colors.grey.shade400);
                                      },
                                    );
                                  },
                                )
                              : Image.network(
                                  profileUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person, size: 40, color: Colors.grey.shade400);
                                  },
                                ),
                        ),
                      ),
                    ),
                    if (onUploadPhoto != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: onUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: buildMobileNavigation(selectedTab, onTabChanged),
          ),
          const SizedBox(height: 16),
          mainContent,
        ],
      ),
    );
  }

  static Widget buildDesktopLayout({
    required String fullName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
    required VoidCallback? onUploadPhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar
          SizedBox(
            width: 280,
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: 280, // Add fixed width to match navigation width
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber.shade700, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey.shade100,
                              child: ClipOval(
                                child: (profileImage != null && profileImage.isNotEmpty)
                                    ? Image.network(
                                        profileImage,
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            profileUrl,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.person, size: 45, color: Colors.grey.shade400);
                                            },
                                          );
                                        },
                                      )
                                    : Image.network(
                                        profileUrl,
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.person, size: 45, color: Colors.grey.shade400);
                                        },
                                      ),
                              ),
                            ),
                          ),
                          if (onUploadPhoto != null)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: onUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6)
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      buildNavigation('About', selectedTab == 'About', () => onTabChanged('About')),
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

  static Widget buildAbout({
    required BuildContext context,
    required String fullName,
    required String contactNumber,
    required String address,
    required String email,
    required bool isEditingFullName,
    required bool isEditingContact,
    required bool isEditingAddress,
    required TextEditingController fullNameController,
    required TextEditingController contactController,
    required TextEditingController addressController,
    required VoidCallback toggleEditFullName,
    required VoidCallback toggleEditContact,
    required VoidCallback toggleEditAddress,
    required VoidCallback saveFullName,
    required VoidCallback saveContact,
    required VoidCallback saveAddress,
    required String contracteeId,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildReadOnlyField(
            'Email',
            email.isEmpty ? 'No email provided' : email,
            Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Full Name',
            fullName,
            Icons.person_outline,
            isEditingFullName,
            fullNameController,
            toggleEditFullName,
            saveFullName,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Contact Number',
            contactNumber,
            Icons.phone_outlined,
            isEditingContact,
            contactController,
            toggleEditContact,
            saveContact,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Address',
            address,
            Icons.location_on_outlined,
            isEditingAddress,
            addressController,
            toggleEditAddress,
            saveAddress,
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoField(
    String label,
    String value,
    IconData icon,
    bool isEditing,
    TextEditingController controller,
    VoidCallback onEdit,
    VoidCallback onSave,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (isEditing)
                Row(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      child: Text('Cancel', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onSave,
                      child: Text('Save', style: TextStyle(fontSize: 13, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined, size: 18, color: Colors.amber.shade700),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEditing)
            TextField(
              controller: controller,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            )
          else
            Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: 14,
                color: value.isNotEmpty ? const Color(0xFF1F2937) : Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  static Widget buildHistory({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredProjects,
    required List<Map<String, dynamic>> filteredTransactions,
    required List<Map<String, dynamic>> reviews,
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
                child: _buildProjectsSection(
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
              const SizedBox(width: 16),
              Expanded(
                child: _buildReviewsSection(context: context, reviews: reviews),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildProjectsSection(
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
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildTransactionsSection(
                    context: context,
                    filteredTransactions: filteredTransactions,
                    transactionSearchController: transactionSearchController,
                    selectedPaymentType: selectedPaymentType,
                    onPaymentTypeChanged: onPaymentTypeChanged,
                    getTimeAgo: getTimeAgo,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildReviewsSection(context: context, reviews: reviews),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  static Widget _buildProjectsSection({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredProjects,
    required TextEditingController projectSearchController,
    required String selectedProjectStatus,
    required Function(String) onProjectStatusChanged,
    required Function(Map<String, dynamic>) onProjectTap,
    required Function getTimeAgo,
  }) {
    // Sort projects: non-completed/cancelled on top
    final sortedProjects = List<Map<String, dynamic>>.from(filteredProjects);
    sortedProjects.sort((a, b) {
      final statusA = (a['status'] ?? '').toString().toLowerCase();
      final statusB = (b['status'] ?? '').toString().toLowerCase();
      
      // Priority: active projects first, then by date
      bool isActiveA = statusA != 'completed' && statusA != 'cancelled';
      bool isActiveB = statusB != 'completed' && statusB != 'cancelled';
      
      if (isActiveA && !isActiveB) return -1;
      if (!isActiveA && isActiveB) return 1;
      
      // If same active status, sort by created date (newest first)
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
                'Project History',
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
                    hintText: 'Search projects...',
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
                        Text('No projects found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sortedProjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = sortedProjects[index];
                      return _buildProjectHistoryCard(project, onProjectTap, getTimeAgo);
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
                'Payment History',
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

  static Widget _buildReviewsSection({
    required BuildContext context,
    required List<Map<String, dynamic>> reviews,
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
              Icon(Icons.star_border, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Review History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Reviews you\'ve given to contractors',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: reviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No reviews yet', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _buildReviewCard(review);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildProjectHistoryCard(
    Map<String, dynamic> project,
    Function(Map<String, dynamic>) onProjectTap,
    Function getTimeAgo,
  ) {
    final status = project['status']?.toString();
    final statusColor = _ProjectStatusHelper.getStatusColor(status);
    final statusIcon = _ProjectStatusHelper.getStatusIcon(status);
    final statusLabel = _ProjectStatusHelper.getStatusLabel(status);
    
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
                    project['title'] ?? 'Untitled Project',
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
            // Quick Actions
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

  static Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toDouble();
    final contractorName = review['contractor_name'] ?? 'Unknown Contractor';
    final contractorPhoto = review['contractor_photo'];
    
    return Container(
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
              // Contractor Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: contractorPhoto != null
                      ? Image.network(
                          contractorPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.grey.shade600),
                        )
                      : Icon(Icons.person, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contractorName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Review',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Rating
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ],
          ),
          if (review['review_text'] != null && review['review_text'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['review_text'],
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          if (review['created_at'] != null) ...[
            const SizedBox(height: 8),
            Text(
              DateTime.parse(review['created_at']).toString().split(' ')[0],
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildNavigation(String title, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.amber.shade800 : const Color(0xFF4B5563),
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(Icons.chevron_right, size: 20, color: Colors.amber.shade700),
          ],
        ),
      ),
    );
  }

  static Widget buildMobileNavigation(String selectedTab, Function(String) onTabChanged) {
    final tabs = ['About', 'History'];
    
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
                  style: TextStyle(
                    fontSize: 12,
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

  static Widget buildProjectDetailsDialog(
    BuildContext context,
    Map<String, dynamic> project,
    Function getTimeAgo,
  ) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header matching ProjectModal
              Container(
                padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.folder_open,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        project['title'] ?? 'Project Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge at the top
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _ProjectStatusHelper.getStatusColor(project['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _ProjectStatusHelper.getStatusColor(project['status']).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _ProjectStatusHelper.getStatusIcon(project['status']),
                              size: 14,
                              color: _ProjectStatusHelper.getStatusColor(project['status']),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _ProjectStatusHelper.getStatusLabel(project['status']),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _ProjectStatusHelper.getStatusColor(project['status']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildProjectDetailsSection(project, getTimeAgo),
                      
                      const SizedBox(height: 24),
                      
                      // Description section
                      _buildDescriptionSection(project),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildProjectDetailsSection(Map<String, dynamic> project, Function getTimeAgo) {
    final details = [
      _buildDetailItem(
        icon: Icons.attach_money,
        label: 'BUDGET',
        value: _formatBudget(project),
      ),
      _buildDetailItem(
        icon: Icons.calendar_today,
        label: 'START DATE',
        value: _formatStartDate(project),
      ),
      _buildDetailItem(
        icon: Icons.location_on,
        label: 'LOCATION',
        value: project['location'] ?? 'Not specified',
      ),
      if (project['type'] != null)
        _buildDetailItem(
          icon: Icons.category,
          label: 'TYPE',
          value: project['type'],
        ),
      if (project['duration'] != null)
        _buildDetailItem(
          icon: Icons.schedule,
          label: 'DURATION',
          value: '${project['duration']} days',
        ),
      _buildDetailItem(
        icon: Icons.calendar_today_outlined,
        label: 'CREATED',
        value: project['created_at'] != null ? getTimeAgo(DateTime.parse(project['created_at'])) : 'N/A',
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < details.length; i += 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details[i]),
                if (i + 1 < details.length)
                  const SizedBox(width: 16),
                if (i + 1 < details.length)
                  Expanded(child: details[i + 1]),
              ],
            ),
          ),
      ],
    );
  }

  static Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildDescriptionSection(Map<String, dynamic> project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            project['description'] ?? 'No description provided',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatBudget(Map<String, dynamic> project) {
    final minBudget = project['min_budget'];
    final maxBudget = project['max_budget'];
    
    if (minBudget != null && maxBudget != null) {
      return '₱$minBudget - ₱$maxBudget';
    } else if (minBudget != null) {
      return '₱$minBudget';
    } else if (maxBudget != null) {
      return '₱$maxBudget';
    }
    return 'Not specified';
  }

  static String _formatStartDate(Map<String, dynamic> project) {
    return project['start_date'] != null
        ? _formatDate(project['start_date'])
        : 'Not specified';
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
