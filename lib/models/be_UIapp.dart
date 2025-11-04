// ignore_for_file: deprecated_member_use, use_super_parameters, file_names
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';
import 'package:intl/intl.dart';

class ContractorsView extends StatelessWidget {
  final String id;
  final String name;
  final String profileImage;
  final double rating;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  const ContractorsView({
    Key? key,
    required this.id,
    required this.name,
    required this.profileImage,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 180,
      height: 250,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.amber.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                (profileImage.isNotEmpty) ? profileImage : profileUrl,
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    profileUrl,
                    height: 160,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      if (index < rating.floor()) {
                        return Icon(Icons.star, color: Colors.amber, size: 20);
                      } else if (index < rating.ceil() && rating % 1 != 0) {
                        return Icon(Icons.star_half, color: Colors.amber, size: 20);
                      } else {
                        return Icon(Icons.star_border, color: Colors.grey, size: 20);
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                 ElevatedButton(
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
                      minimumSize: const Size.fromHeight(36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text("View"),
                  ),
                ],
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
    final isHiringRequest = duration == 0;
    final status = ProjectStatus();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: isHiringRequest ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
                  _buildProjectDetails(isHiringRequest),
                  
                  const SizedBox(height: 16),

                  _buildDescription(),
                  
                  const SizedBox(height: 16),

                  if (!isHiringRequest && project['status'] == 'pending')
                    _buildBiddingInfo(),
                  
                  if (isHiringRequest)
                    _buildHiringInfo(),
                ],
              ),
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
  }

  Widget _buildHeader(BuildContext context, ProjectStatus status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          ),
        ),
        Row(
          children: [
            _buildContractButton(context),
            const SizedBox(width: 8),
            if (onUpdateProject != null || onCancelProject != null)
              _buildActionMenu(context),
          ],
        ),
      ],
    );
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

  Widget _buildContractButton(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FetchService().streamContractsForProject(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

  final contracts = snapshot.data!;
  final latestContract = contracts.first;
        final status = latestContract['status'] as String? ?? 'draft';
        
        Color borderColor;
        Color backgroundColor;
        Color textColor;
        IconData icon;
        String statusText;

        switch (status.toLowerCase()) {
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectDetails(bool isHiringRequest) {
    final details = [
      _buildDetailItem(
        icon: Icons.attach_money,
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

  Widget _buildDetailItem({
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

  Widget _buildHiringInfo() {

  if (project['status'] != 'pending') {
    return const SizedBox.shrink();
  }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FetchService().fetchHiringRequestsForProject(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator.adaptive();
        }

        final requests = snapshot.data!;
        final accepted = requests.firstWhere(
          (r) => r['information']?['status'] == 'accepted',
          orElse: () => {},
        );

        if (accepted.isNotEmpty) {
          return _buildContractorCard(
            icon: Icons.verified,
            color: Colors.green,
            title: 'Accepted Contractor',
            subtitle: accepted['information']?['firm_name'] ?? 'Unknown',
          );
        }

        final pendingRequests = requests.where(
          (r) => r['information']?['status'] == 'pending'
        ).toList();

        if (pendingRequests.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hiring Requests Sent:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...pendingRequests.map((request) => _buildContractorCard(
                icon: Icons.pending,
                color: Colors.orange,
                title: request['information']?['firm_name'] ?? 'Unknown',
                subtitle: 'Pending Response',
              )),
            ],
          );
        }

        return _buildContractorCard(
          icon: Icons.info,
          color: Colors.grey,
          title: 'No hiring requests sent',
          subtitle: 'Send requests to contractors',
        );
      },
    );
  }

  Widget _buildContractorCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
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
                  // Header
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
                            contractData['title'] ?? 'Contract Details',
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
                      stream: FetchService().streamContractById(contractData['contract_id'] as String),
                      initialData: contractData,
                      builder: (context, contractSnap) {
                        final liveData = contractSnap.data ?? contractData;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusBadge(liveData['status'] as String? ?? 'draft'),
                              const SizedBox(height: 20),
 
                              _buildContractInfo(liveData),
                              const SizedBox(height: 20),

                              if ((liveData['status'] as String?)?.toLowerCase() == 'sent') ...[
                                Card(
                                  color: Colors.amber[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _ProjectContractApprovalButtons(
                                      contractId: liveData['contract_id'] as String,
                                      onApproved: () {
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('Contract approved')),
                                        );
                                      },
                                      onRejected: () {
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          const SnackBar(content: Text('Contract rejected')),
                                        );
                                      },
                                      onError: (err) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(content: Text(err)),
                                        );
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
                                onRefresh: () => Navigator.of(dialogContext).pop(),
                              ),
                            ],
                          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contract: $e')),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData icon;
    String displayText;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'signed':
        badgeColor = Colors.green;
        icon = Icons.verified;
        displayText = 'Approved';
        break;
      case 'sent':
      case 'awaiting_signature':
        badgeColor = Colors.orange;
        icon = Icons.pending;
        displayText = 'Pending Review';
        break;
      case 'rejected':
        badgeColor = Colors.red;
        icon = Icons.cancel;
        displayText = 'Rejected';
        break;
      default:
        badgeColor = Colors.blue;
        icon = Icons.description;
        displayText = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: badgeColor),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfo(Map<String, dynamic> contractData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contract Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          if (contractData['created_at'] != null)
            _buildInfoRow(
              'Created',
              DateFormat('MMM dd, yyyy').format(
                DateTime.parse(contractData['created_at']),
              ),
            ),
          if (contractData['updated_at'] != null)
            _buildInfoRow(
              'Last Updated',
              DateFormat('MMM dd, yyyy').format(
                DateTime.parse(contractData['updated_at']),
              ),
            ),
          _buildInfoRow('Status', _formatContractStatus(contractData['status'] as String? ?? 'draft')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatContractStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'awaiting_signature':
        return 'Awaiting Signature';
      case 'active':
        return 'Active';
      case 'signed':
        return 'Signed';
      default:
        return status.capitalize();
    }
  }

  Future<void> _downloadContract(Map<String, dynamic> contractData) async {
    try {
      final pdfUrl = await ViewContractService.getPdfSignedUrl(contractData);
      if (pdfUrl != null) {
        // Implementation depends on platform
        // For web, you can use html.window.open(pdfUrl, '_blank');
      }
    } catch (e) {
      // Handle error
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
