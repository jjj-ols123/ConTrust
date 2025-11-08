// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_pdfextract.dart';
import 'package:backend/utils/be_contractformat.dart';
import 'package:backend/contract_templates/TimeandMaterials.dart';
import 'package:backend/contract_templates/CostPlus.dart';
import 'package:backend/contract_templates/LumpSum.dart';
import 'package:go_router/go_router.dart';

class CreateContractBuild {
  static Widget buildHeader(BuildContext context, {required String title, required List<Widget> actions}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.amber.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.create, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            )
          : Row(
              children: [
                Icon(Icons.create, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                ...actions,
              ],
            ),
    );
  }

  static Widget buildFormContainer(Widget child) {
    return Expanded(child: child);
  }

  static Widget buildPreviewContainer(Widget preview) {
    return Expanded(child: preview);
  }

  static Future<Map<String, dynamic>?> showProjectSelectionDialog(
    BuildContext context,
    String contractorId, {
    String? initialProjectId,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // User must select a project or cancel
      builder: (BuildContext dialogContext) {
        String? selectedProjectId = initialProjectId;
        List<Map<String, dynamic>> projects = [];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load projects if not loaded yet
            if (projects.isEmpty) {
              FetchService().fetchContractorProjectInfo(contractorId).then((fetchedProjects) {
                setDialogState(() {
                  projects = fetchedProjects;
                  // Auto-select if only one project
                  if (projects.length == 1 && selectedProjectId == null) {
                    selectedProjectId = projects.first['project_id'] as String?;
                  }
                });
              });
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
                              Icons.folder_open,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Select Project",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose a project to create a contract for:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (projects.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: selectedProjectId,
                              decoration: InputDecoration(
                                labelText: 'Select Project',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              items: projects.map((project) {
                                final projectId = project['project_id'] as String?;
                                final title = project['title'] as String? ?? 'Untitled Project';
                                return DropdownMenuItem<String>(
                                  value: projectId,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  selectedProjectId = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a project';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(); // Close dialog
                                  // Navigate back to contract types page
                                  if (context.mounted) {
                                    context.go('/contracttypes');
                                  }
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: selectedProjectId != null && selectedProjectId!.isNotEmpty
                                    ? () {
                                        Navigator.of(dialogContext).pop({
                                          'projectId': selectedProjectId,
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Continue'),
                              ),
                            ],
                          ),
                        ],
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

static Future<Map<String, dynamic>?> showSaveDialog(
    BuildContext context,
    String contractorId, {
    TextEditingController? titleController,
    String? initialProjectId,
  }) async {
    titleController ??= TextEditingController();
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
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
                          Icons.save,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Save Contract',
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
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Contract Title',
                            border: OutlineInputBorder(),
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
                                onPressed: () {
                                  if (titleController?.text.trim().isEmpty == true || initialProjectId == null) {
                                    ConTrustSnackBar.error(context, 'Please fill all fields');
                                    return;
                                  }
                                  Navigator.of(dialogContext).pop({
                                    'title': titleController?.text.trim() ?? '',
                                    'projectId': initialProjectId,
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Save'),
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
  }
}



class CreateContractBuildMethods {
  CreateContractBuildMethods({
    required this.context,
    required this.contractFields,
    required this.controllers,
    required this.formKey,
    required this.contractorId,
    required this.isLoadingProject,
    required this.initialProjectId,
    required this.projectData,
    required this.onProjectChanged,
    this.selectedTemplate,
    this.selectedContractTypeName,
    this.onContractTypeChanged,
    this.onItemCountChanged,
    this.onMilestoneCountChanged,
    this.onCalculationTriggered,
  });

  final BuildContext context;
  final List<dynamic> contractFields;
  final Map<String, TextEditingController> controllers;
  final GlobalKey<FormState> formKey;
  final String contractorId;
  final bool isLoadingProject;
  final String? initialProjectId;
  final Map<String, dynamic>? projectData;
  final void Function(String?) onProjectChanged;
  final Map<String, dynamic>? selectedTemplate;
  final String? selectedContractTypeName;
  final void Function(Map<String, dynamic>?)? onContractTypeChanged;
  final void Function(int)? onItemCountChanged;
  final void Function(int)? onMilestoneCountChanged;
  final VoidCallback? onCalculationTriggered;

  Widget buildForm() {
    return Form(
      key: formKey,
      child: ScrollConfiguration(
        behavior: const _NoGlowScrollBehavior(),
        child: SingleChildScrollView(
          key: const PageStorageKey('create_contract_form_scroll'),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...buildFormFields(),
          ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildFormFields() {
    if (contractFields.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please Select a Contract Template',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a contract template above to see the specific fields for that contract type. Each template has its own set of required fields.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Contract Types:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Lump Sum - Fixed price contracts with milestone payments\n'
                        '• Cost-Plus - Cost reimbursement with contractor fee\n'
                        '• Time and Materials - Hourly rates with dynamic item tracking',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    List<Widget> widgets = [];

    final dateFields = contractFields.where((f) {
      final key = (f as dynamic).key as String;
      return key == 'Contract.CreationDate';
    }).toList();    final contracteeFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Contractee.')
    ).toList();
    
    final contractorFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Contractor.')
    ).toList();
    
    final projectFields = contractFields.where((f) {
      final key = (f as dynamic).key as String;
      return key.contains('Project.') ||
        key.contains('Materials.');
    }).toList();
    
    final itemFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Item.')
    ).toList();
    
    final milestoneFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Milestone.') &&
      (f as dynamic).key.split('.').length == 3
    ).toList();
    
    final paymentFields = contractFields.where((f) =>
      (f as dynamic).key.contains('Payment.') ||
      (f as dynamic).key.contains('Labor.Costs') ||
      (f as dynamic).key.contains('Material.Costs') ||
      (f as dynamic).key.contains('Equipment.Costs') ||
      (f as dynamic).key.contains('Overhead.Percentage') ||
      (f as dynamic).key.contains('Estimated.Total') ||
      (f as dynamic).key.contains('Payment.Interval') ||
      (f as dynamic).key.contains('Retention.Fee') ||
      (f as dynamic).key.contains('Late.Fee.Percentage')
    ).toList();

    final milestonePaymentFields = contractFields.where((f) =>
      (f as dynamic).key.contains('Payment.ProgressPayment') ||
      (f as dynamic).key.contains('Payment.Milestone') ||
      (f as dynamic).key.contains('Payment.FinalPaymentPercentage')
    ).toList();
    final regularPaymentFields = paymentFields.where((f) =>
      !(f as dynamic).key.contains('Payment.ProgressPayment') &&
      !(f as dynamic).key.contains('Payment.Milestone') &&
      !(f as dynamic).key.contains('Payment.FinalPaymentPercentage')
    ).toList();    final bondFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Bond.')
    ).toList();
    
    final insuranceFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Insurance.') ||
      (f as dynamic).key.contains('Inspection.')
    ).toList();
    
    final changeOrderFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Change.')
    ).toList();
    
    final legalFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Notice.') ||
      (f as dynamic).key.contains('Warranty.') ||
      (f as dynamic).key.contains('Penalty.') ||
      (f as dynamic).key.contains('Tax.')
    ).toList();

    if (dateFields.isNotEmpty) {
      widgets.add(buildSectionCard('Contract Information', dateFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (contracteeFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Contractee Information', contracteeFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (contractorFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Contractor Information', contractorFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (projectFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Project Information', projectFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (itemFields.isNotEmpty) {
      bool isTimeAndMaterials = itemFields.any((f) =>
        (f as dynamic).key.contains('Item.') &&
        (f as dynamic).key.contains('.Name')
      );      if (isTimeAndMaterials) {
        widgets.add(buildTimeAndMaterialsItemCard('Project Items', itemFields));
      } else {
        widgets.add(buildSectionCard('Project Items', itemFields));
      }
      widgets.add(const SizedBox(height: 16));
    }
    
    if (milestoneFields.isNotEmpty) {
      widgets.add(buildMilestoneCard('Project Milestones', milestoneFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (milestonePaymentFields.isNotEmpty) {
      widgets.add(buildMilestonePaymentCard('Payment Schedule & Milestones', milestonePaymentFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (regularPaymentFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Payment Information', regularPaymentFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (bondFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Bond Information', bondFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (insuranceFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Insurance & Inspection', insuranceFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (changeOrderFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Change Orders', changeOrderFields));
      widgets.add(const SizedBox(height: 16));
    }
    
    if (legalFields.isNotEmpty) {
      widgets.add(buildTwoColumnSectionCard('Legal & Other Information', legalFields));
    }

    return widgets;
  }

  Widget buildSectionCard(String title, List<dynamic> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
          const SizedBox(height: 16),
          ...fields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildFormField(field),
            );
          }),
        ]),
      ),
    );
  }

  Widget buildTimeAndMaterialsItemCard(String title, List<dynamic> fields) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700; 
    
    Map<int, Map<String, dynamic>> itemGroups = {};

    for (var field in fields) {
      final f = field as dynamic;
      final key = f.key as String;

      final parts = key.split('.');
      if (parts.length >= 3 && parts[0] == 'Item') {
        final itemNumber = int.tryParse(parts[1]);
        final fieldType = parts[2];

        if (itemNumber != null) {
          itemGroups[itemNumber] ??= {};
          itemGroups[itemNumber]![fieldType] = f;
        }
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _addNewItem(),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isMobile ? 'Add' : 'Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Price (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(flex: 2, child: Text('Subtotal (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              ...itemGroups.entries.map((entry) {
                final itemNumber = entry.key;
                final itemFields = entry.value;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade400),
                      right: BorderSide(color: Colors.grey.shade400),
                      bottom: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: buildFormField(itemFields['Name'])),
                      const SizedBox(width: 8),
                      Expanded(flex: 4, child: buildFormField(itemFields['Description'])),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: buildFormField(itemFields['Price'])),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: buildFormField(itemFields['Quantity'])),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: buildFormField(itemFields['Subtotal'])),
                      const SizedBox(width: 8),
                      if (itemGroups.length > 1)
                        IconButton(
                          onPressed: () => _removeItem(itemNumber),
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          tooltip: 'Remove Item',
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                );
              }),
            ],

            if (isMobile)
              ...itemGroups.entries.map((entry) {
                final itemNumber = entry.key;
                final itemFields = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Item #$itemNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                          if (itemGroups.length > 1)
                            IconButton(
                              onPressed: () => _removeItem(itemNumber),
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                              tooltip: 'Remove Item',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildFormField(itemFields['Name']),
                      const SizedBox(height: 12),
                      buildFormField(itemFields['Description']),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: buildFormField(itemFields['Price'])),
                          const SizedBox(width: 8),
                          Expanded(child: buildFormField(itemFields['Quantity'])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildFormField(itemFields['Subtotal']),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addNewItem() {
    int currentItemCount = _getCurrentItemCount();

    if (onItemCountChanged != null) {
      onItemCountChanged!(currentItemCount + 1);
    }
  }

  void _removeItem(int itemNumber) {
    int currentItemCount = _getCurrentItemCount();

    if (currentItemCount > 1) {
      if (onItemCountChanged != null) {
        onItemCountChanged!(currentItemCount - 1);
      }
    } else {
      ConTrustSnackBar.error(context, 'Cannot remove the last item. At least one item is required.');
    }
  }

  int _getCurrentItemCount() {
    int maxItemNumber = 0;

    for (var field in contractFields) {
      final f = field as dynamic;
      final key = f.key as String;

      if (key.startsWith('Item.') && key.endsWith('.Name')) {
        final parts = key.split('.');
        if (parts.length >= 3) {
          final itemNumber = int.tryParse(parts[1]) ?? 0;
          if (itemNumber > maxItemNumber) {
            maxItemNumber = itemNumber;
          }
        }
      }
    }    return maxItemNumber;
  }

  void _addNewMilestone() {
    int currentMilestoneCount = _getCurrentMilestoneCount();

    if (onMilestoneCountChanged != null) {
      onMilestoneCountChanged!(currentMilestoneCount + 1);
    }
  }

  void _removeMilestone(int milestoneNumber) {
    int currentMilestoneCount = _getCurrentMilestoneCount();

    if (currentMilestoneCount > 1) {
      if (onMilestoneCountChanged != null) {
        onMilestoneCountChanged!(currentMilestoneCount - 1);
      }
    } else {
      ConTrustSnackBar.error(context, 'Cannot remove the last milestone. At least one milestone is required.');
    }
  }

  int _getCurrentMilestoneCount() {
    int maxMilestoneNumber = 0;

    for (var field in contractFields) {
      final f = field as dynamic;
      final key = f.key as String;

      if (key.startsWith('Milestone.') && key.endsWith('.Description')) {
        final parts = key.split('.');
        if (parts.length >= 3) {
          final milestoneNumber = int.tryParse(parts[1]) ?? 0;
          if (milestoneNumber > maxMilestoneNumber) {
            maxMilestoneNumber = milestoneNumber;
          }
        }
      }
    }    
    return maxMilestoneNumber;
  }

  Widget buildMilestoneCard(String title, List<dynamic> fields) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700; 
    
    Map<int, Map<String, dynamic>> milestoneGroups = {};

    for (var field in fields) {
      final f = field as dynamic;
      final key = f.key as String;

      final parts = key.split('.');
      if (parts.length >= 3 && parts[0] == 'Milestone') {
        final milestoneNumber = int.tryParse(parts[1]);
        final fieldType = parts[2];

        if (milestoneNumber != null) {
          milestoneGroups[milestoneNumber] ??= {};
          milestoneGroups[milestoneNumber]![fieldType] = f;
        }
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _addNewMilestone(),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isMobile ? 'Add' : 'Add Milestone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Duration (days)', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Target Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Payment Amount (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              ...milestoneGroups.entries.map((entry) {
                final milestoneNumber = entry.key;
                final milestoneFields = entry.value;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade400),
                      right: BorderSide(color: Colors.grey.shade400),
                      bottom: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 2, child: buildFormField(milestoneFields['Description'])),
                      const SizedBox(width: 16),
                      Expanded(child: buildFormField(milestoneFields['Duration'])),
                      const SizedBox(width: 16),
                      Expanded(child: buildFormField(milestoneFields['Date'])),
                      const SizedBox(width: 16),
                      Expanded(child: buildFormField(milestoneFields['Amount'])),
                      const SizedBox(width: 8),
                      if (milestoneGroups.length > 1)
                        IconButton(
                          onPressed: () => _removeMilestone(milestoneNumber),
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          tooltip: 'Remove Milestone',
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                );
              }),
            ],

            if (isMobile)
              ...milestoneGroups.entries.map((entry) {
                final milestoneNumber = entry.key;
                final milestoneFields = entry.value;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Milestone $milestoneNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (milestoneGroups.length > 1)
                              IconButton(
                                onPressed: () => _removeMilestone(milestoneNumber),
                                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                tooltip: 'Remove Milestone',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buildFormField(milestoneFields['Description']),
                        const SizedBox(height: 12),
                        buildFormField(milestoneFields['Duration']),
                        const SizedBox(height: 12),
                        buildFormField(milestoneFields['Date']),
                        const SizedBox(height: 12),
                        buildFormField(milestoneFields['Amount']),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildMilestonePaymentCard(String title, List<dynamic> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...buildMilestonePaymentGroups(fields),
          ],
        ),
      ),
    );
  }

  List<Widget> buildMilestonePaymentGroups(List<dynamic> fields) {
    List<Widget> widgets = [];

    final downPaymentField = fields.where((f) =>
      (f as dynamic).key.contains('Payment.DownPaymentPercentage')
    ).toList();

    final progressPayment1Field = fields.where((f) =>
      (f as dynamic).key.contains('Payment.ProgressPayment1Percentage')
    ).toList();
    final milestone1Field = fields.where((f) =>
      (f as dynamic).key.contains('Payment.Milestone1')
    ).toList();

    final progressPayment2Field = fields.where((f) =>
      (f as dynamic).key.contains('Payment.ProgressPayment2Percentage')
    ).toList();
    final milestone2Field = fields.where((f) =>
      (f as dynamic).key.contains('Payment.Milestone2')
    ).toList();

    final finalPaymentField = fields.where((f) =>
      (f as dynamic).key.contains('Payment.FinalPaymentPercentage')
    ).toList();
    if (downPaymentField.isNotEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Down Payment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              buildFormField(downPaymentField.first),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    if (progressPayment1Field.isNotEmpty && milestone1Field.isNotEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Payment 1',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildFormField(progressPayment1Field.first)),
                  const SizedBox(width: 16),
                  Expanded(child: buildFormField(milestone1Field.first)),
                ],
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    if (progressPayment2Field.isNotEmpty && milestone2Field.isNotEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Payment 2',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildFormField(progressPayment2Field.first)),
                  const SizedBox(width: 16),
                  Expanded(child: buildFormField(milestone2Field.first)),
                ],
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    if (finalPaymentField.isNotEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Final Payment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              buildFormField(finalPaymentField.first),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget buildTwoColumnSectionCard(String title, List<dynamic> fields) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useSingleColumn = screenWidth < 700; 
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            useSingleColumn
                ? Column(
                    children: fields.map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: buildFormField(field),
                      );
                    }).toList(),
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            children: buildLeftColumnFields(fields),
                          ),
                        ),
                        Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: buildRightColumnFields(fields),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildLeftColumnFields(List<dynamic> fields) {
    List<Widget> leftFields = [];
    
    for (int i = 0; i < fields.length; i += 2) {
      leftFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: buildFormField(fields[i]),
        ),
      );
    }
    
    return leftFields;
  }

  List<Widget> buildRightColumnFields(List<dynamic> fields) {
    List<Widget> rightFields = [];
    
    for (int i = 1; i < fields.length; i += 2) {
      rightFields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: buildFormField(fields[i]),
        ),
      );
    }
    
    if (fields.length % 2 == 1) {
      rightFields.add(const SizedBox(height: 60));
    }
    
    return rightFields;
  }

  Widget buildFormField(dynamic field) {
    final f = field as dynamic;
    final key = f.key as String;
    final label = f.label as String;
    final placeholder = (f.placeholder as String?) ?? '';
    final inputType = (f.inputType as TextInputType?) ?? TextInputType.text;
    final isRequired = (f.isRequired as bool?) ?? false;
    final maxLines = (f.maxLines as int?) ?? 1;
    final isEnabled = (f.isEnabled as bool?) ?? true;
    
    final isDateField = key.contains('Date') && !key.contains('Duration');
    
    final isProjectDurationField = key == 'Project.Duration';
    final effectivelyEnabled = isProjectDurationField ? false : isEnabled;
    
    if (isDateField && effectivelyEnabled) {
      return GestureDetector(
        onTap: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 3650)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.blue.shade600,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
            controllers[key]?.text = formattedDate;
            
            if (key.contains('StartDate') || key.contains('CompletionDate')) {
              _calculateDuration();
            }
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: controllers[key],
            decoration: InputDecoration(
              labelText: isRequired ? '$label *' : label,
              hintText: placeholder.isEmpty ? 'Enter ${label.toLowerCase()}' : placeholder,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
              fillColor: Colors.white,
            ),
            validator: isRequired 
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
          ),
        ),
      );
    }
    
    return TextFormField(
      controller: controllers[key],
      enabled: effectivelyEnabled,
      scrollPadding: const EdgeInsets.only(bottom: 80),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: placeholder.isEmpty ? 'Enter ${label.toLowerCase()}' : placeholder,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        prefixIcon: ContractStatus().getFieldIcon(key),
        fillColor: effectivelyEnabled ? null : Colors.grey.shade100,
        filled: !effectivelyEnabled,
      ),
      keyboardType: inputType,
      maxLines: maxLines,
      inputFormatters: inputType == TextInputType.number
          ? (_allowsDecimal(key)
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))]
              : [FilteringTextInputFormatter.digitsOnly])
          : null,
      validator: isRequired 
        ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          }
        : null,
      onChanged: (value) {
        if (key.contains('.Price') || key.contains('.Quantity') || key.contains('Payment.Discount') || key.contains('Payment.Tax')) {
          _triggerCalculation();
        }
      },
    );
  }

  bool _allowsDecimal(String key) {
    final k = key.toLowerCase();
    return k.contains('price') ||
        k.contains('amount') ||
        k.contains('rate') ||
        k.contains('percentage') ||
        k.contains('subtotal') ||
        k.contains('total') ||
        k.contains('tax') ||
        k.contains('fee');
  }

  void _triggerCalculation() {
    if (onCalculationTriggered != null) {
      onCalculationTriggered!();
    }
  }

  void _calculateDuration() {
    try {
      final startDateStr = controllers['Project.StartDate']?.text ?? '';
      final completionDateStr = controllers['Project.CompletionDate']?.text ?? '';
      
      if (startDateStr.isNotEmpty && completionDateStr.isNotEmpty) {
        final startDate = DateTime.parse(startDateStr);
        final completionDate = DateTime.parse(completionDateStr);
        final duration = completionDate.difference(startDate).inDays;
        
        if (duration >= 0) {
          controllers['Project.Duration']?.text = duration.toString();
        }
      }
    } catch (e) {
      //Error
    }
  }

  Widget buildPreview() {
    final String contractType = (selectedTemplate?['template_name'] as String?) ?? (selectedContractTypeName ?? '');

    bool shouldShowItemRow(int rowNumber) {
      final descKey = 'Item.$rowNumber.Description';
      final quantityKey = 'Item.$rowNumber.Quantity';
      // Support both UnitRate (legacy) and Price (current)
      final priceKey1 = 'Item.$rowNumber.UnitRate';
      final priceKey2 = 'Item.$rowNumber.Price';

      bool has(String key) => controllers.containsKey(key) && controllers[key]!.text.trim().isNotEmpty;
      return has(descKey) || has(quantityKey) || has(priceKey1) || has(priceKey2);
    }
    ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
    
    bool shouldShowMilestoneRow(int rowNumber) {
      final descKey = 'Milestone.$rowNumber.Description';
      final durationKey = 'Milestone.$rowNumber.Duration';
      final dateKey = 'Milestone.$rowNumber.Date';

      return (controllers.containsKey(descKey) && controllers[descKey]!.text.trim().isNotEmpty) ||
             (controllers.containsKey(durationKey) && controllers[durationKey]!.text.trim().isNotEmpty) ||
             (controllers.containsKey(dateKey) && controllers[dateKey]!.text.trim().isNotEmpty);
    }
    ContractStyle.setMilestoneRowVisibilityChecker((int rowNum) => shouldShowMilestoneRow(rowNum));

    String resolvePlaceholders(String input) {
      final Map<String, String> tokenToKey = {  
        'Contract.CreationDate': 'Contract.CreationDate',
        'Contractor.Company': 'Contractor.Company',
        'Contractor.FirstName': 'Contractor.FirstName',
        'Contractor.LastName': 'Contractor.LastName',
        'Contractor.Address': 'Contractor.Address',
        'Contractor.Phone': 'Contractor.Phone',
        'Contractor.Email': 'Contractor.Email',
        'Contractor.Province': 'Contractor.Province',
        'Contractee.FirstName': 'Contractee.FirstName',
        'Contractee.LastName': 'Contractee.LastName',
        'Contractee.Address': 'Contractee.Address',
        'Contractee.Phone': 'Contractee.Phone',
        'Contractee.Email': 'Contractee.Email',
        'Project.Description': 'Project.Description',
        'Project.Address': 'Project.Address',
        'Project.StartDate': 'Project.StartDate',
        'Project.CompletionDate': 'Project.CompletionDate',
        'Project.Duration': 'Project.Duration',
        'Project.WorkingDays': 'Project.WorkingDays',
        'Project.WorkingHours': 'Project.WorkingHours',
        'Payment.Total': 'Payment.Total',
        'Payment.DownPaymentPercentage': 'Payment.DownPaymentPercentage',
        'Payment.DownPayment': 'Payment.DownPayment',
        'Payment.ProgressPayments': 'Payment.ProgressPayments',
        'Payment.FinalPayment': 'Payment.FinalPayment',
        'Payment.RetentionPercentage': 'Payment.RetentionPercentage',
        'Payment.RetentionAmount': 'Payment.RetentionAmount',
        'Payment.RetentionPeriod': 'Payment.RetentionPeriod',
        'Payment.DueDays': 'Payment.DueDays',
        'Payment.LateFeePercentage': 'Payment.LateFeePercentage',
        'Bond.TimeFrame': 'Bond.TimeFrame',
        'Bond.PerformanceAmount': 'Bond.PerformanceAmount',
        'Bond.PaymentAmount': 'Bond.PaymentAmount',
        'Change.LaborRate': 'Change.LaborRate',
        'Change.MaterialMarkup': 'Change.MaterialMarkup',
        'Change.EquipmentMarkup': 'Change.EquipmentMarkup',
        'Notice.Period': 'Notice.Period',
        'Warranty.Period': 'Warranty.Period',
        'Labor.Costs': 'Labor.Costs',
        'Material.Costs': 'Material.Costs',
        'Equipment.Costs': 'Equipment.Costs',
        'Overhead.Percentage': 'Overhead.Percentage',
        'Estimated.Total': 'Estimated.Total',
        'Payment.Interval': 'Payment.Interval',
        'Retention.Fee': 'Retention.Fee',
        'Late.Fee.Percentage': 'Late.Fee.Percentage',
        
        'First name of the contractee': 'Contractee.FirstName',
        'Last name of the contractee': 'Contractee.LastName',
        'Contractee street address': 'Contractee.Address',
        'Contractee city': 'Contractee.City',
        'Contractee postal code': 'Contractee.PostalCode',
        'First name of the contractor': 'Contractor.FirstName',
        'Last name of the contractor': 'Contractor.LastName',
        'Contractor street address': 'Contractor.Address',
        'Contractor city': 'Contractor.City',
        'Contractor postal code': 'Contractor.PostalCode',
        'Contractor company name': 'Contractor.Company',
        'Contractor firm or company name': 'Contractor.Company',
        'Your Construction Company\'s Name': 'Contractor.Company',
        'Contractor license number': 'Contractor.License',
        'Contractor phone number': 'Contractor.Phone',
        'Contractor province': 'Contractor.Province',
        'Date of contract creation': 'Contract.CreationDate',
        'Project description as defined by the contractor': 'Project.ContractorDef',
        'Estimated labor hours': 'Project.LaborHours',
        'Project duration': 'Project.Duration',
        'Project duration in days': 'Project.Duration',
        'Estimated completion date': 'Project.CompletionDate',
        'Start date of the project': 'Project.StartDate',
        'Project schedule': 'Project.Schedule',
        'List of project milestones': 'Project.MilestonesList',
        'Project address': 'Project.Address',
        'Project site address': 'Project.Address',
        'Legal description of property': 'Project.LegalDescription',
        'Property description': 'Project.PropertyDescription',
        'Project scope of work': 'Project.ScopeOfWork',
        'List of required materials': 'Materials.List',
        'Scope of work': 'Project.Scope',
        'Applicable taxes': 'Tax.List',
        'Maximum penalty amount': 'Penalty.Amount',
        'Total contract price': 'Payment.Total',
        'Total contract price (legacy)': 'Payment.TotalAmount',
        'Payment method': 'Payment.Method',
        'Performance bond amount': 'Bond.PerformanceAmount',
        'Payment bond amount': 'Bond.PaymentAmount',
        'Number of days to submit bonds': 'Bond.SubmitDays',
        'Insurance requirements': 'Insurance.Requirements',
        'Minimum insurance amount': 'Insurance.MinimumAmount',
        'Termination notice period in days': 'Contract.TerminationDays',
        'Warranty period in months': 'Contract.WarrantyMonths',
        'Number of days to commence work': 'Project.CommenceDays',
        'List of work': 'Project.Scope',
        'Time': 'Project.LaborHours',
        'Materials': 'Materials.List',
        'Subtotal amount': 'Payment.Subtotal',
        'Discount amount': 'Payment.DiscountAmount',
        'Tax amount': 'Payment.TaxAmount',
        'Total amount': 'Payment.Total',
        'Item 1 name': 'Item.1.Name',
        'Item 1 description': 'Item.1.Description',
        'Item 1 price': 'Item.1.Price',
        'Item 1 quantity': 'Item.1.Quantity',
        'Item 1 subtotal': 'Item.1.Subtotal',
        'Item 2 name': 'Item.2.Name',
        'Item 2 description': 'Item.2.Description',
        'Item 2 price': 'Item.2.Price',
        'Item 2 quantity': 'Item.2.Quantity',
        'Item 2 subtotal': 'Item.2.Subtotal',
        'Item 3 name': 'Item.3.Name',
        'Item 3 description': 'Item.3.Description',
        'Item 3 price': 'Item.3.Price',
        'Item 3 quantity': 'Item.3.Quantity',
        'Item 3 subtotal': 'Item.3.Subtotal',
        'Item 4 name': 'Item.4.Name',
        'Item 4 description': 'Item.4.Description',
        'Item 4 price': 'Item.4.Price',
        'Item 4 quantity': 'Item.4.Quantity',
        'Item 4 subtotal': 'Item.4.Subtotal',
        'Item 5 name': 'Item.5.Name',
        'Item 5 description': 'Item.5.Description',
        'Item 5 price': 'Item.5.Price',
        'Item 5 quantity': 'Item.5.Quantity',
        'Item 5 subtotal': 'Item.5.Subtotal',
        'Progress payment 1 percentage': 'Payment.ProgressPayment1Percentage',
        'Progress payment 2 percentage': 'Payment.ProgressPayment2Percentage',
        'Final payment percentage': 'Payment.FinalPaymentPercentage',
        'Milestone 1 description': 'Payment.Milestone1',
        'Milestone 2 description': 'Payment.Milestone2',
        'Retention fee percentage': 'Payment.RetentionFeePercentage',
        'Retention fee amount': 'Payment.RetentionFeeAmount',
        'Labor costs': 'Cost.Labor',
        'Material costs': 'Cost.Materials',
        'Equipment costs': 'Cost.Equipment',
        'Estimated total cost': 'Cost.Total',
        'Overhead percentage': 'Cost.OverheadPercentage',
        'Late fee percentage': 'Cost.LateFeePercentage',
        'Number of days to make payment': 'Payment.DueDays',
        'Inspection period in days': 'Inspection.PeriodDays',
        'List of licenses or permits': 'Licenses.List',
        'List of insurance policies': 'Insurance.List',
        'List of bonds': 'Bonds.List',
        'Project legal description': 'Project.LegalDescription',
        'Specification': 'Project.Specification',
      };

      String out = input;
      final reg = RegExp(r'\[(.*?)\]|\{(.*?)\}', caseSensitive: false);
      out = out.replaceAllMapped(reg, (m) {

        final token = (m.group(1) ?? m.group(2) ?? '').trim();
        if (token.isEmpty) return m.group(0)!;
        

        final key = tokenToKey[token];
        if (key != null && controllers.containsKey(key)) {
          final v = controllers[key]!.text.trim();
          if (v.isNotEmpty) return v;
        }
        
        String? caseInsensitiveKey;
        tokenToKey.forEach((k, v) {
          if (k.toLowerCase() == token.toLowerCase()) {
            caseInsensitiveKey = v;
          }
        });
        if (caseInsensitiveKey != null && controllers.containsKey(caseInsensitiveKey)) {
          final v = controllers[caseInsensitiveKey]!.text.trim();
          if (v.isNotEmpty) return v;
        }
        

        if (controllers.containsKey(token)) {
          final v = controllers[token]!.text.trim();
          if (v.isNotEmpty) return v;
        }
        
        if (token.startsWith('Milestone.') && token.split('.').length == 3) {
          final parts = token.split('.');
          final milestoneNum = int.tryParse(parts[1]);
          final field = parts[2];
          if (milestoneNum != null) {
            final key = 'Milestone.$milestoneNum.$field';
            if (controllers.containsKey(key)) {
              final v = controllers[key]!.text.trim();
              if (v.isNotEmpty) return v;
            }
          }
        }
        
        if (token.toLowerCase().contains('item') && 
            (token.toLowerCase().contains('description') || 
             token.toLowerCase().contains('quantity') || 
             token.toLowerCase().contains('rate') || 
             token.toLowerCase().contains('amount') ||
             token.toLowerCase().contains('price') ||
             token.toLowerCase().contains('subtotal'))) {
          final parts = token.split(' ');
          if (parts.length >= 3) {
            final itemNum = int.tryParse(parts[1]);
            final prop = parts.sublist(2).join(' ');
            if (itemNum != null) {
              final candidates = [
                'Item.$itemNum.$prop',
                'Item.$itemNum.${prop.replaceAll(' ', '')}',
                'Item.$itemNum.Name',
                'Item.$itemNum.Description',
                'Item.$itemNum.Price',
                'Item.$itemNum.Quantity',
                'Item.$itemNum.Subtotal',
              ];
              for (var c in candidates) {
                if (controllers.containsKey(c)) {
                  final v = controllers[c]!.text.trim();
                  if (v.isNotEmpty) return v;
                }
              }
            }
          }
        }

        final tkn = token.toLowerCase();
        if (tkn == 'subtotal amount' || tkn == 'subtotal' || tkn == 'payment.subtotal') {
          double subtotal = 0.0;
          controllers.forEach((k, ctrl) {
            final m = RegExp(r'^Item\.(\d+)\.(Subtotal|Amount|subtotal|amount)\b').firstMatch(k);
            if (m != null) {
              subtotal += double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0;
            }
          });
          if (subtotal == 0.0) {
            final itemRe = RegExp(r'^Item\.(\d+)\.');
            final found = <int>{};
            for (var k in controllers.keys) {
              final mm = itemRe.firstMatch(k);
              if (mm != null) found.add(int.tryParse(mm.group(1)!) ?? 0);
            }
            for (var i in found) {
              final price = double.tryParse(controllers['Item.$i.Price']?.text.replaceAll(',', '') ?? '') ?? 0.0;
              final qty = double.tryParse(controllers['Item.$i.Quantity']?.text.replaceAll(',', '') ?? '') ?? 0.0;
              if (price > 0 && qty > 0) subtotal += price * qty;
            }
          }
          if (subtotal > 0) return subtotal.toStringAsFixed(2);
        }

        if (tkn == 'discount amount' || tkn == 'discount' || tkn == 'payment.discount') {
          double sub = double.tryParse(controllers['Payment.Subtotal']?.text.replaceAll(',', '') ?? '') ?? 0.0;
          if (sub == 0.0) {
            controllers.forEach((k, ctrl) {
              final m = RegExp(r'^Item\.(\d+)\.(Subtotal|Amount|subtotal|amount)\b').firstMatch(k);
              if (m != null) {
                sub += double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0;
              }
            });
          }
          String raw = controllers['Payment.Discount']?.text ?? '';
          raw = raw.trim();
          double rate;
          if (raw.endsWith('%')) {
            final v = double.tryParse(raw.substring(0, raw.length - 1).replaceAll(',', '')) ?? 0.0;
            rate = v > 0 ? v / 100.0 : 0.0;
          } else {
            final v = double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
            rate = v > 1.0 ? v / 100.0 : v; 
          }
          final discAmt = sub * rate;
          return discAmt != 0.0 ? discAmt.toStringAsFixed(2) : '0.00';
        }

        if (tkn == 'tax amount' || tkn == 'tax' || tkn == 'payment.tax') {
          double sub = double.tryParse(controllers['Payment.Subtotal']?.text.replaceAll(',', '') ?? '') ?? 0.0;
          if (sub == 0.0) {
            controllers.forEach((k, ctrl) {
              final m = RegExp(r'^Item\.(\d+)\.(Subtotal|Amount|subtotal|amount)\b').firstMatch(k);
              if (m != null) {
                sub += double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0;
              }
            });
          }
          String raw = controllers['Payment.Tax']?.text ?? '';
          raw = raw.trim();
          double rate;
          if (raw.endsWith('%')) {
            final v = double.tryParse(raw.substring(0, raw.length - 1).replaceAll(',', '')) ?? 0.0;
            rate = v > 0 ? v / 100.0 : 0.0;
          } else {
            final v = double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
            rate = v > 1.0 ? v / 100.0 : v; 
          }
          final txAmt = sub * rate;
          return txAmt != 0.0 ? txAmt.toStringAsFixed(2) : '0.00';
        }

        if (tkn == 'total amount' || tkn == 'total' || tkn == 'payment.total' || tkn == 'total contract price') {
  
          final explicit = double.tryParse(controllers['Payment.Total']?.text.replaceAll(',', '') ?? '') ?? double.nan;
          if (!explicit.isNaN) return explicit.toStringAsFixed(2);
          final sub = double.tryParse(controllers['Payment.Subtotal']?.text.replaceAll(',', '') ?? '') ?? 0.0;
          String rawDisc = controllers['Payment.Discount']?.text ?? '';
          rawDisc = rawDisc.trim();
          double discRate;
          if (rawDisc.endsWith('%')) {
            final v = double.tryParse(rawDisc.substring(0, rawDisc.length - 1).replaceAll(',', '')) ?? 0.0;
            discRate = v > 0 ? v / 100.0 : 0.0;
          } else {
            final v = double.tryParse(rawDisc.replaceAll(',', '')) ?? 0.0;
            discRate = v > 1.0 ? v / 100.0 : v;
          }
          final dis = sub * discRate;
          String raw = controllers['Payment.Tax']?.text ?? '';
          raw = raw.trim();
          double rate;
          if (raw.endsWith('%')) {
            final v = double.tryParse(raw.substring(0, raw.length - 1).replaceAll(',', '')) ?? 0.0;
            rate = v > 0 ? v / 100.0 : 0.0;
          } else {
            final v = double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
            rate = v > 1.0 ? v / 100.0 : v;
          }
          final tx = sub * rate;
          final total = sub - dis + tx;
          if (total != 0.0) return total.toStringAsFixed(2);
        }

        return tokenToKey.containsKey(token) ? '_' : m.group(0)!;
      });

      return out;
    }


    Widget contractWidget;
    final normalizedType = contractType.toLowerCase();
    if (normalizedType.contains('lump sum')) {
      ContractStyle.setTextResolver(resolvePlaceholders);
      ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
      ContractStyle.setMilestoneRowVisibilityChecker((int rowNum) => shouldShowMilestoneRow(rowNum));
      contractWidget = const LumpSumContract();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContractStyle.clearTextResolver();
        ContractStyle.clearItemRowVisibilityChecker();
        ContractStyle.clearMilestoneRowVisibilityChecker();
      });
    } else if (normalizedType.contains('cost-plus') || normalizedType.contains('cost plus')) {
      ContractStyle.setTextResolver(resolvePlaceholders);
      ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
      contractWidget = const CostPlusContract();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContractStyle.clearTextResolver();
        ContractStyle.clearItemRowVisibilityChecker();
      });
    } else if (normalizedType.contains('time and materials')) {
      ContractStyle.setTextResolver(resolvePlaceholders);

      ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
      contractWidget = const TimeMaterialsContract();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContractStyle.clearTextResolver();
        ContractStyle.clearItemRowVisibilityChecker();
      });
    } else {
      final filled = resolvePlaceholders(PdfExtractUtils.getDefaultTemplateContent(contractType));
      contractWidget = Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(filled.isNotEmpty ? filled : 'No preview available.'),
      );
    }

    final content = Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ScrollConfiguration(
              behavior: const _NoGlowScrollBehavior(),
              child: SingleChildScrollView(
                key: const PageStorageKey('create_contract_final_preview_scroll'),
                physics: const ClampingScrollPhysics(),
                child: contractWidget,
              ),
            ),
          ),
        ),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => ContractStyle.clearTextResolver());
    return content;
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}