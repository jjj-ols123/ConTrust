// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class ViewContractBuild {
  static Widget buildHeader(
    BuildContext context,
    String? title, {
    required VoidCallback onDownload,
    VoidCallback? onSign,
    String downloadButtonText = 'Download',
    String signButtonText = 'Sign Contract',
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
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
              icon: Icon(signButtonText.contains('Hide') ? Icons.visibility_off : Icons.edit),
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
              return _buildPdfErrorState(pdfUrl, onDownload, height);
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

  static Widget _buildPdfErrorState(String pdfUrl, VoidCallback onDownload, double height) {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'PDF Viewer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF viewing is optimized for web browsers.\nTap download to view the contract.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSignaturesSection(
    Map<String, dynamic>? contractData, {
    VoidCallback? onRefresh,
  }) {
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
            Row(
              children: [
                Icon(Icons.draw, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Signatures',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh signatures',
                    color: Colors.amber[700],
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSignatureSection(
                    title: 'Contractor',
                    signaturePath: contractData?['contractor_signature_url'],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildSignatureSection(
                    title: 'Contractee',
                    signaturePath: contractData?['contractee_signature_url'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSignatureSection({
    required String title,
    String? signaturePath,
  }) {
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
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey.shade300),
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

  static Widget buildEnhancedSignaturesSection(
    Map<String, dynamic>? contractData, {
    VoidCallback? onRefresh,
  }) {
    final contractorSigned = contractData?['contractor_signature_url'] != null &&
        (contractData!['contractor_signature_url'] as String).isNotEmpty;
    final contracteeSigned = contractData?['contractee_signature_url'] != null &&
        (contractData!['contractee_signature_url'] as String).isNotEmpty;
    final bothSigned = contractorSigned && contracteeSigned;
    final signedPdfUrl = contractData?['signed_pdf_url'] as String?;
    final hasSignedPdf = signedPdfUrl != null && signedPdfUrl.isNotEmpty;

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
          ],
        ),
      ),
    );
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
}
