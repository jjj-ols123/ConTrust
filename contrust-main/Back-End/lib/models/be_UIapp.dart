// ignore_for_file: deprecated_member_use, use_super_parameters, file_names, use_build_context_synchronously
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractorsView extends StatelessWidget {
  final String id;
  final String name;
  final String profileImage;
  final double rating;
  final bool isMobile;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  const ContractorsView({
    Key? key,
    required this.id,
    required this.name,
    required this.profileImage,
    required this.rating,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.amber.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                (profileImage.isNotEmpty) ? profileImage : profileUrl,
              height: isMobile ? 90 : 170,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    profileUrl,
                  height: isMobile ? 90 : 170,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: isMobile ? 90 : 170,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.person, size: isMobile ? 45 : 84, color: Colors.grey.shade600),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 14,
                  vertical: isMobile ? 6 : 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 12 : 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starSize = isMobile ? 14.0 : 18.0;
                        if (index < rating.floor()) {
                          return Icon(Icons.star, color: Colors.amber, size: starSize);
                        } else if (index < rating.ceil() && rating % 1 != 0) {
                          return Icon(Icons.star_half, color: Colors.amber, size: starSize);
                        } else {
                          return Icon(Icons.star_border, color: Colors.grey, size: starSize);
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 8 : 14,
                0,
                isMobile ? 8 : 14,
                isMobile ? 8 : 10,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    CheckUserLogin.isLoggedIn(
                      context: context,
                      onAuthenticated: () async {
                        if (!context.mounted) return;
                        final encodedName = Uri.encodeComponent(name);
                        context.go('/contractor/$encodedName');
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 4 : 10,
                      horizontal: isMobile ? 8 : 16,
                    ),
                    minimumSize: Size(0, isMobile ? 32 : 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "View",
                    style: TextStyle(fontSize: isMobile ? 11 : 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectView extends StatelessWidget {
  final Map<String, dynamic> project;
  final String projectId;
  final double highestBid;
  final int duration;
  final DateTime createdAt;
  final Function() onTap;
  final Function(String) handleFinalizeBidding;
  final Function(String)? onUpdateProject;
  final Function(String, String)? onCancelProject;
  final bool isLoading;

  const ProjectView({
    Key? key,
    required this.project,
    required this.projectId,
    required this.highestBid,
    required this.duration,
    required this.createdAt,
    required this.onTap,
    required this.handleFinalizeBidding,
    this.onUpdateProject,
    this.onCancelProject,
    this.isLoading = false, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectData = project['projectdata'] as Map<String, dynamic>?;
    final hiringType = projectData?['hiring_type'] ?? 'bidding';
    final isHiringRequest = duration == 0 || hiringType == 'direct_hire';
    final status = ProjectStatus();
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userType = currentUser?.userMetadata?['user_type']?.toString();
    final isContractee = userType == 'contractee';

    final projectCard = Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, status),

                const SizedBox(height: 16),
                _buildProjectDetails(context, isHiringRequest),

                const SizedBox(height: 16),

                _buildDescription(),

                const SizedBox(height: 16),

                if (!isHiringRequest && project['status'] == 'pending')
                  _buildBiddingInfo(),

              ],
            ),
          ),
          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (isContractee) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContractStatusIndicator(),
          projectCard,
        ],
      );
    }

    return projectCard;
  }

  Widget _buildHeader(BuildContext context, ProjectStatus status) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Determine user type
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userType = currentUser?.userMetadata?['user_type']?.toString();
    final isContractee = userType == 'contractee';
    
    if (isMobile) {
      if (isContractee) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project['title'] ?? 'No title given',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if ((onUpdateProject != null || onCancelProject != null) && project['project_id'] != null)
                  _buildActionMenu(context),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusChip(status),
          ],
        );
      } else {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                const Spacer(),
                _buildContractButton(context),
              ],
            ),
            const SizedBox(height: 8),
              Text(
                project['title'] ?? 'No title given',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildStatusChip(status),
            ],
        );
      }
    } else {
      if (isContractee) {
        return Row(
          children: [
            Expanded(
              child: Text(
                project['title'] ?? 'No title given',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusChip(status),
            const SizedBox(width: 12),
            _buildContractButton(context),
            const SizedBox(width: 8),
            if ((onUpdateProject != null || onCancelProject != null) && project['project_id'] != null)
              _buildActionMenu(context),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project['title'] ?? 'No title given',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(status),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildContractButton(context),
      ],
    );
      }
    }
  }

  Widget _buildStatusChip(ProjectStatus status) {
    final statusColor = status.getStatusColor(project['status']);
    final statusLabel = status.getStatusLabel(project['status']);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(project['status']),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractStatusIndicator() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FetchService().streamContractsForProject(projectId),
      builder: (context, snapshot) {
        Widget buildCenteredChip(Widget child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(child: child),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return buildCenteredChip(_buildNoContractLabel());
        }

        final latestContract = snapshot.data!.first;
        final contractStatus = latestContract['status'] as String?;
        if (contractStatus == null || contractStatus.isEmpty) {
          return buildCenteredChip(_buildNoContractLabel());
        }

        final color = ContractStatus.getStatusColor(contractStatus);
        final icon = ContractStatus.getStatusIcon(contractStatus);
        final label = _formatContractStatusLabel(contractStatus);

        return buildCenteredChip(
          InkWell(
            onTap: () => _showEnhancedContractView(context, latestContract),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Contract Status: $label',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatContractStatusLabel(String status) {
    return status
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (BuildContext context) => [
        if (onUpdateProject != null)
          PopupMenuItem<String>(
            value: 'update',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Update Project'),
              ],
            ),
          ),
        if (onCancelProject != null)
          PopupMenuItem<String>(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Cancel Project'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoContractLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            'No Contract',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractButton(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FetchService().streamContractsForProject(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoContractLabel();
        }

        final contracts = snapshot.data!;
        final latestContract = contracts.first;
        final status = latestContract['status'] as String? ?? 'draft';
        
        final currentUser = Supabase.instance.client.auth.currentUser;
        final userType = currentUser?.userMetadata?['user_type']?.toString();
        final isContractee = userType == 'contractee';
        
        final projectStatus = project['status'] as String? ?? '';
        final projectStatusLower = projectStatus.toLowerCase();
        final contractStatusLower = status.toLowerCase();
        
        if (projectStatusLower == 'awaiting_contract' && contractStatusLower == 'rejected') {
          return _buildNoContractLabel();
        }
        
        final shouldShowContract = !isContractee ||
            contractStatusLower != 'draft';
        
        if (!shouldShowContract) {
          return _buildNoContractLabel();
        }
        
        Color borderColor;
        Color backgroundColor;
        Color textColor;
        IconData icon;
        String statusText;

        final contractStatus = status.toLowerCase().trim();
        final projectStatusTrimmed = projectStatusLower.trim();
        
        final effectiveStatus = (contractStatus == 'draft' && 
            (projectStatusTrimmed == 'awaiting_agreement' || 
             projectStatusTrimmed == 'awaiting_signature' || 
             projectStatusTrimmed == 'awaiting_contract')) 
            ? 'sent' 
            : contractStatus;

        switch (effectiveStatus) {
          case 'approved':
          case 'active':
          case 'signed':
            borderColor = Colors.green.shade600;
            backgroundColor = Colors.green.shade50;
            textColor = Colors.green.shade700;
            icon = Icons.verified;
            statusText = 'Contract Accepted';
            break;
          case 'sent':
            borderColor = Colors.orange.shade600;
            backgroundColor = Colors.orange.shade50;
            textColor = Colors.orange.shade700;
            icon = Icons.pending;
            statusText = 'Contract Waiting for approval';
            break;
          case 'awaiting_signature':
            borderColor = Colors.orange.shade600;
            backgroundColor = Colors.orange.shade50;
            textColor = Colors.orange.shade700;
            icon = Icons.pending;
            statusText = 'Contract Waiting for signature';
            break;
          case 'rejected':
            borderColor = Colors.red.shade600;
            backgroundColor = Colors.red.shade50;
            textColor = Colors.red.shade700;
            icon = Icons.cancel;
            statusText = 'Contract Rejected';
            break;
          default:
            borderColor = Colors.blue.shade600;
            backgroundColor = Colors.blue.shade50;
            textColor = Colors.blue.shade700;
            icon = Icons.description;
            statusText = 'Contract Draft';
        }

        return InkWell(
          onTap: () => _showEnhancedContractView(context, latestContract),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.visibility, size: 14, color: textColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectDetails(BuildContext context, bool isHiringRequest) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    
    final details = [
      _buildDetailItem(
        icon: Icons.money,
        label: 'BUDGET',
        value: _formatBudget(isHiringRequest),
      ),
      _buildDetailItem(
        icon: Icons.calendar_today,
        label: 'START DATE',
        value: _formatStartDate(),
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
      if (!isHiringRequest)
        _buildDetailItem(
          icon: Icons.schedule,
          label: 'DURATION',
          value: '$duration days',
        ),
    ];

    // If screen width > 1200, show labels in two columns
    if (isWideScreen) {
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

    // Otherwise, show all labels in one column
    return Column(
      children: [
        for (int i = 0; i < details.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: details[i],
          ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
              child: isMobile ? Row(
            children: [
              Text(
                '$label:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                      ),
                      textAlign: TextAlign.end,
                ),
              ),
            ],
              ) : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
        );
      },
    );
  }

  Widget _buildDescription() {
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
        Text(
          project['description'] ?? 'No description provided',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBiddingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          _buildBiddingDetail(
            icon: Icons.monetization_on,
            label: 'Highest Bid',
            value: "₱${highestBid.toStringAsFixed(2)}",
            valueColor: Colors.green.shade700,
          ),
          const SizedBox(height: 12),
          _buildCountdownTimer(),
        ],
      ),
    );
  }

  Widget _buildBiddingDetail({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownTimer() {
    return StreamBuilder<Duration>(
      stream: CorBiddingService().getBiddingCountdownStream(createdAt, duration),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text(
            "Loading timer...",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          );
        }

        final remaining = snapshot.data!;
        if (remaining.isNegative) {
          handleFinalizeBidding(projectId);
          return const Text(
            "Bidding Closed",
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        final days = remaining.inDays;
        final hours = remaining.inHours.remainder(24).toString().padLeft(2, '0');
        final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

        return Row(
          children: [
            Icon(Icons.timer_outlined, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            const Text(
              'Time Remaining: ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '$days d $hours:$minutes:$seconds',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatBudget(bool isHiringRequest) {
    if (isHiringRequest) {
      return (project['min_budget'] != null && project['max_budget'] != null)
          ? "₱${project['min_budget']} - ₱${project['max_budget']}"
          : 'Not specified';
    }
    return "₱${project['min_budget']?.toString() ?? '0'} - ₱${project['max_budget']?.toString() ?? '0'}";
  }

  String _formatStartDate() {
    return project['start_date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(project['start_date']))
        : 'Not specified';
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_circle_filled;
      case 'pending':
        return Icons.pending;
      case 'awaiting_contract':
        return Icons.description;
      case 'awaiting_agreement':
        return Icons.handshake;
      case 'awaiting_signature':
        return Icons.edit;
      case 'cancellation_requested_by_contractee':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.verified;
      case 'stopped':
        return Icons.stop_circle;
      case 'closed':
        return Icons.lock;
      case 'rejected':
        return Icons.thumb_down;
      case 'draft':
        return Icons.edit;
      default:
        return Icons.help;
    }
  }

  void _handleMenuSelection(BuildContext context, String value) async {
    if (value == 'update' && onUpdateProject != null) {
      onUpdateProject!(projectId);
    } else if (value == 'cancel' && onCancelProject != null) {
      final contractorId = project['contractor_id'];
      if (contractorId == null || contractorId.toString().isEmpty) {
        onCancelProject!(projectId, '');
        return;
      }
      final reason = await _showCancelReasonDialog(context);
      if (reason != null && reason.isNotEmpty) {
        onCancelProject!(projectId, reason);
      }
    }
  }

  Future<String?> _showCancelReasonDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 1.5),
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
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        child: Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cancel Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project['contractor_id'] != null 
                                  ? 'This will notify the assigned contractor and terminate any ongoing work.'
                                  : 'This action cannot be undone.',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Please provide a reason for cancelling:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: reasonController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your reason...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                maxLength: 200,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Keep Project'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final reason = reasonController.text.trim();
                                  Navigator.of(context).pop(reason.isEmpty ? 'No reason provided' : reason);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB300),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel Project'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEnhancedContractView(BuildContext context, Map<String, dynamic> contractData) async {
    try {
      final freshContractData = await ContractService.getContractById(contractData['contract_id'] as String);

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 900,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
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
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            freshContractData['title'] ?? 'Contract Details',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: StreamBuilder<Map<String, dynamic>?>(
                      stream: FetchService().streamContractById(freshContractData['contract_id'] as String),
                      initialData: freshContractData,
                      builder: (context, contractSnap) {
                        final liveData = contractSnap.data ?? freshContractData;
                        return StatefulBuilder(
                          builder: (context, setState) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
 
                              if ((liveData['status'] as String?)?.toLowerCase() == 'sent') ...[
                                Card(
                                  color: Colors.amber[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _ProjectContractApprovalButtons(
                                      contractId: liveData['contract_id'] as String,
                                      onApproved: () {
                                        Navigator.of(dialogContext).pop();
                                        ConTrustSnackBar.contractApproved(dialogContext);
                                      },
                                      onRejected: () {
                                        Navigator.of(dialogContext).pop();
                                        ConTrustSnackBar.contractRejected(dialogContext);
                                      },
                                      onError: (err) {
                                        ConTrustSnackBar.error(dialogContext, err);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              FutureBuilder<String?>(
                                future: ViewContractService.getPdfSignedUrl(liveData),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return ViewContractBuild.buildLoadingState();
                                  }
                                  
                                  if (snapshot.hasError) {
                                    return Container(
                                      height: 400,
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Failed to load contract PDF',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Please try again or contact support',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
                                    return Container(
                                      height: 400,
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade300),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Contract PDF not available',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'The contract PDF may not have been generated yet',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return ViewContractBuild.buildPdfViewer(
                                    pdfUrl: snapshot.data,
                                    onDownload: () => _downloadContract(liveData),
                                    height: 400,
                                    isSignedContract: (liveData['signed_pdf_url'] as String?)?.isNotEmpty == true,
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              ViewContractBuild.buildEnhancedSignaturesSection(
                                liveData,
                                    onRefresh: () {
                                      setState(() {});
                                    },
                                    currentUserId: Supabase.instance.client.auth.currentUser?.id,
                                    context: dialogContext,
                                    contractStatus: liveData['status'] as String?,
                                    parentDialogContext: dialogContext,
                              ),
                            ],
                          ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error loading contract: $e');
      }
    }
  }

  Future<void> _downloadContract(Map<String, dynamic> contractData) async {
    try {
      final pdfUrl = await ViewContractService.getPdfSignedUrl(contractData);
      if (pdfUrl != null) {
      }
    } catch (e) {
      // 
    }
  }
}

class _ProjectContractApprovalButtons extends StatefulWidget {
  final String contractId;
  final VoidCallback onApproved;
  final VoidCallback onRejected;
  final Function(String) onError;

  const _ProjectContractApprovalButtons({
    required this.contractId,
    required this.onApproved,
    required this.onRejected,
    required this.onError,
  });

  @override
  State<_ProjectContractApprovalButtons> createState() => _ProjectContractApprovalButtonsState();
}

class _ProjectContractApprovalButtonsState extends State<_ProjectContractApprovalButtons> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _approve() async {
    if (_isApproving || _isRejecting) return;
    setState(() => _isApproving = true);
    try {
      await ContractService.updateContractStatus(contractId: widget.contractId, status: 'approved');
      widget.onApproved();
    } catch (e) {
      widget.onError('Failed to approve contract: $e');
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _reject() async {
    if (_isApproving || _isRejecting) return;
    setState(() => _isRejecting = true);
    try {
      await ContractService.updateContractStatus(contractId: widget.contractId, status: 'rejected');
      widget.onRejected();
    } catch (e) {
      widget.onError('Failed to reject contract: $e');
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isApproving || _isRejecting ? null : _approve,
            icon: _isApproving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isApproving ? 'Approving...' : 'Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: _isApproving ? Colors.grey : Colors.green[600], foregroundColor: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isApproving || _isRejecting ? null : _reject,
            icon: _isRejecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Icon(Icons.cancel),
            label: Text(_isRejecting ? 'Rejecting...' : 'Reject'),
            style: ElevatedButton.styleFrom(backgroundColor: _isRejecting ? Colors.grey : Colors.red[600], foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
