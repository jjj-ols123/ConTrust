// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/verify_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_ui_theme.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BuildVerifyMethods {
  static Widget buildVerifyStatisticsCard(BuildContext context, int totalUnverified, VoidCallback? onRefresh) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.iconSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user_outlined, color: AppTheme.iconSecondary, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Pending Verifications',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.headerText),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.buttonSecondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.buttonSecondary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$totalUnverified',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (onRefresh != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: IconButton(
                    onPressed: onRefresh,
                    icon: Icon(Icons.refresh_outlined, color: AppTheme.iconSecondary),
                    tooltip: 'Refresh',
                  ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.iconSecondary),
            const SizedBox(height: 16),
            const Text('Loading contractors...', style: TextStyle(color: AppTheme.headerText)),
          ],
        ),
      );
    }

    if (contractors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 64, color: AppTheme.iconSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No contractors up for verification.',
              style: TextStyle(fontSize: 16, color: AppTheme.headerText),
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
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: InkWell(
            onTap: () => onContractorTap(contractor['contractor_id']),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.iconSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business, color: AppTheme.iconSecondary, size: 24),
              ),
              title: Text(
                contractor['firm_name'] ?? 'Unknown Firm',
                style: const TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 16,
                  color: AppTheme.headerText,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: AppTheme.iconSecondary),
                      const SizedBox(width: 6),
                      Text(
                        contractor['contact_number'] ?? 'N/A',
                        style: TextStyle(color: AppTheme.iconSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppTheme.iconSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(contractor['created_at']),
                        style: TextStyle(color: AppTheme.iconSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.iconSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.iconSecondary),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  static Widget buildVerificationDocuments({
    required String contractorId,
    required BuildContext context,
    VoidCallback? onApproved,
    VoidCallback? onRejected,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: VerifyService().getVerificationDocs(contractorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.iconSecondary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.buttonDanger),
                const SizedBox(height: 16),
                const Text(
                  'Error loading documents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.headerText),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: AppTheme.iconSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
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
                Icon(Icons.description_outlined, size: 64, color: AppTheme.iconSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No verification documents submitted.',
                  style: TextStyle(color: AppTheme.iconSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.iconSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description, color: AppTheme.iconSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Submitted Verification Documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headerText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.iconSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${docs.length} document${docs.length > 1 ? 's' : ''} submitted',
                style: TextStyle(
                  color: AppTheme.iconSecondary, 
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                  final docUrl = doc['doc_url'] as String? ?? '';
                  final fileType = doc['file_type'] as String? ?? 'Unknown';
                  final uploadedAt = doc['uploaded_at'] as String?;
                  
                  // Check if it's an image or PDF/document
                  final isImage = fileType.toLowerCase() == 'image' || 
                                  docUrl.toLowerCase().endsWith('.jpg') ||
                                  docUrl.toLowerCase().endsWith('.jpeg') ||
                                  docUrl.toLowerCase().endsWith('.png') ||
                                  docUrl.toLowerCase().endsWith('.gif') ||
                                  docUrl.toLowerCase().endsWith('.webp');
                  final isPdf = fileType.toLowerCase() == 'document' ||
                                docUrl.toLowerCase().endsWith('.pdf');
                  
                  return FutureBuilder<String>(
                    future: _getImageUrl(docUrl),
                    builder: (context, urlSnapshot) {
                      final finalUrl = urlSnapshot.data ?? docUrl;
                      
                      return GestureDetector(
                        onTap: () async {
                          if (isImage) {
                            final finalImageUrl = await _getImageUrl(docUrl);
                            if (context.mounted) {
                              _showFullScreenImage(context, finalImageUrl);
                            }
                          } else if (isPdf) {
                            final finalPdfUrl = await _getImageUrl(docUrl);
                            if (context.mounted) {
                              _showPdfDocument(context, finalPdfUrl, docUrl);
                            }
                          } else {
                            // For other document types, try to open in browser
                            final finalDocUrl = await _getImageUrl(docUrl);
                            if (context.mounted) {
                              _showDocument(context, finalDocUrl);
                            }
                          }
                        },
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
                                  child: urlSnapshot.connectionState == ConnectionState.waiting
                                      ? Center(child: CircularProgressIndicator(color: AppTheme.iconSecondary))
                                      : isImage
                                          ? Image.network(
                                              finalUrl,
                                              fit: BoxFit.cover,
                                              headers: {
                                                'Cache-Control': 'no-cache',
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(child: CircularProgressIndicator(color: AppTheme.iconSecondary));
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade50,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.broken_image,
                                                        color: AppTheme.iconSecondary,
                                                        size: 48,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        child: Text(
                                                          'Failed to load image',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: AppTheme.iconSecondary,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppTheme.headerBackground,
                                                    Colors.white,
                                                  ],
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.iconSecondary.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isPdf ? Icons.picture_as_pdf : Icons.description,
                                                      color: AppTheme.iconSecondary,
                                                      size: 48,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    isPdf ? 'PDF Document' : 'Document',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.headerText,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tap to view',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.iconSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                        if (!context.mounted) return;

                        Navigator.of(context).pop();
                        
                        await Future.delayed(const Duration(milliseconds: 100));
                        
                        if (context.mounted) {
                          ConTrustSnackBar.success(context, 'Contractor approved successfully!');
                        }
                        onApproved?.call();
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); 
                          ConTrustSnackBar.error(context, 'Error approving contractor: $e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonSuccess,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Save the main dialog context before showing confirmation
                      final mainDialogContext = context;
                      
                      final shouldReject = await showDialog<bool>(
                        context: context,
                        builder: (confirmContext) => AlertDialog(
                          title: const Text('Reject Contractor'),
                          content: const Text(
                            'Are you sure you want to reject this contractor? This will delete all verification documents.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(confirmContext, false),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.iconSecondary,
                              ),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(confirmContext, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.buttonDanger,
                              ),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );

                      if (shouldReject == true && mainDialogContext.mounted) {
                        try {
                          await VerifyService().verifyContractor(contractorId, false);
                          if (!mainDialogContext.mounted) return;
                          
                          // Close the main dialog
                          Navigator.of(mainDialogContext).pop();
                          
                          // Wait a bit for dialog to close
                          await Future.delayed(const Duration(milliseconds: 100));
                          
                          // Show warning message and refresh
                          if (mainDialogContext.mounted) {
                            ConTrustSnackBar.warning(mainDialogContext, 'Contractor rejected');
                          }
                          onRejected?.call();
                        } catch (e) {
                          if (mainDialogContext.mounted) {
                            Navigator.of(mainDialogContext).pop(); // Close dialog even on error
                            ConTrustSnackBar.error(mainDialogContext, 'Error rejecting contractor: $e');
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonDanger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
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

  static Future<String> _getImageUrl(String docUrl) async {
    if (docUrl.isEmpty) return docUrl;
    
    try {
      final supabase = Supabase.instance.client;
      String filePath = docUrl;
      
      // If it's a full URL, extract the path
      if (docUrl.startsWith('http')) {
        // Extract path from full URL
        // Format: https://...supabase.co/storage/v1/object/public/verification/{path}
        if (docUrl.contains('/object/public/verification/')) {
          filePath = docUrl.split('/object/public/verification/').last;
        } else if (docUrl.contains('/verification/')) {
          filePath = docUrl.split('/verification/').last;
        } else {
          // If we can't extract, return original URL
          return docUrl;
        }
      }
      
      // Remove any leading slashes and query parameters
      filePath = filePath.replaceAll(RegExp(r'^/+'), '').split('?').first;
      
      // If it's already a full URL, return it
      if (filePath.startsWith('http')) {
        return filePath;
      }
      
      // Try to use signed URL first (more reliable), then fall back to public URL
      try {
        // Try signed URL first (valid for 1 hour)
        final signedUrl = await supabase.storage
            .from('verification')
            .createSignedUrl(filePath, 3600);
        if (signedUrl.isNotEmpty) {
          return signedUrl;
        }
      } catch (e) {
        // If signed URL fails, try public URL
      }
      
      // Fall back to public URL
      return supabase.storage
          .from('verification')
          .getPublicUrl(filePath);
    } catch (e) {
      // If URL fixing fails, return original URL
      return docUrl;
    }
  }

  static void _showPdfDocument(BuildContext context, String pdfUrl, String originalUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 900),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.buttonSecondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Verification Document - PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: ViewContractBuild.buildPdfViewer(
                    pdfUrl: pdfUrl,
                    onDownload: () async {
                      try {
                        final uri = Uri.parse(pdfUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            ConTrustSnackBar.error(context, 'Could not download PDF document');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ConTrustSnackBar.error(context, 'Error downloading PDF: $e');
                        }
                      }
                    },
                    height: 700,
                    isSignedContract: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showDocument(BuildContext context, String docUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Document', style: TextStyle(color: AppTheme.headerText)),
        content: const Text('This document will open in your browser.', style: TextStyle(color: AppTheme.iconSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.iconSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(docUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                if (context.mounted) {
                  ConTrustSnackBar.error(context, 'Could not open document');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonSecondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open'),
          ),
        ],
      ),
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
                headers: {
                  'Cache-Control': 'no-cache',
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            error.toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.iconSecondary),
                  );
                },
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

      final contractors = await _verifyService.getUnverifiedContractors();

      if (mounted) {
        setState(() {
          _contractors = contractors;
          _isLoading = false;
        });
      }
    } catch (e) {
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
            onApproved: () {
              // Refresh the list when approved
              if (mounted) {
                _loadContractors();
              }
            },
            onRejected: () {
              // Refresh the list when rejected
              if (mounted) {
                _loadContractors();
              }
            },
          ),
        ),
      ),
    );
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