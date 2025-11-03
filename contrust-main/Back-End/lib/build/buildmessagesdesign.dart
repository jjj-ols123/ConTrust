// ignore_for_file: deprecated_member_use, file_names, use_build_context_synchronously, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:backend/services/both%20services/be_project_service.dart';
import 'package:backend/services/both%20services/be_contract_service.dart';
import 'package:backend/services/both%20services/be_contract_pdf_service.dart';
import 'package:backend/services/contractor%20services/contract/cor_viewcontractservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_contractsignature.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:contractee/build/builddrawer.dart'
    show ContracteeShell, ContracteePage;
import 'package:contractee/pages/cee_ongoing.dart' show CeeOngoingProjectScreen;
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
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
  final bool _isProcessing = false; 

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

    if (_isLoading) {
      return Card(
        color: Colors.grey[50],
        margin: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 14 : 16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? 16 : 20,
                height: isMobile ? 16 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Loading project status...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 13 : (isTablet ? 14 : 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    String bannerText = '';
    String buttonText = '';
    VoidCallback? onPressed;
    Color bannerColor = Colors.grey[50]!;

    if (projectStatus == 'cancelled' || projectStatus == 'completed') {
      if (projectStatus == 'cancelled') {
        bannerText = "This project was cancelled. Preserved for archive.";
        buttonText = "Archived";
        bannerColor = Colors.grey[200]!;
      } else {
        bannerText = "This project has been completed. Preserved for archive.";
        buttonText = "Completed";
        bannerColor = Colors.green[100]!;
      }
      onPressed = null;
      
      return Card(
        color: bannerColor,
        margin: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 14 : 16)),
          child: Row(
            children: [
              Icon(
                projectStatus == 'cancelled' 
                    ? Icons.archive_outlined 
                    : Icons.check_circle_outline,
                color: projectStatus == 'cancelled' 
                    ? Colors.grey[700] 
                    : Colors.green[700],
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  bannerText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : (isTablet ? 14 : 16),
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (projectStatus == 'awaiting_signature') {
      // Provide more specific message depending on who has signed
      if (_contractorSigned && !_contracteeSigned) {
        bannerText = widget.userRole == 'contractor'
            ? "You've signed the contract. Waiting for the contractee to sign."
            : "Contractor has signed. Please review and sign to activate the project.";
      } else if (_contracteeSigned && !_contractorSigned) {
        bannerText = widget.userRole == 'contractee'
            ? "You've signed the contract. Waiting for the contractor to sign."
            : "Contractee has signed. Please sign to activate the project.";
      } else {
        bannerText = "Contract approved! Waiting for both parties to sign.";
      }
      buttonText = "Awaiting Signatures";
      onPressed = null;
      bannerColor = Colors.purple[50]!;
    } else if (projectStatus == 'awaiting_agreement') {
      if (widget.userRole == 'contractor') {
        bannerText = "Contract sent. Waiting for contractee approval.";
        buttonText = "Pending Approval";
        onPressed = null;
        bannerColor = Colors.white;
      } else {
        bannerText = "Contract sent. Please review and approve.";
        bannerColor = Colors.white;
      }
    } else if (projectStatus == 'awaiting_contract') {
      if (widget.userRole == 'contractor') {
        bannerText = "Please create and send a contract to the contractee.";
        buttonText = "Create Contract";
        onPressed = widget.onActiveProjectPressed;
        bannerColor = Colors.blue[50]!;
      } else {
        bannerText = "Waiting for contractor to send the contract.";
        buttonText = "Waiting...";
        onPressed = null;
        bannerColor = Colors.orange[50]!;
      }
    } else if (projectStatus == 'active') {
        bannerText = "Project is now active! Proceed to Project Management.";
        buttonText = "Go to Project Management";
        if (widget.userRole == 'contractee') {
          onPressed = () async {
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

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContracteeShell(
                    currentPage: ContracteePage.ongoing,
                    contracteeId: supabase.auth.currentUser?.id ?? '',
                    child: CeeOngoingProjectScreen(projectId: projectId),
                  ),
                ),
              );
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
        } else {
          onPressed = widget.onActiveProjectPressed;
        }
        bannerColor = Colors.green[50]!;
    }

    if (projectStatus == 'cancellation_requested_by_contractee' &&
        widget.userRole == 'contractor') {
      bannerText = "The contractee has requested to cancel this project. Please check your project dashboard to approve or reject this request.";
      buttonText = "Check Dashboard";
      onPressed = null; // Remove action buttons - handle in dashboard
      bannerColor = Colors.orange[50]!;
    } else if (projectStatus == 'cancellation_requested_by_contractee' &&
        widget.userRole == 'contractee') {
      bannerText =
          "You have requested to cancel this project. Waiting for contractor approval.";
      buttonText = "Cancellation Pending";
      onPressed = null;
      bannerColor = Colors.orange[50]!;
    }
    
    return Card(
      color: bannerColor,
      margin: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 14 : 16)),
        child: Column(
          children: [
            Text(
              bannerText,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: isMobile ? 13 : (isTablet ? 14 : 16),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 10),
            isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: onPressed != null && !_isProcessing
                                ? Colors.blue
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isProcessing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Processing...', style: const TextStyle(fontSize: 13)),
                                  ],
                                )
                              : Text(buttonText, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: onPressed != null && !_isProcessing
                                ? Colors.blue
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 20,
                              vertical: isTablet ? 10 : 12,
                            ),
                          ),
                          child: _isProcessing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: isTablet ? 14 : 16,
                                      height: isTablet ? 14 : 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 6 : 8),
                                    Text(
                                      'Processing...', 
                                      style: TextStyle(fontSize: isTablet ? 13 : 14),
                                    ),
                                  ],
                                )
                              : Text(
                            buttonText, 
                            style: TextStyle(fontSize: isTablet ? 13 : 14),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class UIMessage {
  static List<String>? _activeBlobUrls;

  static final SuperAdminAuditService _auditService = SuperAdminAuditService();
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
          ? DateTime.parse(timestamp).toLocal()
          : (timestamp as DateTime).toLocal();
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
      Map<String, dynamic> contractData =
          await ContractService.getContractById(contractId);

      if (!context.mounted) return;

      final isContractee = currentUserId != null &&
          contractData['contractee_id'] == currentUserId;


      showDialog(
          context: context,
          builder: (dialogContext) =>
              StatefulBuilder(builder: (context, setState) {
                void onRefresh() async {
                  try {
                    final updatedData = await ContractService.getContractById(contractId);
                    setState(() {
                      contractData = updatedData;
                    });
                  } catch (e) {
                    ConTrustSnackBar.error(context, 'Failed to refresh contract data'); 
                  }
                }

                return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                  width: MediaQuery.of(context).size.width * 1.2,
                  constraints: const BoxConstraints(maxWidth: 900),
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey.shade50],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StreamBuilder<Map<String, dynamic>?>(
                                stream: FetchService().streamContractById(contractId),
                                initialData: contractData,
                                builder: (context, snapshot) {
                                  final liveData = snapshot.data ?? contractData;
                                  final contractStatus = liveData['status'] as String?;
                                  final messageStatus = messageData?['status'] as String?;
                                  final displayStatus = messageStatus ?? contractStatus;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        liveData['title'] ?? 'Contract',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Status: ${_formatStatus(displayStatus)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<Map<String, dynamic>?>(
                          stream: FetchService().streamContractById(contractId),
                          initialData: contractData,
                          builder: (context, snap) {
                            final data = snap.data ?? contractData;
                            final contractStatus = data['status'] as String?;
                            final messageStatus = messageData?['status'] as String?;
                            final displayStatus = messageStatus ?? contractStatus;
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isContractee &&
                                      (displayStatus == 'sent')) ...[
                                Card(
                                  color: Colors.amber[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _ContractApprovalButtons(
                                      contractId: contractId,
                                      onApproved: () async {
                                        Navigator.of(context).pop();
                                        ConTrustSnackBar.contractApproved(
                                            context);
                                      },
                                      onRejected: () async {
                                        Navigator.of(context).pop();
                                        ConTrustSnackBar.contractRejected(
                                            context);
                                      },
                                      onError: (error) {
                                        ConTrustSnackBar.error(context, error);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Builder(
                                    builder: (context) {
                                      final screenWidth = MediaQuery.of(context).size.width;
                                      final isMobile = screenWidth < 600;
                                      
                                      if (isMobile) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await _downloadContract(data,
                                                    context, messageData);
                                              },
                                              icon: const Icon(Icons.download, size: 16),
                                              label: Text(
                                                _hasSignedPdf(data)
                                                    ? 'Download Signed Contract'
                                                    : 'Download Contract',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue[600],
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            if (isContractee) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  border: Border.all(color: Colors.grey[300]!),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _getSignatureMessage(data,
                                                      currentUserId, displayStatus),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      } else {
                                        return Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await _downloadContract(data,
                                              context, messageData);
                                        },
                                        icon: const Icon(Icons.download),
                                        label: Text(_hasSignedPdf(data)
                                            ? 'Download Signed Contract'
                                            : 'Download Contract'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[600],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      if (isContractee) ...[
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                                    border: Border.all(color: Colors.grey[300]!),
                                                    borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getSignatureMessage(data,
                                                  currentUserId, displayStatus),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<String?>(
                                future: _getPdfUrl(data, messageData),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Card(
                                      child: SizedBox(
                                        height: 400,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.amber),
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError ||
                                      snapshot.data == null ||
                                      snapshot.data!.isEmpty) {
                                    return Card(
                                      child: SizedBox(
                                        height: 400,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error_outline,
                                                  color: Colors.red, size: 48),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Failed to load PDF',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Error: ${snapshot.error ?? "No PDF URL available"}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Signed PDF available: ${_hasSignedPdf(data)}',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                              ),
                                              if (_hasSignedPdf(data))
                                                Text(
                                                  'Signed PDF path: ${data['signed_pdf_url']}',
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12),
                                                ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  await _downloadContract(
                                                      data,
                                                      context,
                                                      messageData);
                                                },
                                                icon:
                                                    const Icon(Icons.download),
                                                label: const Text(
                                                    'Download Instead'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[600],
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return ViewContractBuild.buildPdfViewer(
                                    pdfUrl: snapshot.data,
                                    onDownload: () async {
                                      await _downloadContract(
                                          data, context);
                                    },
                                    height: 500,
                                    isSignedContract:
                                        _hasSignedPdf(data),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Digital Signatures',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildSignatureDisplay(
                                              'Contractor',
                                              data[
                                                  'contractor_signature_url'],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildSignatureDisplay(
                                              'Contractee',
                                              data[
                                                  'contractee_signature_url'],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSignaturePad(
                                          data,
                                          currentUserId,
                                          context,
                                          _canUserSign(data,
                                              currentUserId, displayStatus),
                                          onRefresh),
                                    ],
                                  ),
                                ),
                              ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ));
              }));
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to show enhanced contract view: $e',
        module: 'UI Message',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Show Enhanced Contract View',
          'contract_id': contractId,
          'current_user_id': currentUserId,
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error loading contract: $e');
      }
    }
  }

  static Widget _buildSignatureDisplay(String role, String? signaturePath) {
    final bool isSigned = signaturePath != null && signaturePath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSigned ? Colors.green[50] : Colors.grey[50],
        border: Border.all(
          color: isSigned ? Colors.green[300]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSigned ? Icons.check_circle : Icons.pending,
                color: isSigned ? Colors.green[600] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      isSigned ? 'Signed' : 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSigned ? Colors.green[600] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSigned) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: signaturePath.startsWith('http')
                  ? Image.network(
                      signaturePath,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Text('Failed to load',
                                  style: TextStyle(fontSize: 10))),
                    )
                  : FutureBuilder<String?>(
                      future: ViewContractService.getSignedUrl(signaturePath),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                            ),
                          );
                        }
                        final signedUrl = snapshot.data;
                        if (signedUrl == null) {
                          return const Center(
                            child: Text('No signature',
                                style: TextStyle(fontSize: 10)),
                          );
                        }
                        return Image.network(
                          signedUrl,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Text('Failed to load',
                                      style: TextStyle(fontSize: 10))),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  static bool _canUserSign(Map<String, dynamic> contractData,
      String? currentUserId, String? displayStatus) {
    if (currentUserId == null) return false;

    final contractStatus = displayStatus ?? contractData['status'] as String?;
    final isContractee = contractData['contractee_id'] == currentUserId;
    final isContractor = contractData['contractor_id'] == currentUserId;

    if (contractStatus == 'approved' ||
        contractStatus == 'awaiting_signature') {
      if (isContractee) {
        final contracteeSigned =
            contractData['contractee_signature_url'] != null &&
                (contractData['contractee_signature_url'] as String).isNotEmpty;
        return !contracteeSigned;
      }
      if (isContractor) {
        final contractorSigned =
            contractData['contractor_signature_url'] != null &&
                (contractData['contractor_signature_url'] as String).isNotEmpty;
        return !contractorSigned;
      }
    }

    return false;
  }

  static String _getSignatureMessage(Map<String, dynamic> contractData,
      String? currentUserId, String? displayStatus) {
    if (currentUserId == null) return 'Signature pad disabled';

    final contractStatus = displayStatus ?? contractData['status'] as String?;
    final isContractee = contractData['contractee_id'] == currentUserId;
    final isContractor = contractData['contractor_id'] == currentUserId;

    if (contractStatus == 'sent' && isContractee) {
      return 'Please approve the contract first to enable signing';
    }

    if (contractStatus == 'rejected') {
      return 'Contract has been rejected';
    }

    if (isContractee) {
      final contracteeSigned =
          contractData['contractee_signature_url'] != null &&
              (contractData['contractee_signature_url'] as String).isNotEmpty;
      if (contracteeSigned) {
        return 'You have already signed this contract';
      }
    }

    if (isContractor) {
      final contractorSigned =
          contractData['contractor_signature_url'] != null &&
              (contractData['contractor_signature_url'] as String).isNotEmpty;
      if (contractorSigned) {
        return 'You have already signed this contract';
      }
    }

    return 'Signature pad will be enabled when contract is approved';
  }

  static String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
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
      default:
        return status;
    }
  }

  static bool _hasSignedPdf(Map<String, dynamic> contractData) {
    final signedPdfUrl = contractData['signed_pdf_url'] as String?;
    return signedPdfUrl != null && signedPdfUrl.isNotEmpty;
  }

  static Future<String?> _getPdfUrl(Map<String, dynamic> contractData,
      [Map<String, dynamic>? messageData]) async {
    if (messageData != null) {
      final messagePdfUrl = messageData['pdf_url'] as String?;
      if (messagePdfUrl != null && messagePdfUrl.isNotEmpty) {
        if (messagePdfUrl.startsWith('http')) {
          return messagePdfUrl;
        }
        return await ViewContractService.getSignedContractUrl(messagePdfUrl);
      }
    }
    return await ViewContractService.getPdfSignedUrl(contractData);
  }

  static Future<void> _downloadContract(
      Map<String, dynamic> contractData, BuildContext context,
      [Map<String, dynamic>? messageData]) async {
    try {
      if (messageData != null) {
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

      if (_hasSignedPdf(contractData)) {
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

  static Widget _buildSignaturePad(
      Map<String, dynamic> contractData,
      String? currentUserId,
      BuildContext context,
      bool enabled,
      VoidCallback onRefresh) {
    final signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.blue[50] : Colors.grey[50],
        border:
            Border.all(color: enabled ? Colors.blue[300]! : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Digital Signature',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
              color: enabled ? Colors.black : Colors.grey[600],
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Container(
            width: double.infinity,
            height: isMobile ? 120 : 150,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[100],
              border: Border.all(
                  color: enabled ? Colors.grey[300]! : Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: enabled
                ? Signature(
                    controller: signatureController,
                    backgroundColor: Colors.white,
                  )
                : Container(
                    color: Colors.grey[100],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            enabled
                ? (isMobile 
                    ? 'Draw or upload your signature' 
                    : 'Draw your signature above using your mouse, stylus, or finger, or upload an image')
                : 'Signature pad is currently disabled',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          if (isMobile)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () {
                            signatureController.clear();
                          }
                        : null,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Signature'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? Colors.grey[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () async {
                            final signatureBytes = await _pickSignatureImage(context);
                            if (signatureBytes != null) {
                              _showSignatureDialog(context, contractData,
                                  currentUserId, signatureBytes, onRefresh);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? Colors.orange[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () async {
                            final signature =
                                await signatureController.toPngBytes();
                            if (signature == null || signature.isEmpty) {
                              ConTrustSnackBar.error(
                                  context, 'Please provide a signature');
                              return;
                            }
                            _showSignatureDialog(context, contractData,
                                currentUserId, signature, onRefresh);
                          }
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Sign Contract'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? Colors.green[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () {
                            signatureController.clear();
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? Colors.grey[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () async {
                            final signatureBytes = await _pickSignatureImage(context);
                            if (signatureBytes != null) {
                              _showSignatureDialog(context, contractData,
                                  currentUserId, signatureBytes, onRefresh);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? Colors.orange[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () async {
                            final signature =
                                await signatureController.toPngBytes();
                            if (signature == null || signature.isEmpty) {
                              ConTrustSnackBar.error(
                                  context, 'Please provide a signature');
                              return;
                            }
                            _showSignatureDialog(context, contractData,
                                currentUserId, signature, onRefresh);
                          }
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Sign Contract'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? Colors.green[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Future<Uint8List?> _pickSignatureImage(BuildContext context) async {
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      await input.onChange.first;
      
      if (input.files == null || input.files!.isEmpty) {
        return null; 
      }
      
      final file = input.files!.first;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      final result = reader.result;
      if (result is Uint8List) {
        return result;
      } else if (result is ByteBuffer) {
        return Uint8List.view(result);
      } else {
        throw Exception('Unexpected file reader result type: ${result.runtimeType}');
      }
    } catch (e) {
      ConTrustSnackBar.error(
          context, 'Failed to pick signature image $e');
      
      _errorService.logError(
        errorMessage: 'Failed to pick signature image: $e',
        module: 'UI Message',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Pick Signature Image',
        },
      );

      return null;
    }
  }

  static void _showSignatureDialog(
    BuildContext context,
    Map<String, dynamic> contractData,
    String? currentUserId,
    Uint8List signatureBytes,
    VoidCallback onRefresh) {
  if (currentUserId == null) return;

  final contractId = contractData['contract_id'] as String;
  final isContractee = contractData['contractee_id'] == currentUserId;
  final isContractor = contractData['contractor_id'] == currentUserId;

  if (!isContractee && !isContractor) {
    ConTrustSnackBar.error(
        context, 'You are not authorized to sign this contract');
    return;
  }

  bool isUploading = false;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => Dialog(
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
                        Icons.draw,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Confirm Signature',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isUploading ? null : () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      'You are signing this contract. This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isUploading ? null : () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUploading ? null : () async {
                              setState(() {
                                isUploading = true;
                              });

                              try {
                                final userType = isContractee ? 'contractee' : 'contractor';

                                await SignatureCompletionHandler
                                    .signContractWithPdfGeneration(
                                  contractId: contractId,
                                  userId: currentUserId,
                                  signatureBytes: signatureBytes,
                                  userType: userType,
                                );

                                await _auditService.logAuditEvent(
                                  userId: currentUserId,
                                  action: 'CONTRACT_SIGNED',
                                  details: '$userType signed the contract',
                                  category: 'Contract',
                                  metadata: {
                                    'contract_id': contractId,
                                    'user_type': userType,
                                  },
                                );

                                Navigator.of(dialogContext).pop();
                                
                                final updatedContract = await Supabase.instance.client
                                    .from('Contracts')
                                    .select('contractor_signature_url, contractee_signature_url')
                                    .eq('contract_id', contractId)
                                    .single();

                                final bothSigned = 
                                    (updatedContract['contractor_signature_url'] as String?)?.isNotEmpty == true &&
                                    (updatedContract['contractee_signature_url'] as String?)?.isNotEmpty == true;

                                onRefresh();
                                ConTrustSnackBar.contractSigned(context);
                                
                                if (bothSigned) {
                                  await Future.delayed(const Duration(milliseconds: 1500));
                                  onRefresh();
                                  
                                  await Future.delayed(const Duration(milliseconds: 1500));
                                  onRefresh();
                                }
                                
                              } catch (e) {
                                await _errorService.logError(
                                  errorMessage: 'Failed to sign contract: $e',
                                  module: 'UI Message',
                                  severity: 'High',
                                  extraInfo: {
                                    'operation': 'Sign Contract',
                                    'contract_id': contractId,
                                    'user_type': isContractee ? 'contractee' : 'contractor',
                                  },
                                );
                                ConTrustSnackBar.error(context, '$e');
                                
                                setState(() {
                                  isUploading = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUploading ? Colors.grey : Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isUploading 
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Uploading...'),
                                  ],
                                )
                              : const Text('Confirm & Sign'),
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
    ),
  );
}
}

class _ContractApprovalButtons extends StatefulWidget {
  final String contractId;
  final VoidCallback onApproved;
  final VoidCallback onRejected;
  final Function(String) onError;

  const _ContractApprovalButtons({
    required this.contractId,
    required this.onApproved,
    required this.onRejected,
    required this.onError,
  });

  @override
  State<_ContractApprovalButtons> createState() =>
      _ContractApprovalButtonsState();
}

class _ContractApprovalButtonsState extends State<_ContractApprovalButtons> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _approveContract() async {
    if (_isApproving || _isRejecting) return;

    setState(() => _isApproving = true);
    try {
      await ContractService.updateContractStatus(
          contractId: widget.contractId, status: 'approved');

      await UIMessage._auditService.logAuditEvent(
        action: 'CONTRACT_APPROVED',
        details: 'Contract approved by contractee',
        category: 'Contract',
        metadata: {
          'contract_id': widget.contractId,
        },
      );

      widget.onApproved();
    } catch (e) {
      await UIMessage._errorService.logError(
        errorMessage: 'Failed to approve contract: $e',
        module: 'Contract Approval Buttons',
        severity: 'High',
        extraInfo: {
          'operation': 'Approve Contract',
          'contract_id': widget.contractId,
        },
      );
      widget.onError('Failed to approve contract: $e');
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _rejectContract() async {
    if (_isApproving || _isRejecting) return;

    setState(() => _isRejecting = true);
    try {
      await ContractService.updateContractStatus(
          contractId: widget.contractId, status: 'rejected');

      await UIMessage._auditService.logAuditEvent(
        action: 'CONTRACT_REJECTED',
        details: 'Contract rejected by contractee',
        category: 'Contract',
        metadata: {
          'contract_id': widget.contractId,
        },
      );

      widget.onRejected();
    } catch (e) {
      await UIMessage._errorService.logError(
        errorMessage: 'Failed to reject contract: $e',
        module: 'Contract Approval Buttons',
        severity: 'High',
        extraInfo: {
          'operation': 'Reject Contract',
          'contract_id': widget.contractId,
        },
      );
      widget.onError('Failed to reject contract: $e');
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isApproving || _isRejecting ? null : _approveContract,
                icon: _isApproving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isApproving ? 'Approving...' : 'Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isApproving ? Colors.grey : Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isApproving || _isRejecting ? null : _rejectContract,
                icon: _isRejecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.cancel),
                label: Text(_isRejecting ? 'Rejecting...' : 'Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRejecting ? Colors.grey : Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}