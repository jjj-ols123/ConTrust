// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiddingUIBuildMethods {
  BiddingUIBuildMethods({
    required this.context,
    required this.isLoading,
    required this.projects,
    required this.highestBids,
    required this.onRefresh,
    required this.hasAlreadyBid,
    required this.finalizedProjects,
    required this.selectedProject,
    required this.contracteeInfo,
    required this.contractorBids,
    required this.onProjectSelected, 
  }) ;

  final BuildContext context;
  final bool isLoading;
  final List<Map<String, dynamic>> projects;
  final Map<String, double> highestBids;
  final VoidCallback onRefresh;
  final Future<bool> Function(String, String) hasAlreadyBid;
  final Set<String> finalizedProjects;
  final Map<String, dynamic>? selectedProject;
  final Map<String, Map<String, dynamic>> contracteeInfo;
  final Function(Map<String, dynamic>?) onProjectSelected;
  final CorBiddingService _service = CorBiddingService();
  final List<Map<String, dynamic>> contractorBids;

  Widget buildBiddingUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1000;

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Container(
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
                    'Project Biddings',
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
          buildContractorBidsOverview(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onRefresh,

                  label: Text('Refresh', style: const TextStyle(fontSize: 14)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber[800],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search projects...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.amber[700], size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLargeScreen
                    ? Row(
                      children: [
                        Expanded(flex: 2, child: buildProjectGrid()),
                        Container(
                          width: 1,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        Expanded(flex: 1, child: buildProjectDetails()),
                      ],
                    )
                    : buildProjectGrid(),
          ),
        ],
      ),
    );
  }

  Widget buildContractorBidsOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Bids',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...contractorBids.take(2).map(buildBidItem),
            if (contractorBids.length > 2)
              Text(
                '... and ${contractorBids.length - 2} more',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
        children: contractorBids.skip(2).map(buildBidItem).toList(),
      ),
    );
  }

  Widget buildBidItem(Map<String, dynamic> bid) {
    final project = bid['project'] ?? {};
    final status = bid['status'] ?? 'pending';
    final amount = bid['bid_amount'] ?? 0;
    final projectType = project['type'] ?? 'Unknown Project';

    Color statusColor;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'stopped':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return ListTile(
      leading: Icon(Icons.assignment, color: Colors.amber),
      title: Text(projectType, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Bid: ₱$amount'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildProjectGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : projects.isEmpty
        ? const Center(child: Text("No projects available"))
        : GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                screenWidth > 1200
                    ? 3
                    : screenWidth > 800
                    ? 2
                    : 1,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: screenWidth > 1200 ? 1.3 : 1.7,
          ),
          itemBuilder: (ctx, index) {
            final project = projects[index];
            final screenWidth = MediaQuery.of(context).size.width;
            final isLargeScreen = screenWidth > 1000;

            return GestureDetector(
              onTap: () {
                if (isLargeScreen) {
                  if (selectedProject != null &&
                      selectedProject!['project_id'] == project['project_id']) {
                    onProjectSelected(null);
                  } else {
                    onProjectSelected(project);
                  }
                } else {
                  showDetails(project);
                }
              },
              child: buildProjectCard(project),
            );
          },
        );
  }

  Widget buildProjectDetails() {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          selectedProject == null
              ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  height: 600,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a project to view details',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedProject!['type'] ?? 'Project',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedProject!['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D6D7E),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.shade100,
                            ),
                            child: ClipOval(
                              child:
                                  contracteeInfo[selectedProject!['contractee_id']]?['profile_photo'] !=
                                          null
                                      ? Image.network(
                                        contracteeInfo[selectedProject!['contractee_id']]!['profile_photo'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            'defaultpic.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        'defaultpic.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posted by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7D7D7D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contracteeInfo[selectedProject!['contractee_id']]?['full_name'] ??
                                      'Unknown Contractee',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Location:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${selectedProject!['location']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Minimum Budget:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${selectedProject!['min_budget']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Maximum Budget:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${selectedProject!['max_budget']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    buildBidInput(),
                  ],
                ),
              ),
    );
  }

  Widget buildBidInput() {
    final TextEditingController bidController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submit Your Bid',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bidController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Bid Amount',
            prefixText: '₱',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: messageController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Message to the contractee on what you can offer!',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser?.id;
              if (user == null || selectedProject!['contractee_id'] == null) {
                ConTrustSnackBar.error(context, 'Missing IDs');
                return;
              }
              final already = await hasAlreadyBid(
                user,
                selectedProject!['project_id'].toString(),
              );
              if (already) {
                ConTrustSnackBar.warning(context, 'You have already placed a bid on this project.');
                return;
              }
              final bidAmount = int.tryParse(bidController.text.trim()) ?? 0;
              final message = messageController.text.trim();
              if (!validateBidRequest(
                context,
                bidController.text.trim(),
                message,
              )) {
                return;
              }
              await _service.postBid(
                contractorId: user,
                projectId: selectedProject!['project_id'].toString(),
                bidAmount: bidAmount,
                message: message,
                context: context,
              );
              bidController.clear();
              messageController.clear();
              onProjectSelected(null);
            },
            child: const Text(
              'Submit Bid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void showDetails(Map<String, dynamic> project) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.amber.shade50],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('kitchen.jpg', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      project['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      project['type'] ?? 'Project',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D6D7E),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.shade100,
                            ),
                            child: ClipOval(
                              child:
                                  contracteeInfo[project['contractee_id']]?['profile_photo'] !=
                                          null
                                      ? Image.network(
                                        contracteeInfo[project['contractee_id']]!['profile_photo'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            'defaultpic.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        'defaultpic.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posted by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7D7D7D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contracteeInfo[project['contractee_id']]?['full_name'] ??
                                      'Unknown Contractee',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Location:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${project['location']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Minimum Budget:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${project['min_budget']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Maximum Budget:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${project['max_budget']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    buildBidInput(),
                  ],
                ),
              ),
            )
          )
    );
  }

  Widget buildProjectCard(Map<String, dynamic> project) {
    final isSelected =
        selectedProject != null &&
        selectedProject!['project_id'] == project['project_id'];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isSelected
                  ? [Colors.amber.shade100, Colors.amber.shade200]
                  : [Colors.white, Colors.amber.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            isSelected
                ? Border.all(color: Colors.amber.shade600, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.1),
            blurRadius: isSelected ? 20 : 15,
            offset: const Offset(0, 5),
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Image.asset(
                  'kitchen.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
          "${project['title'] ?? 'Unknown'}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[600]!, Colors.amber[800]!],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Time left:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D6D7E),
                      ),
                    ),
                    StreamBuilder<Duration>(
                      stream: _service.getBiddingCountdownStream(
                        DateTime.parse(project['created_at']),
                        project['duration'],
                      ),
                      builder: (ctx, snap) {
                        if (!snap.hasData) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF85929E),
                            ),
                          );
                        }
                        final remaining = snap.data!;
                        if (remaining.isNegative &&
                            !finalizedProjects.contains(
                              project['project_id'].toString(),
                            )) {
                          finalizedProjects.add(
                            project['project_id'].toString(),
                          );
                        }
                        if (remaining.isNegative) {
                          return const Text(
                            'Ended',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        final days = remaining.inDays;
                        final hours = remaining.inHours
                            .remainder(24)
                            .toString()
                            .padLeft(2, '0');
                        final minutes = remaining.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        final seconds = remaining.inSeconds
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        return Text(
                          '$days d $hours:$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Highest Bid:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D6D7E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[100]!, Colors.amber[200]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₱${highestBids[project['project_id'].toString()]?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD68910),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
