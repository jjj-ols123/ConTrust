// ignore_for_file: use_build_context_synchronously

import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/contract/buildcontract.dart';
import 'package:contractor/build/contract/buildcontracttabs.dart';
import 'package:backend/services/contractor services/contract/cor_createcontractservice.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late final bool isEditMode;
  late int formTabIndex;
  late int previewTabIndex;

  final Map<String, TextEditingController> controllers = {};
  final formKey = GlobalKey<FormState>();
  late TabController tabController;

  Timer? _calculationTimer;

  List<ContractField> contractFields = [];
  Map<String, dynamic>? projectData;
  bool isLoadingProject = false;
  String? selectedContractType;
  Map<String, dynamic>? selectedTemplate;

  String? contractorId;
  Map<String, dynamic>? existingContract;
  bool isLoading = true;
  bool _isFieldsLoaded = false; // Track when contract fields are loaded

  final CreateContractService service = CreateContractService();

  @override
  void initState() {
    super.initState();
    isEditMode = widget.existingContract != null;
    final showTemplate = !isEditMode;
    tabController = TabController(length: showTemplate ? 3 : 2, vsync: this);
    formTabIndex = showTemplate ? 1 : 0;
    previewTabIndex = showTemplate ? 2 : 1;
    tabController.addListener(() {
      if (mounted) {
        setState(() {});
        if (tabController.index != previewTabIndex && isPreparingPreview) {
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
    contractorId = widget.contractorId;
    existingContract = widget.existingContract;
    _initialize();
  }

  void _initialize() async {
    if (initialProjectId == null && widget.existingContract == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showProjectSelectionDialog();
      });
      return; // Don't continue initialization until project is selected
    }

    try {
      final fetchService = FetchService();
      
      if (selectedTemplate != null && 
          selectedTemplate!.containsKey('template_name')) {
        final templateName = selectedTemplate!['template_name'] as String?;
        
        if (selectedTemplate!.containsKey('contract_type_id')) {
          selectedContractType = templateName;
        } else if (templateName != null && templateName.isNotEmpty) {
          selectedContractType = templateName;
          try {
            final templates = await fetchService.fetchContractTypes();

            Map<String, dynamic>? foundTemplate;
            try {
              foundTemplate = templates.firstWhere(
                (t) => (t['template_name'] as String?)?.trim() == templateName.trim(),
              );
            } catch (e) {
              try {
                foundTemplate = templates.firstWhere(
                  (t) => (t['template_name'] as String?)?.toLowerCase().trim() == templateName.toLowerCase().trim(),
                );
              } catch (e2) {
                foundTemplate = null;
              }
            }
            
            if (foundTemplate != null && foundTemplate.isNotEmpty) {
              selectedTemplate = foundTemplate;
              selectedContractType = foundTemplate['template_name'] as String?;
            } else {
              if (mounted) {
                ConTrustSnackBar.error(context, 'Template not found: $templateName');
                setState(() {
                  isLoading = false;
                });
                return;
              }
            }
          } catch (e) {
            if (mounted) {
              ConTrustSnackBar.error(context, 'Error loading template: $templateName');
              setState(() {
                isLoading = false;
              });
              return;
            }
          }
        }
      }
      
      if ((selectedTemplate == null || 
           selectedTemplate!.isEmpty || 
           !selectedTemplate!.containsKey('template_name') ||
           (selectedTemplate!['template_name'] as String?)?.isEmpty == true) &&
          existingContract == null) {
        if (mounted) {
          ConTrustSnackBar.error(context, 'No valid template selected. Please try again.');
          setState(() {
            isLoading = false;
          });
          return;
        }
      }
      
      if (selectedContractType == null || selectedContractType!.isEmpty) {
        selectedContractType = selectedTemplate!['template_name'] as String?;
      }
      
      if (existingContract != null && (selectedTemplate == null || selectedTemplate!.isEmpty)) {
        try {
          final contractId = existingContract!['contract_id'];
          Map<String, dynamic>? contract = await fetchService.fetchContractWithDetails(
            contractId,
            contractorId: contractorId,
          );
          contract ??= await fetchService.fetchContractWithDetails(contractId);
          if (contract != null) {
            existingContract = contract;
            final contractType = contract['contract_type'] as Map<String, dynamic>?;
            if (contractType != null && contractType.isNotEmpty) {
              selectedTemplate = contractType;
              selectedContractType = contractType['template_name'] as String?;
            }
            titleController.text = contract['title'] as String? ?? titleController.text;
            initialProjectId = contract['project_id'] as String? ?? initialProjectId;
          }
        } catch (_) {
          // Ignore, fallback to existing values
        }
      }

      if (existingContract != null && existingContract!['title'] == null) {
        final contractId = existingContract!['contract_id'];
        Map<String, dynamic>? contract = await fetchService.fetchContractWithDetails(contractId, contractorId: contractorId);
        contract ??= await fetchService.fetchContractWithDetails(contractId);
        if (contract == null && mounted) {
          ConTrustSnackBar.error(context, 'Contract not found');
          setState(() {
            isLoading = false;
          });
          return;
        }
        if (contract != null) {
          existingContract = contract;
          
          final contractType = contract['contract_type'] as Map<String, dynamic>?;
          if (contractType != null && contractType.isNotEmpty) {
            selectedTemplate = contractType;
            selectedContractType = contractType['template_name'] as String?;
          }
          
          titleController.text = contract['title'] as String? ?? '';
          initialProjectId = contract['project_id'] as String?;
        }
      }
      
      await initializeFields();
      await checkForProject();
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to load contract data');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> initializeFields() async {
    try {
      if (widget.existingContract != null) {
        await loadExistingContractFieldValues();
      }
      
      if (selectedTemplate != null && selectedTemplate!.isNotEmpty) {
        await loadTemplateAndBuildFields();
      } else {
        buildDefaultFields();
      }
    } catch (e) {
      if (mounted) {
        buildDefaultFields();
      }
    }
  }

  Future<void> checkForProject() async {
    try {
      if (initialProjectId != null) {
        await fetchProjectData(initialProjectId!);
      } else if (contractorId != null) {
        await service.checkForSingleProject(contractorId!, (projectId) {
          if (projectId != null) {
            setState(() {
              initialProjectId = projectId;
            });
            fetchProjectData(projectId);
          }
        });
      }
    } catch (e) {
      // Error checking for project - silently fail, user can select manually
    }
  }

  Future<void> loadExistingContractFieldValues() async {
    if (widget.existingContract == null) return;
    
    try {
      final contractId = widget.existingContract!['contract_id'] as String?;
      if (contractId != null) {
        final fieldValues = await service.fetchContractFieldValues(
          contractId,
          contractorId: contractorId!,
        );
        if (fieldValues != null) {
          widget.existingContract!['field_values'] = fieldValues;
        }
      }
    } catch (e) {
      // Error fetching contract field values - silently fail
    }
  }

  Future<void> loadTemplateAndBuildFields() async {
    if (selectedTemplate == null || selectedTemplate!.isEmpty) {
      buildDefaultFields();
      return;
    }

    try {
      final templateName = selectedTemplate!['template_name'] as String? ?? '';
      if (templateName.isEmpty) {
        buildDefaultFields();
        return;
      }
      
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
            if (selectedTemplate != null) {
              final templateName = selectedTemplate!['template_name']?.toLowerCase() ?? '';
              if (templateName.contains('time and materials')) {
                triggerTimeAndMaterialsCalculation();
              } else if (templateName.contains('lump sum')) {
                triggerMilestoneDurationCalculation();
                triggerLumpSumCalculation();
              }
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

      _isFieldsLoaded = true; // Mark fields as loaded
      if (mounted) setState(() {});
    } catch (e) {
      buildDefaultFields();
      _isFieldsLoaded = true; // Even on error, mark as loaded
      if (mounted) setState(() {});
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

        if (existingContract == null) {
          service.populateProjectFields(
            projectData,
            controllers,
            selectedContractType,
          );
        }
        await service.populateContractorInfo(
          contractorId!,
          controllers,
        );

        // Auto-populate ONLY contractor/contractee info and start date for new contracts
        if (existingContract == null) {
          await _autoPopulateContactFields();
          if (mounted) setState(() {}); // Update UI after auto-population
        }
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
            } else if (templateName.toLowerCase().contains('lump sum')) {
              triggerMilestoneDurationCalculation();
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
          if (mounted) {
            setState(() {});
            if (selectedTemplate != null) {
              final templateName = selectedTemplate!['template_name']?.toLowerCase() ?? '';
              if (templateName.contains('time and materials')) {
                triggerTimeAndMaterialsCalculation();
              } else if (templateName.contains('lump sum')) {
                triggerMilestoneDurationCalculation();
                triggerLumpSumCalculation();
              }
            }
          }
        });
        controllers[field.key] = controller;
      }

      // Trigger calculations for the updated milestone count
      if (selectedTemplate != null) {
        final templateName = selectedTemplate!['template_name']?.toLowerCase() ?? '';
        if (templateName.contains('time and materials')) {
          triggerTimeAndMaterialsCalculation();
        } else if (templateName.contains('lump sum')) {
          triggerMilestoneDurationCalculation();
          triggerLumpSumCalculation();
        }
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

  void triggerLumpSumCalculation() {
    if (selectedTemplate != null &&
        selectedTemplate!['template_name']?.toLowerCase().contains('lump sum') == true) {
      _calculationTimer?.cancel();

      _calculationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          service.calculateLumpSumPayments(controllers);
        }
      });
    }
  }

  void triggerMilestoneDurationCalculation() {
    if (selectedTemplate != null &&
        selectedTemplate!['template_name']?.toLowerCase().contains('lump sum') == true) {
      service.calculateMilestoneDurations(controllers);
    }
  }

  Future<void> saveContract() async {

    if (tabController.index == formTabIndex && !formKey.currentState!.validate()) {
      ConTrustSnackBar.error(context, 'Please fill in all required fields');
      return;
    }

    final contractTypeId =
        selectedTemplate?['contract_type_id'] as String? ??
        '';

    if (contractTypeId.isEmpty) {
      ConTrustSnackBar.error(context, 'Please select a contract type');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (selectedContractType == 'Lump Sum') {
        service.calculateLumpSumPayments(controllers);
      } else if (selectedContractType == 'Time and Materials') {
        service.calculateTimeAndMaterialsRates(controllers);
      }

      final fieldValues = <String, String>{};
      for (var field in contractFields) {
        fieldValues[field.key] = controllers[field.key]?.text ?? '';
      }

      double parsePercent(String raw) {
        final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '');
        final v = double.tryParse(cleaned) ?? 0.0;

        if (cleaned.contains('.')) {
          return v; 
        } else {
          return v / 100.0; 
        }
      }

      if (selectedContractType == 'Cost Plus') {
        final overheadPercentText = fieldValues['Overhead.Percentage'] ?? '0';
        final lateFeePercentText = fieldValues['Late.Fee.Percentage'] ?? '0';

        fieldValues['Overhead.Percentage'] = parsePercent(overheadPercentText).toString();
        fieldValues['Late.Fee.Percentage'] = parsePercent(lateFeePercentText).toString();
      }

      final contractData = await showSaveDialog();

      if (contractData != null) {
        final contractTitle = contractData['title'] as String? ?? '';
        if (contractTitle.trim().isEmpty) {
          ConTrustSnackBar.error(context, 'Contract title is required');
          return;
        }

        try {
          final existingContracts = await FetchService().fetchCreatedContracts(contractorId!);
          final currentContractId = widget.existingContract?['contract_id'];

          final hasDuplicate = existingContracts.any(
            (contract) => contract['title']?.toString().toLowerCase() == contractTitle.toLowerCase() &&
                         (isEditMode ? contract['contract_id'] != currentContractId : true),
          );

          if (hasDuplicate) {
            ConTrustSnackBar.error(context, 'A contract with this title already exists. Please choose a different title.');
            return;
          }
        } catch (e) {
          // 
        }

        ConTrustSnackBar.loading(context, 'Contract saving...');
        
        if (existingContract != null) {
          await service.updateContract(
            contractId: existingContract!['contract_id'] as String,
            contractorId: contractorId!,
            contractTypeId: contractTypeId,
            title: contractData['title'] as String,
            projectId: contractData['projectId'] as String,
            fieldValues: fieldValues,
            contractType: selectedContractType ?? '',
          );
          if (mounted) {
            context.pop();
            ConTrustSnackBar.success(context, 'Contract updated successfully!');
            if (mounted) context.go('/contracttypes');
          }
        } else {
          await service.saveContract(
            contractorId: contractorId!,
            contractTypeId: contractTypeId,
            title: contractData['title'] as String,
            projectId: contractData['projectId'] as String,
            fieldValues: fieldValues,
            contractType: selectedContractType ?? '',
          );
          if (mounted) {
            context.pop();
            ConTrustSnackBar.success(context, 'Contract saved successfully!');
            if (mounted) context.go('/contracttypes');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        try { context.pop(); } catch (_) {}
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

  Future<void> _showProjectSelectionDialog() async {
    if (!mounted) return;

    final result = await CreateContractBuild.showProjectSelectionDialog(
      context,
      contractorId!,
      initialProjectId: initialProjectId,
    );

    if (result != null && result['projectId'] != null && mounted) {
      initialProjectId = result['projectId'] as String;
      // Now proceed with normal initialization
      _initialize();
    } else if (mounted) {
      // User cancelled, go back
      context.pop();
    }
  }

  Future<Map<String, dynamic>?> showSaveDialog() async {
    return await CreateContractBuild.showSaveDialog(
      context,
      contractorId!,
      titleController: titleController,
      initialProjectId: initialProjectId,
    );
  }

  Future<void> prepareFinalPreview() async {
    setState(() {
      isPreparingPreview = true;
    });

    try {

      if (selectedTemplate != null) {
        final templateName = selectedTemplate!['template_name']?.toLowerCase() ?? '';
        if (templateName.contains('time and materials')) {
          service.calculateTimeAndMaterialsRates(controllers);
        } else if (templateName.contains('lump sum')) {
          service.calculateLumpSumPayments(controllers);
          service.calculateMilestoneDurations(controllers);
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && tabController.index == previewTabIndex) {
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
              color: Colors.amber,
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber,),
        ),
      );
    }

    final buildHelper = CreateContractBuildMethods(
      context: context,
      contractFields: contractFields,
      controllers: controllers,
      formKey: formKey,
      contractorId: contractorId!,
      isLoadingProject: isLoadingProject,
      initialProjectId: initialProjectId,
      projectData: projectData,
      selectedTemplate: selectedTemplate,
      selectedContractTypeName: selectedContractType,
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
      onLumpSumCalculationTriggered: () {
        triggerLumpSumCalculation();
      },
      onMilestoneDurationCalculationTriggered: () {
        triggerMilestoneDurationCalculation();
      },
    );

    final canViewFinalPreview = _isFieldsLoaded
        ? ContractTabsBuild.validateRequiredFields(
            contractFields,
            controllers,
          )
        : false; // Don't allow preview until fields are loaded

    final completionStatus = _isFieldsLoaded
        ? ContractTabsBuild.getFieldCompletionStatus(
            contractFields,
            controllers,
          )
        : {'completed': 0, 'total': 0}; // Show 0/0 until fields are loaded

    return Column(
      children: [
        // Save button at the top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: isSaving ? null : saveContract,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFB300),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'Saving...' : 'Save Contract'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Make the rest of the content scrollable
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ContractTabsBuild.buildCompletionIndicator(
                  completedFields: completionStatus['completed']!,
                  totalFields: completionStatus['total']!,
                ),

                ContractTabsBuild.buildTabBar(
                  tabController: tabController,
                  canViewFinalPreview: canViewFinalPreview,
                  onBeforeFinalPreview: () async {
                    await prepareFinalPreview();
                  },
                  showTemplate: !isEditMode,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6, 
                  child: ContractTabsBuild.buildTabBarView(
                    tabController: tabController,
                    templatePreview: ContractTabsBuild.buildTemplatePreview(
                      selectedContractType ?? selectedTemplate?['template_name'],
                    ),
                    contractForm: buildHelper.buildForm(),
                    finalPreview: isPreparingPreview
                        ? buildPreviewLoadingIndicator()
                        : KeyedSubtree(
                            key: ValueKey(_previewRefreshTick),
                            child: buildHelper.buildPreview(),
                          ),
                    canViewFinalPreview: canViewFinalPreview,
                    showTemplate: !isEditMode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    }

  Future<void> _autoPopulateContactFields() async {
    // Use the current project ID from projectData
    final currentProjectId = projectData?['project_id'] as String?;
    if (currentProjectId == null || contractorId == null) return;

    try {
      // Get project data to find contractee_id (we already have it in projectData)
      final contracteeId = projectData?['contractee_id'] as String?;

      // Fetch contractor information
      if (contractorId!.isNotEmpty) {
        try {
          final contractorData = await Supabase.instance.client
              .from('Contractor')
              .select('firm_name, contact_number, address, bio, specialization')
              .eq('contractor_id', contractorId!)
              .single();

          String? contractorEmail;
          try {
            final userData = await Supabase.instance.client
                .from('Users')
                .select('email')
                .eq('users_id', contractorId!)
                .single();
            contractorEmail = userData['email'] as String?;
          } catch (e) {
            //
          }

          if (contractorData['firm_name'] != null && (controllers['Contractor.Company']?.text.isEmpty ?? true)) {
            controllers['Contractor.Company']?.text = contractorData['firm_name'] as String;
          }
          if (contractorData['contact_number'] != null && (controllers['Contractor.Phone']?.text.isEmpty ?? true)) {
            controllers['Contractor.Phone']?.text = contractorData['contact_number'] as String;
          }
          if (contractorData['address'] != null && (controllers['Contractor.Address']?.text.isEmpty ?? true)) {
            controllers['Contractor.Address']?.text = contractorData['address'] as String;
          }
          if (contractorData['bio'] != null && (controllers['Contractor.Bio']?.text.isEmpty ?? true)) {
            controllers['Contractor.Bio']?.text = contractorData['bio'] as String;
          }
          if (contractorEmail != null && (controllers['Contractor.Email']?.text.isEmpty ?? true)) {
            controllers['Contractor.Email']?.text = contractorEmail;
          }
        } catch (e) {
          //
        }
      }

      // Fetch contractee information
      if (contracteeId != null && contracteeId.isNotEmpty) {
        try {
          final contracteeData = await Supabase.instance.client
              .from('Contractee')
              .select('full_name, phone_number, address, project_history_count')
              .eq('contractee_id', contracteeId)
              .single();

          String? contracteeEmail;
          try {
            final userData = await Supabase.instance.client
                .from('Users')
                .select('email')
                .eq('users_id', contracteeId)
                .single();
            contracteeEmail = userData['email'] as String?;
          } catch (e) {
            //
          }

          if (contracteeData['full_name'] != null) {
            final fullName = contracteeData['full_name'] as String;
            final nameParts = fullName.split(' ');
            if (nameParts.isNotEmpty && (controllers['Contractee.FirstName']?.text.isEmpty ?? true)) {
              controllers['Contractee.FirstName']?.text = nameParts.first;
            }
            if (nameParts.length > 1 && (controllers['Contractee.LastName']?.text.isEmpty ?? true)) {
              controllers['Contractee.LastName']?.text = nameParts.sublist(1).join(' ');
            }
          }

          if (contracteeData['phone_number'] != null && (controllers['Contractee.Phone']?.text.isEmpty ?? true)) {
            controllers['Contractee.Phone']?.text = contracteeData['phone_number'] as String;
          }
          if (contracteeData['address'] != null && (controllers['Contractee.Address']?.text.isEmpty ?? true)) {
            controllers['Contractee.Address']?.text = contracteeData['address'] as String;
          }
          if (contracteeEmail != null && (controllers['Contractee.Email']?.text.isEmpty ?? true)) {
            controllers['Contractee.Email']?.text = contracteeEmail;
          }
        } catch (e) {
          //
        }
      }
    } catch (e) {
      //
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    tabController.dispose();
    _calculationTimer?.cancel();
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
