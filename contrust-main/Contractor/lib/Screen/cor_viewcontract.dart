// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
  
  bool pdfLoaded = false;
  String? pdfUrl;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    loadContract();
  }

  Future<void> loadContract() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await ViewContractService.loadContract(
        widget.contractId,
        contractorId: widget.contractorId,
      );
      
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
      ConTrustSnackBar.error(context, 'Failed to load PDF:');
    }
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
        try {
          final pdfBytes = await Supabase.instance.client.storage
              .from('contracts')
              .download(signedPdfUrl);
          
          final fileName = 'Signed_Contract_${contractData!['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
          await ContractPdfService.saveToDevice(Uint8List.fromList(pdfBytes), fileName);
          
          if (mounted) {
            ConTrustSnackBar.success(context, 'Signed contract saved successfully');
          }
        } catch (downloadError) {
          await ViewContractService.handleDownload(
            contractData: contractData!,
            context: context,
          );
        }
      } else {
        await ViewContractService.handleDownload(
          contractData: contractData!,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Download failed: ');
      }
    }
  }

  Future<String?> _getPdfUrlWithSignedPriority() async {
    if (contractData == null) return null;
    
    final signedPdfUrl = contractData!['signed_pdf_url'] as String?;
    if (signedPdfUrl != null && signedPdfUrl.isNotEmpty) {
      try {
        final signedUrl = await ViewContractService.getSignedContractUrl(signedPdfUrl);
        if (signedUrl != null && signedUrl.isNotEmpty) {
          return signedUrl;
        }
      } catch (e) {
        rethrow;
      }
    }
    
    return await ViewContractService.getPdfSignedUrl(contractData!);
  }

  Future<void> _downloadContractWithData(Map<String, dynamic> data) async {
    try {
      final signedPdfUrl = data['signed_pdf_url'] as String?;
      
      if (signedPdfUrl != null && signedPdfUrl.isNotEmpty) {
        try {
          final pdfBytes = await Supabase.instance.client.storage
              .from('contracts')
              .download(signedPdfUrl);
          
          final fileName = 'Signed_Contract_${data['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
          await ContractPdfService.saveToDevice(Uint8List.fromList(pdfBytes), fileName);
          
          if (mounted) {
            ConTrustSnackBar.success(context, 'Signed contract saved successfully');
          }
        } catch (downloadError) {
          await ViewContractService.handleDownload(
            contractData: data,
            context: context,
          );
        }
      } else {
        await ViewContractService.handleDownload(
          contractData: data,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Download failed: ');
      }
    }
  }

  Future<String?> _getPdfUrlWithData(Map<String, dynamic> data) async {
    final signedPdfUrl = data['signed_pdf_url'] as String?;
    if (signedPdfUrl != null && signedPdfUrl.isNotEmpty) {
      try {
        final signedUrl = await ViewContractService.getSignedContractUrl(signedPdfUrl);
        if (signedUrl != null && signedUrl.isNotEmpty) {
          return signedUrl;
        }
      } catch (e) {
        rethrow;
      }
    }
    
    return await ViewContractService.getPdfSignedUrl(data);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: FetchService().streamContractById(widget.contractId),
              initialData: contractData,
              builder: (context, contractSnap) {
                final liveData = contractSnap.data ?? contractData;
                if (liveData == null) {
                  return ViewContractBuild.buildHeader(
                    context,
                    'Loading...',
                    onDownload: () {},
                    downloadButtonText: 'Download',
                  );
                }

                final title = liveData['title'] as String?;
                final signedPdfUrl = liveData['signed_pdf_url'] as String?;
                final hasSignedPdf = signedPdfUrl != null && signedPdfUrl.isNotEmpty;
                final displayTitle = hasSignedPdf ? '$title (Signed)' : title;
                final downloadText = hasSignedPdf ? 'Download Signed' : 'Download';

                return ViewContractBuild.buildHeader(
                  context,
                  displayTitle ?? 'Contract',
                  onDownload: () => _downloadContractWithData(liveData),
                  downloadButtonText: downloadText,
                );
              },
            ),
            Expanded(
              child: isLoading
                  ? ViewContractBuild.buildLoadingState()
                  : errorMessage != null
                      ? ViewContractBuild.buildErrorState(errorMessage!, loadContract)
                      : StreamBuilder<Map<String, dynamic>?>(
                          stream: FetchService().streamContractById(widget.contractId),
                          initialData: contractData,
                          builder: (context, contractSnap) {
                            final liveData = contractSnap.data ?? contractData;
                            if (liveData == null) {
                              return ViewContractBuild.buildLoadingState();
                            }

                            return SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth < 700 ? 8 : 24,
                                vertical: 24,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight > 0
                                      ? constraints.maxHeight - 100
                                      : 0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<String?>(
                                      future: _getPdfUrlWithData(liveData),
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
                                          onDownload: () => _downloadContractWithData(liveData),
                                          height: constraints.maxWidth < 700 ? 500 : 600,
                                          isSignedContract: (liveData['signed_pdf_url'] as String?)?.isNotEmpty == true,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    ViewContractBuild.buildEnhancedSignaturesSection(liveData),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}