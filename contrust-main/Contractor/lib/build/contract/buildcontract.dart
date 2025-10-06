import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'dart:typed_data';

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

  static Widget buildMainContent({
    required bool showPreview,
    required Widget form,
    required Widget preview,
  }) {
    return Row(
      children: [
        CreateContractBuild.buildFormContainer(form),
        if (showPreview) ...[
          const VerticalDivider(width: 1),
          CreateContractBuild.buildPreviewContainer(preview),
        ],
      ],
    );
  }

  static List<Widget> buildActionButtons({
    required BuildContext context,
    required VoidCallback onSave,
    required VoidCallback onPreview,
    required bool isSaving,
    required bool showPreview,
  }) {
    return [
      if (showPreview)
        IconButton(
          onPressed: onPreview,
          icon: const Icon(Icons.visibility_off),
          tooltip: 'Hide Preview',
        )
      else
        IconButton(
          onPressed: onPreview,
          icon: const Icon(Icons.preview),
          tooltip: 'Preview Contract',
        ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: isSaving ? null : onSave,
        icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
        label: Text(isSaving ? 'Saving...' : 'Save Contract'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    ];
  }

  static Future<void> showPdfPreviewDialog(BuildContext context, Uint8List pdfBytes) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Contract Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('PDF Preview Generated Successfully'),
                        SizedBox(height: 8),
                        Text(
                          'The contract PDF has been generated and is ready for review.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text('Error loading projects');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Select Project',
                        border: OutlineInputBorder(),
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
    required this.previewController,
    required this.isLoadingProject,
    required this.initialProjectId,
    required this.projectData,
    required this.onProjectChanged,
    this.selectedTemplate,
    this.onContractTypeChanged,
  });

  final BuildContext context;
  final List<dynamic> contractFields;
  final Map<String, TextEditingController> controllers;
  final GlobalKey<FormState> formKey;
  final String contractorId;
  final QuillController previewController;
  final bool isLoadingProject;
  final String? initialProjectId;
  final Map<String, dynamic>? projectData;
  final void Function(String?) onProjectChanged;
  final Map<String, dynamic>? selectedTemplate;
  final void Function(Map<String, dynamic>?)? onContractTypeChanged;

  Widget buildForm() {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                              child: Text('Error loading contract types: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                              child: const Text('No contract types found.'),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedTemplate?['contract_type_id'],
                                decoration: InputDecoration(
                                  labelText: 'Contract Type',
                                  hintText: 'Choose a contract type',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.description),
                                ),
                                items: snapshot.data!.map((template) => DropdownMenuItem<String>(
                                  value: template['contract_type_id'],
                                  child: Text(template['template_name'] ?? 'Unnamed Template'),
                                )).toList(),
                                onChanged: (value) {
                                  final selectedTemplate = snapshot.data!.firstWhere(
                                    (template) => template['contract_type_id'] == value,
                                    orElse: () => <String, dynamic>{},
                                  );
                                  onContractTypeChanged!(selectedTemplate.isNotEmpty ? selectedTemplate : null);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),

                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: FetchService().fetchContractorProjectInfo(contractorId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                            child: Text('Error loading projects: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                            child: const Text('No projects found.'),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: initialProjectId,
                              decoration: InputDecoration(labelText: 'Select Project', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.folder_outlined)),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Select a project...')),
                                ...snapshot.data!.map((project) => DropdownMenuItem<String>(value: project['project_id'], child: Text(project['title'] ?? project['description'] ?? 'No Title', overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (value) {
                                onProjectChanged(value);
                              },
                            ),
                            if (projectData != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                                child: Row(children: [Icon(Icons.check_circle, color: Colors.green.shade600, size: 16), const SizedBox(width: 8), Expanded(child: Text('Project data loaded: ${projectData!['title'] ?? projectData!['description'] ?? 'Unnamed Project'}', style: TextStyle(color: Colors.green.shade700, fontSize: 12)))]),
                              ),
                            ],
                          ],
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
    );
  }

  List<Widget> buildFormFields() {
    List<Widget> widgets = [];

    final basicFields = contractFields.where((f) => ['DATE', 'Client Name', 'Client Address', 'Contractor Name', 'Contractor Address'].contains((f as dynamic).key)).toList();
    final projectFields = contractFields.where((f) => ['Project Description', 'Project Location', 'Start Date', 'Completion Date', 'Duration'].contains((f as dynamic).key)).toList();
    final paymentFields = contractFields.where((f) => ['Total Amount', 'Down Payment', 'Progress Payment 1', 'Progress Payment 2', 'Progress Payment 3', 'Final Payment', 'Payment Due Days', 'Contractor Fee Percentage', 'Fixed Fee Amount', 'Maximum Budget', 'Hourly Rate', 'Material Markup', 'Equipment Markup', 'Supervisor Rate', 'Skilled Rate', 'General Rate', 'Overtime Multiplier', 'Invoice Frequency', 'Late Fee Percentage', 'Estimated Budget'].contains((f as dynamic).key)).toList();
    final otherFields = contractFields.where((f) => !basicFields.contains(f) && !projectFields.contains(f) && !paymentFields.contains(f)).toList();

    widgets.add(buildSectionCard('Basic Information', basicFields));
    widgets.add(const SizedBox(height: 16));
    widgets.add(buildSectionCard('Project Details', projectFields));
    widgets.add(const SizedBox(height: 16));
    if (paymentFields.isNotEmpty) {
      widgets.add(buildSectionCard('Payment Information', paymentFields));
      widgets.add(const SizedBox(height: 16));
    }
    if (otherFields.isNotEmpty) {
      widgets.add(buildSectionCard('Additional Information', otherFields));
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
                decoration: InputDecoration(
                  labelText: isRequired ? '$label *' : label,
                  hintText: placeholder.isEmpty ? 'Enter ${label.toLowerCase()}' : placeholder,
                  border: const OutlineInputBorder(),
                  prefixIcon: getFieldIcon(key),
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

  Icon? getFieldIcon(String fieldKey) {
    switch (fieldKey) {
      case 'DATE':
      case 'Start Date':
      case 'Completion Date':
        return const Icon(Icons.calendar_today);
      case 'Client Name':
      case 'Contractor Name':
      case 'Witness Name':
        return const Icon(Icons.person);
      case 'Client Address':
      case 'Contractor Address':
      case 'Project Location':
        return const Icon(Icons.location_on);
      case 'Project Description':
      case 'Work Description':
        return const Icon(Icons.description);
      case 'Total Amount':
      case 'Down Payment':
      case 'Progress Payment 1':
      case 'Progress Payment 2':
      case 'Progress Payment 3':
      case 'Final Payment':
      case 'Maximum Budget':
      case 'Estimated Budget':
      case 'Hourly Rate':
      case 'Supervisor Rate':
      case 'Skilled Rate':
      case 'General Rate':
      case 'Fixed Fee Amount':
        return const Icon(Icons.attach_money);
      case 'Duration':
      case 'Payment Due Days':
      case 'Notice Period':
        return const Icon(Icons.schedule);
      case 'Materials List':
      case 'Equipment List':
        return const Icon(Icons.inventory);
      default:
        return const Icon(Icons.text_fields);
    }
  }

  Widget buildPreview() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(children: [const Icon(Icons.preview, color: Colors.blue), const SizedBox(width: 8), Text('Contract Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade600))]),
        ),
        Expanded(child: Container(padding: const EdgeInsets.all(16), child: QuillEditor.basic(controller: previewController))),
      ],
    );
  }
}
