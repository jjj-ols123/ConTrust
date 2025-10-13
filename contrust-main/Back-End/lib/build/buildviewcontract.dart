// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
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

  static Widget buildPdfViewerPlaceholder(VoidCallback onDownload) {
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
                Icon(Icons.picture_as_pdf, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Contract PDF',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                      'PDF Contract Viewer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add flutter_pdfview package to view PDF here',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
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
  }) {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      return buildPdfViewerPlaceholder(onDownload);
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
            Container(
              height: height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    kIsWeb
                        ? _buildWebPdfViewer(pdfUrl)
                        : _buildMobilePdfViewer(pdfUrl, onDownload),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildWebPdfViewer(String pdfUrl) {
    final viewerUrl =
        'https://mozilla.github.io/pdf.js/web/viewer.html'
        '?file=${Uri.encodeComponent(pdfUrl)}'
        '#toolbar=0'
        '&navpanes=0'
        '&scrollbar=1'
        '&spread=0'
        '&sidebar=0';

    final viewType = 'pdf-viewer-${pdfUrl.hashCode.abs()}';

    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe =
            html.IFrameElement()
              ..src = viewerUrl
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%'
              ..allow = 'fullscreen';

        return iframe;
      });
    }

    return HtmlElementView(viewType: viewType);
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
            _buildSignatureSection(
              title: 'Contractor',
              signaturePath: contractData?['contractor_signature_url'],
            ),
            const SizedBox(height: 24),
            _buildSignatureSection(
              title: 'Contractee',
              signaturePath: contractData?['contractee_signature_url'],
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
          height: 80,
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

  static Widget buildSignaturePad({
    required SignatureController controller,
    double height = 200,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.draw_rounded, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Draw your signature',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Container(
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              width: double.infinity,
              height: height + 40,
              child: Signature(
                controller: controller,
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign above using your mouse, stylus, or finger.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => controller.clear(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  static Future<void> showSignatureDialog({
    required BuildContext context,
    required Future<void> Function(Uint8List? signature) onSign,
  }) async {
    await onSign(null);
  }

  static Widget buildInlineSignaturePad({
    required SignatureController controller,
    required VoidCallback onClear,
    required Future<void> Function(Uint8List? signature) onSign,
    bool isEnabled = true,
    required bool isSaving,
    required Function(bool) onSavingChanged,
    required BuildContext context,
    Map<String, dynamic>? contractData,
    String? userType, 
  }) {

    final hasExistingSignature = contractData != null && userType != null && 
      contractData['${userType}_signature_url'] != null && 
      (contractData['${userType}_signature_url'] as String).isNotEmpty;
    
    final effectiveIsEnabled = isEnabled && !hasExistingSignature;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200, width: 2),
        ),
        child: AbsorbPointer(
          absorbing: !effectiveIsEnabled,
          child: Opacity(
            opacity: effectiveIsEnabled ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasExistingSignature ? Icons.check_circle : Icons.edit, 
                      color: hasExistingSignature ? Colors.green[700] : Colors.amber[700], 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasExistingSignature ? 'Contract Already Signed' : 'Draw Your Signature',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasExistingSignature ? Colors.green[700] : const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasExistingSignature ? Colors.green[50] : Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hasExistingSignature ? Colors.green[200]! : Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasExistingSignature ? Icons.check_circle : Icons.info_outline, 
                        color: hasExistingSignature ? Colors.green[700] : Colors.amber[700], 
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasExistingSignature 
                            ? 'You have already signed this contract.'
                            : 'Draw your signature below using your mouse or stylus. This will be legally binding.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.amber[400]!, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Signature(
                      controller: controller,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSaving || !effectiveIsEnabled ? null : onClear,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[400]!, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isSaving || !effectiveIsEnabled
                            ? null
                            : () async {
                                if (controller.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning, color: Colors.white, size: 16),
                                          SizedBox(width: 8),
                                          Text('Please draw your signature first'),
                                        ],
                                      ),
                                      backgroundColor: Colors.orange[600],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                onSavingChanged(true);
                                try {
                                  final signature = await controller.toPngBytes();
                                  await onSign(signature);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error, color: Colors.white, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Error saving signature: $e')),
                                          ],
                                        ),
                                        backgroundColor: Colors.red[600],
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } finally {
                                  onSavingChanged(false);
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 16),
                        label: Text(
                          isSaving ? 'Saving...' : 'Sign Contract',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[600],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
