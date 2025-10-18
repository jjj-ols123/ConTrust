// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, use_build_context_synchronously
import 'dart:ui';
import 'package:backend/services/both%20services/be_contract_pdf_service.dart';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/contractor%20services/contract/cor_contractservice.dart';
import 'package:backend/services/contractor%20services/contract/cor_contracttypeservice.dart';
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
    final isUploadOption = templateName.toLowerCase().contains('upload') || templateName.toLowerCase().contains('custom');  // More flexible check

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          print('Tapped template: $templateName, isUploadOption: $isUploadOption');

          if (isUploadOption) {
            await showUploadContractDialog(
              context: context,
              contractorId: contractorId,
              onRefreshContracts: onRefreshContracts,
            );
          } else {
            await ContractTypeService.navigateToCreateContract(
              context: context,
              template: template,
              contractorId: contractorId,
            );
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Colors.amber[100],
        child: Icon(Icons.assignment_turned_in, color: Colors.amber[700]),
      ),
      title: Text(
        contract['title'] ?? 'Untitled Contract',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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
    XFile? selectedFile;
    String title = '';
    String? selectedProjectId;
    List<Map<String, dynamic>> projects = [];
    bool isLoading = false;

    // Load projects
    final fetchService = FetchService();
    projects = await fetchService.fetchContractorProjectInfo(contractorId);
    projects = projects.where((p) => p['status'] == 'awaiting_contract').toList();

    await showDialog(
      context: context,
      builder: (dialogContext) {
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
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('No PDF file selected. Please try again.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to pick file: $e')),
                );
              }
            }

            Future<void> saveCustomContract() async {
              if (selectedFile == null || title.isEmpty || selectedProjectId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields and select a file.')),
                );
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


                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Contract uploaded successfully!')),
                );
                Navigator.of(dialogContext).pop();
                onRefreshContracts();
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Upload failed: $e')),
                );
              } finally {
                setState(() => isLoading = false);
              }
            }

            return AlertDialog(
              title: const Text('Upload Custom Contract'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Contract Title'),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Project'),
                      value: selectedProjectId,
                      items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(
                        value: p['project_id'] as String,
                        child: Text(p['title'] ?? 'Project'),
                      )).toList(),
                      onChanged: (value) => setState(() => selectedProjectId = value),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: pickFile,
                      child: Text(selectedFile == null ? 'Select PDF File' : 'File Selected: ${selectedFile!.name}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : saveCustomContract,
                  child: isLoading ? const CircularProgressIndicator() : const Text('Upload'),
                ),
              ],
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
      DateTime dateTime = DateTime.parse(dateTimeString.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString.toString();
    }
  }
}