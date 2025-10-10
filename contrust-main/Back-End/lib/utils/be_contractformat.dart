import 'package:flutter/material.dart';

class ContractStyle {
  // Optional resolver to transform placeholder text into filled values.
  // When set, paragraph/bullet/numbered will pass text through this function.
  static String Function(String)? textResolver;
  
  // Function to check if item row should be displayed based on filled values
  static bool Function(int)? itemRowVisibilityChecker;

  // Helpers to scope/clear resolver
  static void setTextResolver(String Function(String) resolver) {
    textResolver = resolver;
  }

  static void clearTextResolver() {
    textResolver = null;
  }
  
  // Set the visibility checker function
  static void setItemRowVisibilityChecker(bool Function(int) checker) {
    itemRowVisibilityChecker = checker;
  }
  
  // Clear the visibility checker
  static void clearItemRowVisibilityChecker() {
    itemRowVisibilityChecker = null;
  }
  
  // Check if an item row should be visible
  static bool shouldShowItemRow(int rowNumber) {
    return itemRowVisibilityChecker != null 
        ? itemRowVisibilityChecker!(rowNumber) 
        : true; // Default to showing all rows
  }
  static Widget sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  /// Paragraph (standard justified text)
  static Widget paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          textResolver != null ? textResolver!(text) : text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      );

  static Widget infoBlock(List<String> lines) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((t) => paragraph(textResolver != null ? textResolver!(t) : t))
            .toList(),
      );

  static Widget bulletList(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          textResolver != null ? textResolver!(item) : item,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );

  static Widget numberedList(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final text = textResolver != null ? textResolver!(items[i]) : items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ', style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          );
        }),
      );

  static Widget signatureBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SIGNATURES:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('CONTRACTOR: _________________    DATE: _________________'),
          Text('[Contractor Name]'),
          SizedBox(height: 12),
          Text('CLIENT: _________________    DATE: _________________'),
          Text('[Client Name]'),
          SizedBox(height: 12),
          Text('WITNESS: _________________    DATE: _________________'),
          Text('[Witness Name]'),
        ],
      );

      String resolvePlaceholders(String input) {
      // Map of friendly tokens to controller keys (extend as needed)
      final Map<String, String> tokenToKey = {
        // People
        'First name of the contractee': 'Contractee.FirstName',
        'Last name of the contractee': 'Contractee.LastName',
        'Contractee street address': 'Contractee.Address',
        'Contractee city': 'Contractee.City',
        'Contractee postal code': 'Contractee.PostalCode',
        'First name of the contractor': 'Contractor.FirstName',
        'Last name of the contractor': 'Contractor.LastName',
        'Contractor street address': 'Contractor.Address',
        'Contractor city': 'Contractor.City',
        'Contractor postal code': 'Contractor.PostalCode',

        // Company name should resolve from Contractor.Company
        'Contractor company name': 'Contractor.Company',
        'Contractor firm or company name': 'Contractor.Company',
        'Your Construction Company\'s Name': 'Contractor.Company',

        // Common company/identifier extras
        'Contractor license number': 'Contractor.License',
        'Contractor phone number': 'Contractor.Phone',
        'Contractor province': 'Contractor.Province',

        // Project basics
        'Date of contract creation': 'Contract.CreationDate',
        'Project description as defined by the contractor': 'Project.ContractorDef',
        'Estimated labor hours': 'Project.LaborHours',
        'Project duration': 'Project.Duration',
        'Project duration in days': 'Project.Duration',
        'Estimated completion date': 'Project.CompletionDate',
        'Start date of the project': 'Project.StartDate',
        'Project schedule': 'Project.Schedule',
        'List of project milestones': 'Project.MilestonesList',
  
        // Common address/placeholders across templates
        'Project address': 'Project.Address',
        'Project site address': 'Project.Address',
        'Legal description of property': 'Project.LegalDescription',
        'Property description': 'Project.PropertyDescription',
        'Project scope of work': 'Project.ScopeOfWork',
        'List of required materials': 'Materials.List',
        'Scope of work': 'Project.Scope',

        // Taxes/fees
        'Applicable taxes': 'Tax.List',
        'Maximum penalty amount': 'Penalty.Amount',
        // Payment summary fields
        'Total contract price': 'Payment.Total',
        'Total contract price (legacy)': 'Payment.TotalAmount',
        'Payment method': 'Payment.Method',
        'Performance bond amount': 'Bond.PerformanceAmount',
        'Payment bond amount': 'Bond.PaymentAmount',
        'Number of days to submit bonds': 'Bond.SubmitDays',
        'Insurance requirements': 'Insurance.Requirements',
        'Minimum insurance amount': 'Insurance.MinimumAmount',
        'Termination notice period in days': 'Contract.TerminationDays',
        'Warranty period in months': 'Contract.WarrantyMonths',
        'Number of days to commence work': 'Project.CommenceDays',
        
        // Table cells and other template elements
        'List of work': 'Project.Scope',
        'Time': 'Project.LaborHours',
        'Materials': 'Materials.List',

        // Payment calculation placeholders
        'Subtotal amount': 'Payment.Subtotal',
        'Payment.Subtotal': 'Payment.Subtotal',
        'Discount amount': 'Payment.Discount',
        'Payment.Discount': 'Payment.Discount',
        'Tax amount': 'Payment.Tax',
        'Payment.Tax': 'Payment.Tax',
        'Total amount': 'Payment.Total',
        'Payment.Total': 'Payment.Total',
        
        // Item rows (needs to handle 1-based index)
        'Item 1 name': 'Item.1.Name',
        'Item 1 description': 'Item.1.Description',
        'Item 1 price': 'Item.1.Price',
        'Item 1 quantity': 'Item.1.Quantity',
        'Item 1 subtotal': 'Item.1.Subtotal',

        'Item 2 name': 'Item.2.Name',
        'Item 2 description': 'Item.2.Description',
        'Item 2 price': 'Item.2.Price',
        'Item 2 quantity': 'Item.2.Quantity',
        'Item 2 subtotal': 'Item.2.Subtotal',

        'Item 3 name': 'Item.3.Name',
        'Item 3 description': 'Item.3.Description',
        'Item 3 price': 'Item.3.Price',
        'Item 3 quantity': 'Item.3.Quantity',
        'Item 3 subtotal': 'Item.3.Subtotal',

        'Item 4 name': 'Item.4.Name',
        'Item 4 description': 'Item.4.Description',
        'Item 4 price': 'Item.4.Price',
        'Item 4 quantity': 'Item.4.Quantity',
        'Item 4 subtotal': 'Item.4.Subtotal',

        'Item 5 name': 'Item.5.Name',
        'Item 5 description': 'Item.5.Description',
        'Item 5 price': 'Item.5.Price',
        'Item 5 quantity': 'Item.5.Quantity',
        'Item 5 subtotal': 'Item.5.Subtotal',

        // Payment schedule/milestones
        'Down payment percentage': 'Payment.DownPaymentPercentage',
        'Progress payment 1 percentage': 'Payment.ProgressPayment1Percentage',
        'Progress payment 2 percentage': 'Payment.ProgressPayment2Percentage',
        'Final payment percentage': 'Payment.FinalPaymentPercentage',
        'Milestone 1 description': 'Payment.Milestone1',
        'Milestone 2 description': 'Payment.Milestone2',
        'Retention fee percentage': 'Payment.RetentionFeePercentage',
        'Retention fee amount': 'Payment.RetentionFeeAmount',
        'Labor costs': 'Cost.Labor',
        'Material costs': 'Cost.Materials',
        'Equipment costs': 'Cost.Equipment',
        'Estimated total cost': 'Cost.Total',
        'Overhead percentage': 'Cost.OverheadPercentage',
        'Late fee percentage': 'Cost.LateFeePercentage',
        'Number of days to make payment': 'Payment.DueDays',
        'Inspection period in days': 'Inspection.PeriodDays',
        'List of licenses or permits': 'Licenses.List',
        'List of insurance policies': 'Insurance.List',
        'List of bonds': 'Bonds.List',
        'Project legal description': 'Project.LegalDescription',
        'Specification': 'Project.Specification',
      };
      // Replace occurrences of friendly tokens with their mapped keys (adjust as needed)
      String result = input;
      tokenToKey.forEach((token, key) {
        if (token.isNotEmpty) {
          result = result.replaceAll(token, key);
        }
      });
      return result;
      }
}
