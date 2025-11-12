// ignore_for_file: deprecated_member_use, file_names, use_build_context_synchronously, avoid_web_libraries_in_flutter

import 'dart:async';
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:backend/services/both%20services/be_project_service.dart';
import 'package:backend/services/both%20services/be_contract_service.dart';
import 'package:backend/services/both%20services/be_contract_pdf_service.dart';
import 'package:backend/services/contractor%20services/contract/cor_viewcontractservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractAgreementBanner extends StatefulWidget {
  final String chatRoomId;
  final String userRole;
  final VoidCallback? onActiveProjectPressed;

  const ContractAgreementBanner({
    super.key,
    required this.chatRoomId,
    required this.userRole,
    this.onActiveProjectPressed,
  });

  @override
  State<ContractAgreementBanner> createState() =>
      _ContractAgreementBannerState();
}

class _ContractAgreementBannerState extends State<ContractAgreementBanner> {
  final supabase = Supabase.instance.client;
  bool dialogShown = false;
  bool contractSent = false;
  String? projectStatus;
  bool _isLoading = true;

  bool _contractorSigned = false;
  bool _contracteeSigned = false;

  late final StreamSubscription _projectSubscription;
  late final StreamSubscription _messagesSubscription;
  StreamSubscription? _contractsSubscription;

  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  @override
  void initState() {
    super.initState();
    checkProject();
  }

  void checkProject() async {
    try {
      final projectId = await ProjectService().getProjectId(widget.chatRoomId);
      if (projectId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _projectSubscription = supabase
          .from('Projects')
          .stream(primaryKey: ['project_id'])
          .eq('project_id', projectId)
          .listen((event) {
            if (event.isNotEmpty) {
              final project = event.first;
              final status = project['status'] as String?;

              setState(() {
                projectStatus = status;
                _isLoading = false;
              });
            }
          });

      _messagesSubscription = supabase
          .from('Messages')
          .stream(primaryKey: ['msg_id'])
          .order('timestamp', ascending: false)
          .listen((messages) {
            final contractMessages = messages
                .where((msg) =>
                    msg['chatroom_id'] == widget.chatRoomId &&
                    msg['message_type'] == 'contract')
                .toList();

            if (contractMessages.isNotEmpty) {
              final latestContractMessage = contractMessages.first;
              final contractStatus = latestContractMessage['status'] as String?;

              setState(() {
                contractSent = contractStatus == 'sent' ||
                    contractStatus == 'approved' ||
                    contractStatus == 'rejected';
              });
            } else {
              setState(() {
                contractSent = false;
              });
            }
          });

      // Subscribe to Contracts for signature updates
      _contractsSubscription?.cancel();
      _contractsSubscription = supabase
          .from('Contracts')
          .stream(primaryKey: ['contract_id'])
          .eq('project_id', projectId)
          .listen((contracts) {
        if (contracts.isNotEmpty) {
          // Consider the most recent contract row
          final latest = contracts.first;
          final contractorUrl = latest['contractor_signature_url'] as String?;
          final contracteeUrl = latest['contractee_signature_url'] as String?;
          final contractorSigned = (contractorUrl != null && contractorUrl.isNotEmpty);
          final contracteeSigned = (contracteeUrl != null && contracteeUrl.isNotEmpty);
          if (mounted) {
            setState(() {
              _contractorSigned = contractorSigned;
              _contracteeSigned = contracteeSigned;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _contractorSigned = false;
              _contracteeSigned = false;
            });
          }
        }
      });
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check project: $e',
        module: 'Contract Agreement Banner',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Check Project',
          'chat_room_id': widget.chatRoomId,
          'user_role': widget.userRole,
        },
      );
    }
  }

  @override
  void dispose() {
    _projectSubscription.cancel();
    _messagesSubscription.cancel();
    _contractsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1000;

    final isCancelled = projectStatus == 'cancelled';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isCancelled ? Colors.grey.shade100 : Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(color: isCancelled ? Colors.grey.shade300 : Colors.amber.shade200, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : (isTablet ? 20 : 24), vertical: 12),
      child: _isLoading ? _buildLoadingState(isMobile, isTablet) : _buildTimelineBanner(isMobile, isTablet),
    );
  }

  Widget _buildLoadingState(bool isMobile, bool isTablet) {
    return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
          width: isMobile ? 14 : 16,
          height: isMobile ? 14 : 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
        SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Loading project status...',
                style: TextStyle(
                  color: Colors.grey[600],
            fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
    );
  }

  Widget _buildTimelineBanner(bool isMobile, bool isTablet) {
    // Define timeline steps
    final steps = [
      {'status': 'awaiting_contract', 'percentage': 25, 'label': 'Create', 'icon': Icons.edit_note},
      {'status': 'awaiting_agreement', 'percentage': 50, 'label': 'Review', 'icon': Icons.visibility},
      {'status': 'awaiting_signature', 'percentage': 75, 'label': 'Sign', 'icon': Icons.draw},
      {'status': 'active', 'percentage': 100, 'label': 'Active', 'icon': Icons.rocket_launch},
    ];

    // Determine current step and progress
    int currentStepIndex = 0;
    int progressPercentage = 0;
    String statusText = '';
    String actionText = '';
    VoidCallback? actionCallback;
    Color primaryColor = Colors.grey;
    Color secondaryColor = Colors.grey.shade300;

      if (projectStatus == 'cancelled') {
      currentStepIndex = -1; 
      progressPercentage = 0;
      statusText = 'Project Cancelled';
      primaryColor = Colors.red.shade600;
      secondaryColor = Colors.grey.shade300;
    } else if (projectStatus == 'completed') {
      currentStepIndex = 3;
      progressPercentage = 100;
      statusText = 'Project Completed';
      primaryColor = Colors.amber.shade600;
      secondaryColor = Colors.grey.shade300;
    } else if (projectStatus == 'active') {
      // Active projects don't show progress bar/percentage (similar to cancelled)
      currentStepIndex = -1;
      progressPercentage = 0;
      statusText = 'Project is Active!';
      actionText = widget.userRole == 'contractor'
          ? 'Go to Project Management'
          : 'Go to Project Management';
      primaryColor = Colors.green.shade600; // Green for active projects
      secondaryColor = Colors.grey.shade300;
      actionCallback = widget.userRole == 'contractor'
          ? () async {
              try {
                final projectId = await ProjectService().getProjectId(widget.chatRoomId);
                if (projectId == null) {
                  if (mounted) {
                    ConTrustSnackBar.error(context, 'Project not found');
                  }
                  return;
      }

                if (!mounted) return;
                context.go('/project-management/$projectId');
              } catch (e) {
                await _errorService.logError(
                  errorMessage: 'Failed to navigate to project management: $e',
                  module: 'Contract Agreement Banner',
                  severity: 'Medium',
                  extraInfo: {
                    'operation': 'Go to Project Management',
                    'chat_room_id': widget.chatRoomId,
                    'user_role': widget.userRole,
                  },
                );
                if (mounted) {
                  ConTrustSnackBar.error(context, 'Error navigating to project management');
                }
              }
            }
          : () async {
            try {
              final projects = await FetchService().fetchUserProjects();
              final activeProjects =
                  projects.where((p) => p['status'] == 'active').toList();
              if (activeProjects.isEmpty) {
                if (mounted) {
                  ConTrustSnackBar.error(context, 'No active project found');
                }
                return;
              }

              if (!mounted) return;

              String projectId;
              if (activeProjects.length > 1) {
                projectId = await showDialog<String>(
                      context: context,
                      builder: (ctx) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                        Icons.apartment,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Select Active Project',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Navigator.of(ctx).pop(''),
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
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: activeProjects.length,
                                    itemBuilder: (context, index) {
                                      final p = activeProjects[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(
                                            p['title'] ?? 'Untitled Project',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(p['location'] ?? 'No location'),
                                          trailing: Icon(Icons.chevron_right, color: Colors.amber.shade700),
                                          onTap: () => Navigator.of(ctx).pop(p['project_id'] as String),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ) ??
                    '';
                if (projectId.isEmpty) return;
              } else {
                projectId = activeProjects.first['project_id'];
              }

              if (!mounted) return;
              context.go('/ongoing/$projectId');
            } catch (e) {
              await _errorService.logError(
                errorMessage: 'Failed to navigate to ongoing project: $e',
                module: 'Contract Agreement Banner',
                severity: 'Medium',
                extraInfo: {
                  'operation': 'Go to Project Management',
                  'chat_room_id': widget.chatRoomId,
                  'user_role': widget.userRole,
                },
              );
              if (mounted) {
                ConTrustSnackBar.error(
                    context, 'Error loading ongoing project');
              }
            }
          };
    } else if (projectStatus == 'awaiting_signature') {
      currentStepIndex = 2;
      progressPercentage = 75;
      if (_contractorSigned && !_contracteeSigned) {
        statusText = widget.userRole == 'contractor'
            ? "You've signed. Waiting for contractee."
            : "Contractor signed. Please review and sign.";
      } else if (_contracteeSigned && !_contractorSigned) {
        statusText = widget.userRole == 'contractee'
            ? "You've signed. Waiting for contractor."
            : "Contractee signed. Please sign to activate.";
        } else {
        statusText = "Waiting for both parties to sign.";
      }
      primaryColor = Colors.amber.shade600;
      secondaryColor = Colors.grey.shade300;
    } else if (projectStatus == 'awaiting_agreement') {
      currentStepIndex = 1;
      progressPercentage = 50;
      if (widget.userRole == 'contractor') {
        statusText = "Contract sent. Waiting for approval.";
        primaryColor = Colors.amber.shade600;
        secondaryColor = Colors.grey.shade300;
      } else {
        statusText = "Contract sent. Please review and approve.";
        actionText = "Review Contract";
        primaryColor = Colors.amber.shade600;
        secondaryColor = Colors.grey.shade300;
      }
    } else if (projectStatus == 'awaiting_contract') {
      currentStepIndex = 0;
      progressPercentage = 25;
      if (widget.userRole == 'contractor') {
        statusText = "Please create and send a contract.";
        actionText = "Create Contract";
        primaryColor = Colors.amber.shade600;
        secondaryColor = Colors.grey.shade300;
        actionCallback = widget.onActiveProjectPressed;
      } else {
        statusText = "Waiting for contractor to send contract.";
        primaryColor = Colors.amber.shade600;
        secondaryColor = Colors.grey.shade300;
    }
    } else if (projectStatus == 'cancellation_requested_by_contractee' &&
        widget.userRole == 'contractor') {
      currentStepIndex = 2;
      progressPercentage = 75;
      statusText = "Contractee requested cancellation. Check dashboard.";
      actionText = "Check Dashboard";
      primaryColor = Colors.amber.shade600;
      secondaryColor = Colors.grey.shade300;
    } else if (projectStatus == 'cancellation_requested_by_contractee' &&
        widget.userRole == 'contractee') {
      currentStepIndex = 2;
      progressPercentage = 75;
      statusText = "You requested cancellation. Waiting for approval.";
      actionText = "Cancellation Pending";
      primaryColor = Colors.amber.shade600;
      secondaryColor = Colors.grey.shade300;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Status text
        if (statusText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            Text(
                  statusText,
              style: TextStyle(
                    fontWeight: projectStatus == 'cancelled' ? FontWeight.bold : FontWeight.w600,
                    fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                    color: projectStatus == 'cancelled' ? Colors.grey.shade700 : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
                if (projectStatus == 'cancelled')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Archiving chat history.',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                          ),
              ],
            ),
          ),

        // Timeline progress bar - only show if not cancelled
        if (currentStepIndex != -1)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = index < currentStepIndex;
                final isCurrent = index == currentStepIndex;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < steps.length - 1 ? 4 : 0),
                    child: Column(
                    children: [
                        // Progress bar segment
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? primaryColor
                                : isCurrent
                                    ? primaryColor.withOpacity(0.7)
                                    : secondaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Step indicator
                        Container(
                          width: isMobile ? 32 : 36,
                          height: isMobile ? 32 : 36,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? primaryColor
                                : isCurrent
                                    ? primaryColor.withOpacity(0.8)
                                    : Colors.white,
                            border: Border.all(
                              color: isCompleted || isCurrent ? primaryColor : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: isCompleted || isCurrent ? Colors.white : Colors.grey.shade400,
                            size: isMobile ? 16 : 18,
                                      ),
                                    ),
                        const SizedBox(height: 4),
                        // Step label
                                    Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: isCompleted || isCurrent ? primaryColor : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Progress percentage centered - only show if not cancelled
        if (currentStepIndex != -1)
          Center(
            child: Text(
              '$progressPercentage% Complete',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
                                    ),
          ),
        // Action button below (if exists)
        if (actionText.isNotEmpty && actionCallback != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: ElevatedButton(
                onPressed: actionCallback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 8 : 10,
                  ),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                          ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                      ),
                ),
                child: Text(actionText),
              ),
        ),
      ),
      ],
    );
  }
}

class UIMessage {
  static List<String>? _activeBlobUrls;
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  static void cleanupBlobUrls() {
    if (_activeBlobUrls != null) {
      for (final url in _activeBlobUrls!) {
        if (kIsWeb) {
          html.Url.revokeObjectUrl(url);
        }
      }
      _activeBlobUrls!.clear();
    }
  }

  static Widget buildContractMessage(
    BuildContext context,
    Map<String, dynamic> msg,
    bool isMe,
    String currentUserId,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1000;
    
    if (msg['message_type'] == 'contract') {
      return Container(
        margin: EdgeInsets.only(
          top: isMobile ? 8 : (isTablet ? 10 : 12),
          bottom: isMobile ? 8 : (isTablet ? 10 : 12),
          left: isMe ? (isMobile ? 40 : (isTablet ? 50 : 60)) : (isMobile ? 8 : 12),
          right: isMe ? (isMobile ? 8 : 12) : (isMobile ? 40 : (isTablet ? 50 : 60)),
        ),
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 15 : 18)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.blue[300]!, width: isMobile ? 1.5 : 2),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: isMobile ? 6 : 8,
              offset: Offset(0, isMobile ? 3 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description, 
                  color: Colors.blue[700],
                  size: isMobile ? 20 : (isTablet ? 22 : 24),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Expanded(
                  child: Text(
                    'Contract Sent',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (msg['timestamp'] != null && (!isMobile || screenWidth > 350))
                  Text(
                    _formatTime(msg['timestamp']),
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12, 
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              msg['message'] ?? '', 
              style: TextStyle(fontSize: isMobile ? 13 : (isTablet ? 14 : 15)),
            ),
            SizedBox(height: isMobile ? 10 : (isTablet ? 12 : 14)),
            Align(
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEnhancedContractView(
                      context, msg['contract_id'], currentUserId, msg);
                },
                icon: Icon(Icons.visibility, size: isMobile ? 16 : 18),
                label: Text(
                  isMobile ? 'View' : 'View Contract',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : (isTablet ? 14 : 16),
                    vertical: isMobile ? 8 : (isTablet ? 10 : 12),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return buildNormalMessageBubble(msg, isMe, context: context);
  }

  static Widget buildNormalMessageBubble(Map<String, dynamic> msg, bool isMe, {BuildContext? context}) {
    final screenWidth = context != null ? MediaQuery.of(context).size.width : 800;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1000;
    
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe && (!isMobile || screenWidth > 350)) ...[
          CircleAvatar(
            radius: isMobile ? 14 : (isTablet ? 16 : 18),
            backgroundColor: Colors.amber[100],
            child: Icon(
              Icons.person, 
              color: Colors.amber,
              size: isMobile ? 16 : (isTablet ? 18 : 20),
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
        ],
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              top: isMobile ? 4 : 6,
              bottom: isMobile ? 4 : 6,
              left: isMe ? (isMobile ? 20 : (isTablet ? 30 : 40)) : 0,
              right: isMe ? 0 : (isMobile ? 20 : (isTablet ? 30 : 40)),
            ),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 10 : 12,
              horizontal: isMobile ? 14 : (isTablet ? 16 : 18),
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                      colors: [Colors.amber[300]!, Colors.amber[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.white, Colors.grey[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMobile ? 12 : 16),
                topRight: Radius.circular(isMobile ? 12 : 16),
                bottomLeft: Radius.circular(isMe ? (isMobile ? 12 : 16) : (isMobile ? 2 : 4)),
                bottomRight: Radius.circular(isMe ? (isMobile ? 2 : 4) : (isMobile ? 12 : 16)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.10),
                  blurRadius: isMobile ? 4 : 6,
                  offset: Offset(0, isMobile ? 1 : 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg['message'] ?? '',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                    color: isMe ? Colors.black : Colors.grey[900],
                  ),
                ),
                if (msg['timestamp'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: isMobile ? 3 : 4),
                    child: Text(
                      _formatTime(msg['timestamp']),
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11, 
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isMe && (!isMobile || screenWidth > 350)) ...[
          SizedBox(width: isMobile ? 6 : 8),
          CircleAvatar(
            radius: isMobile ? 14 : (isTablet ? 16 : 18),
            backgroundColor: Colors.amber[300],
            child: Icon(
              Icons.person, 
              color: Colors.white,
              size: isMobile ? 16 : (isTablet ? 18 : 20),
            ),
          ),
        ],
      ],
    );
  }

  static String _formatTime(dynamic timestamp) {
    try {
      final date = timestamp is String
          ? DateTime.parse(timestamp)
          : (timestamp as DateTime);
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    } catch (e) {
      return '';
    }
  }

  static Future<void> _showEnhancedContractView(
      BuildContext context, String contractId, String? currentUserId,
      [Map<String, dynamic>? messageData]) async {
    try {
      final freshContractData = await ContractService.getContractById(contractId);

      if (!context.mounted) return;

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
                                  if ((liveData['status'] as String?)?.toLowerCase() == 'sent' &&
                                      currentUserId != null &&
                                      liveData['contractee_id'] == currentUserId) ...[
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

                                      return ViewContractBuild.buildPdfViewer(
                                        pdfUrl: snapshot.data,
                                        onDownload: () => _downloadContract(liveData, context),
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
                                    currentUserId: currentUserId,
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

  static bool _hasSignedPdf(Map<String, dynamic> contractData, [Map<String, dynamic>? messageData]) {
    // Check message's signed_pdf_url first (for approved messages)
    if (messageData != null) {
      final messageSignedPdfUrl = messageData['signed_pdf_url'] as String?;
      if (messageSignedPdfUrl != null && messageSignedPdfUrl.isNotEmpty) {
        return true;
      }
    }
    // Fall back to contract's signed_pdf_url
    final signedPdfUrl = contractData['signed_pdf_url'] as String?;
    return signedPdfUrl != null && signedPdfUrl.isNotEmpty;
  }

  static Future<void> _downloadContract(
      Map<String, dynamic> contractData, BuildContext context,
      [Map<String, dynamic>? messageData]) async {
    try {
      if (messageData != null) {
        final messageSignedPdfUrl = messageData['signed_pdf_url'] as String?;
        if (messageSignedPdfUrl != null && messageSignedPdfUrl.isNotEmpty) {
          try {
            final pdfBytes = await Supabase.instance.client.storage
                .from('contracts')
                .download(messageSignedPdfUrl);
            
            final fileName =
                'Signed_Contract_${contractData['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
            await ContractPdfService.saveToDevice(
                Uint8List.fromList(pdfBytes), fileName);
            
            if (context.mounted) {
              ConTrustSnackBar.downloadSuccess(
                  context, 'Signed contract downloaded successfully');
            }
            return;
          } catch (e) {
            //
          }
        }
        
        final messagePdfUrl = messageData['pdf_url'] as String?;
        if (messagePdfUrl != null && messagePdfUrl.isNotEmpty) {
          Uint8List pdfBytes;
          if (messagePdfUrl.startsWith('http')) {
            await ViewContractService.handleDownload(
              contractData: contractData,
              context: context,
            );
            return;
          } else {
            pdfBytes = await Supabase.instance.client.storage
                .from('contracts')
                .download(messagePdfUrl);
          }

          final fileName =
              'Contract_${contractData['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
          await ContractPdfService.saveToDevice(pdfBytes, fileName);

          if (context.mounted) {
            ConTrustSnackBar.downloadSuccess(
                context, 'Contract downloaded successfully');
          }
          return;
        }
      }

      // Priority 3: Fall back to contract's signed PDF or regular PDF
      if (_hasSignedPdf(contractData, messageData)) {
        final signedPdfUrl = contractData['signed_pdf_url'] as String?;
        final pdfBytes = await Supabase.instance.client.storage
            .from('contracts')
            .download(signedPdfUrl!);

        final fileName =
            'Signed_Contract_${contractData['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
        await ContractPdfService.saveToDevice(
            Uint8List.fromList(pdfBytes), fileName);

        if (context.mounted) {
          ConTrustSnackBar.downloadSuccess(
              context, 'Signed contract downloaded successfully');
        }
      } else {
        await ViewContractService.handleDownload(
          contractData: contractData,
          context: context,
        );
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download contract: $e',
        module: 'UI Message',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Contract',
          'contract_id': contractData['contract_id'],
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Download failed');
      }
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