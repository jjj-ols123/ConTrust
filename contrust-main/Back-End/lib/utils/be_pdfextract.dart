class PdfExtractUtils {
  static String getDefaultTemplateContent(String templateName) {
    final name = (templateName).toLowerCase();
    if (name.contains('lump') && name.contains('sum')) {
      return '''This Lump Sum Construction Contract is entered into on [Contract.CreationDate] between [Contractee.FirstName] [Contractee.LastName] (Contractee) and [Contractor.Company] (Contractor).
                
                CONTRACTEE: [Contractee.FirstName] [Contractee.LastName]
                Address: [Contractee.Address]
                Phone: [Contractee.Phone]
                Email: [Contractee.Email]
                
                CONTRACTOR: [Contractor.Company]
                Name: [Contractor.FirstName] [Contractor.LastName]
                Address: [Contractor.Address]
                Phone: [Contractor.Phone]
                Email: [Contractor.Email]
                Province: [Contractor.Province]
                
                PROJECT:
                Description: [Project.Description]
                Site Address: [Project.Address]
                Start Date: [Project.StartDate]
                Completion Date: [Project.CompletionDate]
                Duration (days): [Project.Duration]
                Working Days: [Project.WorkingDays]
                Working Hours: [Project.WorkingHours]

                PAYMENT:
                Total Contract Price (₱): [Payment.Total]
                Down Payment (₱): [Payment.DownPayment]
                Final Payment (₱): [Payment.FinalPayment]
                Retention (%): [Payment.RetentionPercentage]
                Retention Amount (₱): [Payment.RetentionAmount]
                Retention Period (days): [Payment.RetentionPeriod]
                Payment Due Days: [Payment.DueDays]
                Late Fee (%): [Payment.LateFeePercentage]
                
                MILESTONES:
                Milestone 1: [Milestone.1.Description] — [Milestone.1.Duration] days — Target: [Milestone.1.Date]
                Milestone 2: [Milestone.2.Description] — [Milestone.2.Duration] days — Target: [Milestone.2.Date]
                Milestone 3: [Milestone.3.Description] — [Milestone.3.Duration] days — Target: [Milestone.3.Date]
                Milestone 4: [Milestone.4.Description] — [Milestone.4.Duration] days — Target: [Milestone.4.Date]
                
                BONDS:
                Bond Timeframe (days): [Bond.TimeFrame]
                Performance Bond (₱): [Bond.PerformanceAmount]
                Payment Bond (₱): [Bond.PaymentAmount]
                
                CHANGE ORDERS:
                Labor Rate (₱/hr): [Change.LaborRate]
                Material Markup (%): [Change.MaterialMarkup]
                Equipment Markup (%): [Change.EquipmentMarkup]
                
                Notice Period (days): [Notice.Period]
                Warranty Period (months): [Warranty.Period]
                ''';
    } else if ((name.contains('cost') && name.contains('plus')) ||
        name.contains('cost-plus')) {
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
      return '''CONSTRUCTION CONTRACT PREVIEW\n\nTitle: [Title]\nDate: [Contract.CreationDate]\n\nParties:\nContractee: [Contractee.FirstName] [Contractee.LastName]\nContractor: [Contractor.Company]''';
    }
  }



  static String fillTemplate(
      String templateContent, Map<String, String> fieldValues) {
    String filledTemplate = templateContent;

    fieldValues.forEach((key, value) {
      final placeholder = '[$key]';
      final fillValue = value.isNotEmpty ? value : '____________';
      filledTemplate = filledTemplate.replaceAll(placeholder, fillValue);
    });

    return filledTemplate;
  }
}
