// ignore_for_file: use_build_context_synchronously

import 'package:contractor/build/builddrawer.dart';
import 'package:contractor/build/contract/buildcontract.dart';
import 'package:contractor/build/contract/buildcontracttabs.dart';
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

class _CreateContractPageState extends State<CreateContractPage>
    with SingleTickerProviderStateMixin {
  bool isSaving = false;
  late final TextEditingController titleController;
  String? initialProjectId;
  // Bump this to force the Final Preview subtree to remount (fresh build)
  int _previewRefreshTick = 0;

  final Map<String, TextEditingController> controllers = {};
  final formKey = GlobalKey<FormState>();
  bool showPreview = false;
  late QuillController previewController;
  late TabController tabController;

  List<ContractField> contractFields = [];
  Map<String, dynamic>? projectData;
  bool isLoadingProject = false;
  String? selectedContractType;
  Map<String, dynamic>? selectedTemplate;

  final CreateContractService service = CreateContractService();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    // Rebuild when switching tabs so header actions (like Next) can update visibility
    tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      // Use contract type specific fields instead of extracting from template
      final templateName = selectedTemplate!['template_name'] ?? '';
      final fields = service.getContractTypeSpecificFields(templateName);

      for (var controller in controllers.values) {
        controller.dispose();
      }
      controllers.clear();

      contractFields = fields;
      for (var field in contractFields) {
        final controller = TextEditingController();
        // Add listener to update UI when fields change
        controller.addListener(() {
          if (mounted) {
            setState(() {});
            // Trigger calculation for Time and Materials contracts
            if (selectedTemplate != null && 
                selectedTemplate!['template_name']?.toLowerCase().contains('time and materials') == true) {
              _triggerTimeAndMaterialsCalculation();
            }
          }
        });
        controllers[field.key] = controller;
      }

      if (mounted) setState(() {});
    } catch (e) {
      _buildDefaultFields();
    }
  }

  void _buildDefaultFields() {
    // Use contract type specific fields if template is available
    if (selectedTemplate != null) {
      final templateName = selectedTemplate!['template_name'] ?? '';
      contractFields = service.getContractTypeSpecificFields(templateName);
    } else {
      // No template selected - empty fields list
      contractFields = [];
    }
    
    for (var field in contractFields) {
      final controller = TextEditingController();
      // Add listener to update UI when fields change
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      controllers[field.key] = controller;
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

  void _updateItemCount(int newItemCount) {
    if (selectedTemplate == null) return;

    try {
      final templateName = selectedTemplate!['template_name'] ?? '';
      
      // Save current field values
      final oldValues = <String, String>{};
      for (var field in contractFields) {
        oldValues[field.key] = controllers[field.key]?.text ?? '';
      }

      // Generate new fields with the updated item count
      final newFields = service.getContractTypeSpecificFields(templateName, itemCount: newItemCount);

      // Dispose old controllers and create new ones
      for (var controller in controllers.values) {
        controller.dispose();
      }
      controllers.clear();

      contractFields = newFields;
      for (var field in contractFields) {
        final controller = TextEditingController();
        // Restore old values if they exist
        if (oldValues.containsKey(field.key)) {
          controller.text = oldValues[field.key] ?? '';
        }
        // Add listener to trigger calculations for Time and Materials
        controller.addListener(() {
          if (mounted) {
            setState(() {});
            // Trigger calculation if this is a Time and Materials contract
            if (templateName.toLowerCase().contains('time and materials')) {
              _triggerTimeAndMaterialsCalculation();
            }
          }
        });
        controllers[field.key] = controller;
      }

      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating item count: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _triggerTimeAndMaterialsCalculation() {
    if (selectedTemplate != null && 
        selectedTemplate!['template_name']?.toLowerCase().contains('time and materials') == true) {
      // Delay the calculation to ensure the UI has updated
      Future.delayed(const Duration(milliseconds: 100), () {
        service.calculateTimeAndMaterialsRates(controllers);
      });
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
  @override
  Widget build(BuildContext context) {
    final buildHelper = CreateContractBuildMethods(
      context: context,
      contractFields: contractFields,
      controllers: controllers,
      formKey: formKey,
      contractorId: widget.contractorId,
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
      onItemCountChanged: (int newItemCount) {
        _updateItemCount(newItemCount);
      },
      onCalculationTriggered: () {
        _triggerTimeAndMaterialsCalculation();
      },
    );

    // Check if required fields are completed for Final Preview tab
    final canViewFinalPreview = ContractTabsBuild.validateRequiredFields(
      contractFields,
      controllers,
    );

    // Get completion status for progress indicator
    final completionStatus = ContractTabsBuild.getFieldCompletionStatus(
      contractFields,
      controllers,
    );

    return ContractorShell(
      currentPage: ContractorPage.contracts,
      contractorId: widget.contractorId,
      child: Column(
        children: [
          // Header
          CreateContractBuild.buildHeader(
            context,
            title: 'Create Contract',
            actions: [
              ElevatedButton.icon(
                onPressed: isSaving ? null : _saveContract,
                icon: isSaving
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

          // Progress Indicator
          ContractTabsBuild.buildCompletionIndicator(
            completedFields: completionStatus['completed']!,
            totalRequiredFields: completionStatus['total']!,
          ),

          // Tab Bar
          ContractTabsBuild.buildTabBar(
            tabController: tabController,
            canViewFinalPreview: canViewFinalPreview,
            onBeforeFinalPreview: () async {
              // Show a quick toast while preparing the preview
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Preparing preview...'),
                  duration: Duration(milliseconds: 900),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              FocusScope.of(context).unfocus();
              // Run calculations immediately to populate payment fields
              service.calculateTimeAndMaterialsRates(controllers);
              // Small delay to allow any listeners to propagate values
              await Future.delayed(const Duration(milliseconds: 75));
              // Force Final Preview to rebuild fresh so resolver picks up latest values
              if (mounted) {
                setState(() {
                  _previewRefreshTick++;
                });
              }
            },
          ),

          // Tab Bar View
          Expanded(
            child: ContractTabsBuild.buildTabBarView(
              tabController: tabController,
              templatePreview: ContractTabsBuild.buildTemplatePreview(
                selectedTemplate?['template_name'],
              ),
              contractForm: buildHelper.buildForm(),
              finalPreview: KeyedSubtree(
                key: ValueKey(_previewRefreshTick),
                child: buildHelper.buildPreview(
                  onEdit: () {
                    tabController.animateTo(1);
                  },
                ),
              ),
              canViewFinalPreview: canViewFinalPreview,
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    titleController.dispose();
    previewController.dispose();
    tabController.dispose();
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
