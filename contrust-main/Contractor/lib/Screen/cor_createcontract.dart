// ignore_for_file: use_build_context_synchronously

import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/builddrawer.dart';
import 'package:contractor/build/contract/buildcontract.dart';
import 'package:contractor/build/contract/buildcontracttabs.dart';
import 'package:backend/services/contractor services/contract/cor_createcontractservice.dart';
import 'package:flutter/material.dart';

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

  int _previewRefreshTick = 0;
  bool isPreparingPreview = false;

  final Map<String, TextEditingController> controllers = {};
  final formKey = GlobalKey<FormState>();
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
    tabController.addListener(() {
      if (mounted) {
        setState(() {});
        if (tabController.index != 2 && isPreparingPreview) {
          setState(() {
            isPreparingPreview = false;
          });
        }
      }
    });
    titleController = TextEditingController(
      text: widget.existingContract?['title'] as String? ?? '',
    );
    initialProjectId = widget.existingContract?['project_id'] as String?;
    selectedContractType = widget.contractType;
    selectedTemplate = widget.template;
    initializeFields();
    checkForProject();
  }

  void initializeFields() async {
    if (widget.existingContract != null) {
      await loadExistingContractFieldValues();
    }
    
    if (selectedTemplate != null) {
      loadTemplateAndBuildFields();
    } else {
      buildDefaultFields();
    }
  }

  Future<void> checkForProject() async {
    if (initialProjectId != null) {
      fetchProjectData(initialProjectId!);
    } else {
      await service.checkForSingleProject(widget.contractorId, (projectId) {
        if (projectId != null) {
          setState(() {
            initialProjectId = projectId;
          });
          fetchProjectData(projectId);
        }
      });
    }
  }

  Future<void> loadExistingContractFieldValues() async {
    if (widget.existingContract == null) return;
    
    try {
      final contractId = widget.existingContract!['contract_id'] as String?;
      if (contractId != null) {
        final fieldValues = await service.fetchContractFieldValues(
          contractId,
          contractorId: widget.contractorId,
        );
        if (fieldValues != null) {
  
          widget.existingContract!['field_values'] = fieldValues;
        }
      }
    } catch (e) {
      debugPrint('Error fetching contract field values');
    }
  }

  Future<void> loadTemplateAndBuildFields() async {
    if (selectedTemplate == null) return;

    try {

      final templateName = selectedTemplate!['template_name'] ?? '';
      final fields = service.getContractTypeSpecificFields(templateName);

      for (var controller in controllers.values) {
        controller.dispose();
      }
      controllers.clear();

      contractFields = fields;
      for (var field in contractFields) {
        final controller = TextEditingController();
        controller.addListener(() {
          if (mounted) {
            setState(() {});
            if (selectedTemplate != null && 
                selectedTemplate!['template_name']?.toLowerCase().contains('time and materials') == true) {
              triggerTimeAndMaterialsCalculation();
            }
          }
        });
        controllers[field.key] = controller;
      }

      if (widget.existingContract != null && widget.existingContract!['field_values'] != null) {
        final existingFieldValues = widget.existingContract!['field_values'] as Map<String, dynamic>;
        for (var field in contractFields) {
          final value = existingFieldValues[field.key];
          if (value != null) {
            controllers[field.key]?.text = value.toString();
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      buildDefaultFields();
    }
  }

  void buildDefaultFields() {
    if (selectedTemplate != null) {
      final templateName = selectedTemplate!['template_name'] ?? '';
      contractFields = service.getContractTypeSpecificFields(templateName);
    } else if (selectedContractType != null) {
      contractFields = service.getContractTypeSpecificFields(selectedContractType!);
    } else {
      contractFields = [];
    }
    
    for (var field in contractFields) {
      final controller = TextEditingController();
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      controllers[field.key] = controller;
    }

    if (widget.existingContract != null && widget.existingContract!['field_values'] != null) {
      final existingFieldValues = widget.existingContract!['field_values'] as Map<String, dynamic>;
      for (var field in contractFields) {
        final value = existingFieldValues[field.key];
        if (value != null) {
          controllers[field.key]?.text = value.toString();
        }
      }
    }
  }

  Future<void> fetchProjectData(String projectId) async {
    setState(() {
      isLoadingProject = true;
    });

    try {
      final projectData = await service.fetchProjectData(projectId);
      if (projectData != null) {
        setState(() {
          this.projectData = projectData;
        });

        if (widget.existingContract == null) {
          service.populateProjectFields(
            projectData,
            controllers,
            selectedContractType,
          );
        }
        await service.populateContractorInfo(
          widget.contractorId,
          controllers,
        );
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading project data. Please try again. $e');
      }
    } finally {
      setState(() {
        isLoadingProject = false;
      });
    }
  }

  Future<void> setContractType(Map<String, dynamic>? template) async {
    if (template == null || template == selectedTemplate) return;

    final oldValues = <String, String>{};
    for (var field in contractFields) {
      oldValues[field.key] = controllers[field.key]?.text ?? '';
    }

    selectedTemplate = template;
    selectedContractType = template['template_name'];

    await loadTemplateAndBuildFields();

    for (var field in contractFields) {
      if (oldValues.containsKey(field.key)) {
        controllers[field.key]?.text = oldValues[field.key] ?? '';
      }
    }

    if (initialProjectId != null) {
      fetchProjectData(initialProjectId!);
    }
  }

  void updateItemCount(int newItemCount) {
    if (selectedTemplate == null) return;

    try {
      final templateName = selectedTemplate!['template_name'] ?? '';
      
      final oldValues = <String, String>{};
      for (var field in contractFields) {
        oldValues[field.key] = controllers[field.key]?.text ?? '';
      }

      final newFields = service.getContractTypeSpecificFields(templateName, itemCount: newItemCount);

      for (var controller in controllers.values) {
        controller.dispose();
      }
      controllers.clear();

      contractFields = newFields;
      for (var field in contractFields) {
        final controller = TextEditingController();
        if (oldValues.containsKey(field.key)) {
          controller.text = oldValues[field.key] ?? '';
        }
        controller.addListener(() {
          if (mounted) {
            setState(() {});
            if (templateName.toLowerCase().contains('time and materials')) {
              triggerTimeAndMaterialsCalculation();
            }
          }
        });
        controllers[field.key] = controller;
      }

      if (mounted) setState(() {});
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error updating item count');
    }
  }

  void updateMilestoneCount(int newMilestoneCount) {
    if (selectedTemplate == null) return;

    try {
      final templateName = selectedTemplate!['template_name'] ?? '';
      
      final oldValues = <String, String>{};
      for (var field in contractFields) {
        oldValues[field.key] = controllers[field.key]?.text ?? '';
      }

      final newFields = service.getContractTypeSpecificFields(templateName, milestoneCount: newMilestoneCount);

      for (var controller in controllers.values) {
        controller.dispose();
      }
      controllers.clear();

      contractFields = newFields;
      for (var field in contractFields) {
        final controller = TextEditingController();
        if (oldValues.containsKey(field.key)) {
          controller.text = oldValues[field.key] ?? '';
        }
        controller.addListener(() {
          if (mounted) setState(() {});
        });
        controllers[field.key] = controller;
      }

      if (mounted) setState(() {});
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error updating milestone count');
    }
  }

  void triggerTimeAndMaterialsCalculation() {
    if (selectedTemplate != null && 
        selectedTemplate!['template_name']?.toLowerCase().contains('time and materials') == true) {
      Future.delayed(const Duration(milliseconds: 100), () {
        service.calculateTimeAndMaterialsRates(controllers);
      });
    }
  }

  Future<void> saveContract() async {

    if (tabController.index == 1 && !formKey.currentState!.validate()) {
      ConTrustSnackBar.error(context, 'Please fill in all required fields');
      return;
    }

    final contractTypeId =
        selectedTemplate?['contract_type_id'] as String? ??
        widget.template?['contract_type_id'] as String? ??
        '';

    if (contractTypeId.isEmpty) {
      ConTrustSnackBar.error(context, 'Please select a contract type');
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

      final contractData = await showSaveDialog();

      if (contractData != null) {
        Navigator.pop(context, true);
        
        ConTrustSnackBar.loading(context, 'Contract saving...');
        
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
          if (mounted) {
            Navigator.pop(context); 
            ConTrustSnackBar.success(context, 'Contract updated successfully!');
          }
        } else {
          await service.saveContract(
            contractorId: widget.contractorId,
            contractTypeId: contractTypeId,
            title: contractData['title'] as String,
            projectId: contractData['projectId'] as String,
            fieldValues: fieldValues,
            contractType: selectedContractType ?? widget.contractType ?? '',
          );
          if (mounted) {
            Navigator.pop(context);
            ConTrustSnackBar.success(context, 'Contract saved successfully!');
          }
        }
      }
    } catch (e) {
      if (mounted) {  
        try {
          Navigator.pop(context);
        } catch (_) {
          return;
        }
        ConTrustSnackBar.error(context, 'Failed to save contract');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> showSaveDialog() async {
    String? selectedProjectId = initialProjectId;
    return await CreateContractBuild.showSaveDialog(
      context,
      widget.contractorId,
      titleController: titleController,
      initialProjectId: selectedProjectId,
      onProjectChanged: (String? projectId) {
        if (projectId != null && projectId != selectedProjectId) {
          selectedProjectId = projectId;
          fetchProjectData(projectId);
        }
      },
    );
  }

  Future<void> prepareFinalPreview() async {
    setState(() {
      isPreparingPreview = true;
    });

    try {

      if (selectedTemplate != null && 
          selectedTemplate!['template_name']?.toLowerCase().contains('time and materials') == true) {
        service.calculateTimeAndMaterialsRates(controllers);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && tabController.index == 2) {
        setState(() {
          _previewRefreshTick++;
        });
      }

    } finally {
      if (mounted) {
        setState(() {
          isPreparingPreview = false;
        });
      }
    }
  }

  Widget buildPreviewLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              'Preparing Final Preview...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculating values and generating preview',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
          await fetchProjectData(projectId);
        } else {
          setState(() {
            initialProjectId = null;
            projectData = null;
          });
          service.clearAutoPopulatedFields(controllers);
        }
      },
      onContractTypeChanged: setContractType,
      onItemCountChanged: (int newItemCount) {
        updateItemCount(newItemCount);
      },
      onMilestoneCountChanged: (int newMilestoneCount) {
        updateMilestoneCount(newMilestoneCount);
      },
      onCalculationTriggered: () {
        triggerTimeAndMaterialsCalculation();
      },
    );

    final canViewFinalPreview = ContractTabsBuild.validateRequiredFields(
      contractFields,
      controllers,
    );

    final completionStatus = ContractTabsBuild.getFieldCompletionStatus(
      contractFields,
      controllers,
    );

    return ContractorShell(
      currentPage: ContractorPage.contracts,
      contractorId: widget.contractorId,
      child: Column(
        children: [
          CreateContractBuild.buildHeader(
            context,
            title: 'Create Contract',
            actions: [
              ElevatedButton.icon(
                onPressed: isSaving ? null : saveContract,
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

          ContractTabsBuild.buildCompletionIndicator(
            completedFields: completionStatus['completed']!,
            totalRequiredFields: completionStatus['total']!,
          ),

          ContractTabsBuild.buildTabBar(
            tabController: tabController,
            canViewFinalPreview: canViewFinalPreview,
            onBeforeFinalPreview: () async {
              await prepareFinalPreview();
            },
          ),

          Expanded(
            child: ContractTabsBuild.buildTabBarView(
              tabController: tabController,
              templatePreview: ContractTabsBuild.buildTemplatePreview(
                selectedTemplate?['template_name'],
              ),
              contractForm: buildHelper.buildForm(),
              finalPreview: isPreparingPreview
                  ? buildPreviewLoadingIndicator()
                  : KeyedSubtree(
                      key: ValueKey(_previewRefreshTick),
                    child: buildHelper.buildPreview(),
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
    tabController.dispose();
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
