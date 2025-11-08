import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        errorMessage: 'Failed to check for single project: $e',
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
      return getTemplateSpecificFields(contractType, itemCount: itemCount, milestoneCount: milestoneCount);
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get contract type specific fields: $e',
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
      String norm(String s) => s
          .toLowerCase()
          .replaceAll('&', 'and')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      final normalized = norm(contractType);

      if (normalized.contains('lumpsum')) {
        return getLumpSumFieldsWithMilestones(milestoneCount);
      } else if (normalized.contains('costplus')) {
        return getCostPlusFields();
      } else if (normalized.contains('timeandmaterials') || normalized.contains('timeandmaterial')) {
        return getTimeAndMaterialsFieldsWithItems(itemCount);
      }
      return [];
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get template specific fields: $e',
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
          ContractField(key: 'Milestone.$i.Description', label: 'Milestone $i Description', isRequired: i <= 3, maxLines: 2),
          ContractField(key: 'Milestone.$i.Duration', label: 'Milestone $i Duration (days)', isRequired: i <= 3, inputType: TextInputType.number),
          ContractField(key: 'Milestone.$i.Date', label: 'Milestone $i Target Date', isRequired: i <= 3),
          ContractField(key: 'Milestone.$i.Amount', label: 'Milestone $i Payment Amount (₱)', isRequired: i <= 3, inputType: TextInputType.number),
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
      // Only populate non-numeric fields and start date - NO BUDGETS OR NUMBERS
      // Only fill if field is empty (preserve manual entries)
      if ((controllers['Project.Description']?.text ?? '').isEmpty) {
        controllers['Project.Description']?.text = projectData['description'] ?? '';
      }
      if ((controllers['Project.Address']?.text ?? '').isEmpty) {
        controllers['Project.Address']?.text = projectData['location'] ?? '';
      }

      final currentDate = DateTime.now().toString().split(' ')[0];
      controllers['Contract.CreationDate']?.text = currentDate;

      // Only populate start date if empty - preserve manual entries
      if ((controllers['Project.StartDate']?.text ?? '').isEmpty) {
        if (projectData['start_date'] != null) {
          final startDate = projectData['start_date'].toString().split(' ')[0];
          controllers['Project.StartDate']?.text = startDate;
        } else {
          controllers['Project.StartDate']?.text = currentDate;
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

  void calculateMilestonePayments(Map<String, TextEditingController> controllers, {int? milestoneCount}) {
    try {
      double totalContractPrice = 0.0;
      
      final totalPriceText = controllers['Payment.Total']?.text ?? '0';
      try {
        totalContractPrice = double.parse(totalPriceText.replaceAll(',', ''));
      } catch (e) {
        return; 
      }
      
      if (totalContractPrice <= 0) return;
      
      int maxMilestones = milestoneCount ?? getMaxMilestoneCountFromControllers(controllers);
      double totalMilestoneAmounts = 0.0;
      List<double> milestoneAmounts = [];

      for (int i = 1; i <= maxMilestones; i++) {
        final amountText = controllers['Milestone.$i.Amount']?.text ?? '0';
        try {
          double amount = double.parse(amountText.replaceAll(',', ''));
          milestoneAmounts.add(amount);
          totalMilestoneAmounts += amount;
        } catch (e) {
          milestoneAmounts.add(0.0);
        }
      }
      
      if (totalMilestoneAmounts == 0) {
        int activeMilestones = 0;
        for (int i = 1; i <= maxMilestones; i++) {
          final description = controllers['Milestone.$i.Description']?.text ?? '';
          if (description.trim().isNotEmpty) {
            activeMilestones++;
          }
        }
        
        if (activeMilestones > 0) {
          double amountPerMilestone = totalContractPrice / activeMilestones;
          for (int i = 1; i <= maxMilestones; i++) {
            final description = controllers['Milestone.$i.Description']?.text ?? '';
            if (description.trim().isNotEmpty) {
              controllers['Milestone.$i.Amount']?.text = amountPerMilestone.toStringAsFixed(2);
            }
          }
        }
      }
      
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to calculate milestone payments: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Calculate Milestone Payments',
        },
      );
    }
  }

  Map<String, dynamic> validateMilestonePayments(Map<String, TextEditingController> controllers, {int? milestoneCount}) {
    try {
      double totalContractPrice = 0.0;
      
      final totalPriceText = controllers['Payment.Total']?.text ?? '0';
      try {
        totalContractPrice = double.parse(totalPriceText.replaceAll(',', ''));
      } catch (e) {
        return {'isValid': false, 'message': 'Invalid total contract price'};
      }
      
      if (totalContractPrice <= 0) {
        return {'isValid': false, 'message': 'Total contract price must be greater than 0'};
      }
      
      int maxMilestones = milestoneCount ?? getMaxMilestoneCountFromControllers(controllers);
      double totalMilestoneAmounts = 0.0;
      int activeMilestones = 0;

      for (int i = 1; i <= maxMilestones; i++) {
        final description = controllers['Milestone.$i.Description']?.text ?? '';
        final amountText = controllers['Milestone.$i.Amount']?.text ?? '0';
        
        if (description.trim().isNotEmpty) {
          activeMilestones++;
          try {
            double amount = double.parse(amountText.replaceAll(',', ''));
            if (amount < 0) {
              return {'isValid': false, 'message': 'Milestone $i amount cannot be negative'};
            }
            totalMilestoneAmounts += amount;
          } catch (e) {
            return {'isValid': false, 'message': 'Invalid amount for milestone $i'};
          }
        }
      }

      double difference = (totalMilestoneAmounts - totalContractPrice).abs();
      if (difference > 0.01) { 
        return {
          'isValid': false, 
          'message': 'Total milestone amounts (₱${totalMilestoneAmounts.toStringAsFixed(2)}) must equal total contract price (₱${totalContractPrice.toStringAsFixed(2)})'
        };
      }
      
      return {
        'isValid': true, 
        'message': 'Milestone payments are valid',
        'totalMilestoneAmounts': totalMilestoneAmounts,
        'totalContractPrice': totalContractPrice,
        'activeMilestones': activeMilestones
      };
      
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to validate milestone payments: ',
        module: 'Create Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Validate Milestone Payments',
        },
      );
      return {'isValid': false, 'message': 'Error validating milestone payments'};
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
      // Auto-fill contractor and contractee information from database
      final enrichedFieldValues = await _enrichFieldValuesWithContactInfo(
        fieldValues,
        projectId,
        contractorId,
      );

      await ContractService.saveContract(
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        projectId: projectId,
        fieldValues: enrichedFieldValues,
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
      // Auto-fill contractor and contractee information from database
      final enrichedFieldValues = await _enrichFieldValuesWithContactInfo(
        fieldValues,
        projectId,
        contractorId,
      );

      await ContractService.updateContract(
        contractId: contractId,
        contractorId: contractorId,
        contractTypeId: contractTypeId,
        title: title,
        projectId: projectId,
        fieldValues: enrichedFieldValues,
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

  /// Enrich field values with contractor and contractee contact information from database
  Future<Map<String, String>> _enrichFieldValuesWithContactInfo(
    Map<String, String> fieldValues,
    String projectId,
    String contractorId,
  ) async {
    try {
      // Create a copy of fieldValues to modify
      final enrichedValues = Map<String, String>.from(fieldValues);

      // Get project data to find contractee_id
      final projectData = await Supabase.instance.client
          .from('Projects')
          .select('contractee_id')
          .eq('project_id', projectId)
          .single();

      final contracteeId = projectData['contractee_id'] as String?;

      // Fetch contractor information
      if (contractorId.isNotEmpty) {
        try {
          final contractorData = await Supabase.instance.client
              .from('Contractor')
              .select('firm_name, contact_number, address, bio, specialization')
              .eq('contractor_id', contractorId)
              .single();

          // Also fetch contractor email from Users table
          String? contractorEmail;
          try {
            final userData = await Supabase.instance.client
                .from('Users')
                .select('email')
                .eq('users_id', contractorId)
                .single();
            contractorEmail = userData['email'] as String?;
          } catch (e) {
            debugPrint('Failed to fetch contractor email for enrichment: $e');
          }

          // Auto-fill contractor information if not already set
          if (contractorData['firm_name'] != null && (enrichedValues['Contractor.Company']?.isEmpty ?? true)) {
            enrichedValues['Contractor.Company'] = contractorData['firm_name'] as String;
          }
          if (contractorData['contact_number'] != null && (enrichedValues['Contractor.Phone']?.isEmpty ?? true)) {
            enrichedValues['Contractor.Phone'] = contractorData['contact_number'] as String;
          }
          if (contractorData['address'] != null && (enrichedValues['Contractor.Address']?.isEmpty ?? true)) {
            enrichedValues['Contractor.Address'] = contractorData['address'] as String;
          }
          if (contractorData['bio'] != null && (enrichedValues['Contractor.Bio']?.isEmpty ?? true)) {
            enrichedValues['Contractor.Bio'] = contractorData['bio'] as String;
          }
          if (contractorEmail != null && (enrichedValues['Contractor.Email']?.isEmpty ?? true)) {
            enrichedValues['Contractor.Email'] = contractorEmail;
          }
        } catch (e) {
          debugPrint('Failed to fetch contractor data: $e');
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

          // Also fetch contractee email from Users table
          String? contracteeEmail;
          try {
            final userData = await Supabase.instance.client
                .from('Users')
                .select('email')
                .eq('users_id', contracteeId)
                .single();
            contracteeEmail = userData['email'] as String?;
          } catch (e) {
            debugPrint('Failed to fetch contractee email for enrichment: $e');
          }

          // Auto-fill contractee information if not already set
          if (contracteeData['full_name'] != null) {
            // Split full name into first and last name
            final fullName = contracteeData['full_name'] as String;
            final nameParts = fullName.split(' ');
            if (nameParts.isNotEmpty && (enrichedValues['Contractee.FirstName']?.isEmpty ?? true)) {
              enrichedValues['Contractee.FirstName'] = nameParts.first;
            }
            if (nameParts.length > 1 && (enrichedValues['Contractee.LastName']?.isEmpty ?? true)) {
              enrichedValues['Contractee.LastName'] = nameParts.sublist(1).join(' ');
            }
          }

          if (contracteeData['phone_number'] != null && (enrichedValues['Contractee.Phone']?.isEmpty ?? true)) {
            enrichedValues['Contractee.Phone'] = contracteeData['phone_number'] as String;
          }
          if (contracteeData['address'] != null && (enrichedValues['Contractee.Address']?.isEmpty ?? true)) {
            enrichedValues['Contractee.Address'] = contracteeData['address'] as String;
          }
          if (contracteeEmail != null && (enrichedValues['Contractee.Email']?.isEmpty ?? true)) {
            enrichedValues['Contractee.Email'] = contracteeEmail;
          }
        } catch (e) {
          debugPrint('Failed to fetch contractee data: $e');
        }
      }

      return enrichedValues;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to enrich field values with contact info: ',
        module: 'Create Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Enrich Field Values',
          'project_id': projectId,
          'contractor_id': contractorId,
        },
      );
      // Return original values if enrichment fails
      return fieldValues;
    }
  }
}