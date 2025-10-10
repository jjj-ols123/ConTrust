
class PdfExtractUtils {

  /// Extracts the default template content for different contract types
  /// This provides the raw template structure with placeholders for each contract type
  static String getDefaultTemplateContent(String templateName) {
    final name = (templateName).toLowerCase();
    if (name.contains('lump') && name.contains('sum')) {
        return '''This Lump Sum Construction Contract is entered into on [Contract.CreationDate] between [Contractee.FirstName] [Contractee.LastName] (Contractee) and [Contractor.Company] (Contractor).

Project: [Project.Description]
Site Address: [Project.Address]
Start Date: [Project.StartDate]
Completion Date: [Project.CompletionDate]
Duration (days): [Project.Duration]

Contract Price (₱): [Project.ContractPrice]
Payment Method: [Payment.Method]
Down Payment (%): [Payment.DownPaymentPercentage]
Progress Payment 1 (%): [Payment.ProgressPayment1Percentage] at [Payment.Milestone1]
Progress Payment 2 (%): [Payment.ProgressPayment2Percentage] at [Payment.Milestone2]
Final Payment (%): [Payment.FinalPaymentPercentage]

Minimum Insurance Amount (₱): [Insurance.MinimumAmount]
Inspection Period (days): [Inspection.PeriodDays]
Jurisdiction: [Contractor.Province]
''';
    } else if ((name.contains('cost') && name.contains('plus')) || name.contains('cost-plus')) {
        return '''This Cost-Plus Construction Contract (Contract) is entered into on [Contract.CreationDate] by and between [Contractor.Firm] (Contractor) and [Contractee.FirstName] [Contractee.LastName] (Contractee).

Project Description: [Project.Description]
Project Address: [Project.Address]
Start Date: [Project.StartDate]
Estimated Completion: [Project.CompletionDate]
Duration (days): [Project.Duration]
Labor Costs (₱/hr): [Labor Costs]
Estimated Material Costs (₱): [Material Costs]
Estimated Equipment Costs (₱): [Equipment Costs]
Overhead/Profit (%): [Overhead Percentage]
Estimated Total (₱): [Estimated Total]

Payment Interval: [Payment Interval]
Retention Fee (₱): [Retention Fee]
Late Payment Fee (%): [Late Fee Percentage]
Payment Due Days: [Payment.DueDays]

Bond Submission Timeframe (days): [Bond.TimeFrame]
Payment Bond Amount (₱): [Bond.PaymentAmount]
Performance Bond Amount (₱): [Bond.Performance]

Warranty Period (months): [Warranty Period]
Notice Period (days): [Notice Period]
Jurisdiction: [Contractor.Province]
''';
    } else if (name.contains('time') && name.contains('material')) {
        return '''This Time and Materials Contract is effective on [Contract.CreationDate] between [Contractee.FirstName] [Contractee.LastName] (Contractee) and [Contractor.FirstName] [Contractor.LastName] (Contractor).

Project Definition: [Project.ContractorDef]
Scope of Work: [Project.Scope]
Estimated Labor Hours: [Project.LaborHours]
Project Duration: [Project.Duration]
Start Date: [Project.StartDate]
Completion Date: [Project.CompletionDate]
Schedule: [Project.Schedule]
Milestones: [Project.MilestonesList]
Materials: [Materials.List]

Item 1: [Item.1.Name] — [Item.1.Description] — Price ₱[Item.1.Price] — Qty [Item.1.Quantity] — Subtotal ₱[Item.1.Subtotal]
Item 2: [Item.2.Name] — [Item.2.Description] — Price ₱[Item.2.Price] — Qty [Item.2.Quantity] — Subtotal ₱[Item.2.Subtotal]
Item 3: [Item.3.Name] — [Item.3.Description] — Price ₱[Item.3.Price] — Qty [Item.3.Quantity] — Subtotal ₱[Item.3.Subtotal]
Item 4: [Item.4.Name] — [Item.4.Description] — Price ₱[Item.4.Price] — Qty [Item.4.Quantity] — Subtotal ₱[Item.4.Subtotal]
Item 5: [Item.5.Name] — [Item.5.Description] — Price ₱[Item.5.Price] — Qty [Item.5.Quantity] — Subtotal ₱[Item.5.Subtotal]

Subtotal (₱): [Payment.Subtotal]
Discount (₱): [Payment.Discount]
Tax (₱): [Payment.Tax]
Total (₱): [Payment.Total]

Penalty (₱): [Penalty.Amount]
Applicable Taxes: [Tax.List]
''';
    } else {
      // Safe fallback so preview is never empty
      return '''CONSTRUCTION CONTRACT PREVIEW\n\nTitle: [Title]\nDate: [Contract.CreationDate]\n\nParties:\nContractee: [Contractee.FirstName] [Contractee.LastName]\nContractor: [Contractor.Company]''';
    }
  }

  /// Extracts all placeholders from a template content string
  /// Returns a list of unique placeholders found in the template
  static List<String> extractPlaceholders(String templateContent) {
    final RegExp placeholderRegex = RegExp(r'\[([^\]]+)\]');
    final matches = placeholderRegex.allMatches(templateContent);
    
    final placeholders = <String>{};
    for (final match in matches) {
      final placeholder = match.group(1);
      if (placeholder != null && placeholder.isNotEmpty) {
        placeholders.add(placeholder);
      }
    }
    
    return placeholders.toList()..sort();
  }

  /// Categorizes placeholders by their type/section
  /// Returns a map with categories as keys and lists of placeholders as values
  static Map<String, List<String>> categorizePlaceholders(List<String> placeholders) {
    final Map<String, List<String>> categories = {
      'Contract': [],
      'Contractee': [],
      'Contractor': [],
      'Project': [],
      'Items': [],
      'Payment': [],
      'Bond': [],
      'Insurance': [],
      'Legal': [],
      'Other': [],
    };

    for (final placeholder in placeholders) {
      if (placeholder.contains('Contract.') || placeholder == 'DATE' || placeholder == 'Date') {
        categories['Contract']!.add(placeholder);
      } else if (placeholder.contains('Contractee.')) {
        categories['Contractee']!.add(placeholder);
      } else if (placeholder.contains('Contractor.')) {
        categories['Contractor']!.add(placeholder);
      } else if (placeholder.contains('Project.') || placeholder.contains('Materials.')) {
        categories['Project']!.add(placeholder);
      } else if (placeholder.contains('Item.')) {
        categories['Items']!.add(placeholder);
      } else if (placeholder.contains('Payment.') || placeholder.contains('Costs') || 
                 placeholder.contains('Rate') || placeholder.contains('Fee') ||
                 placeholder.contains('Budget') || placeholder.contains('Total')) {
        categories['Payment']!.add(placeholder);
      } else if (placeholder.contains('Bond.')) {
        categories['Bond']!.add(placeholder);
      } else if (placeholder.contains('Insurance.') || placeholder.contains('Inspection.')) {
        categories['Insurance']!.add(placeholder);
      } else if (placeholder.contains('Period') || placeholder.contains('Penalty.') || 
                 placeholder.contains('Tax.') || placeholder.contains('Warranty')) {
        categories['Legal']!.add(placeholder);
      } else {
        categories['Other']!.add(placeholder);
      }
    }

    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);
    
    return categories;
  }

  /// Gets the complete placeholder analysis for a contract type
  /// Returns detailed information about all placeholders in the template
  static Map<String, dynamic> getTemplateAnalysis(String contractType) {
    final templateContent = getDefaultTemplateContent(contractType);
    final placeholders = extractPlaceholders(templateContent);
    final categories = categorizePlaceholders(placeholders);
    
    return {
      'contractType': contractType,
      'templateContent': templateContent,
      'totalPlaceholders': placeholders.length,
      'placeholders': placeholders,
      'categories': categories,
      'hasItems': categories.containsKey('Items'),
      'hasPaymentSchedule': categories['Payment']?.any((p) => p.contains('Progress')) ?? false,
      'hasDynamicItems': placeholders.any((p) => p.startsWith('Item.')),
    };
  }

  /// Validates if all required placeholders are present in field values
  /// Returns a list of missing required placeholders
  static List<String> validateFieldValues(String contractType, Map<String, String> fieldValues) {
    final analysis = getTemplateAnalysis(contractType);
    final placeholders = List<String>.from(analysis['placeholders']);
    final missing = <String>[];
    
    for (final placeholder in placeholders) {
      if (!fieldValues.containsKey(placeholder) || fieldValues[placeholder]?.isEmpty == true) {
        missing.add(placeholder);
      }
    }
    
    return missing;
  }

  /// Fills template content with provided field values
  /// Returns the template with all placeholders replaced with actual values
  static String fillTemplate(String templateContent, Map<String, String> fieldValues) {
    String filledTemplate = templateContent;
    
    fieldValues.forEach((key, value) {
      final placeholder = '[$key]';
      final fillValue = value.isNotEmpty ? value : '____________';
      filledTemplate = filledTemplate.replaceAll(placeholder, fillValue);
    });
    
    return filledTemplate;
  }

  /// Gets the maximum item count for Time and Materials contracts
  /// Returns the highest item number found in the field values
  static int getMaxItemCount(Map<String, String> fieldValues) {
    int maxCount = 0;
    
    for (final key in fieldValues.keys) {
      if (key.startsWith('Item.') && key.contains('.')) {
        final parts = key.split('.');
        if (parts.length >= 2) {
          final itemNumber = int.tryParse(parts[1]) ?? 0;
          if (itemNumber > maxCount) {
            maxCount = itemNumber;
          }
        }
      }
    }
    
    return maxCount > 0 ? maxCount : 3; // Default to 3 if no items found
  }

  /// Generates dynamic item placeholders for Time and Materials contracts
  /// Returns a list of placeholder strings for the specified number of items
  static List<String> generateItemPlaceholders(int itemCount) {
    final placeholders = <String>[];
    
    for (int i = 1; i <= itemCount; i++) {
      placeholders.addAll([
        'Item.$i.Name',
        'Item.$i.Description', 
        'Item.$i.Price',
        'Item.$i.Quantity',
        'Item.$i.Subtotal',
      ]);
    }
    
    return placeholders;
  }
}

