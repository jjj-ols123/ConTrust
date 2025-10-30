// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, use_build_context_synchronously
import 'dart:ui';
import 'package:backend/services/both%20services/be_contract_pdf_service.dart';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/contractor%20services/contract/cor_contractservice.dart';
import 'package:backend/services/contractor%20services/contract/cor_contracttypeservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class ContractTypeBuild {
  static Widget buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.handyman_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Choose your Contract',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTypeCarousel({
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: FetchService().fetchContractTypes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber,));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No contract types available.'),
            );
          }
          final contractTypes = snapshot.data!;
          return buildContractTypesList(
            context: context,
            contractTypes: contractTypes,
            contractorId: contractorId,
            onRefreshContracts: onRefreshContracts,
          );
        },
      ),
    );
  }

  static Widget buildContractTypesList({
    required BuildContext context,
    required List<Map<String, dynamic>> contractTypes,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: contractTypes.length,
        itemBuilder: (context, index) {
          final template = contractTypes[index];
          return buildContractTypeCard(
            context: context,
            template: template,
            contractorId: contractorId,
            onRefreshContracts: onRefreshContracts,
          );
        },
      ),
    );
  }

  static Widget buildContractTypeCard({
    required BuildContext context,
    required Map<String, dynamic> template,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    final templateName = template['template_name'] ?? '';
    final isUploadOption = templateName.toLowerCase().contains('upload') || templateName.toLowerCase().contains('custom'); 

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (isUploadOption) {
            await showUploadContractDialog(
              context: context,
              contractorId: contractorId,
              onRefreshContracts: onRefreshContracts,
            );
          } else {
            final result = await ContractTypeService.navigateToCreateContract(
              context: context,
              template: template,
              contractorId: contractorId,
            );
            if (result == true) {
              onRefreshContracts();
            }
          }
        },
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.amber[100]!, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 38, color: Colors.amber[700]),
                const SizedBox(height: 18),
                Text(
                  template['template_name'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  template['template_description'] ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildContractListContainer({
    required String contractorId,
    required Key contractListKey,
    required VoidCallback onRefreshContracts,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          key: contractListKey,
          future: FetchService().fetchCreatedContracts(contractorId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            final contracts = snapshot.data!;
            if (contracts.isEmpty) {
              return const Center(child: Text('No contracts created yet.'));
            }
            return buildContractsList(
              context: context,
              contracts: contracts,
              contractorId: contractorId,
              onRefreshContracts: onRefreshContracts,
            );
          },
        ),
      ),
    );
  }

  static Widget buildContractsList({
    required BuildContext context,
    required List<Map<String, dynamic>> contracts,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: contracts.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Colors.amberAccent,
        thickness: 0.7,
      ),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return buildContractListItem(
          context: context,
          contract: contract,
          contractorId: contractorId,
          theme: theme,
          onRefreshContracts: onRefreshContracts,
        );
      },
    );
  }

  static Widget buildContractListItem({
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String contractorId,
    required ThemeData theme,
    required VoidCallback onRefreshContracts,
  }) {
    final project = contract['project'] as Map<String, dynamic>?;
    final projectName = project?['title'] ?? 'Unknown Project';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Colors.amber[100],
        child: Icon(Icons.assignment_turned_in, color: Colors.amber[700]),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contract['title'] ?? 'Untitled Contract',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction, size: 12, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  projectName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Text(
        formatDateTime(contract['created_at']),
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
      ),
      trailing: Builder(
        builder: (buttonContext) {
          return IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ContractTypeService.showContractMenu(
                context: buttonContext,
                contract: contract,
                contractorId: contractorId,
                onRefreshContracts: onRefreshContracts,
              );
            },
          );
        },
      ),
      onTap: () async {
        final contractId = contract['contract_id'] as String;
        await ContractTypeService.navigateToViewContract(
          context: context,
          contractId: contractId,
          contractorId: contractorId,
        );
      },
    );
  }

  static Future<void> showUploadContractDialog({
    required BuildContext context,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) async {
    final fetchService = FetchService();
    final projects = await fetchService.fetchContractorProjectInfo(contractorId);
    final filteredProjects = projects.where((p) {
      final status = p['status'] as String?;
      return status == 'awaiting_contract' || status == 'awaiting_agreement';
    }).toList();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        XFile? selectedFile;
        String title = '';
        String? selectedProjectId;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickFile() async {
              try {
                const XTypeGroup pdfType = XTypeGroup(
                  label: 'PDF files',
                  extensions: ['pdf'],
                );
                final XFile? file = await openFile(acceptedTypeGroups: [pdfType]);
                if (file != null) {
                  setState(() {
                    selectedFile = file;
                  });
                } else {
                  ConTrustSnackBar.warning(dialogContext, 'No PDF file selected. Please try again.');
                }
              } catch (e) {
                ConTrustSnackBar.error(dialogContext, 'Failed to pick file');
              }
            }

            Future<void> saveCustomContract() async {
              if (selectedFile == null || title.isEmpty || selectedProjectId == null) {
                ConTrustSnackBar.warning(dialogContext, 'Please fill all fields and select a file.');
                return;
              }

              setState(() => isLoading = true);

              try {
                final bytes = await selectedFile!.readAsBytes();  
                final projectData = await fetchService.fetchProjectDetails(selectedProjectId!);
                final contracteeId = projectData?['contractee_id'];

                if (contracteeId == null) {
                  throw Exception('Project has no contractee.');
                }

                final pdfPath = await ContractPdfService.uploadContractPdfToStorage(
                  pdfBytes: bytes,
                  contractorId: contractorId,
                  projectId: selectedProjectId!,
                  contracteeId: contracteeId,
                );


                await ContractorContractService.uploadCustomContract(
                  contractorId: contractorId,
                  contracteeId: contracteeId,
                  projectId: selectedProjectId!,
                  title: title,
                  pdfPath: pdfPath, 
                  contractType: 'Custom',
                );


                ConTrustSnackBar.success(dialogContext, 'Contract uploaded successfully!');
                Navigator.of(dialogContext).pop();
                onRefreshContracts();
              } catch (e) {
                ConTrustSnackBar.error(dialogContext, 'Upload failed');
              } finally {
                setState(() => isLoading = false);
              }
            }

            return Dialog(
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
                      padding: const EdgeInsets.all(24),
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
                              Icons.upload_file,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Upload Custom Contract',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Contract Title',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => title = value,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Project',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedProjectId,
                              items: filteredProjects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(
                                value: p['project_id'] as String,
                                child: Text(p['title'] ?? 'Project'),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedProjectId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: pickFile,
                              icon: const Icon(Icons.attach_file),
                              label: Text(selectedFile == null ? 'Select PDF File' : 'File: ${selectedFile!.name}'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.amber.shade100,
                                foregroundColor: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : saveCustomContract,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: isLoading 
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Upload'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String formatDateTime(dynamic dateTimeString) {
    if (dateTimeString == null || dateTimeString.toString().isEmpty) {
      return 'Unknown date';
    }

    try {
      final dateString = dateTimeString.toString();
      DateTime dateTime;
      
      if (dateString.endsWith('Z') || dateString.contains('+')) {
        dateTime = DateTime.parse(dateString);
      } else {
        dateTime = DateTime.parse('${dateString}Z');
      }
      
      DateTime localDateTime = dateTime.toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(localDateTime);
    } catch (e) {
      return dateTimeString.toString();
    }
  }
}