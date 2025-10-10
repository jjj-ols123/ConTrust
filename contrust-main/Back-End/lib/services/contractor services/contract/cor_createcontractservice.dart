import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
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

  List<ContractField> getContractTypeSpecificFields(String contractType, {int itemCount = 3}) {
    final normalizedType = contractType.toLowerCase();
    return getTemplateSpecificFields(normalizedType, itemCount: itemCount);
  }

  List<ContractField> getTemplateSpecificFields(String contractType, {int itemCount = 3}) {
    if (contractType.contains('lump sum')) {
      return getLumpSumFields();
    } else if (contractType.contains('cost-plus') || contractType.contains('cost plus')) {
      return getCostPlusFields();
    } else if (contractType.contains('time and materials')) {
      return getTimeAndMaterialsFieldsWithItems(itemCount);
    }
    return [];
  }

  List<ContractField> getLumpSumFields() {
    return [
      ContractField(key: 'Contract.CreationDate', label: 'Contract Creation Date', isRequired: true),

      ContractField(key: 'Contractee.FirstName', label: 'Contractee First Name', isRequired: true),
      ContractField(key: 'Contractee.LastName', label: 'Contractee Last Name', isRequired: true),
      ContractField(key: 'Contractee.Address', label: 'Contractee Street Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Contractee.Phone', label: 'Contractee Phone', isRequired: true),
      ContractField(key: 'Contractee.Email', label: 'Contractee Email', isRequired: true),
      
      ContractField(key: 'Contractor.Company', label: 'Contractor Company', isRequired: true),
      ContractField(key: 'Contractor.License', label: 'Contractor License Number', isRequired: true),
      ContractField(key: 'Contractor.Address', label: 'Contractor Street Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Contractor.Phone', label: 'Contractor Phone', isRequired: true),
      ContractField(key: 'Contractor.Email', label: 'Contractor Email', isRequired: true),
      ContractField(key: 'Contractor.Province', label: 'Contractor Province', isRequired: true),
      
      ContractField(key: 'Project.Description', label: 'Project Description', isRequired: true, maxLines: 3),
      ContractField(key: 'Project.Address', label: 'Project Site Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Project.LegalDescription', label: 'Legal Description of Property', maxLines: 2),
      ContractField(key: 'Project.PropertyDescription', label: 'Property Description', maxLines: 2),
      ContractField(key: 'Project.ScopeOfWork', label: 'Project Scope of Work', isRequired: true, maxLines: 3),
      ContractField(key: 'Project.Specification', label: 'Project Specification', maxLines: 2),
      ContractField(key: 'Project.NumofDays', label: 'Number of Days to Commence', isRequired: true, inputType: TextInputType.number),
      ContractField(key: 'Project.StartDate', label: 'Project Start Date', isRequired: true),
      ContractField(key: 'Project.CompletionDate', label: 'Project Completion Date', isRequired: true),
      ContractField(key: 'Project.Duration', label: 'Project Duration (days)', isRequired: true, inputType: TextInputType.number),
      ContractField(key: 'Project.InsuranceRequirement', label: 'Insurance Requirements', maxLines: 2),
      
      ContractField(key: 'Project.ContractPrice', label: 'Total Contract Price (₱)', isRequired: true, inputType: TextInputType.number),
      ContractField(key: 'Payment.Method', label: 'Payment Method', isRequired: true),
      ContractField(key: 'Payment.DownPaymentPercentage', label: 'Down Payment Percentage (%)', isRequired: true, inputType: TextInputType.number),
      ContractField(key: 'Payment.ProgressPayment1Percentage', label: 'Progress Payment 1 Percentage (%)', inputType: TextInputType.number),
      ContractField(key: 'Payment.Milestone1', label: 'Milestone 1 Description', maxLines: 2),
      ContractField(key: 'Payment.ProgressPayment2Percentage', label: 'Progress Payment 2 Percentage (%)', inputType: TextInputType.number),
      ContractField(key: 'Payment.Milestone2', label: 'Milestone 2 Description', maxLines: 2),
      ContractField(key: 'Payment.FinalPaymentPercentage', label: 'Final Payment Percentage (%)', isRequired: true, inputType: TextInputType.number),
      
      ContractField(key: 'Insurance.MinimumAmount', label: 'Minimum Insurance Amount (₱)', inputType: TextInputType.number),
      ContractField(key: 'Inspection.PeriodDays', label: 'Inspection Period (days)', inputType: TextInputType.number),
    ];
  }

  List<ContractField> getCostPlusFields() {
    return [
      ContractField(key: 'Contract.CreationDate', label: 'Contract Creation Date', isRequired: true),
      
      ContractField(key: 'Contractor.Firm', label: 'Contractor Firm/Company Name', isRequired: true),
      ContractField(key: 'Contractor.FirstName', label: 'Contractor First Name', isRequired: true),
      ContractField(key: 'Contractor.LastName', label: 'Contractor Last Name', isRequired: true),
      ContractField(key: 'Contractor.Address', label: 'Contractor Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Contractor.City', label: 'Contractor City', isRequired: true),
      ContractField(key: 'Contractor.PostalCode', label: 'Contractor Postal Code', isRequired: true),
      ContractField(key: 'Contractor.Company', label: 'Contractor Company (for signature)', isRequired: true),
      ContractField(key: 'Contractor.Province', label: 'Contractor Province', isRequired: true),

      ContractField(key: 'Contractee.FirstName', label: 'Contractee First Name', isRequired: true),
      ContractField(key: 'Contractee.LastName', label: 'Contractee Last Name', isRequired: true),
      ContractField(key: 'Contractee.Address', label: 'Contractee Address', isRequired: true, maxLines: 2),
      ContractField(key: 'Contractee.City', label: 'Contractee City', isRequired: true),
      ContractField(key: 'Contractee.PostalCode', label: 'Contractee Postal Code', isRequired: true),
      
      ContractField(key: 'Project.Description', label: 'Project Description', isRequired: true, maxLines: 3),
      ContractField(key: 'Project.Address', label: 'Project Address/Location', isRequired: true, maxLines: 2),
      ContractField(key: 'Project.StartDate', label: 'Project Start Date', isRequired: true),
      ContractField(key: 'Project.CompletionDate', label: 'Project Completion Date (Estimate)', isRequired: true),
      ContractField(key: 'Project.Duration', label: 'Project Duration (days)', isRequired: true, inputType: TextInputType.number),
      
      ContractField(key: 'Labor Costs', label: 'Labor Costs per Hour (₱)', isRequired: true, inputType: TextInputType.number),
      ContractField(key: 'Material Costs', label: 'Estimated Material Costs (₱)', inputType: TextInputType.number),
      ContractField(key: 'Equipment Costs', label: 'Estimated Equipment Costs (₱)', inputType: TextInputType.number),
      ContractField(key: 'Overhead Percentage', label: 'Overhead and Profit Percentage (%)', isRequired: true, inputType: TextInputType.number),
      ContractField(key: 'Estimated Total', label: 'Total Estimated Project Cost (₱)', isRequired: true, inputType: TextInputType.number),
      
      ContractField(key: 'Payment Interval', label: 'Payment Interval (weekly/bi-weekly/monthly)', isRequired: true),
      ContractField(key: 'Retention Fee', label: 'Retention Fee (₱)', inputType: TextInputType.number),
      ContractField(key: 'Late Fee Percentage', label: 'Late Payment Fee Percentage (%)', inputType: TextInputType.number),
      ContractField(key: 'Payment.DueDays', label: 'Payment Due Days from Invoice', inputType: TextInputType.number),
      
      ContractField(key: 'Bond.TimeFrame', label: 'Bond Submission Timeframe (days)', inputType: TextInputType.number),
      ContractField(key: 'Bond.PaymentAmount', label: 'Payment Bond Amount (₱)', inputType: TextInputType.number),
      ContractField(key: 'Bond.Performance', label: 'Performance Bond Amount (₱)', inputType: TextInputType.number),

      ContractField(key: 'Notice Period', label: 'Termination Notice Period (days)', inputType: TextInputType.number),
      ContractField(key: 'Warranty Period', label: 'Warranty Period (months)', inputType: TextInputType.number),
    ];
  }

  List<ContractField> getTimeAndMaterialsFields() {
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
      
      // Dynamic item count - will be populated by getTimeAndMaterialsFieldsWithItems
      ContractField(key: 'ItemCount', label: 'Number of Items', inputType: TextInputType.number, isRequired: true),
      
      ContractField(key: 'Payment.Subtotal', label: 'Payment Subtotal (₱)', inputType: TextInputType.number, isEnabled: false),
  // Discount is now percentage-based; hint includes %
  ContractField(key: 'Payment.Discount', label: 'Payment Discount (%)', placeholder: 'e.g., 5%', inputType: TextInputType.number),
  // Tax is now percentage-based; hint includes %
  ContractField(key: 'Payment.Tax', label: 'Payment Tax (%)', placeholder: 'e.g., 12%', inputType: TextInputType.number, isRequired: true),
      ContractField(key: 'Payment.Total', label: 'Payment Total (₱)', inputType: TextInputType.number, isEnabled: false),
      
      ContractField(key: 'Penalty.Amount', label: 'Penalty Amount (₱)', inputType: TextInputType.number),
      ContractField(key: 'Tax.List', label: 'Tax List', maxLines: 2),
    ];
  }

  List<ContractField> getTimeAndMaterialsFieldsWithItems(int itemCount) {
    List<ContractField> fields = getTimeAndMaterialsFields();
    
    // Remove the ItemCount field from the main list
    fields.removeWhere((field) => field.key == 'ItemCount');
    
    // Find the index where to insert item fields (after Materials.List)
    int insertIndex = fields.indexWhere((field) => field.key == 'Materials.List') + 1;
    
    // Generate dynamic item fields
    List<ContractField> itemFields = [];
    for (int i = 1; i <= itemCount; i++) {
      itemFields.addAll([
        ContractField(key: 'Item.$i.Name', label: 'Item $i Name', isRequired: i <= 3), // First 3 items required
        ContractField(key: 'Item.$i.Description', label: 'Item $i Description', isRequired: i <= 3),
        ContractField(key: 'Item.$i.Price', label: 'Item $i Price (₱)', isRequired: i <= 3, inputType: TextInputType.number),
        ContractField(key: 'Item.$i.Quantity', label: 'Item $i Quantity', isRequired: i <= 3, inputType: TextInputType.number),
        ContractField(key: 'Item.$i.Subtotal', label: 'Item $i Subtotal (₱)', inputType: TextInputType.number, isEnabled: false), // Disabled for auto-calculation
      ]);
    }
    
    // Insert item fields at the correct position
    fields.insertAll(insertIndex, itemFields);
    
    return fields;
  }

  Future<Map<String, dynamic>?> fetchProjectData(String projectId) async {
    try {
      return await FetchService().fetchProjectDetails(projectId);
    } catch (e) {
      rethrow;
    }
  }

  void populateProjectFields(Map<String, dynamic> projectData, Map<String, TextEditingController> controllers, String? selectedContractType) {
    // Project Information
    controllers['Project.Description']?.text = projectData['description'] ?? '';
    controllers['Project.Address']?.text = projectData['location'] ?? '';
    
    // Date handling
    final currentDate = DateTime.now().toString().split(' ')[0];
    controllers['Contract.CreationDate']?.text = currentDate;
    
    if (projectData['start_date'] != null) {
      final startDate = projectData['start_date'].toString().split(' ')[0];
      controllers['Project.StartDate']?.text = startDate;
    } else {
      controllers['Project.StartDate']?.text = currentDate;
    }
    
    // Handle completion date
    if (projectData['end_date'] != null) {
      final endDate = projectData['end_date'].toString().split(' ')[0];
      controllers['Project.CompletionDate']?.text = endDate;
    }

    final contractType = selectedContractType?.toLowerCase();
    final maxBudget = projectData['max_budget']?.toString() ?? '';
    
    if (contractType?.contains('lump sum') == true) {
      if (maxBudget.isNotEmpty) {
        controllers['Project.ContractPrice']?.text = maxBudget;
      }
    } else if (contractType?.contains('cost-plus') == true || contractType?.contains('cost plus') == true) {
      if (maxBudget.isNotEmpty) {
        controllers['Estimated Total']?.text = maxBudget;
      }
    } else if (contractType?.contains('time and materials') == true) {
      if (maxBudget.isNotEmpty) {
        controllers['Payment.Total']?.text = maxBudget;
      }
    }
  }

  void calculateTimeAndMaterialsRates(Map<String, TextEditingController> controllers, {int? itemCount}) {
    double totalSubtotal = 0.0;
    
    // Get the dynamic item count if provided, otherwise try to determine from available controllers
    int maxItems = itemCount ?? getMaxItemCountFromControllers(controllers);
    
    // Calculate subtotals for each item (dynamic count)
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
    
    // Calculate Payment Subtotal
    controllers['Payment.Subtotal']?.text = totalSubtotal.toStringAsFixed(2);
    
    // Get user-inputted values
    // Parse percentage helper; supports values like "12", "12%", or "0.12"
    double parsePercent(String raw) {
      final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '');
      final v = double.tryParse(cleaned) ?? 0.0;
      if (v <= 0) return 0.0;
      // If user typed 0..1, treat as fraction; if >1, treat as percent
      return v > 1.0 ? (v / 100.0) : v;
    }
    final discountRate = parsePercent(controllers['Payment.Discount']?.text ?? '0');
    final discountAmount = totalSubtotal * discountRate;
    final taxRate = parsePercent(controllers['Payment.Tax']?.text ?? '0');
    final taxAmount = totalSubtotal * taxRate;

    // Calculate Total (subtotal - discountAmount + taxAmount)
    final total = totalSubtotal - discountAmount + taxAmount;
    controllers['Payment.Total']?.text = total.toStringAsFixed(2);
    // Optionally keep computed amounts if such controllers exist
    controllers['Payment.DiscountAmount']?.text = discountAmount.toStringAsFixed(2);
    // Optionally keep a computed tax amount if such a controller exists
    controllers['Payment.TaxAmount']?.text = taxAmount.toStringAsFixed(2);
    
    // Update legacy fields for compatibility
    controllers['Contract Price']?.text = total.toStringAsFixed(2);
    controllers['Estimated Budget']?.text = total.toStringAsFixed(2);
  }

  int getMaxItemCountFromControllers(Map<String, TextEditingController> controllers) {
    int maxItems = 3; // Default fallback changed to 3
    
    // Check for controllers with Item.X.Name pattern to determine max count
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
      rethrow;
    }
  }

  void clearAutoPopulatedFields(Map<String, TextEditingController> controllers) {

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