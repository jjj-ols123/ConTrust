// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/builddrawer.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractorViewContractPage extends StatefulWidget {
  final String contractId;
  final String contractorId;

  const ContractorViewContractPage({
    super.key,
    required this.contractId,
    required this.contractorId,
  });

  @override
  State<ContractorViewContractPage> createState() => _ContractorViewContractPageState();
}

class _ContractorViewContractPageState extends State<ContractorViewContractPage> {
  Map<String, dynamic>? contractData;
  bool isLoading = true;
  String? errorMessage;
  late QuillController _controller;
  bool isSaving = false;
  late SignatureController _signatureController;
  
  bool pdfLoaded = false;
  bool signaturesLoaded = false;
  String? pdfUrl;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
    );
    loadContract();
  }

  String? _getContractTitle() {
    final title = contractData?['title'] as String?;
    final signedPdfUrl = contractData?['signed_pdf_url'] as String?;
    final hasSignedPdf = signedPdfUrl != null && signedPdfUrl.isNotEmpty;
    
    if (hasSignedPdf) {
      return '$title (Signed)';
    }
    return title;
  }

  String _getDownloadButtonText() {
    final signedPdfUrl = contractData?['signed_pdf_url'] as String?;
    final hasSignedPdf = signedPdfUrl != null && signedPdfUrl.isNotEmpty;
    
    return hasSignedPdf ? 'Download Signed' : 'Download';
  }

  Future<void> loadContract() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await ViewContractService.loadContract(widget.contractId);
      
      setState(() {
        contractData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> loadPdfLazily() async {
    if (pdfLoaded || contractData == null) return;
    
    try {
      final url = await _getPdfUrlWithSignedPriority();
      setState(() {
        pdfUrl = url;
        pdfLoaded = true;
      });
    } catch (e) {
      ConTrustSnackBar.error(context, 'Failed to load PDF: $e');
    }
  }

  Future<void> loadSignaturesLazily() async {
    if (signaturesLoaded) return;
    
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      signaturesLoaded = true;
    });
  }

  Future<void> downloadContract() async {
    if (contractData == null) return;
    
    await _downloadContractWithSignedPriority();
  }

  Future<void> _downloadContractWithSignedPriority() async {
    if (contractData == null) return;
    
    try {
      final signedPdfUrl = contractData!['signed_pdf_url'] as String?;
      
      if (signedPdfUrl != null && signedPdfUrl.isNotEmpty) {
        final pdfBytes = await Supabase.instance.client.storage
            .from('contracts')
            .download(signedPdfUrl);
        
        final fileName = 'Signed_Contract_${contractData!['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
        await ContractPdfService.saveToDevice(Uint8List.fromList(pdfBytes), fileName);
        
        if (mounted) {
          ConTrustSnackBar.success(context, 'Signed contract downloaded successfully');
        }
      } else {
        await ViewContractService.handleDownload(
          contractData: contractData!,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Download failed: $e');
      }
    }
  }

  Future<String?> _getPdfUrlWithSignedPriority() async {
    if (contractData == null) return null;
    
    final signedPdfUrl = contractData!['signed_pdf_url'] as String?;
    if (signedPdfUrl != null && signedPdfUrl.isNotEmpty) {
      try {
        final signedUrl = await Supabase.instance.client.storage
            .from('contracts')
            .createSignedUrl(signedPdfUrl, 60 * 60 * 24);
        return signedUrl;
      } catch (e) {
          rethrow; 
      }
    }
    
    return await ViewContractService.getPdfSignedUrl(contractData!);
  }

  Future<void> handleSignature(Uint8List? signature) async {
    if (signature == null) return;
    
    final success = await ViewContractService.handleSignature(
      contractId: widget.contractId,
      contractorId: widget.contractorId,
      signatureBytes: signature,
      context: context,
      onSuccess: () {
        loadContract();
      },
    );
    
    if (success) {
      ConTrustSnackBar.success(context, 'Signature saved successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContractorShell(
      currentPage: ContractorPage.contracts,
      contractorId: widget.contractorId,
      child: Column(
        children: [
          ViewContractBuild.buildHeader(
            context, 
            _getContractTitle(), 
            onDownload: downloadContract,
            downloadButtonText: _getDownloadButtonText(),
          ),
          Expanded(
            child: isLoading
                ? ViewContractBuild.buildLoadingState()
                : errorMessage != null
                    ? ViewContractBuild.buildErrorState(errorMessage!, loadContract)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String?>(
                              future: _getPdfUrlWithSignedPriority(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Card(
                                    child: SizedBox(
                                      height: 400,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: Colors.amber),
                                      ),
                                    ),
                                  );
                                }
                                
                                return ViewContractBuild.buildPdfViewer(
                                  pdfUrl: snapshot.data,
                                  onDownload: downloadContract,
                                  height: 600,
                                );
                              },
                            ),            
                            const SizedBox(height: 24),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ViewContractBuild.buildInlineSignaturePad(
                                    controller: _signatureController,
                                    onClear: () => _signatureController.clear(),
                                    onSign: handleSignature,
                                    isEnabled: true, 
                                    isSaving: isSaving,
                                    onSavingChanged: (saving) => setState(() {
                                      isSaving = saving;
                                    }),
                                    context: context,
                                    contractData: contractData,
                                    userType: 'contractor',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEnhancedSignaturesSection(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSignaturesSection() {
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
            
            buildCompactSignatureSection(
              title: 'Contractor',
              signaturePath: contractData?['contractor_signature_url'],
            ),
            
            const SizedBox(height: 16),
            
            buildCompactSignatureSection(
              title: 'Contractee',
              signaturePath: contractData?['contractee_signature_url'],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCompactSignatureSection({
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

  @override
  void dispose() {
    _controller.dispose();
    _signatureController.dispose();
    super.dispose();
  }
}