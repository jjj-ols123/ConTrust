// ignore_for_file: deprecated_member_use, file_names, use_build_context_synchronously

import 'package:backend/services/be_contract_service.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractee/pages/cee_ongoing.dart';

class UIContract {

  static Future<Map<String, dynamic>?> showSaveDialog(
    BuildContext context,
    String contractorId, {
    required TextEditingController titleController,
    String? initialProjectId,
  }) async {
    String? selectedProjectId = initialProjectId;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Save Contract'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Contract Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: FetchService().fetchContractorProjectInfo(contractorId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error getting projects');
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('No projects found. Create a project first.');
                        }
                        return DropdownButtonFormField<String>(
                          value: selectedProjectId,
                          decoration: const InputDecoration(
                            labelText: 'Select Project *',
                            border: OutlineInputBorder(),
                          ),
                          items: snapshot.data!.map((project) => DropdownMenuItem<String>(
                                value: project['project_id'] as String,
                                child: Text(
                                  project['description'] ?? 'No Description',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedProjectId = value;
                            });
                          },
                        );
                      },
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
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title is required')),
                      );
                      return;
                    }
                    if (selectedProjectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project is required')),
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop({
                      'title': titleController.text.trim(),
                      'projectId': selectedProjectId,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<String?> getSignedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    final signedUrl = await Supabase.instance.client.storage
        .from('signatures')
        .createSignedUrl(path, 60 * 60);
    return signedUrl;
  }

  static Future<void> viewContract(
      BuildContext context, String contractId) async {
    try {
      final contractData = await ContractService.getContractById(contractId);
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final isContractee = contractData['contractee_id'] == currentUserId;
      final isContractor = contractData['contractor_id'] == currentUserId;
      final status = contractData['status'];
      final contracteeSignaturePath = contractData['contractee_signature_url'];
      final contractorSignaturePath = contractData['contractor_signature_url'];

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              contractData['title'] ?? 'Contract',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(minWidth: 350),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text('Status:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('\t${contractData['status']}'),
                    const Divider(),
                    Text('Content:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(contractData['content'] ?? 'No content'),
                    const Divider(),
                    Text('Contractee Signature:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (contracteeSignaturePath != null && contracteeSignaturePath.isNotEmpty)
                      (contracteeSignaturePath).startsWith('http')
                        ? Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.network(
                              contracteeSignaturePath,
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text('No signature yet.'),
                            ),
                          )
                        : FutureBuilder<String?>(
                            future: getSignedUrl(contracteeSignaturePath),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                                );
                              }
                              final signedUrl = snapshot.data;
                              if (signedUrl == null) {
                                return const Text('No signature yet.');
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  signedUrl,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text('No signature yet.'),
                                ),
                              );
                            },
                          )
                    else
                      const Text('No signature yet.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                    Text('Contractor Signature:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (contractorSignaturePath != null && contractorSignaturePath.isNotEmpty)
                      contractorSignaturePath.startsWith('http')
                        ? Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                      child: Image.network(
                              contractorSignaturePath,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Could not load signature image'),
                      ),
                          )
                        : FutureBuilder<String?>(
                            future: getSignedUrl(contractorSignaturePath),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                                );
                              }
                              final signedUrl = snapshot.data;
                              if (signedUrl == null) {
                                return const Text('No signature yet.');
                              }
                              return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  signedUrl,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Text('No signature yet.'),
                                ),
                              );
                            },
                          )
                    else
                      const Text('No signature yet.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            actions: [
              if (isContractor && status == 'approved' && (contractorSignaturePath == null || (contractorSignaturePath as String).isEmpty)) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final SignatureController controller = SignatureController(
                              penStrokeWidth: 3,
                              penColor: Colors.black,
                            );
                            bool isSaving = false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Sign the Contract'),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.of(context).pop(),
                                        tooltip: 'Close',
                                      ),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: SizedBox(
                                      width: 350,
                                      child: UIContract.buildSignaturePad(
                                        controller: controller,
                                        height: 200,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton.icon(
                                      onPressed: isSaving
                                          ? null
                                          : () async {
                                              if (controller.isNotEmpty) {
                                                setState(() {
                                                  isSaving = true;
                                                });
                                                final signature = await controller.toPngBytes();
                                                try {
                                                  await ContractService.signContract(
                                                    contractId: contractId,
                                                    userId: currentUserId!,
                                                    signatureBytes: signature!,
                                                    userType: 'contractor',
                                                  );
                                                  Navigator.of(context).pop();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Signature saved!')),
                                                    );
                                                  }
                                                } catch (e) {
                                                  setState(() {
                                                    isSaving = false;
                                                  });
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to save signature')),
                                                    );
                                                  }
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Please provide a signature')),
                                                  );
                                                }
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
                                          : const Icon(Icons.save),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Sign the Contract'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ]
              else if (isContractee && status == 'approved' && (contracteeSignaturePath == null || (contracteeSignaturePath as String).isEmpty)) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final SignatureController controller = SignatureController(
                              penStrokeWidth: 3,
                              penColor: Colors.black,
                            );
                            bool isSaving = false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Sign the Contract'),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.of(context).pop(),
                                        tooltip: 'Close',
                                      ),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: SizedBox(
                                      width: 350,
                                      child: UIContract.buildSignaturePad(
                                        controller: controller,
                                        height: 200,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton.icon(
                                      onPressed: isSaving
                                          ? null
                                          : () async {
                                              if (controller.isNotEmpty) {
                                                setState(() {
                                                  isSaving = true;
                                                });
                                                final signature = await controller.toPngBytes();
                                                try {
                                                  await ContractService.signContract(
                                                    contractId: contractId,
                                                    userId: currentUserId!,
                                                    signatureBytes: signature!,
                                                    userType: 'contractee',
                                                  );
                                                  Navigator.of(context).pop();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Signature saved!')),
                                                    );
                                                  }
                                                } catch (e) {
                                                  setState(() {
                                                    isSaving = false;
                                                  }); 
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Failed to save signature')),
                                                    );
                                                  }
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Please provide a signature')),
                                                  );
                                                }
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
                                          : const Icon(Icons.save),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Sign the Contract'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ]
              else if (isContractee && status == 'sent') ...[
                TextButton.icon(
                  onPressed: () async {
                    await ContractService.updateContractStatus(
                      contractId: contractId,
                      status: 'rejected',
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contract rejected')),
                    );
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ContractService.updateContractStatus(
                      contractId: contractId,
                      status: 'approved',
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contract approved!')),
                    );
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ] else
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
            ],
          ),
        );
        _pollForActiveStatus(context, contractId, isContractor);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contract')),
        );
      }
    }
  }

  static Future<void> _pollForActiveStatus(
    BuildContext context,
    String contractId,
    bool isContractor,
    ) async {
  bool dialogShown = false;
  while (context.mounted && !dialogShown) {
    final contract = await ContractService.getContractById(contractId);
    if (contract['status'] == 'active') {
      dialogShown = true;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Project Started!'),
            content: const Text('The contract is now active. Do you want to go to the project management page?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => isContractor
                        ? CorOngoingProjectScreen(projectId: contract['project_id'])
                        : CeeOngoingProjectScreen(projectId: contract['project_id']),
                    ),
                  );
                },
                child: const Text('Go'),
              ),
            ],
          ),
        );
      }
      break;
    }
    await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Widget buildSignaturePad({
    required SignatureController controller,
    double height = 200,
    Color backgroundColor = const Color(0xFFE0E0E0),
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
                Icon(Icons.draw_rounded, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Draw your signature',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                border: Border.all(color: Colors.blue[200]!, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
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
                    backgroundColor: Colors.orange[400],
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
}



