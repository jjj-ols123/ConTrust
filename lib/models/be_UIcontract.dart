// ignore_for_file: deprecated_member_use

import 'package:backend/services/be_contract_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            title: Text(contractData['title'] ?? 'Contract'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Status: ${contractData['status']}'),
                  const SizedBox(height: 8),
                  Text('Content:'),
                  const SizedBox(height: 4),
                  Text(contractData['content'] ?? 'No content'),
                ],
              ),
            ),
            actions: [
              if (isContractee && status == 'sent') ...[
                TextButton(
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
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Accept'),
                ),
              ] else
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
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
}

