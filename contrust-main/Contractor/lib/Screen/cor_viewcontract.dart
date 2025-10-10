// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:contractor/build/builddrawer.dart';
import 'package:contractor/build/contract/buildviewcontract.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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

  Future<void> downloadContract() async {
    if (contractData == null) return;
    
    await ViewContractService.handleDownload(
      contractData: contractData!,
      context: context,
    );
  }

  Future<void> signContract() async {
    await ViewContractBuild.showSignatureDialog(
      context: context,
      onSign: (signature) async {
        final success = await ViewContractService.handleSignature(
          contractId: widget.contractId,
          contractorId: widget.contractorId,
          signatureBytes: signature,
          context: context,
          onSuccess: () {
            Navigator.of(context).pop();
            loadContract();
          },
        );
        
        if (success) {
          Navigator.of(context).pop();
        }
      },
    );
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
            contractData?['title'], 
            onDownload: downloadContract, 
            onSign: ViewContractService.canSignContract(contractData) ? signContract : null,
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
                              future: ViewContractService.getPdfSignedUrl(contractData!),
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
                            ViewContractBuild.buildSignaturesSection(
                              buildSignatureSection(
                                title: 'Contractor Signature',
                                signaturePath: contractData?['contractor_signature_url'],
                              ),
                              buildSignatureSection(
                                title: 'Contractee Signature',
                                signaturePath: contractData?['contractee_signature_url'],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget buildSignatureSection({
    required String title,
    String? signaturePath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(16),
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
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }
                    
                    final signedUrl = snapshot.data;
                    if (signedUrl == null) {
                      return Center(
                        child: Text(
                          'Unable to load signature',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    
                    return Image.network(
                      signedUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          'Failed to load signature',
                          style: TextStyle(color: Colors.grey[600]),
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
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Not signed yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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
    super.dispose();
  }
}