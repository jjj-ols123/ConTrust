import 'package:backend/utils/be_status.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_pdfextract.dart';
import 'package:backend/utils/be_contractformat.dart';
import 'package:backend/contract_templates/TimeandMaterials.dart';
import 'package:backend/contract_templates/CostPlus.dart';
import 'package:backend/contract_templates/LumpSum.dart';

class CreateContractBuild {
  static Widget buildHeader(BuildContext context, {required String title, required List<Widget> actions}) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.amber.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Icon(Icons.create, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), overflow: TextOverflow.ellipsis),
          ),
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

static Future<Map<String, dynamic>?> showSaveDialog(
    BuildContext context, 
    String contractorId, {
    TextEditingController? titleController, 
    String? initialProjectId,
    Function(String?)? onProjectChanged,
  }) async {
    String? selectedProjectId = initialProjectId;
    titleController ??= TextEditingController();
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Save Contract'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Contract Title',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: FetchService().fetchContractorProjectInfo(contractorId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text('Error loading projects');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Select Project',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      items: snapshot.data!.map((project) => DropdownMenuItem<String>(
                        value: project['project_id'],
                        child: Text(project['title'] ?? project['description'] ?? 'No Title'),
                      )).toList(),
                      onChanged: (value) {
                        selectedProjectId = value;
                        onProjectChanged?.call(value);
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
                if (titleController?.text.trim().isEmpty == true || selectedProjectId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop({
                  'title': titleController?.text.trim() ?? '',
                  'projectId': selectedProjectId,
                });
              },
              child: const Text('Save'),
            ),
          ],
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
    this.onContractTypeChanged,
    this.onItemCountChanged,
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
  final void Function(Map<String, dynamic>?)? onContractTypeChanged;
  final void Function(int)? onItemCountChanged;
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Contract Information', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                        ),
                        if (isLoadingProject)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLoadingProject ? 'Loading project data and auto-populating fields...' : 'Fill in the following details to generate your contract',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (onContractTypeChanged != null)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: FetchService().fetchContractTypes(),
                        builder: (context, snapshot) {
                          // Reserve a consistent vertical space to avoid layout jumps while loading
                          const double kSelectorHeight = 88;
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: kSelectorHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return SizedBox(
                              height: kSelectorHeight,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                                child: Text('Error loading contract types: ${snapshot.error}'),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return SizedBox(
                              height: kSelectorHeight,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                                child: const Text('No contract types found.'),
                              ),
                            );
                          }

                          return SizedBox(
                            height: kSelectorHeight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    alignment: AlignmentDirectional.centerStart,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    initialValue: selectedTemplate?['contract_type_id'],
                                    decoration: InputDecoration(
                                      labelText: 'Contract Type',
                                      hintText: 'Choose a contract type',
                                      border: const OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      enabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 1),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black, width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.description),
                                    ),
                                    items: snapshot.data!.map((template) => DropdownMenuItem<String>(
                                      value: template['contract_type_id'],
                                      child: Text(template['template_name'] ?? 'Unnamed Template', overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (value) {
                                      final selectedTemplate = snapshot.data!.firstWhere(
                                        (template) => template['contract_type_id'] == value,
                                        orElse: () => <String, dynamic>{},
                                      );
                                      onContractTypeChanged!(selectedTemplate.isNotEmpty ? selectedTemplate : null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: FetchService().fetchContractorProjectInfo(contractorId),
                      builder: (context, snapshot) {
                        const double kProjectBlockHeight = 148;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: kProjectBlockHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return SizedBox(
                            height: kProjectBlockHeight,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                              child: Text('Error loading projects: ${snapshot.error}'),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: kProjectBlockHeight,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                              child: const Text('No projects found.'),
                            ),
                          );
                        }

                        return SizedBox(
                          height: kProjectBlockHeight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                alignment: AlignmentDirectional.centerStart,
                                icon: const Icon(Icons.arrow_drop_down),
                                initialValue: initialProjectId,
                                decoration: InputDecoration(
                                  labelText: 'Select Project', 
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 2),
                                  ),
                                  prefixIcon: const Icon(Icons.folder_outlined)
                                ),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text('Select a project...')),
                                  ...snapshot.data!.map((project) => DropdownMenuItem<String>(value: project['project_id'], child: Text(project['title'] ?? project['description'] ?? 'No Title', overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (value) {
                                  onProjectChanged(value);
                                },
                              ),
                              const SizedBox(height: 8),
                              // Reserve space for the status chip to avoid height change when projectData toggles
                              SizedBox(
                                height: 40,
                                child: (projectData != null)
                                    ? Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                                        child: Row(children: [Icon(Icons.check_circle, color: Colors.green.shade600, size: 16), const SizedBox(width: 8), Expanded(child: Text('Project data loaded: ${projectData!['title'] ?? projectData!['description'] ?? 'Unnamed Project'}', style: TextStyle(color: Colors.green.shade700, fontSize: 12)))]),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
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

    // Categorize fields based on actual field keys from service methods
    final dateFields = contractFields.where((f) => 
      (f as dynamic).key == 'Date' ||
      (f as dynamic).key == 'Contract.CreationDate' ||
      (f as dynamic).key.contains('Date') ||
      (f as dynamic).key.contains('Duration')
    ).toList();
    
    final contracteeFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Contractee.')
    ).toList();
    
    final contractorFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Contractor.')
    ).toList();
    
    final projectFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Project.') ||
      (f as dynamic).key.contains('Materials.')
    ).toList();
    
    final itemFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Item.')
    ).toList();
    
    final paymentFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Payment.') ||
      (f as dynamic).key.contains('Labor Costs') ||
      (f as dynamic).key.contains('Material Costs') ||
      (f as dynamic).key.contains('Equipment Costs') ||
      (f as dynamic).key.contains('Overhead Percentage') ||
      (f as dynamic).key.contains('Estimated Total') ||
      (f as dynamic).key.contains('Payment Interval') ||
      (f as dynamic).key.contains('Retention Fee') ||
      (f as dynamic).key.contains('Late Fee Percentage')
    ).toList();
    
    // Extract milestone payment fields separately for special handling
    final milestonePaymentFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Payment.ProgressPayment') ||
      (f as dynamic).key.contains('Payment.Milestone') ||
      (f as dynamic).key.contains('Payment.DownPaymentPercentage') ||
      (f as dynamic).key.contains('Payment.FinalPaymentPercentage')
    ).toList();
    
    // Remove milestone fields from regular payment fields to avoid duplication
    final regularPaymentFields = paymentFields.where((f) => 
      !(f as dynamic).key.contains('Payment.ProgressPayment') &&
      !(f as dynamic).key.contains('Payment.Milestone') &&
      !(f as dynamic).key.contains('Payment.DownPaymentPercentage') &&
      !(f as dynamic).key.contains('Payment.FinalPaymentPercentage')
    ).toList();
    
    final bondFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Bond.')
    ).toList();
    
    final insuranceFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Insurance.') ||
      (f as dynamic).key.contains('Inspection.')
    ).toList();
    
    final legalFields = contractFields.where((f) => 
      (f as dynamic).key.contains('Notice Period') ||
      (f as dynamic).key.contains('Warranty Period') ||
      (f as dynamic).key.contains('Penalty.') ||
      (f as dynamic).key.contains('Tax.')
    ).toList();

    // Build sections only if fields exist
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
      // Check if this is Time and Materials contract by looking for Item fields
      bool isTimeAndMaterials = itemFields.any((f) => 
        (f as dynamic).key.contains('Item.') && 
        (f as dynamic).key.contains('.Name')
      );
      
      if (isTimeAndMaterials) {
        widgets.add(buildTimeAndMaterialsItemCard('Project Items', itemFields));
      } else {
        widgets.add(buildSectionCard('Project Items', itemFields));
      }
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
            final f = field as dynamic;
            final key = f.key as String;
            final label = f.label as String;
            final placeholder = (f.placeholder as String?) ?? '';
            final inputType = (f.inputType as TextInputType?) ?? TextInputType.text;
            final isRequired = (f.isRequired as bool?) ?? false;
            final maxLines = (f.maxLines as int?) ?? 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: controllers[key],
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
                  prefixIcon: ContractStatus().getFieldIcon(key),
                ),
                keyboardType: inputType,
                maxLines: maxLines,
                validator: isRequired ? (value) { if (value == null || value.trim().isEmpty) return '$label is required'; return null; } : null,
              ),
            );
          }),
        ]),
      ),
    );
  }

  Widget buildTimeAndMaterialsItemCard(String title, List<dynamic> fields) {
    // Group fields by item number
    Map<int, Map<String, dynamic>> itemGroups = {};
    
    for (var field in fields) {
      final f = field as dynamic;
      final key = f.key as String;
      
      // Extract item number from key like "Item.1.Name"
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _addNewItem(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Table header
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
                  const SizedBox(width: 40), // Space for remove button
                ],
              ),
            ),
            
            // Item rows
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
                    if (itemGroups.length > 1) // Only show remove button if more than 1 item
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
        ),
      ),
    );
  }

  void _addNewItem() {
    // Get current item count
    int currentItemCount = _getCurrentItemCount();
    
    // Add new item (increase count by 1)
    if (onItemCountChanged != null) {
      onItemCountChanged!(currentItemCount + 1);
    }
  }

  void _removeItem(int itemNumber) {
    // Get current item count
    int currentItemCount = _getCurrentItemCount();
    
    if (currentItemCount > 1) { // Don't allow removing if only 1 item left
      // Remove the last item (decrease count by 1)
      if (onItemCountChanged != null) {
        onItemCountChanged!(currentItemCount - 1);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the last item. At least one item is required.')),
      );
    }
  }

  int _getCurrentItemCount() {
    // Count how many items we have by looking at Item.X.Name fields
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
    }
    
    return maxItemNumber;
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
            // Group milestone payments with their corresponding milestones
            ...buildMilestonePaymentGroups(fields),
          ],
        ),
      ),
    );
  }

  List<Widget> buildMilestonePaymentGroups(List<dynamic> fields) {
    List<Widget> widgets = [];
    
    // Find down payment field
    final downPaymentField = fields.where((f) => 
      (f as dynamic).key.contains('Payment.DownPaymentPercentage')
    ).toList();
    
    // Find progress payment and milestone pairs
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
    
    // Find final payment field
    final finalPaymentField = fields.where((f) => 
      (f as dynamic).key.contains('Payment.FinalPaymentPercentage')
    ).toList();

    // Build down payment section
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

    // Build progress payment 1 section
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

    // Build progress payment 2 section
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

    // Build final payment section
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
            // Two-column layout with full-height divider
            IntrinsicHeight(
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
    
    // Add empty space if odd number of fields to maintain alignment
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
    
    return TextFormField(
      controller: controllers[key],
      enabled: isEnabled,
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
        fillColor: isEnabled ? null : Colors.grey.shade100,
        filled: !isEnabled,
      ),
      keyboardType: inputType,
      maxLines: maxLines,
      validator: isRequired 
        ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          }
        : null,
      onChanged: isEnabled ? (value) {
        // If this is a price or quantity field, trigger recalculation
        if (key.contains('.Price') || key.contains('.Quantity') || key.contains('Payment.Discount') || key.contains('Payment.Tax')) {
          _triggerCalculation();
        }
      } : null,
    );
  }

  void _triggerCalculation() {
    // Trigger the calculation callback if provided
    if (onCalculationTriggered != null) {
      onCalculationTriggered!();
    }
  }

  Widget buildPreview({VoidCallback? onEdit}) {
    // Build a styled Final Preview using the same template widgets but with values injected.
    final String contractType = (selectedTemplate?['template_name'] as String?) ?? '';

    // Add this function to check if a row should be visible
    bool shouldShowItemRow(int rowNumber) {
      // Check if any field for this item has a value
      final nameKey = 'Item.$rowNumber.Description';
      final quantityKey = 'Item.$rowNumber.Quantity';
      final priceKey = 'Item.$rowNumber.UnitRate';
      
      // If any of the main fields have a value, show the row
      return (controllers.containsKey(nameKey) && controllers[nameKey]!.text.trim().isNotEmpty) ||
             (controllers.containsKey(quantityKey) && controllers[quantityKey]!.text.trim().isNotEmpty) ||
             (controllers.containsKey(priceKey) && controllers[priceKey]!.text.trim().isNotEmpty);
    }
    
    // Set a global function to check item visibility that templates can access
    ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
    
    // Prepare a resolver to replace placeholders with controller values.
    String resolvePlaceholders(String input) {
      // Map of friendly tokens to controller keys (extend as needed)
      final Map<String, String> tokenToKey = {
        // People
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
        
        // Common company/identifier extras
        'Contractor license number': 'Contractor.License',
        'Contractor phone number': 'Contractor.Phone',
        'Contractor province': 'Contractor.Province',

        // Project basics
        'Date of contract creation': 'Contract.CreationDate',
        'Project description as defined by the contractor': 'Project.ContractorDef',
        'Estimated labor hours': 'Project.LaborHours',
        'Project duration': 'Project.Duration',
        'Project duration in days': 'Project.Duration',
        'Estimated completion date': 'Project.CompletionDate',
        'Start date of the project': 'Project.StartDate',
        'Project schedule': 'Project.Schedule',
        'List of project milestones': 'Project.MilestonesList',

        // Common address/placeholders across templates
        'Project address': 'Project.Address',
        'Project site address': 'Project.Address',
        'Legal description of property': 'Project.LegalDescription',
        'Property description': 'Project.PropertyDescription',
        'Project scope of work': 'Project.ScopeOfWork',
        'List of required materials': 'Materials.List',
        'Scope of work': 'Project.Scope',

        // Taxes/fees
        'Applicable taxes': 'Tax.List',
        'Maximum penalty amount': 'Penalty.Amount',

        // Payment summary fields
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
              
        // Table cells and other template elements
        'List of work': 'Project.Scope',
        'Time': 'Project.LaborHours',
        'Materials': 'Materials.List',

        // Payment calculation placeholders
        'Subtotal amount': 'Payment.Subtotal',
        'Payment.Subtotal': 'Payment.Subtotal',
        'Discount amount': 'Payment.Discount',
        'Payment.Discount': 'Payment.Discount',
        'Tax amount': 'Payment.Tax',
        'Payment.Tax': 'Payment.Tax',
        'Total amount': 'Payment.Total',
        'Payment.Total': 'Payment.Total',
        
        // Item rows (needs to handle 1-based index)
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

        // Payment schedule/milestones
        'Down payment percentage': 'Payment.DownPaymentPercentage',
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
      // Case-insensitive regex to match any placeholder content pattern ([...] or {...})
      final reg = RegExp(r'\[(.*?)\]|\{(.*?)\}', caseSensitive: false);
      out = out.replaceAllMapped(reg, (m) {
        // Get the token inside [] or {} (whichever matched)
        final token = (m.group(1) ?? m.group(2) ?? '').trim();
        if (token.isEmpty) return m.group(0)!;
        
        // Try exact match
        final key = tokenToKey[token];
        if (key != null && controllers.containsKey(key)) {
          final v = controllers[key]!.text.trim();
          if (v.isNotEmpty) return v;
        }
        
        // Try case-insensitive match with token map
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
        
        // If not mapped, try direct key lookup
        if (controllers.containsKey(token)) {
          final v = controllers[token]!.text.trim();
          if (v.isNotEmpty) return v;
        }
        
        // Try looking for dynamic item fields (Item.N.Property pattern)
        if (token.toLowerCase().contains('item') && 
            (token.toLowerCase().contains('description') || 
             token.toLowerCase().contains('quantity') || 
             token.toLowerCase().contains('rate') || 
             token.toLowerCase().contains('amount') ||
             token.toLowerCase().contains('price') ||
             token.toLowerCase().contains('subtotal'))) {
          // Extract item number and property
          final parts = token.split(' ');
          if (parts.length >= 3) {
            final itemNum = int.tryParse(parts[1]);
            final prop = parts.sublist(2).join(' ');
            if (itemNum != null) {
              // try common variants
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

        // Special computed payment placeholders: subtotal/discount/tax/total
        final tkn = token.toLowerCase();
        if (tkn == 'subtotal amount' || tkn == 'subtotal' || tkn == 'payment.subtotal') {
          // Sum item subtotals or price*qty
          double subtotal = 0.0;
          // First, check for explicit item subtotal controllers
          controllers.forEach((k, ctrl) {
            final m = RegExp(r'^Item\.(\d+)\.(Subtotal|Amount|subtotal|amount)\b').firstMatch(k);
            if (m != null) {
              subtotal += double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0;
            }
          });
          // If none found, compute from price * quantity
          if (subtotal == 0.0) {
            // detect max item number dynamically
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
          // Compute discount as percentage of subtotal: supports "5", "5%", or "0.05"
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
            rate = v > 1.0 ? v / 100.0 : v; // 5 -> 0.05, 0.05 -> 0.05
          }
          final discAmt = sub * rate;
          return discAmt != 0.0 ? discAmt.toStringAsFixed(2) : '0.00';
        }

        if (tkn == 'tax amount' || tkn == 'tax' || tkn == 'payment.tax') {
          // Compute tax as percentage of subtotal: supports "12", "12%", or "0.12"
          double sub = double.tryParse(controllers['Payment.Subtotal']?.text.replaceAll(',', '') ?? '') ?? 0.0;
          if (sub == 0.0) {
            // If subtotal not filled, estimate from item rows
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
            rate = v > 1.0 ? v / 100.0 : v; // 12 -> 0.12, 0.12 -> 0.12
          }
          final txAmt = sub * rate;
          return txAmt != 0.0 ? txAmt.toStringAsFixed(2) : '0.00';
        }

        if (tkn == 'total amount' || tkn == 'total' || tkn == 'payment.total' || tkn == 'total contract price') {
          // prefer explicit total controller
          final explicit = double.tryParse(controllers['Payment.Total']?.text.replaceAll(',', '') ?? '') ?? double.nan;
          if (!explicit.isNaN) return explicit.toStringAsFixed(2);
          // compute: subtotal - discount + tax
          final sub = double.tryParse(controllers['Payment.Subtotal']?.text.replaceAll(',', '') ?? '') ?? 0.0;
          // Compute discount from percentage
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
          // Compute tax from percentage
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

        // Leave original token if no value; or show underscore for emphasis
        return tokenToKey.containsKey(token) ? '_' : m.group(0)!;
      });

      return out;
    }

    // Choose the widget for the contract type (reuse template preview components)
    Widget contractWidget;
    final normalizedType = contractType.toLowerCase();
    if (normalizedType.contains('lump sum')) {
      // Set resolver before building widget, then clear it after frame is built
      ContractStyle.setTextResolver(resolvePlaceholders);
      // Set row visibility checker
      ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
      contractWidget = const LumpSumContract();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContractStyle.clearTextResolver();
        ContractStyle.clearItemRowVisibilityChecker();
      });
    } else if (normalizedType.contains('cost-plus') || normalizedType.contains('cost plus')) {
      ContractStyle.setTextResolver(resolvePlaceholders);
      // Set row visibility checker
      ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
      contractWidget = const CostPlusContract();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContractStyle.clearTextResolver();
        ContractStyle.clearItemRowVisibilityChecker();
      });
    } else if (normalizedType.contains('time and materials')) {
      ContractStyle.setTextResolver(resolvePlaceholders);
      // Set row visibility checker
      ContractStyle.setItemRowVisibilityChecker((int rowNum) => shouldShowItemRow(rowNum));
      contractWidget = const TimeMaterialsContract();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContractStyle.clearTextResolver();
        ContractStyle.clearItemRowVisibilityChecker();
      });
    } else {
      // Default to plain filled text
      final filled = resolvePlaceholders(PdfExtractUtils.getDefaultTemplateContent(contractType));
      contractWidget = Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(filled.isNotEmpty ? filled : 'No preview available.'),
      );
    }

    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
        ),
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

    // Ensure we clear resolver after build to avoid accidental global effect
    WidgetsBinding.instance.addPostFrameCallback((_) => ContractStyle.clearTextResolver());
    return content;
  }
}

// Custom scroll behavior to remove overscroll glow and clamp physics
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
