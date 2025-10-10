class PdfExtractUtils {
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
      // Safe fallback so preview is never empty
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
