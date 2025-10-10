// ignore_for_file: use_build_context_synchronously

import 'package:contractor/build/builddrawer.dart';
import 'package:contractor/build/contract/buildcontract.dart';
import 'package:backend/services/contractor services/contract/cor_createcontractservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CreateContractPage extends StatefulWidget {
  final String? contractType;
  final Map<String, dynamic>? template;
  final String contractorId;
  final Map<String, dynamic>? existingContract;

  const CreateContractPage({
    super.key,
    this.template,
    required this.contractType,
    required this.contractorId,
    this.existingContract,
  });

  @override
  State<CreateContractPage> createState() => _CreateContractPageState();
}

class _CreateContractPageState extends State<CreateContractPage> {
  bool isSaving = false;
  late final TextEditingController titleController;
  String? initialProjectId;

  final Map<String, TextEditingController> controllers = {};
  final formKey = GlobalKey<FormState>();
  bool showPreview = false;
  late QuillController previewController;

  List<ContractField> contractFields = [];
  Map<String, dynamic>? projectData;
  bool isLoadingProject = false;
  String? selectedContractType;
  Map<String, dynamic>? selectedTemplate;

  final CreateContractService service = CreateContractService();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.existingContract?['title'] as String? ?? '',
    );
    initialProjectId = widget.existingContract?['project_id'] as String?;
    previewController = QuillController.basic();
    selectedContractType = widget.contractType;
    selectedTemplate = widget.template;
    _initializeFields();
    _checkForProject();
  }

  void _initializeFields() {
    if (selectedTemplate != null) {
      _loadTemplateAndBuildFields();
    } else {
      _buildDefaultFields();
    }
  }

  Future<void> _checkForProject() async {
    if (initialProjectId != null) {
      _fetchProjectData(initialProjectId!);
    } else {
      await service.checkForSingleProject(widget.contractorId, (projectId) {
        if (projectId != null) {
          setState(() {
            initialProjectId = projectId;
          });
          _fetchProjectData(projectId);
        }
      });
    }
  }

  Future<void> _loadTemplateAndBuildFields() async {
    if (selectedTemplate == null) return;

    try {
      final templateContent = await service.loadTemplateContent(
        selectedTemplate!['template_name'],
      );
      final fields = service.extractFieldsFromTemplate(templateContent);

      for (var controller in controllers.values) {
        controller.dispose();
      }
      controllers.clear();

      contractFields = fields;
      for (var field in contractFields) {
        controllers[field.key] = TextEditingController();
      }

      if (mounted) setState(() {});
    } catch (e) {
      _buildDefaultFields();
    }
  }

  void _buildDefaultFields() {
    contractFields = service.buildDefaultFields();
    for (var field in contractFields) {
      controllers[field.key] = TextEditingController();
    }
  }

  Future<void> _generatePreview() async {
    try {
      final fieldValues = <String, String>{};
      for (var field in contractFields) {
        fieldValues[field.key] = controllers[field.key]?.text ?? '';
      }

      final pdfBytes = await service.generatePreview(
        selectedContractType ?? widget.contractType ?? '',
        fieldValues,
        titleController.text,
      );

      if (mounted) {
        await CreateContractBuild.showPdfPreviewDialog(context, pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchProjectData(String projectId) async {
    setState(() {
      isLoadingProject = true;
    });

    try {
      final projectData = await service.fetchProjectData(projectId);
      if (projectData != null) {
        setState(() {
          this.projectData = projectData;
        });
        service.populateProjectFields(
          projectData,
          controllers,
          selectedContractType,
        );
        await service.populateContractorInfo(
          widget.contractorId,
          controllers,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching project data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingProject = false;
      });
    }
  }

  Future<void> _setContractType(Map<String, dynamic>? template) async {
    if (template == null || template == selectedTemplate) return;

    final oldValues = <String, String>{};
    for (var field in contractFields) {
      oldValues[field.key] = controllers[field.key]?.text ?? '';
    }

    selectedTemplate = template;
    selectedContractType = template['template_name'];

    await _loadTemplateAndBuildFields();

    for (var field in contractFields) {
      if (oldValues.containsKey(field.key)) {
        controllers[field.key]?.text = oldValues[field.key] ?? '';
      }
    }

    if (initialProjectId != null) {
      _fetchProjectData(initialProjectId!);
    }
  }

  Future<void> _saveContract() async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final contractTypeId =
        selectedTemplate?['contract_type_id'] as String? ??
        widget.template?['contract_type_id'] as String? ??
        '';

    if (contractTypeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a contract type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final fieldValues = <String, String>{};
      for (var field in contractFields) {
        fieldValues[field.key] = controllers[field.key]?.text ?? '';
      }

      final contractData = await _showSaveDialog();

      if (contractData != null) {
        if (widget.existingContract != null) {
          await service.updateContract(
            contractId: widget.existingContract!['contract_id'] as String,
            contractorId: widget.contractorId,
            contractTypeId: contractTypeId,
            title: contractData['title'] as String,
            projectId: contractData['projectId'] as String,
            fieldValues: fieldValues,
            contractType: selectedContractType ?? widget.contractType ?? '',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await service.saveContract(
            contractorId: widget.contractorId,
            contractTypeId: contractTypeId,
            title: contractData['title'] as String,
            projectId: contractData['projectId'] as String,
            fieldValues: fieldValues,
            contractType: selectedContractType ?? widget.contractType ?? '',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      return;
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _showSaveDialog() async {
    String? selectedProjectId = initialProjectId;
    return await CreateContractBuild.showSaveDialog(
      context,
      widget.contractorId,
      titleController: titleController,
      initialProjectId: selectedProjectId,
      onProjectChanged: (String? projectId) {
        if (projectId != null && projectId != selectedProjectId) {
          selectedProjectId = projectId;
          _fetchProjectData(projectId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildHelper = CreateContractBuildMethods(
      context: context,
      contractFields: contractFields,
      controllers: controllers,
      formKey: formKey,
      contractorId: widget.contractorId,
      previewController: previewController,
      isLoadingProject: isLoadingProject,
      initialProjectId: initialProjectId,
      projectData: projectData,
      selectedTemplate: selectedTemplate,
      onProjectChanged: (String? projectId) async {
        if (projectId != null) {
          setState(() {
            isLoadingProject = true;
            initialProjectId = projectId;
          });
          await _fetchProjectData(projectId);
        } else {
          setState(() {
            initialProjectId = null;
            projectData = null;
          });
          service.clearAutoPopulatedFields(controllers);
        }
      },
      onContractTypeChanged: _setContractType,
    );

    return ContractorShell(
      currentPage: ContractorPage.contracts,
      contractorId: widget.contractorId,
      child: Column(
        children: [
          CreateContractBuild.buildHeader(
            context,
            title: 'Create your Contract',
            actions: [
              if (!showPreview)
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) _generatePreview();
                  },
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.black,
                  ),
                ),
              if (showPreview)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showPreview = false;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isSaving ? null : _saveContract,
                icon:
                    isSaving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(isSaving ? 'Saving...' : 'Save Contract'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          showPreview
              ? CreateContractBuild.buildPreviewContainer(
                buildHelper.buildPreview(),
              )
              : CreateContractBuild.buildFormContainer(buildHelper.buildForm()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    previewController.dispose();
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
