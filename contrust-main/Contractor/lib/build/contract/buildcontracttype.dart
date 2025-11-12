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
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractTypeBuild {
  static Future<Map<String, dynamic>> _fetchContractData(String contractorId) async {
    final results = await Future.wait([
      FetchService().fetchContractTypes(),
      FetchService().fetchContractorData(contractorId),
    ]);
    return {
      'contractTypes': results[0] as List<Map<String, dynamic>>,
      'contractorData': results[1] as Map<String, dynamic>?,
    };
  }

  static Widget buildHeader(BuildContext context) {
    return const SizedBox.shrink();
  }

  static Widget buildTypeCarousel({
    Key? key,
    required String contractorId,
    String searchQuery = '',
    String selectedCategory = 'All',
  }) {
    return SizedBox(
      key: key,
      height: 220,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchContractData(contractorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber,));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No contract types available.'),
            );
          }
          final allContractTypes = snapshot.data!['contractTypes'] as List<Map<String, dynamic>>;
          
          Future<Map<String, bool>> checkUserVerification() async {
            try {
              final session = Supabase.instance.client.auth.currentSession;
              if (session == null) return {'verified': false};

              final userResp = await Supabase.instance.client
                  .from('Users')
                  .select('verified')
                  .eq('users_id', session.user.id)
                  .maybeSingle();

              final userVerified = userResp != null && (userResp['verified'] == true);
              return {'verified': userVerified};
            } catch (e) {
              return {'verified': false};
            }
          }

          return FutureBuilder<Map<String, bool>>(
            future: checkUserVerification(),
            builder: (context, verificationSnapshot) {
              final isVerified = verificationSnapshot.data?['verified'] ?? false;

              // Filter contract types based on search and category
              final filteredContractTypes = allContractTypes.where((template) {
                final templateName = template['template_name']?.toString().toLowerCase() ?? '';
                final templateDescription = template['template_description']?.toString().toLowerCase() ?? '';

                // Search filter
                final matchesSearch = searchQuery.isEmpty ||
                    templateName.contains(searchQuery) ||
                    templateDescription.contains(searchQuery);

                // Category filter
                final matchesCategory = selectedCategory == 'All' ||
                    (selectedCategory == 'Standard' && !templateName.toLowerCase().contains('specialized') && !templateName.toLowerCase().contains('custom')) ||
                    (selectedCategory == 'Specialized' && templateName.toLowerCase().contains('specialized')) ||
                    (selectedCategory == 'Custom' && (templateName.toLowerCase().contains('custom') || templateName.toLowerCase().contains('upload')));

                return matchesSearch && matchesCategory;
              }).toList();

              return buildContractTypesList(
                context: context,
                contractTypes: filteredContractTypes,
                contractorId: contractorId,
                isVerified: isVerified,
              );
            },
          );
        },
      ),
    );
  }

  static Widget buildContractTypesList({
    required BuildContext context,
    required List<Map<String, dynamic>> contractTypes,
    required String contractorId,
    required bool isVerified,
  }) {
    if (contractTypes.isEmpty) {
      return const Center(
        child: Text('No contract types match your search.'),
      );
    }

    return Center(
      child: ScrollConfiguration(
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
              isVerified: isVerified,
            );
          },
        ),
      ),
    );
  }

  static Widget buildContractTypeCard({
    required BuildContext context,
    required Map<String, dynamic> template,
    required String contractorId,
    required bool isVerified,
  }) {
    final templateName = template['template_name'] ?? '';
    final isUploadOption = templateName.toLowerCase().contains('upload') || templateName.toLowerCase().contains('custom'); 

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isVerified ? () async {
          if (isUploadOption) {
            await showUploadContractDialog(
              context: context,
              contractorId: contractorId,
            );
          } else {
            await ContractTypeService.navigateToCreateContract(
              context: context,
              template: template,
              contractorId: contractorId,
            );
          }
        } : () {
          ConTrustSnackBar.warning(
            context,
            'Your account needs to be verified before you can create contracts. Please complete your verification.',
          );
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
            border: Border.all(
              color: Colors.amber[100]!,
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 38,
                  color: Colors.amber[700],
                ),
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
    String searchQuery = '',
    String selectedStatus = 'All',
    String selectedProject = 'All',
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          key: contractListKey,
          stream: FetchService().streamCreatedContracts(contractorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            final contracts = snapshot.data!;
            if (contracts.isEmpty) {
              return const Center(child: Text('No contracts created yet.'));
            }
            // Filter contracts based on search query, status, and project
            final filteredContracts = contracts.where((contract) {
              final contractTitle = contract['title']?.toString().toLowerCase() ?? '';
              final project = contract['project'] as Map<String, dynamic>?;
              final projectId = project?['project_id']?.toString() ?? '';
              final contractStatus = contract['status']?.toString().toLowerCase() ?? '';

              // Search filter (by title)
              final matchesSearch = searchQuery.isEmpty || contractTitle.contains(searchQuery);

              // Status filter
              final matchesStatus = selectedStatus == 'All' || contractStatus == selectedStatus.toLowerCase();

              // Project filter
              final matchesProject = selectedProject == 'All' || projectId == selectedProject;

              return matchesSearch && matchesStatus && matchesProject;
            }).toList();

            return buildContractsList(
              context: context,
              contracts: filteredContracts,
              contractorId: contractorId,
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
        );
      },
    );
  }

  static Widget buildContractListItem({
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String contractorId,
    required ThemeData theme,
  }) {
    final project = contract['project'] as Map<String, dynamic>?;
    final projectName = project?['title'] ?? 'Unknown Project';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: Icon(Icons.assignment_turned_in, color: Colors.amber[700]),
        ),
        title: Text(
          contract['title'] ?? 'Untitled Contract',
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          formatDateTime(contract['created_at']),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
        trailing: Builder(
          builder: (buttonContext) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((contract['status'] as String?) != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getContractStatusColor((contract['status'] as String?) ?? 'unknown').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getContractStatusColor((contract['status'] as String?) ?? 'unknown').withOpacity(0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: _getContractStatusColor((contract['status'] as String?) ?? 'unknown')),
                        const SizedBox(width: 6),
                        Text(
                          _getContractStatusLabel((contract['status'] as String?) ?? 'Unknown'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getContractStatusColor((contract['status'] as String?) ?? 'unknown').withOpacity(0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
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
                if (contract['status'] != 'rejected' && contract['status'] != 'cancelled' && contract['status'] != 'sent' && contract['status'] != 'active')
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      ContractTypeService.showContractMenu(
                        context: buttonContext,
                        contract: contract,
                        contractorId: contractorId,
                      );
                    },
                  ),
              ],
            );
          },
        ),
        onTap: () {
          final contractId = contract['contract_id'] as String;
          ContractTypeService.navigateToViewContract(
            context: context,
            contractId: contractId,
            contractorId: contractorId,
          );
        },
      ),
    );
  }

  static Future<void> showUploadContractDialog({
    required BuildContext context,
    required String contractorId,
    Map<String, dynamic>? existingContract,
  }) async {
    final fetchService = FetchService();
    
    // Check if contractor is verified
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ConTrustSnackBar.warning(
        context,
        'You need to be logged in to create contracts.',
      );
      return;
    }

    final userResp = await Supabase.instance.client
        .from('Users')
        .select('verified')
        .eq('users_id', session.user.id)
        .maybeSingle();
    
    final isVerified = userResp != null && (userResp['verified'] == true);
    
    if (!isVerified) {
      ConTrustSnackBar.warning(
        context,
        'Your account needs to be verified before you can create contracts. Please complete your verification.',
      );
      return;
    }
    
    final projects = await fetchService.fetchContractorProjectInfo(contractorId);
    final filteredProjects = projects.where((p) {
      final status = p['status'] as String?;
      return status == 'awaiting_contract' || status == 'awaiting_agreement';
    }).toList();

    final isUpdate = existingContract != null;
    final existingProjectId = existingContract?['project_id'] as String?;
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        XFile? selectedFile;
        final titleController = TextEditingController(text: existingContract?['title'] as String? ?? '');
        String title = existingContract?['title'] as String? ?? '';
        String? selectedProjectId = existingProjectId;
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
              // For update, file is optional (can keep existing file)
              // For new, file is required
              if (!isUpdate && selectedFile == null) {
                ConTrustSnackBar.warning(dialogContext, 'Please select a PDF file.');
                return;
              }
              
              if (title.isEmpty || selectedProjectId == null) {
                ConTrustSnackBar.warning(dialogContext, 'Please fill all required fields.');
                return;
              }

              setState(() => isLoading = true);

              try {
                String? pdfPath;
                
                // Only upload new file if one was selected
                if (selectedFile != null) {
                  final bytes = await selectedFile!.readAsBytes();
                  final projectData = await fetchService.fetchProjectDetails(selectedProjectId!);
                  final contracteeId = projectData?['contractee_id'];

                  if (contracteeId == null) {
                    throw Exception('Project has no contractee.');
                  }

                  final String? contractIdForUpload = existingContract != null 
                    ? existingContract['contract_id'] as String? 
                    : null;
                  pdfPath = await ContractPdfService.uploadContractPdfToStorage(
                    pdfBytes: bytes,
                    contractorId: contractorId,
                    projectId: selectedProjectId!,
                    contracteeId: contracteeId,
                    contractId: contractIdForUpload,
                  );
                }

                if (existingContract != null) {
                  // Update existing custom contract
                  await ContractorContractService.updateCustomContract(
                    contractId: existingContract['contract_id'] as String,
                    contractorId: contractorId,
                    projectId: selectedProjectId!,
                    title: title,
                    pdfPath: pdfPath, // null if no new file selected (keeps existing)
                  );
                } else {
                  // Create new custom contract
                  final projectData = await fetchService.fetchProjectDetails(selectedProjectId!);
                  final contracteeId = projectData?['contractee_id'];

                  if (contracteeId == null) {
                    throw Exception('Project has no contractee.');
                  }

                  await ContractorContractService.uploadCustomContract(
                    contractorId: contractorId,
                    contracteeId: contracteeId,
                    projectId: selectedProjectId!,
                    title: title,
                    pdfPath: pdfPath!,
                    contractType: 'Custom',
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                }
                if (context.mounted) {
                  ConTrustSnackBar.success(
                    context, 
                    isUpdate 
                      ? 'Custom contract updated successfully!' 
                      : 'Custom contract uploaded successfully!'
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ConTrustSnackBar.error(dialogContext, '${isUpdate ? 'Update' : 'Upload'} failed: ${e.toString()}');
                  setState(() => isLoading = false);
                }
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
                          Expanded(
                            child: Text(
                              isUpdate ? 'Update Custom Contract' : 'Upload Custom Contract',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
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
                              controller: titleController,
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
                              onChanged: isUpdate ? null : (value) {
                                setState(() {
                                  selectedProjectId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: pickFile,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                selectedFile == null 
                                  ? (isUpdate ? 'Select New PDF File (Optional)' : 'Select PDF File')
                                  : 'File: ${selectedFile!.name}'
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.amber.shade100,
                                foregroundColor: Colors.amber.shade900,
                              ),
                            ),
                            if (isUpdate && selectedFile == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Current file will be kept if no new file is selected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
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
                                      : Text(isUpdate ? 'Update' : 'Upload'),
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
      final dateString = dateTimeString.toString().trim();
      DateTime dateTime;
      
      // Handle different date formats more robustly
      if (dateString.endsWith('Z') ||
          dateString.contains('+') ||
          dateString.contains('-') && dateString.length > 10) {
        // ISO format with timezone
        dateTime = DateTime.parse(dateString);
      } else if (dateString.length == 10 && !dateString.contains('T')) {
        // Date only format (YYYY-MM-DD)
        dateTime = DateTime.parse('${dateString}T00:00:00.000Z');
      } else if (dateString.contains('T') && !dateString.endsWith('Z')) {
        // ISO format without Z
        dateTime = DateTime.parse('${dateString}Z');
      } else {
        // Try direct parsing
        dateTime = DateTime.parse(dateString);
      }

      final localDateTime = dateTime.toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(localDateTime);
    } catch (e) {
      // If parsing fails, try to extract just the date part
      try {
        final dateStr = dateTimeString.toString();
        if (dateStr.length >= 10) {
          final dateOnly = dateStr.substring(0, 10); // Extract YYYY-MM-DD
          final dateTime = DateTime.parse('${dateOnly}T00:00:00.000Z');
          final localDateTime = dateTime.toLocal();
          return DateFormat('MMM dd, yyyy').format(localDateTime);
        }
      } catch (e2) {
        // If all parsing fails, return a generic message
        return 'Date unavailable';
      }
      return 'Date unavailable';
    }
  }

  static Color _getContractStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'awaiting_signature':
      case 'awaiting_agreement':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
      case 'expired':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  static String _getContractStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'awaiting_signature':
        return 'Awaiting Signature';
      case 'awaiting_agreement':
        return 'Awaiting Agreement';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }
}