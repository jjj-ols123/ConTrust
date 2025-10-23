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
        'This Cost-Plus Construction Contract ("Contract") is entered into on [Date of contract creation] by and between [Contractor firm or company name] ("Your Construction Company\'s Name"), hereinafter referred to as the "Contractor," and [First name of the contractee] [Last name of the contractee], hereinafter referred to as the "Contractee."'),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('The Parties'),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContractStyle.sectionTitle('Contractee'),
                    const SizedBox(height: 8),
                    ContractStyle.paragraph('Name: [First name of the contractee] [Last name of the contractee]'),
                    ContractStyle.paragraph('Address: [Contractee street address] [Contractee city] [Contractee postal code]'),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContractStyle.sectionTitle('Contractor'),
                    const SizedBox(height: 8),
                    ContractStyle.paragraph('Name: [First name of the contractor] [Last name of the contractor]'),
                    ContractStyle.paragraph('Address: [Contractor street address] [Contractor city] [Contractor postal code]'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('Recitals'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              'WHEREAS, the Contractee intends to undertake a construction project (the "Project") described as follows:'),
          
          ContractStyle.bulletList([
            'Brief Description of the Project: [Project description]',
            'Location: [Project address]',
            'Start Date: [Start date of the project]',
            'Completion Date: [Estimated completion date] (Estimate)',
            'Duration: [Project duration] days',
          ]),

          ContractStyle.paragraph(
              'WHEREAS, Contractor is willing to provide construction services for the Project, as further described herein;'),

          ContractStyle.paragraph(
              'NOW, THEREFORE, in consideration of the premises and mutual covenants contained herein, and for other good and valuable consideration, the parties hereto agree as follows:'),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('1. Scope of Work and Cost'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '1.1. The Contractor shall be reimbursed for actual costs incurred for labor, materials, equipment, and other expenses related to the project, plus a fee for overhead and profit as detailed below:'),

          ContractStyle.bulletList([
            'Labor Costs: Actual hourly rates as specified - PHP[Hourly labor rate] per hour',
            'Material Costs: Actual cost of materials with receipts - PHP[Estimated material costs] (estimated)',
            'Equipment Costs: Actual rental/usage costs - PHP[Estimated equipment costs] (estimated)',
            'Subcontractor Costs: Actual payments to qualified subcontractors',
            'Overhead and Profit Fee: [Overhead and profit percentage]% of total project costs',
          ]),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('1.2 Payment Terms:'),
          ContractStyle.bulletList([
            'Total Estimated Project Cost: PHP[Total estimated project cost]',
            'Payment Interval: [Payment interval] (weekly/bi-weekly/monthly)',
            'Retention Fee: PHP[Retention fee] (held until project completion)',
            'Late Payment Fee: [Late payment fee percentage]% per month on overdue amounts',
            'Payment Due: [Number of days after invoice due] days from invoice date',
          ]),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('2. Obligations and Responsibilities'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('Contractee\'s Responsibilities'),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Payment to Contractor'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractee shall be responsible for making payments to the Contractor for the cost of the work, as well as the agreed-upon fee. The cost of the work shall include all allowable costs as defined in this Contract.'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Site Access and Utilities'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractee shall ensure that the Contractor has unobstructed access to the construction site and shall provide all necessary utilities required for the construction, including but not limited to water, electricity, and sanitation facilities.'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Permits and Approvals'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractee shall be responsible for obtaining all necessary permits, licenses, and approvals required for the construction project. This includes, but is not limited to, building permits, zoning variances, and environmental clearances.'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Builder\'s Risk Insurance'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractee shall obtain and maintain the builder\'s risk insurance for the construction project. This insurance shall cover any loss or damage to the work, including materials and equipment, caused by perils such as fire, theft, vandalism, and natural disasters.'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('3. Contractor\'s Responsibilities'),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Performance of Work'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractor shall diligently and competently perform all work in strict accordance with the contract documents, including but not limited to the plans, specifications, and any subsequent modifications or change orders. The Contractor shall ensure the quality of workmanship and materials meets or exceeds industry standards.'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Procurement of Materials and Employment of Workers'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractor is responsible for the procurement of all necessary materials, equipment, and labor required to complete the construction project. This shall include but is not limited to, the selection, purchase, delivery, and storage of all materials and the hiring, supervision, and payment of all laborers, subcontractors, and suppliers.'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Subcontractor Payments'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractor shall promptly and, in accordance with the terms of their agreements, make all payments to subcontractors and suppliers associated with the project. The Contractor shall bear full responsibility for the management and payment of all subcontractors and suppliers.'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ContractStyle.sectionTitle('Compliance with Laws and Standards'),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: ContractStyle.paragraph(
                    'The Contractor shall, at all times, comply with all applicable federal, state, and local laws, regulations, ordinances, codes, rules, and standards pertaining to the construction work. This includes but is not limited to safety standards, building codes, environmental regulations, and permits required for the project.'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('3.1. Cost of Work and Payments'),
          const SizedBox(height: 12),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('Cost Plus Fee'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              'The Contractor\'s compensation under this Agreement shall be based on the cost of work. The Contractor shall receive a fee calculated as a negotiated percentage of the cost of work, exclusive of certain components.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Contractor\'s fee shall be calculated based solely on the following:'),

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

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('Procedures for Time Extensions:'),
          ContractStyle.paragraph(
              'In the event that the Contractor is delayed in the progress of the Work for reasons beyond the Contractor\'s control, including but not limited to acts of God, strikes, material shortages, changes in the Work ordered by the Contractee, or other excusable delays, the Contractor shall promptly notify the Contractee in writing of the cause of the delay. The Contractee shall have the right to grant or deny time extensions, at the Contractee\'s sole discretion, for any delays that are found to be excusable.'),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('No Damages to the Contractor for Delay:'),
          ContractStyle.paragraph(
              'The Contractor acknowledges and agrees that, except for the extension of time for completing the Work as provided herein, the Contractor shall not be entitled to any additional compensation, damages, or claims for any delays or interruptions in the progress of the Work, regardless of the cause of such delays. The Contractor further waives any right to recover consequential damages, lost profits, or any other indirect damages arising from any delay.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('5. Insurance and Bonds'),
          const SizedBox(height: 12),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('Contractor\'s Insurance:'),
          ContractStyle.paragraph(
              'The Contractor shall, at its own expense, procure and maintain insurance coverage during the term of this Agreement, in accordance with industry standards and with limits of liability as specified herein, and shall provide evidence of such insurance to the Contractee prior to commencing any work under this Contract. Such insurance shall include, but not be limited to:'),

          const SizedBox(height: 12),
      ContractStyle.sectionTitle('Performance and Payment Bonds'),
      ContractStyle.paragraph(
        'The Contractor shall furnish to the Contractee, within [Number of days to submit bonds] days, performance and payment bonds executed by a surety company licensed to do business in the jurisdiction where the project is located. The performance bond shall be in an amount not less than PHP[Performance bond amount] and shall guarantee the faithful performance of all Work under this Agreement.'),

          ContractStyle.paragraph(
        'The payment bond shall be in an amount not less than PHP[Payment bond amount] and shall guarantee the payment to all subcontractors, laborers, and material suppliers for labor and materials furnished in connection with this Contract. The Contractor shall maintain these bonds in full force and effect throughout the duration of the project.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('6. Change Orders and Modifications'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '6.1. Any changes to the scope of work, cost adjustments, or modifications to the project timeline must be mutually approved in writing through a formal change order process. All change orders must include: detailed description of changes, cost impact analysis, time impact assessment, and signatures from both parties.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('7. Termination and Disputes'),
          const SizedBox(height: 12),

      ContractStyle.paragraph(
        '7.1. Either party may terminate this contract with [Termination notice period in days] days written notice. Upon termination, Contractor shall be compensated for all work completed and costs incurred up to the termination date.'),

          const SizedBox(height: 12),
      ContractStyle.paragraph(
        '7.2. Contractor provides a [Warranty period in months] months warranty on workmanship and materials from the date of project completion. This warranty covers defects in materials and workmanship under normal use and conditions.'),

          const SizedBox(height: 12),
      ContractStyle.paragraph(
        '7.3. Any disputes arising from this contract shall be resolved through mediation first, and if unsuccessful, through arbitration under Philippine law. All legal proceedings shall be conducted in the courts of [Contractor province], Republic of the Philippines.'),

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
                    ContractStyle.paragraph('[First name of the contractee] [Last name of the contractee]'),
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
                    ContractStyle.paragraph('[First name of the contractor] [Last name of the contractor]'),
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
}
