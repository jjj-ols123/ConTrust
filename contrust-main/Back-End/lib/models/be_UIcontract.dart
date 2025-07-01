import 'package:backend/services/be_fetchservice.dart';
import 'package:flutter/material.dart';

class UIContract {
  
  static Future<Map<String, dynamic>?> showSaveDialog(
      BuildContext context, String contractorId) async {
    final titleController = TextEditingController();
    String? selectedProjectId;

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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text(
                              'No projects found. Create a project first.');
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedProjectId,
                          decoration: const InputDecoration(
                            labelText: 'Select Project *',
                            border: OutlineInputBorder(),
                          ),
                          items: snapshot.data!
                              .map((project) => DropdownMenuItem<String>(
                                    value: project['project_id'],
                                    child: Text(
                                      project['description'] ??
                                          'No Description',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
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
                      'title': titleController.text,
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

  static Future<Map<String, dynamic>?> showSendDialog(BuildContext context) async {
    final messageController = TextEditingController();
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Send Contract to Client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will send the contract to the client for review and approval.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message to Client (Optional)',
                    hintText: 'Add any notes or instructions for the client...',
                    border: OutlineInputBorder(),
                  ),
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
                Navigator.of(dialogContext).pop({
                  'message': messageController.text,
                  'send': true,
                });
              },
              child: const Text('Send Contract'),
            ),
          ],
        );
      },
    );
  }

  static Future<Map<String, dynamic>?> showStatusUpdateDialog(
      BuildContext context, 
      String currentStatus,
      {bool isContractee = false}) async {
    final notesController = TextEditingController();
    String? selectedStatus = currentStatus;
    
    // Define available status transitions
    List<String> availableStatuses = [];
    if (isContractee) {
      // Contractee can approve, reject, or request changes
      if (currentStatus == 'sent') {
        availableStatuses = ['under_review', 'approved', 'rejected'];
      } else if (currentStatus == 'under_review') {
        availableStatuses = ['approved', 'rejected'];
      }
    } else {
      // Contractor can send or withdraw
      if (currentStatus == 'draft') {
        availableStatuses = ['sent'];
      } else if (currentStatus == 'sent') {
        availableStatuses = ['draft']; // Withdraw
      }
    }
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isContractee ? 'Review Contract' : 'Update Contract Status'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (availableStatuses.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: availableStatuses.map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status.replaceAll('_', ' ').toUpperCase()),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isContractee ? 'Review Notes (Optional)' : 'Notes (Optional)',
                        hintText: isContractee 
                          ? 'Add your feedback or concerns...'
                          : 'Add any notes...',
                        border: const OutlineInputBorder(),
                      ),
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
                    Navigator.of(dialogContext).pop({
                      'status': selectedStatus,
                      'notes': notesController.text,
                    });
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

