// ignore_for_file: file_names

import 'package:backend/utils/be_contractformat.dart';
import 'package:flutter/material.dart';

class TimeMaterialsContract extends StatelessWidget {
  const TimeMaterialsContract({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'TIME AND MATERIALS CONSTRUCTION CONTRACT',
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
        'This time and materials contract (hereinafter referred to as the "Contract") is entered into and shall be effective this [Date of contract creation] ("Effective Date") by and between [First name of the contractee] [Last name of the contractee] ("Contractee") residing at [Contractee street address], [Contractee city], [Contractee postal code] and [First name of the contractor] [Last name of the contractor] ("Contractor") with principal office at [Contractor street address], [Contractor city], [Contractor postal code].'),

          ContractStyle.paragraph(
              'The Contractee and Contractor are collectively referred to as the "Parties" and individually as "Party" throughout this Contract.'),

      ContractStyle.paragraph(
        'The Parties agree that the Contractor will complete the project described as: [Project description as defined by the contractor] ("Project"), and furnish all materials, supplies, services, labor, tools, transportation, equipment, and parts for said work in accordance with this Contract. (Include a clear, detailed description of what the project entails.)'),

          const SizedBox(height: 24),
          ContractStyle.sectionTitle('Terms and Conditions'),
          const SizedBox(height: 16),

          ContractStyle.sectionTitle('1. Relationship of Parties'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Contractor, in the fulfillment of this Contract, shall act in the capacity of an independent contractor and not as an agent, employee, or partner, of the Contractee.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('2. Contractor\'s Duties'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Contractor agrees to provide the time and materials required to complete the Project as defined in this Contract.'),

          const SizedBox(height: 12),
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
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Duties', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Text('Scope of Work'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Scope of work]') 
                                : '[Scope of work]'
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Text('Time'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Estimated labor hours]') 
                                : '[Estimated labor hours]'
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Text('Materials'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[List of required materials]') 
                                : '[List of required materials]'
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          ContractStyle.paragraph(
              'Subcontractors. Any subcontractor used by the Contractor in connection with the Contractor\'s work under this Contract shall be limited to individuals or firms that are specifically identified by the Contractor and agreed to by the Contractee. The Contractor shall obtain the Contractee\'s written consent before making any changes with regard to the previously approved subcontractors.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('3. Completion Schedule'),
          const SizedBox(height: 12),
      ContractStyle.paragraph(
        'This Contract shall be effective as of the Effective Date herein and shall continue until [Estimated completion date] or for [Project duration] days unless terminated early or an extension is mutually agreed upon between the Parties with written consent. The project shall commence on [Start date of the project]. The Contractor shall execute the Project in accordance with a detailed schedule mutually agreed upon by the Parties.'),

      ContractStyle.paragraph(
        'Schedule: [Project schedule]'),
          
      ContractStyle.paragraph(
        'Milestones: [List of project milestones]'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('4. Materials Supply and Delivery'),
          const SizedBox(height: 12),

          ContractStyle.sectionTitle('4.1 Quality of Materials:'),
          ContractStyle.paragraph(
              'The Contractor shall inspect all materials used for the Project to ensure they are of acceptable quality. If a quality issue occurs as a result of improper or lack of inspection, the Contractor will be responsible for any damages that occur and the expenses to replace said materials with appropriate substitutes.'),

          const SizedBox(height: 12),
          ContractStyle.sectionTitle('4.2 Delivery of Materials:'),
          ContractStyle.paragraph(
              'The Contract may deliver materials in installments if the Parties agree to do so in the Contract, in which case materials should be invoiced and paid for separately. The Contract shall provide that each material delivery is accompanied by a delivery note showing the quantity and type of materials included.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('5. Timeliness'),
          const SizedBox(height: 12),
      ContractStyle.paragraph(
        'This Contract shall begin on the day specified and shall continue until the Project is completed or upon the set due date. Any delays incurred by the Contractor that are found to be unreasonable shall be determined a breach of this Contract. The Company shall impose a fine of up to PHP[Maximum penalty amount] for such a delay.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('6. Representation and Warranties'),
          const SizedBox(height: 12),
          ContractStyle.bulletList([
            'The Contractor represents they have the expertise, knowledge, and experience needed to provide the labor and materials outlined in this Contract.',
            'The Contractor agrees to uphold all legal requirements and laws of the Republic of the Philippines.',
            'The Contractor shall conform to all materials with regards to their description and any applicable specification, ensure defect-free material in terms of material, design, and workmanship, and ensure they are of satisfactory quality according to Contractor standards.',
          ]),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('7. Rates & Payment'),
          const SizedBox(height: 12),
      ContractStyle.paragraph(
        'The Contractor agrees to such standard pre-determined rates set by [First name of the contractee] [Last name of the contractee]. The following rates shall apply unless otherwise mutually modified by both parties:'),

          const SizedBox(height: 12),
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
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
                
                if (ContractStyle.shouldShowItemRow(1))
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_box, color: Colors.blue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    ContractStyle.textResolver != null 
                                        ? ContractStyle.textResolver!('[Item 1 name]') 
                                        : '[Item 1 name]',
                                    style: const TextStyle(fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                              Text(
                                ContractStyle.textResolver != null 
                                    ? ContractStyle.textResolver!('[Item 1 description]') 
                                    : '[Item 1 description]',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 1 price]') 
                                : 'PHP[Item 1 price]'
                          )
                        ),
                        Expanded(
                          flex: 1, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Item 1 quantity]') 
                                : '[Item 1 quantity]'
                          )
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 1 subtotal]') 
                                : 'PHP[Item 1 subtotal]', 
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          )
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (ContractStyle.shouldShowItemRow(2))
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_box, color: Colors.blue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    ContractStyle.textResolver != null 
                                        ? ContractStyle.textResolver!('[Item 2 name]') 
                                        : '[Item 2 name]',
                                    style: const TextStyle(fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                              Text(
                                ContractStyle.textResolver != null 
                                    ? ContractStyle.textResolver!('[Item 2 description]') 
                                    : '[Item 2 description]',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 2 price]') 
                                : 'PHP[Item 2 price]'
                          )
                        ),
                        Expanded(
                          flex: 1, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Item 2 quantity]') 
                                : '[Item 2 quantity]'
                          )
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 2 subtotal]') 
                                : 'PHP[Item 2 subtotal]', 
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          )
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (ContractStyle.shouldShowItemRow(3))
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_box, color: Colors.blue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    ContractStyle.textResolver != null 
                                        ? ContractStyle.textResolver!('[Item 3 name]') 
                                        : '[Item 3 name]',
                                    style: const TextStyle(fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                              Text(
                                ContractStyle.textResolver != null 
                                    ? ContractStyle.textResolver!('[Item 3 description]') 
                                    : '[Item 3 description]',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 3 price]') 
                                : 'PHP[Item 3 price]'
                          )
                        ),
                        Expanded(
                          flex: 1, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Item 3 quantity]') 
                                : '[Item 3 quantity]'
                          )
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 3 subtotal]') 
                                : 'PHP[Item 3 subtotal]', 
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          )
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (ContractStyle.shouldShowItemRow(4))
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    ContractStyle.textResolver != null 
                                        ? ContractStyle.textResolver!('[Item 4 name]') 
                                        : '[Item 4 name]',
                                    style: const TextStyle(fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                              Text(
                                ContractStyle.textResolver != null 
                                    ? ContractStyle.textResolver!('[Item 4 description]') 
                                    : '[Item 4 description]',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 4 price]') 
                                : 'PHP[Item 4 price]'
                          )
                        ),
                        Expanded(
                          flex: 1, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Item 4 quantity]') 
                                : '[Item 4 quantity]'
                          )
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 4 subtotal]') 
                                : 'PHP[Item 4 subtotal]', 
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          )
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (ContractStyle.shouldShowItemRow(5))
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    ContractStyle.textResolver != null 
                                        ? ContractStyle.textResolver!('[Item 5 name]') 
                                        : '[Item 5 name]',
                                    style: const TextStyle(fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                              Text(
                                ContractStyle.textResolver != null 
                                    ? ContractStyle.textResolver!('[Item 5 description]') 
                                    : '[Item 5 description]',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 5 price]') 
                                : 'PHP[Item 5 price]'
                          )
                        ),
                        Expanded(
                          flex: 1, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('[Item 5 quantity]') 
                                : '[Item 5 quantity]'
                          )
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            ContractStyle.textResolver != null 
                                ? ContractStyle.textResolver!('PHP[Item 5 subtotal]') 
                                : 'PHP[Item 5 subtotal]', 
                            style: const TextStyle(fontWeight: FontWeight.w500)
                          )
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(flex: 6, child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null
                                ? 'PHP${ContractStyle.textResolver!('[Subtotal amount]')}'
                                : 'PHP[Subtotal amount]',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(flex: 6, child: Text('Discount', style: TextStyle(color: Colors.red))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null
                                ? '-PHP${ContractStyle.textResolver!('[Discount amount]')}'
                                : '-PHP[Discount amount]',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(flex: 6, child: Text('Tax')),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null
                                ? 'PHP${ContractStyle.textResolver!('[Tax amount]')}'
                                : 'PHP[Tax amount]',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade400)),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(flex: 6, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ContractStyle.textResolver != null
                                ? 'PHP${ContractStyle.textResolver!('[Total amount]')}'
                                : 'PHP[Total amount]',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
      ContractStyle.paragraph(
        'All invoices shall be sent to [First name of the contractee] [Last name of the contractee] or the authorized personnel identified in this Contract. The Contractee will make payments for services on a (weekly, biweekly, monthly, or other) basis for services performed during the previous month in accordance with this Contract. The Contractee will pay the Contractor, upon submission of proper invoices, the prices agreed to in the Contract for services rendered and accepted, minus any deductions provided in this Contract, within 30 days (Net 30).'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('8. Security Interest'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Contractee shall grant to the Contractor a security interest, in all of the Contractee\'s title, right, and interest in the materials and products sold hereunder, to secure the purchase price payment and the performance of obligations, when due from the Contractee as per this Agreement.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('9. Tax'),
          const SizedBox(height: 12),
      ContractStyle.paragraph(
        'Prices for materials are exclusive of [Applicable taxes]. The Contractee agrees to pay such taxes directly or to reimburse the Contractor for all such taxes. Where applicable, said tax or taxes shall be added to the invoice as a separate charge or invoiced separately.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('10. Limitation of Liability'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'Neither Party shall be liable to the other party or any third party for any damages resulting from any part of this Contract, such as but not limited to, loss of revenue, profit, or failure in the delivery of services.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('11. Assignment'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'Neither Party may assign this Contract or the rights and obligations hereunder to any third party without the consent of the other Party. This consent shall be prior express written consent before the assignment and shall not be unreasonably withheld.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('12. Confidentiality'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'All confidential information obtained by or communicated to either of the Parties in connection with this Contract\'s services shall be held by them in full faith. At no time shall the Parties use any confidential information obtained through this relationship, either indirectly or directly, for personal benefit. The Parties also shall not disclose or communicate confidential information to any third party. This provision shall exist after the termination of this Contract.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('13. Disputes'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'In the event of any dispute arising out of, or in connection with, this Contract between the Parties that cannot be resolved by mutual agreement, it shall be resolved by Arbitration. The Venue of the Arbitration shall occur in the Philippines. The Arbitrator\'s decision shall be final and binding on both Parties.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('14. Notice'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'Any notice required by this Contract shall be in writing and shall be delivered to the appropriate party by personal delivery or registered or certified mail with postage prepaid.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('15. Severability'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'In the event that any provision of this Contract is voided or deemed invalid or unenforceable by a court of competent jurisdiction, in whole or in part, that part shall be severed from the remainder of this Contract, and all other provisions shall remain in full force and effect as valid and enforceable.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('16. Entire Agreement'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Parties acknowledge that this Contract represents the entire Contract between both Parties.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('17. Changes and Amendments'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'If the Parties desire to change, add to, or modify any terms, they shall be made in writing and signed by both Parties before being attached to this Agreement.'),

          const SizedBox(height: 16),
          ContractStyle.sectionTitle('18. Governing Law'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'This Contract shall be governed by and construed in full accordance with the laws of the Republic of the Philippines. If a dispute should arise under this Contract that cannot be resolved by Arbitration, it shall be resolved by litigation in the courts of (state, region, etc.).'),

          const SizedBox(height: 30),
          ContractStyle.sectionTitle('Acceptance'),
          const SizedBox(height: 12),
          ContractStyle.paragraph(
              'The Parties agree to the terms and conditions set forth know this Contract as demonstrated by their signatures as follows:'),

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
