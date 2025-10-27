import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:flutter/material.dart';

class ContractField {
  final String key;
  final String label;
  final String placeholder;
  final TextInputType inputType;
  final bool isRequired;
  final int maxLines;
  final bool isEnabled;

  ContractField({
    required this.key,
    required this.label,
    this.placeholder = '',
    this.inputType = TextInputType.text,
    this.isRequired = false,
    this.maxLines = 1,
    this.isEnabled = true,
  });
}

class CreateContractService {

  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  Future<void> checkForSingleProject(String contractorId, Function(String?) onProjectSelected) async {
    try {
      final projects = await FetchService().fetchContractorProjectInfo(contractorId);
      if (projects.length == 1) {
        final projectId = projects.first['project_id'] as String;
        onProjectSelected(projectId);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check for single project: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Check for Single Project',
          'contractor_id': contractorId,
        },
      );
      return;
    }
  }

  List<ContractField> getContractTypeSpecificFields(String contractType, {int itemCount = 3, int milestoneCount = 4}) {
    try {
      final normalizedType = contractType.toLowerCase();
      return getTemplateSpecificFields(normalizedType, itemCount: itemCount, milestoneCount: milestoneCount);
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get contract type specific fields:',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Contract Type Specific Fields',
          'contract_type': contractType,
        },
      );
      return [];
    }
  }

  List<ContractField> getTemplateSpecificFields(String contractType, {int itemCount = 3, int milestoneCount = 4}) {
    try {
      if (contractType.contains('lump sum')) {
        return getLumpSumFieldsWithMilestones(milestoneCount);
      } else if (contractType.contains('cost-plus') || contractType.contains('cost plus')) {
        return getCostPlusFields();
      } else if (contractType.contains('time and materials')) {
        return getTimeAndMaterialsFieldsWithItems(itemCount);
      }
      return [];
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get template specific fields: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Template Specific Fields',
          'contract_type': contractType,
        },
      );
      return [];
    }
  }

  List<ContractField> getLumpSumFields() {
    return getLumpSumFieldsWithMilestones(4);
  }

  List<ContractField> getLumpSumFieldsWithMilestones(int milestoneCount) {
    try {
      List<ContractField> fields = [
        ContractField(key: 'Contract.CreationDate', label: 'Contract Creation Date', isRequired: true),

        ContractField(key: 'Contractee.FirstName', label: 'Contractee First Name', isRequired: true),
        ContractField(key: 'Contractee.LastName', label: 'Contractee Last Name', isRequired: true),
        ContractField(key: 'Contractee.Address', label: 'Contractee Street Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Contractee.Phone', label: 'Contractee Phone', isRequired: true),
        ContractField(key: 'Contractee.Email', label: 'Contractee Email', isRequired: true),
        
        ContractField(key: 'Contractor.Company', label: 'Contractor Company', isRequired: true),
        ContractField(key: 'Contractor.FirstName', label: 'Contractor First Name', isRequired: true),
        ContractField(key: 'Contractor.LastName', label: 'Contractor Last Name', isRequired: true),
        ContractField(key: 'Contractor.Address', label: 'Contractor Street Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Contractor.Phone', label: 'Contractor Phone', isRequired: true),
        ContractField(key: 'Contractor.Email', label: 'Contractor Email', isRequired: true),
        ContractField(key: 'Contractor.Province', label: 'Contractor Province', isRequired: true),
        
        ContractField(key: 'Project.Description', label: 'Project Description', isRequired: true, maxLines: 3),
        ContractField(key: 'Project.Address', label: 'Project Site Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Project.StartDate', label: 'Project Start Date', isRequired: true),
        ContractField(key: 'Project.CompletionDate', label: 'Project Completion Date', isRequired: true),
        ContractField(key: 'Project.Duration', label: 'Project Duration (days)', isRequired: true, inputType: TextInputType.number),
        ContractField(key: 'Project.WorkingDays', label: 'Working Days (e.g., Monday through Friday)', isRequired: true),
        ContractField(key: 'Project.WorkingHours', label: 'Working Hours (e.g., 8:00 AM - 5:00 PM)', isRequired: true),
        
        ContractField(key: 'Payment.Total', label: 'Total Contract Price (₱)', isRequired: true, inputType: TextInputType.number),
        ContractField(key: 'Payment.DownPaymentPercentage', label: 'Down Payment Percentage (%)', inputType: TextInputType.number),
        ContractField(key: 'Payment.RetentionPercentage', label: 'Retention Percentage (%)', inputType: TextInputType.number),
        ContractField(key: 'Payment.RetentionPeriod', label: 'Retention Period (days)', inputType: TextInputType.number),
        ContractField(key: 'Payment.DueDays', label: 'Payment Due Days from Invoice', inputType: TextInputType.number),
        ContractField(key: 'Payment.LateFeePercentage', label: 'Late Payment Fee Percentage (%)', inputType: TextInputType.number),
      ];

      for (int i = 1; i <= milestoneCount; i++) {
        fields.addAll([
          ContractField(key: 'Milestone.$i.Description', label: 'Milestone Description', isRequired: i <= 3, maxLines: 2),
          ContractField(key: 'Milestone.$i.Duration', label: 'Milestone Duration (days)', isRequired: i <= 3, inputType: TextInputType.number),
          ContractField(key: 'Milestone.$i.Date', label: 'Milestone Target Date', isRequired: i <= 3),
        ]);
      }

      fields.addAll([
        ContractField(key: 'Bond.TimeFrame', label: 'Bond Submission Timeframe (days)', inputType: TextInputType.number),
        ContractField(key: 'Bond.PerformanceAmount', label: 'Performance Bond Amount (₱)', inputType: TextInputType.number),
        ContractField(key: 'Bond.PaymentAmount', label: 'Payment Bond Amount (₱)', inputType: TextInputType.number),
        
        ContractField(key: 'Change.LaborRate', label: 'Change Order Labor Rate (₱/hr)', inputType: TextInputType.number),
        ContractField(key: 'Change.MaterialMarkup', label: 'Change Order Material Markup (%)', inputType: TextInputType.number),
        ContractField(key: 'Change.EquipmentMarkup', label: 'Change Order Equipment Markup (%)', inputType: TextInputType.number),
        
        ContractField(key: 'Notice.Period', label: 'Termination Notice Period (days)', inputType: TextInputType.number),
        ContractField(key: 'Warranty.Period', label: 'Warranty Period (months)', inputType: TextInputType.number),
      ]);

      return fields;
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get lump sum fields: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Lump Sum Fields',
        },
      );
      return [];
    }
  }

  List<ContractField> getCostPlusFields() {
    try {
      return [
        ContractField(key: 'Contract.CreationDate', label: 'Contract Creation Date', isRequired: true),
        
        ContractField(key: 'Contractor.Company', label: 'Contractor Company Name', isRequired: true),
        ContractField(key: 'Contractor.FirstName', label: 'Contractor First Name', isRequired: true),
        ContractField(key: 'Contractor.LastName', label: 'Contractor Last Name', isRequired: true),
        ContractField(key: 'Contractor.Address', label: 'Contractor Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Contractor.Phone', label: 'Contractor Phone', isRequired: true),
        ContractField(key: 'Contractor.Email', label: 'Contractor Email', isRequired: true),
        ContractField(key: 'Contractor.Province', label: 'Contractor Province', isRequired: true),

        ContractField(key: 'Contractee.FirstName', label: 'Contractee First Name', isRequired: true),
        ContractField(key: 'Contractee.LastName', label: 'Contractee Last Name', isRequired: true),
        ContractField(key: 'Contractee.Address', label: 'Contractee Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Contractee.Phone', label: 'Contractee Phone', isRequired: true),
        ContractField(key: 'Contractee.Email', label: 'Contractee Email', isRequired: true),
        
        ContractField(key: 'Project.Description', label: 'Project Description', isRequired: true, maxLines: 3),
        ContractField(key: 'Project.Address', label: 'Project Address/Location', isRequired: true, maxLines: 2),
        ContractField(key: 'Project.StartDate', label: 'Project Start Date', isRequired: true),
        ContractField(key: 'Project.CompletionDate', label: 'Project Completion Date (Estimate)', isRequired: true),
        ContractField(key: 'Project.Duration', label: 'Project Duration (days)', isRequired: true, inputType: TextInputType.number),
        
        ContractField(key: 'Labor.Costs', label: 'Labor Costs per Hour (₱)', isRequired: true, inputType: TextInputType.number),
        ContractField(key: 'Material.Costs', label: 'Estimated Material Costs (₱)', inputType: TextInputType.number),
        ContractField(key: 'Equipment.Costs', label: 'Estimated Equipment Costs (₱)', inputType: TextInputType.number),
        ContractField(key: 'Overhead.Percentage', label: 'Overhead and Profit Percentage (%)', isRequired: true, inputType: TextInputType.number),
        ContractField(key: 'Estimated.Total', label: 'Total Estimated Project Cost (₱)', isRequired: true, inputType: TextInputType.number),
        
        ContractField(key: 'Payment.Interval', label: 'Payment Interval (weekly/bi-weekly/monthly)', isRequired: true),
        ContractField(key: 'Retention.Fee', label: 'Retention Fee (₱)', inputType: TextInputType.number),
        ContractField(key: 'Late.Fee.Percentage', label: 'Late Payment Fee Percentage (%)', inputType: TextInputType.number),
        ContractField(key: 'Payment.DueDays', label: 'Payment Due Days from Invoice', inputType: TextInputType.number),
        
        ContractField(key: 'Bond.TimeFrame', label: 'Bond Submission Timeframe (days)', inputType: TextInputType.number),
        ContractField(key: 'Bond.PaymentAmount', label: 'Payment Bond Amount (₱)', inputType: TextInputType.number),
        ContractField(key: 'Bond.PerformanceAmount', label: 'Performance Bond Amount (₱)', inputType: TextInputType.number),

        ContractField(key: 'Notice.Period', label: 'Termination Notice Period (days)', inputType: TextInputType.number),
        ContractField(key: 'Warranty.Period', label: 'Warranty Period (months)', inputType: TextInputType.number),
      ];
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get cost plus fields: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Cost Plus Fields',
        },
      );
      return [];
    }
  }

  List<ContractField> getTimeAndMaterialsFields() {
    try {
      return [
        
        ContractField(key: 'Contract.CreationDate', label: 'Contract Creation Date', isRequired: true),
        
        ContractField(key: 'Contractee.FirstName', label: 'Contractee First Name', isRequired: true),
        ContractField(key: 'Contractee.LastName', label: 'Contractee Last Name', isRequired: true),
        ContractField(key: 'Contractee.Address', label: 'Contractee Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Contractee.City', label: 'Contractee City', isRequired: true),
        ContractField(key: 'Contractee.PostalCode', label: 'Contractee Postal Code', isRequired: true),
        
        ContractField(key: 'Contractor.FirstName', label: 'Contractor First Name', isRequired: true),
        ContractField(key: 'Contractor.LastName', label: 'Contractor Last Name', isRequired: true),
        ContractField(key: 'Contractor.Address', label: 'Contractor Address', isRequired: true, maxLines: 2),
        ContractField(key: 'Contractor.City', label: 'Contractor City', isRequired: true),
        ContractField(key: 'Contractor.PostalCode', label: 'Contractor Postal Code', isRequired: true),
        ContractField(key: 'Contractor.Company', label: 'Contractor Company (for signature)', isRequired: true),
        
        ContractField(key: 'Project.ContractorDef', label: 'Project Definition by Contractor', isRequired: true, maxLines: 3),
        ContractField(key: 'Project.Scope', label: 'Project Scope of Work', isRequired: true, maxLines: 3),
        ContractField(key: 'Project.LaborHours', label: 'Project Labor Hours', isRequired: true, inputType: TextInputType.number),
        ContractField(key: 'Project.Duration', label: 'Project Duration', isRequired: true),
        ContractField(key: 'Project.StartDate', label: 'Project Start Date', isRequired: true),
        ContractField(key: 'Project.CompletionDate', label: 'Project Completion Date', isRequired: true),
        ContractField(key: 'Project.Schedule', label: 'Project Schedule', maxLines: 4, placeholder: 'Enter detailed project schedule including phases, dates, and key activities'),
        ContractField(key: 'Project.MilestonesList', label: 'Project Milestones List', maxLines: 4, placeholder: 'List major project milestones with completion dates and deliverables'),
        
        ContractField(key: 'Materials.List', label: 'Materials List', maxLines: 3),
        
        ContractField(key: 'ItemCount', label: 'Number of Items', inputType: TextInputType.number, isRequired: true),
        
        ContractField(key: 'Payment.Subtotal', label: 'Payment Subtotal (₱)', inputType: TextInputType.number, isEnabled: false),

  ContractField(key: 'Payment.Discount', label: 'Payment Discount (%)', placeholder: 'e.g., 5%', inputType: TextInputType.number),
  ContractField(key: 'Payment.Tax', label: 'Payment Tax (%)', placeholder: 'e.g., 12%', inputType: TextInputType.number, isRequired: true),
      ContractField(key: 'Payment.Total', label: 'Payment Total (₱)', inputType: TextInputType.number, isEnabled: false),
      
      ContractField(key: 'Penalty.Amount', label: 'Penalty Amount (₱)', inputType: TextInputType.number),
      ContractField(key: 'Tax.List', label: 'Tax List', maxLines: 2),
    ];
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get time and materials fields: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Time and Materials Fields',
        },
      );
      return [];
    }
  }

  List<ContractField> getTimeAndMaterialsFieldsWithItems(int itemCount) {
    try {
      List<ContractField> fields = getTimeAndMaterialsFields();
      
      fields.removeWhere((field) => field.key == 'ItemCount');

      int insertIndex = fields.indexWhere((field) => field.key == 'Materials.List') + 1;
      
      List<ContractField> itemFields = [];
      for (int i = 1; i <= itemCount; i++) {
        itemFields.addAll([
          ContractField(key: 'Item.$i.Name', label: 'Item Name', isRequired: i <= 3), 
          ContractField(key: 'Item.$i.Description', label: 'Item Description', isRequired: i <= 3),
          ContractField(key: 'Item.$i.Price', label: 'Item Price (₱)', isRequired: i <= 3, inputType: TextInputType.number),
          ContractField(key: 'Item.$i.Quantity', label: 'Item Quantity', isRequired: i <= 3, inputType: TextInputType.number),
          ContractField(key: 'Item.$i.Subtotal', label: 'Item Subtotal (₱)', inputType: TextInputType.number, isEnabled: false), 
        ]);
      }
      
      fields.insertAll(insertIndex, itemFields);
      
      return fields;
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get time and materials fields with items: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Time and Materials Fields with Items',
          'item_count': itemCount,
        },
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchProjectData(String projectId) async {
    try {
      return await FetchService().fetchProjectDetails(projectId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch project data:',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Project Data',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  void populateProjectFields(Map<String, dynamic> projectData, Map<String, TextEditingController> controllers, String? selectedContractType) {
    try {
      controllers['Project.Description']?.text = projectData['description'] ?? '';
      controllers['Project.Address']?.text = projectData['location'] ?? '';
      

      final currentDate = DateTime.now().toString().split(' ')[0];
      controllers['Contract.CreationDate']?.text = currentDate;
      
      if (projectData['start_date'] != null) {
        final startDate = projectData['start_date'].toString().split(' ')[0];
        controllers['Project.StartDate']?.text = startDate;
      } else {
        controllers['Project.StartDate']?.text = currentDate;
      }
      
      if (projectData['end_date'] != null) {
        final endDate = projectData['end_date'].toString().split(' ')[0];
        controllers['Project.CompletionDate']?.text = endDate;
      }

      if (projectData['start_date'] != null && projectData['end_date'] != null) {
        try {
          final startDate = DateTime.parse(projectData['start_date'].toString());
          final endDate = DateTime.parse(projectData['end_date'].toString());
          final duration = endDate.difference(startDate).inDays;
          if (duration > 0) {
            controllers['Project.Duration']?.text = duration.toString();
          }
        } catch (_) {}
      }

      final contractType = selectedContractType?.toLowerCase();
      final maxBudget = projectData['max_budget']?.toString() ?? '';
      
      if (contractType?.contains('lump sum') == true) {
        if ((controllers['Payment.Total']?.text ?? '').isEmpty && maxBudget.isNotEmpty) {
          controllers['Payment.Total']?.text = maxBudget;
        }
      } else if (contractType?.contains('cost-plus') == true || contractType?.contains('cost plus') == true) {
        if ((controllers['Estimated.Total']?.text ?? '').isEmpty && maxBudget.isNotEmpty) {
          controllers['Estimated.Total']?.text = maxBudget;
        }
      } else if (contractType?.contains('time and materials') == true) {
        if ((controllers['Payment.Total']?.text ?? '').isEmpty && maxBudget.isNotEmpty) {
          controllers['Payment.Total']?.text = maxBudget;
        }
      }
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to populate project fields: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Populate Project Fields',
        },
      );
    }
  }

  void calculateTimeAndMaterialsRates(Map<String, TextEditingController> controllers, {int? itemCount}) {
    try {
      double totalSubtotal = 0.0;

      int maxItems = itemCount ?? getMaxItemCountFromControllers(controllers);
      
      for (int i = 1; i <= maxItems; i++) {
        final priceKey = 'Item.$i.Price';
        final quantityKey = 'Item.$i.Quantity';
        final subtotalKey = 'Item.$i.Subtotal';
        
        final price = double.tryParse(controllers[priceKey]?.text ?? '0') ?? 0;
        final quantity = double.tryParse(controllers[quantityKey]?.text ?? '0') ?? 0;
        
        if (price > 0 && quantity > 0) {
          final subtotal = price * quantity;
          controllers[subtotalKey]?.text = subtotal.toStringAsFixed(2);
          totalSubtotal += subtotal;
        } else if (controllers[subtotalKey] != null) {
          controllers[subtotalKey]?.text = '0.00';
        }
      }
      
      controllers['Payment.Subtotal']?.text = totalSubtotal.toStringAsFixed(2);
      
      double parsePercent(String raw) {
        final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '');
        final v = double.tryParse(cleaned) ?? 0.0;
        if (v <= 0) return 0.0;
        return v > 1.0 ? (v / 100.0) : v;
      }
      final discountRate = parsePercent(controllers['Payment.Discount']?.text ?? '0');
      final discountAmount = totalSubtotal * discountRate;
      final taxRate = parsePercent(controllers['Payment.Tax']?.text ?? '0');
      final taxAmount = totalSubtotal * taxRate;

      final total = totalSubtotal - discountAmount + taxAmount;
      controllers['Payment.Total']?.text = total.toStringAsFixed(2);

      controllers['Payment.DiscountAmount']?.text = discountAmount.toStringAsFixed(2);

      controllers['Payment.TaxAmount']?.text = taxAmount.toStringAsFixed(2);
      
      controllers['Contract Price']?.text = total.toStringAsFixed(2);
      controllers['Estimated Budget']?.text = total.toStringAsFixed(2);
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to calculate time and materials rates: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Calculate Time and Materials Rates',
        },
      );
    }
  }

  int getMaxItemCountFromControllers(Map<String, TextEditingController> controllers) {
    try {
      int maxItems = 3; 
      
      for (String key in controllers.keys) {
        if (key.startsWith('Item.') && key.endsWith('.Name')) {
          final itemNumberStr = key.split('.')[1];
          final itemNumber = int.tryParse(itemNumberStr) ?? 0;
          if (itemNumber > maxItems) {
            maxItems = itemNumber;
          }
        }
      }
      
      return maxItems;
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get max item count from controllers: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Max Item Count from Controllers',
        },
      );
      return 3;
    }
  }

  int getMaxMilestoneCountFromControllers(Map<String, TextEditingController> controllers) {
    try {
      int maxMilestones = 4; 
      
      for (String key in controllers.keys) {
        if (key.startsWith('Milestone.') && key.endsWith('.Description')) {
          final milestoneNumberStr = key.split('.')[1];
          final milestoneNumber = int.tryParse(milestoneNumberStr) ?? 0;
          if (milestoneNumber > maxMilestones) {
            maxMilestones = milestoneNumber;
          }
        }
      }
      
      return maxMilestones;
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get max milestone count from controllers: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Max Milestone Count from Controllers',
        },
      );
      return 4;
    }
  }

  

  Future<void> populateContractorInfo(String contractorId, Map<String, TextEditingController> controllers) async {
    try {

      final firstName = controllers['Contractor.FirstName']?.text.trim();
      final lastName = controllers['Contractor.LastName']?.text.trim();
      final company = controllers['Contractor.Company']?.text.trim();
      final address = controllers['Contractor.Address']?.text.trim();
      final city = controllers['Contractor.City']?.text.trim();
      final postal = controllers['Contractor.PostalCode']?.text.trim();
      final title = controllers['Contractor.Title']?.text.trim();

    final composedName = [firstName, lastName]
      .where((v) => (v ?? '').isNotEmpty)
      .map((v) => v!)
      .join(' ');
      if (controllers['Contractor Name'] != null) {
        controllers['Contractor Name']!.text = composedName.isNotEmpty
            ? composedName
            : (company != null && company.isNotEmpty ? company : controllers['Contractor Name']!.text);
      }

      final parts = <String>[];
      if (address != null && address.isNotEmpty) parts.add(address);
      if (city != null && city.isNotEmpty) parts.add(city);
      if (postal != null && postal.isNotEmpty) parts.add(postal);
      if (controllers['Contractor Address'] != null && parts.isNotEmpty) {
        controllers['Contractor Address']!.text = parts.join(', ');
      }

      if (controllers['Contractor Title'] != null && title != null && title.isNotEmpty) {
        controllers['Contractor Title']!.text = title;
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to populate contractor info:',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Populate Contractor Info',
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  void clearAutoPopulatedFields(Map<String, TextEditingController> controllers) {
    try {
      controllers['Project.Description']?.clear();
      controllers['Project.Address']?.clear();
      controllers['Project.Duration']?.clear();
      controllers['Project.StartDate']?.clear();
      controllers['Project.CompletionDate']?.clear();
      
      controllers['Project.ContractPrice']?.clear();
      controllers['Estimated Total']?.clear();
      controllers['Payment.Total']?.clear();
      
      controllers['Payment.DownPaymentPercentage']?.clear();
      controllers['Payment.ProgressPayment1Percentage']?.clear();
      controllers['Payment.ProgressPayment2Percentage']?.clear();
      controllers['Payment.FinalPaymentPercentage']?.clear();
      
      controllers['Overhead Percentage']?.clear();
      controllers['Labor Costs']?.clear();
      controllers['Material Costs']?.clear();
      controllers['Equipment Costs']?.clear();
      
      for (int i = 1; i <= 5; i++) {
        controllers['Item.$i.Name']?.clear();
        controllers['Item.$i.Description']?.clear();
        controllers['Item.$i.Price']?.clear();
        controllers['Item.$i.Quantity']?.clear();
        controllers['Item.$i.Subtotal']?.clear();
      }
      controllers['Payment.Subtotal']?.clear();
      controllers['Payment.Discount']?.clear();
      controllers['Payment.Tax']?.clear();
      
      controllers['Contract.CreationDate']?.clear();
      
      controllers['Penalty.Amount']?.clear();
      controllers['Payment.DueDays']?.clear();
      controllers['Warranty Period']?.clear();
      controllers['Notice Period']?.clear();
      controllers['Late Fee Percentage']?.clear();
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to clear auto populated fields: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Clear Auto Populated Fields',
        },
      );
    }
  }

  Future<void> saveContract({
    required String contractorId,
    required String contractTypeId,
    required String title,
    required String projectId,
    required Map<String, String> fieldValues,
    required String contractType,
  }) async {
    try {
      await ContractService.saveContract(
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        projectId: projectId,
        fieldValues: fieldValues,
        contractType: contractType,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to save contract: ',
        module: 'Create Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Save Contract',
          'contractor_id': contractorId,
          'project_id': projectId,
        },
      );
      rethrow;
    }
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
    try {
      await ContractService.updateContract(
        contractId: contractId,
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        projectId: projectId,
        fieldValues: fieldValues,
        contractType: contractType,
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to update contract: ',
        module: 'Create Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Update Contract',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchContractFieldValues(
    String contractId, {
    String? contractorId,
  }) async {
    try {
      final contractData = await FetchService().fetchContractData(
        contractId,
        contractorId: contractorId,
      );
      if (contractData != null && contractData['field_values'] != null) {
        return contractData['field_values'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch contract field values: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contract Field Values',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }
}