import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ContractField {
  final String key;
  final String label;
  final String placeholder;
  final TextInputType inputType;
  final bool isRequired;
  final int maxLines;

  ContractField({
    required this.key,
    required this.label,
    this.placeholder = '',
    this.inputType = TextInputType.text,
    this.isRequired = false,
    this.maxLines = 1,
  });
}

class CreateContractService {
  Future<void> checkForSingleProject(String contractorId, Function(String?) onProjectSelected) async {
    try {
      final projects = await FetchService().fetchContractorProjectInfo(contractorId);
      if (projects.length == 1) {
        final projectId = projects.first['project_id'] as String;
        onProjectSelected(projectId);
      }
    } catch (e) {
      return;
    }
  }

  Future<String> loadTemplateContent(String templateName) async {
    try {
      return getDefaultTemplateContent(templateName);
    } catch (e) {
      return getDefaultTemplateContent(templateName);
    }
  }

  String getDefaultTemplateContent(String templateName) {
    switch (templateName.toLowerCase()) {
      case 'lump sum':
        return '''[DATE] [Client Name] [Client Address] [Contractor Name] [Contractor Address] 
[Project Description] [Project Location] [Start Date] [Completion Date] [Duration]
[Total Amount] [Down Payment] [Progress Payment 1] [Progress Payment 2] [Progress Payment 3] 
[Final Payment] [Materials List] [Equipment List] [Payment Due Days] [Warranty Period] 
[Notice Period] [Contractor Title] [Client Title] [Witness Name]''';
      case 'cost-plus':
        return '''[DATE] [Client Name] [Client Address] [Contractor Name] [Contractor Address]
[Project Description] [Project Location] [Start Date] [Completion Date] [Duration]
[Contractor Fee Percentage] [Fixed Fee Amount] [Maximum Budget] [Payment Due Days]
[Warranty Period] [Notice Period] [Contractor Title] [Client Title] [Witness Name]''';
      case 'time and materials':
        return '''[DATE] [Client Name] [Client Address] [Contractor Name] [Contractor Address]
[Project Description] [Project Location] [Start Date] [Completion Date] [Duration]
[Hourly Rate] [Position/Trade] [Material Markup] [Equipment Markup] [Supervisor Rate]
[Skilled Rate] [General Rate] [Overtime Multiplier] [Invoice Frequency] [Late Fee Percentage]
[Estimated Budget] [Work Description] [Payment Due Days] [Warranty Period] [Notice Period]
[Contractor Title] [Client Title] [Witness Name]''';
      default:
        return '''[DATE] [Client Name] [Client Address] [Contractor Name] [Contractor Address]
[Project Description] [Project Location] [Start Date] [Completion Date] [Duration]
[Payment Due Days] [Warranty Period] [Notice Period] [Contractor Title] [Client Title] [Witness Name]''';
    }
  }

  List<ContractField> extractFieldsFromTemplate(String templateContent) {
    final fieldRegex = RegExp(r'\[([^\]]+)\]');
    final matches = fieldRegex.allMatches(templateContent);
    final Set<String> uniqueFields = {};
    
    for (final match in matches) {
      final fieldName = match.group(1);
      if (fieldName != null) {
        uniqueFields.add(fieldName);
      }
    }
    
    return uniqueFields.map((fieldName) {
      return ContractField(
        key: fieldName,
        label: fieldName,
        isRequired: isFieldRequired(fieldName),
        inputType: getInputType(fieldName),
        maxLines: getMaxLines(fieldName),
      );
    }).toList();
  }

  List<ContractField> buildDefaultFields() {
    return [
      ContractField(key: 'DATE', label: 'Contract Date', isRequired: true),
      ContractField(key: 'Client Name', label: 'Client Name', isRequired: true),
      ContractField(key: 'Client Address', label: 'Client Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Contractor Name', label: 'Contractor Name', isRequired: true),
      ContractField(key: 'Contractor Address', label: 'Contractor Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Project Description', label: 'Project Description', isRequired: true, maxLines: 3),
      ContractField(key: 'Project Location', label: 'Project Location', isRequired: true, maxLines: 2),
      ContractField(key: 'Start Date', label: 'Start Date', isRequired: true),
      ContractField(key: 'Completion Date', label: 'Completion Date', isRequired: true),
      ContractField(key: 'Duration', label: 'Duration (days)', isRequired: true),
      ContractField(key: 'Payment Due Days', label: 'Payment Due Days', inputType: TextInputType.number),
      ContractField(key: 'Warranty Period', label: 'Warranty Period', isRequired: true),
      ContractField(key: 'Notice Period', label: 'Notice Period (days)', inputType: TextInputType.number),
      ContractField(key: 'Contractor Title', label: 'Contractor Title'),
      ContractField(key: 'Client Title', label: 'Client Title'),
      ContractField(key: 'Witness Name', label: 'Witness Name'),
    ];
  }

  bool isFieldRequired(String fieldName) {
    final requiredFields = {
      'DATE', 'Client Name', 'Client Address', 'Contractor Name', 'Contractor Address',
      'Project Description', 'Project Location', 'Start Date', 'Completion Date', 'Duration'
    };
    return requiredFields.contains(fieldName);
  }

  TextInputType getInputType(String fieldName) {
    if (fieldName.toLowerCase().contains('amount') ||
        fieldName.toLowerCase().contains('rate') ||
        fieldName.toLowerCase().contains('payment') ||
        fieldName.toLowerCase().contains('budget') ||
        fieldName.toLowerCase().contains('fee') ||
        fieldName.toLowerCase().contains('percentage') ||
        fieldName.toLowerCase().contains('days') ||
        fieldName.toLowerCase().contains('duration') ||
        fieldName.toLowerCase().contains('multiplier')) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  int getMaxLines(String fieldName) {
    if (fieldName.toLowerCase().contains('description') ||
        fieldName.toLowerCase().contains('list')) {
      return 3;
    }
    if (fieldName.toLowerCase().contains('address') ||
        fieldName.toLowerCase().contains('location')) {
      return 2;
    }
    return 1;
  }

  Future<Map<String, dynamic>?> fetchProjectData(String projectId) async {
    try {
      return await FetchService().fetchProjectDetails(projectId);
    } catch (e) {
      rethrow;
    }
  }

  void populateProjectFields(Map<String, dynamic> projectData, Map<String, TextEditingController> controllers, String? selectedContractType) {
    controllers['Project Description']?.text = projectData['description'] ?? '';
    controllers['Project Location']?.text = projectData['location'] ?? '';
    controllers['Duration']?.text = projectData['duration']?.toString() ?? '';
    
    final contractType = selectedContractType?.toLowerCase();
    if (contractType == 'lump sum') {
      final maxBudget = projectData['max_budget']?.toString() ?? '';
      if (maxBudget.isNotEmpty) {
        controllers['Total Amount']?.text = maxBudget;
        calculatePaymentSchedule(maxBudget, controllers);
      }
    } else if (contractType == 'cost-plus') {
      final maxBudget = projectData['max_budget']?.toString() ?? '';
      if (maxBudget.isNotEmpty) {
        controllers['Maximum Budget']?.text = maxBudget;
      }
    } else if (contractType == 'time and materials') {
      final maxBudget = projectData['max_budget']?.toString() ?? '';
      if (maxBudget.isNotEmpty) {
        controllers['Estimated Budget']?.text = maxBudget;
      }
    }
    
    controllers['DATE']?.text = DateTime.now().toString().split(' ')[0];
    
    if (projectData['start_date'] != null) {
      controllers['Start Date']?.text = projectData['start_date'].toString().split(' ')[0];
    } else {
      controllers['Start Date']?.text = DateTime.now().toString().split(' ')[0];
    }
    
    final duration = int.tryParse(projectData['duration']?.toString() ?? '') ?? 30;
    final startDate = DateTime.tryParse(controllers['Start Date']?.text ?? '') ?? DateTime.now();
    final completionDate = startDate.add(Duration(days: duration));
    controllers['Completion Date']?.text = completionDate.toString().split(' ')[0];
    
    controllers['Payment Due Days']?.text = '30';
    controllers['Warranty Period']?.text = '1 year';
    controllers['Notice Period']?.text = '7';
  }

  void calculatePaymentSchedule(String totalAmountStr, Map<String, TextEditingController> controllers) {
    final totalAmount = double.tryParse(totalAmountStr.replaceAll(',', '')) ?? 0;
    if (totalAmount > 0) {
      final downPayment = totalAmount * 0.20;
      final progressPayment = totalAmount * 0.20;
      final finalPayment = totalAmount * 0.20;
      
      controllers['Down Payment']?.text = downPayment.toStringAsFixed(0);
      controllers['Progress Payment 1']?.text = progressPayment.toStringAsFixed(0);
      controllers['Progress Payment 2']?.text = progressPayment.toStringAsFixed(0);
      controllers['Progress Payment 3']?.text = progressPayment.toStringAsFixed(0);
      controllers['Final Payment']?.text = finalPayment.toStringAsFixed(0);
    }
  }

  Future<void> populateContractorInfo(String contractorId, Map<String, TextEditingController> controllers) async {
    try {
      final contractorData = await FetchService().fetchContractorData(contractorId);
      if (contractorData != null) {
        controllers['Contractor Name']?.text = contractorData['firm_name'] ?? '';
        controllers['Contractor Address']?.text = contractorData['address'] ?? '';
        controllers['Contractor Title']?.text = 'General Contractor';
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void clearAutoPopulatedFields(Map<String, TextEditingController> controllers) {
    controllers['Project Description']?.clear();
    controllers['Project Location']?.clear();
    controllers['Duration']?.clear();
    controllers['Start Date']?.clear();
    controllers['Completion Date']?.clear();
    controllers['Total Amount']?.clear();
    controllers['Maximum Budget']?.clear();
    controllers['Estimated Budget']?.clear();
    controllers['Down Payment']?.clear();
    controllers['Progress Payment 1']?.clear();
    controllers['Progress Payment 2']?.clear();
    controllers['Progress Payment 3']?.clear();
    controllers['Final Payment']?.clear();
    controllers['DATE']?.clear();
    controllers['Payment Due Days']?.clear();
    controllers['Warranty Period']?.clear();
    controllers['Notice Period']?.clear();
  }

  Future<Uint8List> generatePreview(String contractType, Map<String, String> fieldValues, String title) async {
    return await ContractPdfService.generateContractPdf(
      contractType: contractType,
      fieldValues: fieldValues,
      title: title,
    );
  }

  Future<void> saveContract({
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String projectId,
    required Map<String, String> fieldValues,
    required String contractType,
  }) async {
    await ContractService.saveContract(
      contractorId: contractorId,
      contractTypeId: contractTypeId,
      title: title,
      projectId: projectId,
      fieldValues: fieldValues,
      contractType: contractType,
    );
  }

  Future<void> updateContract({
    required String contractId,
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String projectId,
    required Map<String, String> fieldValues,
    required String contractType,
  }) async {
    await ContractService.updateContract(
      contractId: contractId,
      contractorId: contractorId,
      contractTypeId: contractTypeId,
      title: title,
      projectId: projectId,
      fieldValues: fieldValues,
      contractType: contractType,
    );
  }
}