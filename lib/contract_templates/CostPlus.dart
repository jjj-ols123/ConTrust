// ignore_for_file: file_names

import 'package:backend/utils/be_contractformat.dart';
import 'package:flutter/material.dart';

class CostPlusContract extends StatelessWidget {
  const CostPlusContract({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'COST-PLUS CONSTRUCTION CONTRACT',
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
            'This Cost-Plus Construction Contract ("Contract") is entered into on [Contract.CreationDate] by and between [Contractor.Company] ("Your Construction Company\'s Name"), hereinafter referred to as the "Contractor," and [Contractee.FirstName] [Contractee.LastName], hereinafter referred to as the "Contractee."'),

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
          ContractStyle.sectionTitle('1. Scope of Work and Cost'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '1.1. The Contractor shall be reimbursed for actual costs incurred for labor, materials, equipment, and other expenses related to the project, plus a fee for overhead and profit as detailed below:'),
          const SizedBox(height: 8),

          ContractStyle.bulletList([
            'Labor Costs: Actual hourly rates as specified - PHP [Labor.Costs] per hour',
            'Material Costs: Actual cost of materials with receipts - PHP [Material.Costs] (estimated)',
            'Equipment Costs: Actual rental/usage costs - PHP [Equipment.Costs] (estimated)',
            'Subcontractor Costs: Actual payments to qualified subcontractors',
            'Overhead and Profit Fee: [Overhead.Percentage]% of total project costs',
          ]),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('1.2 Payment Terms:'),
          const SizedBox(height: 8),

          ContractStyle.bulletList([
            'Total Estimated Project Cost: PHP [Estimated.Total]',
            'Payment Interval: [Payment.Interval] (weekly/bi-weekly/monthly)',
            'Retention Fee: PHP [Retention.Fee] (held until project completion)',
            'Late Payment Fee: [Late.Fee.Percentage]% per month on overdue amounts',
            'Payment Due: [Payment.DueDays] days from invoice date',
          ]),

          const SizedBox(height: 20),
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
          ContractStyle.sectionTitle('3.1. Cost of Work and Payments'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Cost Plus Fee'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              'The Contractor\'s compensation under this Agreement shall be based on the cost of work. The Contractor shall receive a fee calculated as a negotiated percentage of the cost of work, exclusive of certain components.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Contractor\'s fee shall be calculated based solely on the following:'),

          const SizedBox(height: 8),
          ContractStyle.bulletList([
            '(a) The Contractor\'s costs for materials, labor, equipment, and other direct project expenses as directly related to the cost of work.',
            '(b) No markup shall be allowed on subcontracts for the execution of the cost of work.',
            '(c) Excluded from the calculation of the Contractor\'s fee are Contractor overhead, profit, salaries, and other indirect expenses.',
          ]),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('Payment Procedures'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              'Payment to the Contractor shall be made through progress payments based on the Contractor\'s invoices, which shall accurately reflect the Cost of Work as defined in this Agreement.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The final payment to the Contractor shall be made after the completion of the Work and the acceptance of the project by the Owner. Final payment shall be based on the final Cost of Work as determined in accordance with the terms of this Agreement.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('4. Delays and Extensions of Time'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Procedures for Time Extensions:'),
          ContractStyle.paragraph(
              'In the event that the Contractor is delayed in the progress of the Work for reasons beyond the Contractor\'s control, including but not limited to acts of God, strikes, material shortages, changes in the Work ordered by the Contractee, or other excusable delays, the Contractor shall promptly notify the Contractee in writing of the cause of the delay.'),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('No Damages to the Contractor for Delay:'),
          ContractStyle.paragraph(
              'The Contractor acknowledges and agrees that, except for the extension of time for completing the Work as provided herein, the Contractor shall not be entitled to any additional compensation, damages, or claims for any delays or interruptions in the progress of the Work, regardless of the cause of such delays. The Contractor further waives any right to recover consequential damages, lost profits, or any other indirect damages arising from any delay.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('5. Insurance and Bonds'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Contractor\'s Insurance:'),
          ContractStyle.paragraph(
              'The Contractor shall, at its own expense, procure and maintain insurance coverage during the term of this Agreement, in accordance with industry standards and with limits of liability as specified herein, and shall provide evidence of such insurance to the Contractee prior to commencing any work under this Contract. Such insurance shall include, but not be limited to:'),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('Performance and Payment Bonds'),
          ContractStyle.paragraph(
            'The Contractor shall furnish to the Contractee, within [Bond.TimeFrame] days, performance and payment bonds executed by a surety company licensed to do business in the jurisdiction where the project is located. The performance bond shall be in an amount not less than PHP [Bond.PerformanceAmount] and shall guarantee the faithful performance of all Work under this Agreement.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
            'The payment bond shall be in an amount not less than PHP [Bond.PaymentAmount] and shall guarantee the payment to all subcontractors, laborers, and material suppliers for labor and materials furnished in connection with this Contract. The Contractor shall maintain these bonds in full force and effect throughout the duration of the project.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('6. Change Orders and Modifications'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '6.1. Any changes to the scope of work, cost adjustments, or modifications to the project timeline must be mutually approved in writing through a formal change order process. All change orders must include: detailed description of changes, cost impact analysis, time impact assessment, and signatures from both parties.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('7. Termination and Disputes'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
            '7.1. Either party may terminate this contract with [Notice.Period] days written notice. Upon termination, Contractor shall be compensated for all work completed and costs incurred up to the termination date.'),

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
              'This Contract shall be governed by and construed in accordance with the laws of the Republic of the Philippines, without regard to its conflict of law principles. Any legal action or proceeding arising under or in connection with this Contract shall be brought exclusively in the state or federal courts located within the Republic of the Philippines, and the parties hereby consent to the personal jurisdiction and venue of these courts.'),

          ContractStyle.paragraph(
              'The prevailing party in any such legal action or proceeding shall be entitled to recover its reasonable attorneys\' fees and costs incurred in connection with such action or proceeding.'),

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
}
