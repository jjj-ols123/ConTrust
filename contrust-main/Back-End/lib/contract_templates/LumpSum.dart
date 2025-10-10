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
        'This Lump Sum Construction Contract is entered into on [Date of contract creation] between [First name of the contractee] [Last name of the contractee] ("Contractee") and [Contractor company name] ("Contractor") (collectively, the "Parties").'),
          
          const SizedBox(height: 16),
      ContractStyle.paragraph(
        'This Construction Contract, along with incorporated documents referenced herein, sets forth the terms and conditions agreed to between the Parties relating to the construction of [Project description] by Contractor for Contractee.'),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('Terms and Conditions'),
          const SizedBox(height: 16),

          ContractStyle.sectionTitle('1. Parties and Property'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('1.1 Contractee Information:'),
          ContractStyle.paragraph(
              'Contractee is [First name of the contractee] [Last name of the contractee], the legal owner of the property on which construction will be completed under this Construction Contract, with contact information as follows:'),
          ContractStyle.infoBlock([
            '[Contractee street address]',
            '[Contractee phone number]',
            '[Contractee email address]'
          ]),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('1.2 Contractor Information:'),
          ContractStyle.paragraph(
              '[Contractor company name] is a duly licensed general contractor in good standing. License number [Contractor license number], with contact information as follows:'),
          ContractStyle.infoBlock([
            '[Contractor street address]',
            '[Contractor phone number]',
            '[Contractor email address]'
          ]),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('1.3 Construction Site:'),
          ContractStyle.paragraph(
              'The site for the construction to be completed under this Construction Contract is as follows:'),
          ContractStyle.infoBlock([
            'Site Address: [Project site address]',
            'Legal Description: [Legal description of property]',
            'Property Description: [Property description]'
          ]),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '1.4. Construction Project shall mean the work that Contractor (and/or Contractor\'s agents) are obligated to perform for Contractee as detailed within the following plans and specification documents, which are incorporated herein by reference:'),
          ContractStyle.bulletList([
            'Project Scope of Work: [Project scope of work]'
            'Project Specification: [Project specification]'
          ]),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('2. Compensation'),
          const SizedBox(height: 12),

      ContractStyle.paragraph(
        'The Contractee agrees to pay the Contractor for the Work the total amount of ₱[Total contract price] (the "Contract Price"). Payment of this amount is subject to additions or deductions pursuant to Change Orders as provided for in Article 4 of this Agreement. Payment for the work will be by [Payment method], according to the following schedule:'),
          
          const SizedBox(height: 16),
          ContractStyle.sectionTitle('Payment Schedule:'),
          ContractStyle.bulletList([
            'Down Payment: [Down payment percentage]% upon signing this Contract as a mobilization fee',
          ]),
          
          const SizedBox(height: 12),
          ContractStyle.sectionTitle('Progress Payments:'),
          ContractStyle.bulletList([
            'Progress Payment 1: [Progress payment 1 percentage]% at the completion of [Milestone 1 description]',
            'Progress Payment 2: [Progress payment 2 percentage]% at the completion of [Milestone 2 description]',
          ]),
          
          const SizedBox(height: 12),
          ContractStyle.sectionTitle('Final Payment:'),
          ContractStyle.bulletList([
            'Final Payment: [Final payment percentage]% upon final completion and acceptance of the project',
          ]),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('3. Contingencies, Commencement, and Completion'),
          const SizedBox(height: 12),

          ContractStyle.paragraph('3.1. This Construction Contract:'),
          ContractStyle.bulletList([
            'Is contingent on the Contractee obtaining a construction loan: The Contractee will notify the Contractor when the construction loan has been approved. If loan is not obtained by the contingency deadline, neither party shall have obligations under this Contract.',
            'Is NOT contingent on the Contractee obtaining a construction loan: The Contractee has confirmed financing is available and construction can proceed as scheduled.'
          ]),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('3.2 Work Commencement:'),
      ContractStyle.paragraph(
        '3.2. Work on the Construction Project will commence no later than [Number of days to commence work] days after the Effective Date of this Construction Contract or after the Contractor receives notice from the Contractee of approval of any construction loan, whichever is later [Start date of the project].'),

          const SizedBox(height: 12),
      ContractStyle.paragraph(
        '3.3. The Construction Project is scheduled to be completed within [Project duration in days] days of the Commencement Date, with an estimated completion date of [Estimated completion date], unless modified by change order as defined herein.'),

          const SizedBox(height: 20),

          ContractStyle.sectionTitle('4. Change Orders'),
          const SizedBox(height: 12),
  
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '4.1. From time to time during the performance of work under this Construction Contract, there may be changes required or requested to the scope of work, price, and time for completion under this Construction Contract. All such proposed changes will be submitted to the other Party in writing containing at least the following information: proposal date, the Change requested, explanation of how that will affect the cost of time of completion, and signed by the proposing party.'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'When both parties have signed to acknowledge their approval of such a proposal, it will be designated as a "Change Order" and will then be incorporated into this Construction Contract and is binding on both parties.'),

          const SizedBox(height: 20),

          ContractStyle.sectionTitle('5. Additional Provisions'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '5.1. The Contractor will obtain, at its own cost, all necessary permits and permissions to perform the work required for the Construction Project.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.2. The Contractor will maintain, throughout the duration of this Construction Contract, all legally required licenses and permissions to perform the work required for the Construction Project. To the extent it is permitted by law, the Contractor may subcontract portions of work to property qualified and licensed subcontractors upon written notice to the Contractee and ensure that prompt and proper payment is made to such subcontractors as will avoid any liens being placed on the Property.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.3. The Contractee will provide the Contractor and its employees, agents, and subcontractors reasonable access to the Property for purposes of conducting work on the Construction Project.'),

          const SizedBox(height: 12),
      ContractStyle.paragraph(
        '5.4 The Parties will purchase and maintain the following insurance policy(ies) during the course of work on the Construction Project with duly licensed insurance companies in the amount of no less than ₱[Minimum insurance amount] and with reasonable deductibles not to exceed minimum deductible amount:'),
          ContractStyle.bulletList([
        '[Insurance requirements]'
          ]),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.5 The Contractor will be responsible for properly disposing of all construction materials and debris from the Property from the Commencement Date until the date a certificate of occupancy is issued to the Contractee.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.7. "Hazardous Materials" means any substance commonly referred to or defined in any Law as a hazardous material or hazardous substance (or other similar terms), including but not limited to chemicals, solvents, petroleum products, flammable materials, explosives, asbestos, urea formaldehyde, PCB\'s, chlorofluorocarbons, freon or radioactive materials.'),

          ContractStyle.paragraph(
              'The Contractor will be responsible to comply with legal regulations regarding the removal and disposal of Hazardous Materials on its own and unless otherwise specified in this Construction Contract. The Contractor will indemnify the Contractee for any damages resulting from improper handling or disposal of Hazardous Materials at or from the Property from the Commencement Date until the date a certificate of occupancy is issued to the Contractee.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.8. Utility services to the Property during the time of construction will be arranged for, and paid by, the utility responsible party.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.9. In the event of destruction of the Property, in whole or in part, from the Commencement Date until the date a certificate of occupancy is issued to the Contractee, either party will have the right to terminate this Construction Contract.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '5.10. Contractor will not be deemed in breach of this Construction Contract or have liability to Contractee for failure to perform obligations under this Construction Contract if the failure is due to any or in substantial part to strikes, acts of God, unavailability of specified labor or materials, war, acts of terror, or other causes beyond the reasonable control of Contractor.'),

          const SizedBox(height: 20),
          
          ContractStyle.sectionTitle('6. Substantial Completion and Punch List'),
          const SizedBox(height: 12),

      ContractStyle.paragraph(
        '6.1. The Contractor will provide notice to the Contractee when the Construction Project is substantially complete. The Contractee will inspect the Construction Project within [Inspection period in days] days after receiving such notice and deliver to the Contractor a "punch list" of deficiencies found on the Construction Project. The Contractor will promptly correct the matters identified on the punch list. The Contractee may withhold from the final payment to the Contractor a reasonable estimate of the cost to correct the punch list items until such items are corrected.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('7. Warranties'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '7.1. Contractor warrants and represents that it is duly licensed to perform the work under this Construction Agreement and will perform such work in a workmanlike manner, in compliance with all applicable laws, regulations, codes, restrictive covenants, and homeowners\' association requirements, with new materials meeting the standards set for in the Construction Contract, including plans and specifications incorporated therein.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '7.2 Contractee represents that (he/she/it) is the legal owner of the Property or otherwise has the full legal authority to enter into this Construction Contract without approval from any other person or entity, that the requested work as outlined in the plans and specifications are in compliance with all applicable laws, regulations, codes, restrictive covenants, and homeowners\' association requirements, and that Contractee has the financial ability to pay the compensation to the Contractor, and any reasonable adjustments thereto via change orders, when due and that Contractee will make such payments.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '7.3 Both Parties will execute and deliver to the other or to third parties any and all documents necessary to effectuate the provisions of this Construction Contract, including construction permits, certificate of occupancy, and any other documents.'),

          const SizedBox(height: 20),
          ContractStyle.sectionTitle('9. General Terms'),
          const SizedBox(height: 12),

          ContractStyle.paragraph(
              '9.1. This Construction Contract may not be assigned by either Party without written consent of the other Party, and such consent is not to be unreasonably withheld.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '9.2. Any notice required or permitted under the terms of this Construction Contract shall be provided to the contact information set forth in Article 1 above.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '9.3. If any provision of this Construction Contract is found to be invalid, illegal, or unenforceable, the remaining portions shall remain in full force and effect.'),

          const SizedBox(height: 12),
      ContractStyle.paragraph(
        '9.4. This Construction Contract is governed and is to be interpreted under the laws of the Republic of the Philippines, and any legal proceedings relating to this Construction Contract will be maintained only in the Courts of [Contractor province] in the Republic of the Philippines.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '9.5. This Construction Contract will be binding upon and inure to the benefit of the Parties and, if applicable, to their trustee, successor, executor or administrator, or heirs.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '9.6. In the event of a conflict between the documents incorporated into this Construction Contract, the specifications will take precedence over the plans, and the plans will take precedence over this document.'),

          const SizedBox(height: 12),
          ContractStyle.paragraph(
              '9.7. This Construction Contract and the documents incorporated herein in Section 1.4, and any change orders created per the process outlined in Section 4.1, represent the entire agreement between the Parties and can only be modified in writing, signed and dated by both Parties.'),

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
        ],
      ),
    );
  }
}
