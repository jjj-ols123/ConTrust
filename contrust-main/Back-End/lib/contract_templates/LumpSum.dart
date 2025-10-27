// ignore_for_file: file_names

import 'package:backend/utils/be_contractformat.dart';
import 'package:flutter/material.dart';

class LumpSumContract extends StatelessWidget {
  const LumpSumContract({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'LUMP SUM CONSTRUCTION CONTRACT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),

      ContractStyle.paragraph(
            'This Lump Sum Construction Contract ("Contract") is entered into on [Contract.CreationDate] by and between [Contractor.Company] ("Your Construction Company\'s Name"), hereinafter referred to as the "Contractor," and [Contractee.FirstName] [Contractee.LastName], hereinafter referred to as the "Contractee."'),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('The Parties'),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade400)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contractor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Company: ${ContractStyle.textResolver!('[Contractor.Company]')}' 
                              : 'Company: [Contractor.Company]',
                          style: const TextStyle(fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Address: ${ContractStyle.textResolver!('[Contractor.Address]')}' 
                              : 'Address: [Contractor.Address]',
                          style: const TextStyle(fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Phone: ${ContractStyle.textResolver!('[Contractor.Phone]')}' 
                              : 'Phone: [Contractor.Phone]',
                          style: const TextStyle(fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Email: ${ContractStyle.textResolver!('[Contractor.Email]')}' 
                              : 'Email: [Contractor.Email]',
                          style: const TextStyle(fontSize: 12)
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contractee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Name: ${ContractStyle.textResolver!('[Contractee.FirstName]')} ${ContractStyle.textResolver!('[Contractee.LastName]')}' 
                              : 'Name: [Contractee.FirstName] [Contractee.LastName]',
                          style: const TextStyle(fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Address: ${ContractStyle.textResolver!('[Contractee.Address]')}' 
                              : 'Address: [Contractee.Address]',
                          style: const TextStyle(fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Phone: ${ContractStyle.textResolver!('[Contractee.Phone]')}' 
                              : 'Phone: [Contractee.Phone]',
                          style: const TextStyle(fontSize: 12)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ContractStyle.textResolver != null 
                              ? 'Email: ${ContractStyle.textResolver!('[Contractee.Email]')}' 
                              : 'Email: [Contractee.Email]',
                          style: const TextStyle(fontSize: 12)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('Recitals'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              'WHEREAS, the Contractee intends to undertake a construction project (the "Project") described as follows:'),
          const SizedBox(height: 8),
          
          ContractStyle.bulletList([
            'Brief Description of the Project: [Project.Description]',
            'Location: [Project.Address]',
            'Start Date: [Project.StartDate]',
            'Completion Date: [Project.CompletionDate] (Estimate)',
            'Duration: [Project.Duration] days',
          ]),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'WHEREAS, Contractor is willing to provide construction services for the Project, as further described herein;'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'NOW, THEREFORE, in consideration of the premises and mutual covenants contained herein, and for other good and valuable consideration, the parties hereto agree as follows:'),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('1. Scope of Work and Contract Price'),
          const SizedBox(height: 12),

      ContractStyle.paragraph(
              '1.1. The Contractor agrees to furnish all labor, materials, equipment, and services necessary for the completion of the Project in accordance with the plans, specifications, and other contract documents for a total contract price of:'),
          
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'TOTAL CONTRACT PRICE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  ContractStyle.textResolver != null 
                      ? 'PHP ${ContractStyle.textResolver!('[Payment.Total]')}' 
                      : 'PHP [Payment.Total]',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            '1.2 Payment Schedule:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ContractStyle.bulletList([
            ContractStyle.textResolver != null 
                ? 'Down Payment: ${ContractStyle.textResolver!('[Payment.DownPaymentPercentage]')}% of total contract price - Due upon contract signing'
                : 'Down Payment: [Payment.DownPaymentPercentage]% of total contract price - Due upon contract signing',
            ContractStyle.textResolver != null 
                ? 'Final Payment: PHP${ContractStyle.textResolver!('[Payment.FinalPayment]')} - Due upon final completion and acceptance'
                : 'Final Payment: PHP[Payment.FinalPayment] - Due upon final completion and acceptance',
            ContractStyle.textResolver != null 
                ? 'Retention: ${ContractStyle.textResolver!('[Payment.RetentionPercentage]')}% - Released after ${ContractStyle.textResolver!('[Payment.RetentionPeriod]')} days from completion'
                : 'Retention: [Payment.RetentionPercentage]% - Released after [Payment.RetentionPeriod] days from completion',
            ContractStyle.textResolver != null 
                ? 'Payment Terms: Net ${ContractStyle.textResolver!('[Payment.DueDays]')} days from invoice date'
                : 'Payment Terms: Net [Payment.DueDays] days from invoice date',
            ContractStyle.textResolver != null 
                ? 'Late Payment Fee: ${ContractStyle.textResolver!('[Payment.LateFeePercentage]')}% per month on overdue amounts'
                : 'Late Payment Fee: [Payment.LateFeePercentage]% per month on overdue amounts',
          ]),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('2. Obligations and Responsibilities'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Contractee\'s Responsibilities'),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResponsibilityRow('Payment to Contractor', 'Make payments according to schedule', isFirst: true),
                _buildResponsibilityRow('Site Access and Utilities', 'Provide access and utilities as needed'),
                _buildResponsibilityRow('Permits and Approvals', 'Assist in obtaining necessary permits'),
                _buildResponsibilityRow('Builder\'s Risk Insurance', 'Maintain appropriate insurance coverage', isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('3. Contractor\'s Responsibilities'),
          const SizedBox(height: 12),
  
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResponsibilityRow('Performance of Work', 'Execute work according to plans and specifications', isFirst: true),
                _buildResponsibilityRow('Procurement of Materials', 'Source materials and hire qualified workers'),
                _buildResponsibilityRow('Subcontractor Payments', 'Ensure timely payment to subcontractors'),
                _buildResponsibilityRow('Compliance with Laws', 'Comply with all applicable laws and building codes', isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('4. Project Schedule and Milestones'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Project Timeline:'),
          const SizedBox(height: 8),
          ContractStyle.bulletList([
            'Project Start Date: [Project.StartDate]',
            'Estimated Completion: [Project.CompletionDate]',
            'Total Duration: [Project.Duration] days',
            'Working Days: [Project.WorkingDays]',
            'Working Hours: [Project.WorkingHours]',
          ]),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('Major Milestones:'),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Expanded(flex: 1, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Target Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                if (ContractStyle.shouldShowMilestoneRow(1))
                  _buildMilestoneRow('1', '[Milestone.1.Description]', '[Milestone.1.Duration]', '[Milestone.1.Date]'),
                if (ContractStyle.shouldShowMilestoneRow(2))
                  _buildMilestoneRow('2', '[Milestone.2.Description]', '[Milestone.2.Duration]', '[Milestone.2.Date]'),
                if (ContractStyle.shouldShowMilestoneRow(3))
                  _buildMilestoneRow('3', '[Milestone.3.Description]', '[Milestone.3.Duration]', '[Milestone.3.Date]'),
                if (ContractStyle.shouldShowMilestoneRow(4))
                  _buildMilestoneRow('4', '[Milestone.4.Description]', '[Milestone.4.Duration]', '[Milestone.4.Date]', isLast: true),
                if (ContractStyle.shouldShowMilestoneRow(5))
                  _buildMilestoneRow('5', '[Milestone.5.Description]', '[Milestone.5.Duration]', '[Milestone.5.Date]', isLast: true),
                if (ContractStyle.shouldShowMilestoneRow(6))
                  _buildMilestoneRow('6', '[Milestone.6.Description]', '[Milestone.6.Duration]', '[Milestone.6.Date]', isLast: true),
                if (ContractStyle.shouldShowMilestoneRow(7))
                  _buildMilestoneRow('7', '[Milestone.7.Description]', '[Milestone.7.Duration]', '[Milestone.7.Date]', isLast: true),
                if (ContractStyle.shouldShowMilestoneRow(8))
                  _buildMilestoneRow('8', '[Milestone.8.Description]', '[Milestone.8.Duration]', '[Milestone.8.Date]', isLast: true),
                if (ContractStyle.shouldShowMilestoneRow(9))
                  _buildMilestoneRow('9', '[Milestone.9.Description]', '[Milestone.9.Duration]', '[Milestone.9.Date]', isLast: true),
                if (ContractStyle.shouldShowMilestoneRow(10))
                  _buildMilestoneRow('10', '[Milestone.10.Description]', '[Milestone.10.Duration]', '[Milestone.10.Date]', isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('5. Insurance and Bonds'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Performance and Payment Bonds'),
      ContractStyle.paragraph(
              'The Contractor shall furnish to the Contractee, within [Bond.TimeFrame] days, performance and payment bonds executed by a surety company licensed to do business in the jurisdiction where the project is located. The performance bond shall be in an amount not less than PHP [Bond.PerformanceAmount] and the payment bond shall be in an amount not less than PHP [Bond.PaymentAmount].'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('6. Change Orders and Modifications'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '6.1. Any changes to the scope of work, contract price adjustments, or modifications to the project timeline must be mutually approved in writing through a formal change order process.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '6.2. Change Order Pricing: Labor rates for change orders shall be PHP [Change.LaborRate] per hour. Materials shall be charged at cost plus [Change.MaterialMarkup]% markup. Equipment charges shall be at cost plus [Change.EquipmentMarkup]% markup.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('7. Termination and Warranties'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '7.1. Either party may terminate this contract with [Notice.Period] days written notice. Upon termination, Contractor shall be compensated for all work completed and accepted by the Contractee up to the termination date.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '7.2. Contractor provides a [Warranty.Period] months warranty on workmanship and materials from the date of project completion. This warranty covers defects in materials and workmanship under normal use and conditions.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '7.3. Any disputes arising from this contract shall be resolved through mediation first, and if unsuccessful, through arbitration under Philippine law. All legal proceedings shall be conducted in the courts of [Contractor.Province], Republic of the Philippines.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('8. Governing Law'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              'This Contract shall be governed by and construed in accordance with the laws of the Republic of the Philippines, without regard to its conflict of law principles.'),

          const SizedBox(height: 30),
          const Center(
            child: Text(
              'Executed by the Parties on the date indicated below.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade50,
                      ),
                      child: const Center(
                        child: Text('Signature', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade50,
                      ),
                      child: const Center(
                        child: Text('MM / DD / YYYY', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ContractStyle.textResolver != null 
                          ? '${ContractStyle.textResolver!('[Contractee.FirstName]')} ${ContractStyle.textResolver!('[Contractee.LastName]')}' 
                          : '[Contractee.FirstName] [Contractee.LastName]',
                      style: const TextStyle(fontSize: 12)
                    ),
                    Text('Contractee', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade50,
                      ),
                      child: const Center(
                        child: Text('Signature', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade50,
                      ),
                      child: const Center(
                        child: Text('MM / DD / YYYY', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ContractStyle.textResolver != null 
                          ? '${ContractStyle.textResolver!('[Contractor.FirstName]')} ${ContractStyle.textResolver!('[Contractor.LastName]')}' 
                          : '[Contractor.FirstName] [Contractor.LastName]',
                      style: const TextStyle(fontSize: 12)
                    ),
                    Text('Contractor', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  static Widget _buildResponsibilityRow(String title, String description, {bool isFirst = false, bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
        ),
        borderRadius: isLast ? const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ) : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(description, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  static Widget _buildMilestoneRow(String phase, String description, String duration, String date, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade400)),
        borderRadius: isLast ? const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ) : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 1, 
            child: Text(phase, style: const TextStyle(fontSize: 11))
          ),
          Expanded(
            flex: 3, 
            child: Text(
              ContractStyle.textResolver != null 
                  ? ContractStyle.textResolver!(description) 
                  : description,
              style: const TextStyle(fontSize: 11)
            )
          ),
          Expanded(
            flex: 2, 
            child: Text(
              ContractStyle.textResolver != null 
                  ? '${ContractStyle.textResolver!(duration)} days' 
                  : '$duration days',
              style: const TextStyle(fontSize: 11)
            )
          ),
          Expanded(
            flex: 2, 
            child: Text(
              ContractStyle.textResolver != null 
                  ? ContractStyle.textResolver!(date) 
                  : date,
              style: const TextStyle(fontSize: 11)
            )
          ),
        ],
      ),
    );
  }
}
