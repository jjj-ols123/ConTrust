// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/verify_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildVerifyMethods {
  static Widget buildVerifyStatisticsCard(BuildContext context, int totalUnverified, VoidCallback? onRefresh) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.verified_user_outlined, color: Colors.grey.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Pending Verifications',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Text(
                '$totalUnverified',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (onRefresh != null)
              IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh_outlined, color: Colors.grey.shade600),
                tooltip: 'Refresh',
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildUnverifiedContractorsList({
    required List<Map<String, dynamic>> contractors,
    required Function(String) onContractorTap,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading contractors...', style: TextStyle(color: Colors.black)),
          ],
        ),
      );
    }

    if (contractors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No contractors up for verification.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contractors.length,
      itemBuilder: (context, index) {
        final contractor = contractors[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business, color: Colors.grey.shade700),
            ),
            title: Text(
              contractor['firm_name'] ?? 'Unknown Firm',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      contractor['contact_number'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(contractor['created_at']),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
            onTap: () => onContractorTap(contractor['contractor_id']),
          ),
        );
      },
    );
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  static Widget buildVerificationDocuments({
    required String contractorId,
    required BuildContext context,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: VerifyService().getVerificationDocs(contractorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Error loading documents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No verification documents submitted.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submitted Verification Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${docs.length} document${docs.length > 1 ? 's' : ''} submitted',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final url = doc['doc_url'] as String;
                  final fileType = doc['file_type'] as String? ?? 'Unknown';
                  final uploadedAt = doc['uploaded_at'] as String?;
                  
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, url),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.insert_drive_file, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        fileType,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (uploadedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatDate(uploadedAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await VerifyService().verifyContractor(contractorId, true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contractor approved successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error approving contractor: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final shouldReject = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reject Contractor'),
                          content: const Text(
                            'Are you sure you want to reject this contractor? This will delete all verification documents.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );

                      if (shouldReject == true && context.mounted) {
                        try {
                          await VerifyService().verifyContractor(contractorId, false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contractor rejected'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error rejecting contractor: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationManagementTable extends StatefulWidget {
  const VerificationManagementTable({super.key});

  @override
  VerificationManagementTableState createState() => VerificationManagementTableState();
}

class VerificationManagementTableState extends State<VerificationManagementTable> {
  final VerifyService _verifyService = VerifyService();
  List<Map<String, dynamic>> _contractors = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadContractors();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _loadContractors(silent: true);
      }
    });
  }

  Future<void> _loadContractors({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      print('DEBUG UI: Starting to load contractors...');
      final contractors = await _verifyService.getUnverifiedContractors();
      print('DEBUG UI: Loaded ${contractors.length} contractors');
      print('DEBUG UI: Contractors data: $contractors');

      if (mounted) {
        setState(() {
          _contractors = contractors;
          _isLoading = false;
        });
        print('DEBUG UI: State updated with ${_contractors.length} contractors');
      }
    } catch (e) {
      print('ERROR UI: Failed to load contractors: $e');
      if (!silent) {
        await SuperAdminErrorService().logError(
          errorMessage: 'Failed to load unverified contractors: $e',
          module: 'Verification Management',
          severity: 'High',
          extraInfo: {
            'operation': 'Load Contractors',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onContractorTap(String contractorId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          padding: const EdgeInsets.all(16),
          child: BuildVerifyMethods.buildVerificationDocuments(
            contractorId: contractorId,
            context: context,
          ),
        ),
      ),
    ).then((_) => _loadContractors());
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Error loading contractors',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContractors,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        BuildVerifyMethods.buildVerifyStatisticsCard(
          context,
          _contractors.length,
          _loadContractors,
        ),
        Expanded(
          child: BuildVerifyMethods.buildUnverifiedContractorsList(
            contractors: _contractors,
            onContractorTap: _onContractorTap,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }
}