import 'package:flutter/material.dart';

class ProjectStatus { 

String getStatusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'awaiting_contract':
        return 'Awaiting for Contract';
      case 'awaiting_agreement':
        return 'Awaiting Agreement';
      case 'closed':
        return 'Closed';
      case 'ended':
        return 'Ended';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'awaiting_contract':
        return Colors.blue;
      case 'awaiting_agreement':
        return Colors.purple;
      case 'closed':
        return Colors.redAccent;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class ContractStatus { 
  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'signed':
        return Colors.purple;
      case 'active':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'under_review':
        return Icons.visibility;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'signed':
        return Icons.verified;
      case 'active':
        return Icons.play_circle;
      default:
        return Icons.info;
    }
  }

  Icon? getFieldIcon(String fieldKey) {
    switch (fieldKey) {
      // Date fields
      case 'Date':
      case 'Contract.CreationDate':
      case 'Start Date':
      case 'Completion Date':
      case 'Project.StartDate':
      case 'Project.CompletionDate':
        return const Icon(Icons.calendar_today);
      
      // People fields
      case 'Contractee.FirstName':
      case 'Contractee.LastName':
      case 'Contractor.FirstName':
      case 'Contractor.LastName':
        return const Icon(Icons.person);
      
      // Company/Organization fields
      case 'Contractor.Company':
      case 'Contractor.Firm':
        return const Icon(Icons.business);
      
      // Address fields
      case 'Contractee.Address':
      case 'Contractor.Address':
      case 'Contractee.City':
      case 'Contractor.City':
      case 'Contractee.PostalCode':
      case 'Contractor.PostalCode':
      case 'Project.Address':
      case 'Contractor.Province':
        return const Icon(Icons.location_on);
      
      // Contact fields
      case 'Contractee.Phone':
      case 'Contractor.Phone':
      case 'Contractee.Email':
      case 'Contractor.Email':
        return const Icon(Icons.contact_phone);
      
      // Project fields
      case 'Project.Description':
      case 'Project.ContractorDef':
      case 'Project.Scope':
        return const Icon(Icons.description);
      case 'Project.LegalDescription':
      case 'Project.PropertyDescription':
      case 'Project.ScopeOfWork':
      case 'Project.Specification':
        return const Icon(Icons.assignment);
      case 'Project.Schedule':
      case 'Project.MilestonesList':
        return const Icon(Icons.timeline);
      case 'Project.InsuranceRequirement':
        return const Icon(Icons.security);
      
      // Duration/Time fields
      case 'Duration':
      case 'Project.Duration':
      case 'Project.LaborHours':
      case 'Project.NumofDays':
        return const Icon(Icons.schedule);
      
      // Money/Payment fields
      case 'Project.ContractPrice':
      case 'Labor Costs':
      case 'Material Costs':
      case 'Equipment Costs':
      case 'Estimated Total':
      case 'Retention Fee':
      case 'Bond.PaymentAmount':
      case 'Bond.Performance':
      case 'Insurance.MinimumAmount':
      case 'Payment.Subtotal':
      case 'Payment.Discount':
      case 'Payment.Tax':
      case 'Payment.Total':
      case 'Penalty.Amount':
        return const Icon(Icons.money);
      
      // Percentage fields
      case 'Overhead Percentage':
      case 'Late Fee Percentage':
      case 'Payment.DownPaymentPercentage':
      case 'Payment.ProgressPayment1Percentage':
      case 'Payment.ProgressPayment2Percentage':
      case 'Payment.FinalPaymentPercentage':
        return const Icon(Icons.percent);
      
      // Payment method/interval fields
      case 'Payment.Method':
      case 'Payment Interval':
        return const Icon(Icons.payment);
      
      // Item fields
      case 'Item.1.Name':
      case 'Item.2.Name':
      case 'Item.3.Name':
      case 'Item.4.Name':
      case 'Item.5.Name':
        return const Icon(Icons.label);
      case 'Item.1.Description':
      case 'Item.2.Description':
      case 'Item.3.Description':
      case 'Item.4.Description':
      case 'Item.5.Description':
        return const Icon(Icons.description);
      case 'Item.1.Price':
      case 'Item.2.Price':
      case 'Item.3.Price':
      case 'Item.4.Price':
      case 'Item.5.Price':
      case 'Item.1.Subtotal':
      case 'Item.2.Subtotal':
      case 'Item.3.Subtotal':
      case 'Item.4.Subtotal':
      case 'Item.5.Subtotal':
        return const Icon(Icons.attach_money);
      case 'Item.1.Quantity':
      case 'Item.2.Quantity':
      case 'Item.3.Quantity':
      case 'Item.4.Quantity':
      case 'Item.5.Quantity':
        return const Icon(Icons.numbers);
      
      // Materials/Equipment
      case 'Materials.List':
        return const Icon(Icons.inventory);
      
      // Legal/Time periods
      case 'Notice Period':
      case 'Warranty Period':
      case 'Bond.TimeFrame':
      case 'Inspection.PeriodDays':
        return const Icon(Icons.timer);
      
      // Bond fields
      case 'Payment.DueDays':
        return const Icon(Icons.event);
      
      // Milestones
      case 'Payment.Milestone1':
      case 'Payment.Milestone2':
        return const Icon(Icons.flag);
      
      // License/Legal
      case 'Contractor.License':
        return const Icon(Icons.card_membership);
      
      // Tax
      case 'Tax.List':
        return const Icon(Icons.receipt_long);
      
      default:
        return const Icon(Icons.text_fields);
    }
  }
  
}