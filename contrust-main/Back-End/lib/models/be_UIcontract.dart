// ignore_for_file: deprecated_member_use

import 'package:backend/services/be_contract_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';

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
                      future: ContractService.getContractorProjectInfo(contractorId),
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

  static Future<void> viewContract(
      BuildContext context, String contractId) async {
    try {
      final contractData = await ContractService.getContractById(contractId);
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final isContractee = contractData['contractee_id'] == currentUserId;
      final status = contractData['status'];

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
                    Text('${contractData['status']}'),
                    const Divider(),
                    Text('Content:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(contractData['content'] ?? 'No content'),
                    const Divider(),
                    if (contractData['contractee_signature_url'] != null &&
                        (contractData['contractee_signature_url'] as String).isNotEmpty) ...[
                      Text('Contractee Signature:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          contractData['contractee_signature_url'],
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('Could not load signature image'),
                        ),
                      ),
                    ] else ...[
                      const Text('No signature yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (isContractee && status == 'sent') ...[
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
              ] else if (isContractee && status == 'approved') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final SignatureController _controller = SignatureController(
                          penStrokeWidth: 3,
                          penColor: Colors.black,
                        );
                        return StatefulBuilder(
                          builder: (context, setState) {
                            bool isSaving = false;
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
                              content: UIContract.buildSignaturePad(
                                controller: _controller,
                              ),
                              actions: [
                                ElevatedButton.icon(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          if (_controller.isNotEmpty) {
                                            setState(() => isSaving = true);
                                            final signature = await _controller.toPngBytes();
                                            try {
                                              await ContractService.signContract(
                                                contractId: contractId,
                                                userId: currentUserId!,
                                                signatureBytes: signature!,
                                              );
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Signature saved!')),
                                              );
                                            } catch (e) {
                                              setState(() => isSaving = false);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Failed to save signature')),
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
              ] else
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contract')),
        );
      }
    }
  }

  static Widget buildSignaturePad({
    required SignatureController controller,
    double height = 200,
    Color backgroundColor = const Color(0xFFE0E0E0),
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Signature(
            controller: controller,
            height: height,
            backgroundColor: backgroundColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.refresh),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}



