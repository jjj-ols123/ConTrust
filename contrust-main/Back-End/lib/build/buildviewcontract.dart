// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, use_build_context_synchronously

import 'package:backend/services/both%20services/be_contract_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:backend/build/html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:backend/build/ui_web_stub.dart' if (dart.library.html) 'dart:ui_web' as ui_web;
import 'dart:typed_data';
import 'package:signature/signature.dart';
import 'package:backend/utils/be_contractsignature.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ViewContractBuild {
  static Widget buildHeader(
    BuildContext context,
    String? title, {
    required VoidCallback onDownload,
    VoidCallback? onSign,
    String downloadButtonText = 'Download',
    String signButtonText = 'Sign Contract',
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title ?? 'Contract Details',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download, size: 16),
                        label: Text(
                          downloadButtonText,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (onSign != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSign,
                          icon: Icon(
                            signButtonText.contains('Hide')
                                ? Icons.visibility_off
                                : Icons.edit,
                            size: 16,
                          ),
                          label: Text(
                            signButtonText,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[600],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Icon(Icons.description, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? 'Contract Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: Text(downloadButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                if (onSign != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onSign,
                    icon: Icon(signButtonText.contains('Hide')
                        ? Icons.visibility_off
                        : Icons.edit),
                    label: Text(signButtonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  static Widget buildPdfViewerPlaceholder(VoidCallback onDownload, {bool isSignedContract = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 400),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSignedContract ? 'Signed Contract PDF' : 'PDF Contract Viewer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildPdfViewer({
    required String? pdfUrl,
    required VoidCallback onDownload,
    double height = 600,
    bool isSignedContract = false,
  }) {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      return buildPdfViewerPlaceholder(onDownload, isSignedContract: isSignedContract);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSignedContract) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Signed Contract',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              height: height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? _buildWebPdfViewerWithFallback(pdfUrl, onDownload, height)
                    : _buildMobilePdfViewer(pdfUrl, onDownload),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildWebPdfViewer(String pdfUrl) {
    final viewType = 'pdf-viewer-${pdfUrl.hashCode.abs()}';

    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = pdfUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'fullscreen'
          ..onError.listen((event) {
          });

        return iframe;
      });
    }

    return HtmlElementView(viewType: viewType);
  }

  static Widget _buildWebPdfViewerWithFallback(String pdfUrl, VoidCallback onDownload, double height) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<bool>(
          future: _testPdfUrl(pdfUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildPdfLoadingState();
            }
            
            if (snapshot.hasError || snapshot.data == false) {
              return _buildPdfErrorState(pdfUrl, onDownload, height, context);
            }
            
            return _buildWebPdfViewer(pdfUrl);
          },
        );
      },
    );
  }

  static Future<bool> _testPdfUrl(String pdfUrl) async {
    try {
      final response = await html.HttpRequest.request(
        pdfUrl,
        method: 'HEAD',
      );
      return response.status == 200;
    } catch (e) {
      return false;
    }
  }

  static Widget _buildPdfLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      ),
    );
  }

  static Widget _buildPdfErrorState(String pdfUrl, VoidCallback onDownload, double height, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Cannot Be Displayed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The PDF viewer cannot display this document. This may be due to CORS restrictions or the file format.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      html.window.open(pdfUrl, '_blank');
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in New Tab'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMobilePdfViewer(String pdfUrl, VoidCallback onDownload) {
    return FutureBuilder<Uint8List?>(
      future: _downloadPdfBytes(pdfUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the button below to open in external app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _launchPdfUrl(context, pdfUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        try {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SfPdfViewer.memory(
              snapshot.data!,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            ),
          );
        } catch (e) {
          debugPrint('Error displaying PDF with SfPdfViewer: $e');
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error displaying PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _launchPdfUrl(context, pdfUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  static Future<Uint8List?> _downloadPdfBytes(String pdfUrl) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          debugPrint('PDF download returned empty bytes');
          return null;
        }
        debugPrint('PDF downloaded successfully: ${bytes.length} bytes');
        return bytes;
      } else {
        debugPrint('PDF download failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading PDF bytes: $e');
      return null;
    }
  }

  static Future<void> _launchPdfUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Could not open PDF URL');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error opening PDF: $e');
      }
    }
  }


  static Widget buildEnhancedSignaturesSection(
    Map<String, dynamic>? contractData, {
    VoidCallback? onRefresh,
    String? currentUserId,
    BuildContext? context,
    String? contractStatus,
    BuildContext? parentDialogContext,
  }) {
    final contractorSigned = contractData?['contractor_signature_url'] != null &&
        (contractData!['contractor_signature_url'] as String).isNotEmpty;
    final contracteeSigned = contractData?['contractee_signature_url'] != null &&
        (contractData!['contractee_signature_url'] as String).isNotEmpty;
    final bothSigned = contractorSigned && contracteeSigned;
    final signedPdfUrl = contractData?['signed_pdf_url'] as String?;
    final hasSignedPdf = signedPdfUrl != null && signedPdfUrl.isNotEmpty;
    
    final status = contractStatus ?? contractData?['status'] as String? ?? '';
    final canSign = contractData != null ? _canUserSign(contractData, currentUserId, status) : false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bothSigned ? Colors.green.shade200 : Colors.amber.shade100,
            width: 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  bothSigned ? Icons.verified : Icons.draw,
                  color: bothSigned ? Colors.green[700] : Colors.amber[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bothSigned ? 'Contract Signed' : 'Signatures',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: bothSigned ? Colors.green[700] : const Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),

            if (bothSigned && hasSignedPdf) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Signed PDF Available',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: buildCompactSignatureSection(
                    title: 'Contractor',
                    signaturePath: contractData?['contractor_signature_url'],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: buildCompactSignatureSection(
                    title: 'Contractee',
                    signaturePath: contractData?['contractee_signature_url'],
                  ),
                ),
              ],
            ),
            
            if (context != null && currentUserId != null && contractData != null && canSign) ...[
              const SizedBox(height: 20),
              _buildSignaturePad(
                contractData,
                currentUserId,
                context,
                canSign,
                onRefresh ?? () {},
                parentDialogContext: parentDialogContext,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _canUserSign(Map<String, dynamic> contractData, String? currentUserId, String? status) {
    if (currentUserId == null) return false;

    final contractStatus = status ?? contractData['status'] as String?;
    final isContractee = contractData['contractee_id'] == currentUserId;
    final isContractor = contractData['contractor_id'] == currentUserId;

    if (contractStatus == 'awaiting_signature' || contractStatus == 'approved') {
      if (isContractee) {
        final contracteeSignatureUrl = contractData['contractee_signature_url'] as String?;
        final contracteeSigned = contracteeSignatureUrl != null && contracteeSignatureUrl.isNotEmpty;
        return !contracteeSigned;
      }
      if (isContractor) {
        final contractorSignatureUrl = contractData['contractor_signature_url'] as String?;
        final contractorSigned = contractorSignatureUrl != null && contractorSignatureUrl.isNotEmpty;
        return !contractorSigned;
      }
    }

    return false;
  }

  static Widget buildCompactSignatureSection({
    required String title,
    String? signaturePath,
  }) {
    final bool isSigned = signaturePath != null && signaturePath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title Signature',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSigned ? Colors.green[50] : Colors.grey[50],
            border: Border.all(
              color: isSigned ? Colors.green[300]! : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: signaturePath != null && signaturePath.isNotEmpty
              ? FutureBuilder<String?>(
                  future: ViewContractService.getSignedUrl(signaturePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.amber,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final signedUrl = snapshot.data;
                    if (signedUrl == null) {
                      return Center(
                        child: Text(
                          'Unable to load',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      );
                    }

                    return Image.network(
                      signedUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          'Failed to load',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_outlined,
                        size: 24,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Not signed',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  static Widget buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 16),
          Text('Loading contract...'),
        ],
      ),
    );
  }

  static Widget buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Contract',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSignaturePad(
    Map<String, dynamic> contractData,
    String? currentUserId,
    BuildContext context,
    bool enabled,
    VoidCallback onRefresh, {
    BuildContext? parentDialogContext,
  }) {
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
        border: Border.all(color: enabled ? Colors.blue[300]! : Colors.grey[300]!),
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
              border: Border.all(color: enabled ? Colors.grey[300]! : Colors.grey[400]!),
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
                    : 'Draw your signature above using your mouse, stylus, or finger')
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
                      backgroundColor: enabled ? Colors.grey[600] : Colors.grey[400],
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
                            final signatureBytes = await pickSignatureImage(context);
                            if (signatureBytes != null) {
                              _showSignatureDialog(
                                context, 
                                contractData,
                                currentUserId, 
                                signatureBytes, 
                                onRefresh,
                                parentDialogContext: parentDialogContext,
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabled ? Colors.orange[600] : Colors.grey[400],
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
                            final signature = await signatureController.toPngBytes();
                            if (signature == null || signature.isEmpty) {
                              ConTrustSnackBar.error(
                                  context, 'Please provide a signature');
                              return;
                            }
                            _showSignatureDialog(
                              context, 
                              contractData,
                              currentUserId, 
                              signature, 
                              onRefresh,
                              parentDialogContext: parentDialogContext,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Sign Contract'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabled ? Colors.green[600] : Colors.grey[400],
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
                      backgroundColor: enabled ? Colors.grey[600] : Colors.grey[400],
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
                            final signatureBytes = await pickSignatureImage(context);
                            if (signatureBytes != null) {
                              _showSignatureDialog(
                                context, 
                                contractData,
                                currentUserId, 
                                signatureBytes, 
                                onRefresh,
                                parentDialogContext: parentDialogContext,
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabled ? Colors.orange[600] : Colors.grey[400],
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
                            final signature = await signatureController.toPngBytes();
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
                      backgroundColor: enabled ? Colors.green[600] : Colors.grey[400],
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

  static Future<Uint8List?> pickSignatureImage(BuildContext context) async {
    final bytes = await pickSignatureImageHelper(context);
    if (bytes == null) {
      ConTrustSnackBar.error(context, 'Failed to pick signature image');
    }
    return bytes;
  }

  static Future<Uint8List?> pickSignatureImageHelper(BuildContext context) async {
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
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Failed to pick signature image: $e');
      }
      return null;
    }
  }

  static void _showSignatureDialog(
    BuildContext context,
    Map<String, dynamic> contractData,
    String? currentUserId,
    Uint8List signatureBytes,
    VoidCallback onRefresh, {
    BuildContext? parentDialogContext,
  }) {
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

                                  await SignatureCompletionHandler.signContractWithPdfGeneration(
                                    contractId: contractId,
                                    userId: currentUserId,
                                    signatureBytes: signatureBytes,
                                    userType: userType,
                                  );

                                  // Check if both parties have signed
                                  final updatedContract = await ContractService.getContractById(contractId);
                                  final hasContractorSignature = updatedContract['contractor_signature_url'] != null &&
                                      (updatedContract['contractor_signature_url'] as String).isNotEmpty;
                                  final hasContracteeSignature = updatedContract['contractee_signature_url'] != null &&
                                      (updatedContract['contractee_signature_url'] as String).isNotEmpty;
                                  final bothSigned = hasContractorSignature && hasContracteeSignature;

                                  Navigator.of(dialogContext).pop();
                                  onRefresh();
                                  
                                  // If both parties have signed, close the parent contract dialog
                                  if (bothSigned && parentDialogContext != null) {
                                    Navigator.of(parentDialogContext).pop();
                                  }
                                  
                                } catch (e) {
                                  ConTrustSnackBar.error(context, 'Failed to sign contract: $e');
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
