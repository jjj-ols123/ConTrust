// ignore_for_file: file_names

import 'dart:typed_data';
import 'package:backend/utils/be_contractformat.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CostPlusPDF {

  static List<pw.Widget> buildCostPlusPdf(
    Map<String, String> fieldValues, {
    Uint8List? contractorSignature,
    Uint8List? contracteeSignature,
  }) {
    List<pw.Widget> widgets = [];
    widgets.add(
      pw.Center(
        child: pw.Text(
          'COST-PLUS CONSTRUCTION CONTRACT',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 30));
    widgets.add(
      pw.Text(
        'This Cost-Plus Construction Contract ("Contract") is entered into on ${ContractStyle.getFieldValue(fieldValues, 'Contract.CreationDate')} by and between ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Company')} ("Your Construction Company\'s Name"), hereinafter referred to as the "Contractor," and ${ContractStyle.getFieldValue(fieldValues, 'Contractee.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractee.LastName')}, hereinafter referred to as the "Contractee."',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 24));
    widgets.add(
      pw.Text(
        'The Parties',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Contractor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Text('Company: ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Company')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Address: ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Address')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Phone: ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Phone')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Email: ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Email')}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Contractee', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Text('Name: ${ContractStyle.getFieldValue(fieldValues, 'Contractee.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractee.LastName')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Address: ${ContractStyle.getFieldValue(fieldValues, 'Contractee.Address')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Phone: ${ContractStyle.getFieldValue(fieldValues, 'Contractee.Phone')}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Email: ${ContractStyle.getFieldValue(fieldValues, 'Contractee.Email')}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 24));
    widgets.add(
      pw.Text(
        'Recitals',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'WHEREAS, the Contractee intends to undertake a construction project (the "Project") described as follows:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(
      pw.Bullet(
        text: 'Brief Description of the Project: ${ContractStyle.getFieldValue(fieldValues, 'Project.Description')}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Location: ${ContractStyle.getFieldValue(fieldValues, 'Project.Address')}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Start Date: ${ContractStyle.getFieldValue(fieldValues, 'Project.StartDate')}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Completion Date: ${ContractStyle.getFieldValue(fieldValues, 'Project.CompletionDate')} (Estimate)',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Duration: ${ContractStyle.getFieldValue(fieldValues, 'Project.Duration')} days',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'WHEREAS, Contractor is willing to provide construction services for the Project, as further described herein;',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'NOW, THEREFORE, in consideration of the premises and mutual covenants contained herein, and for other good and valuable consideration, the parties hereto agree as follows:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 24));

    widgets.add(
      pw.Text(
        '1. Scope of Work and Cost',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        '1.1. The Contractor shall be reimbursed for actual costs incurred for labor, materials, equipment, and other expenses related to the project, plus a fee for overhead and profit as detailed below:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(
      pw.Bullet(
        text: 'Labor Costs: Actual hourly rates as specified - PHP${ContractStyle.getFieldValue(fieldValues, 'Labor.Costs')} per hour',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Material Costs: Actual cost of materials with receipts - PHP${ContractStyle.getFieldValue(fieldValues, 'Material.Costs')} (estimated)',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Equipment Costs: Actual rental/usage costs - PHP${ContractStyle.getFieldValue(fieldValues, 'Equipment.Costs')} (estimated)',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Subcontractor Costs: Actual payments to qualified subcontractors',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Overhead and Profit Fee: ${ContractStyle.getFieldValue(fieldValues, 'Overhead.Percentage')}% of total project costs',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        '1.2 Payment Terms:',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(
      pw.Bullet(
        text: 'Total Estimated Project Cost: PHP${ContractStyle.getFieldValue(fieldValues, 'Estimated.Total')}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Payment Interval: ${ContractStyle.getFieldValue(fieldValues, 'Payment.Interval')} (weekly/bi-weekly/monthly)',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Retention Fee: PHP${ContractStyle.getFieldValue(fieldValues, 'Retention.Fee')} (held until project completion)',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Late Payment Fee: ${ContractStyle.getFieldValue(fieldValues, 'Late.Fee.Percentage')}% per month on overdue amounts',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: 'Payment Due: ${ContractStyle.getFieldValue(fieldValues, 'Payment.DueDays')} days from invoice date',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '2. Obligations and Responsibilities',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'Contractee\'s Responsibilities',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Payment to Contractor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Make payments according to schedule', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Site Access and Utilities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Provide access and utilities as needed', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Permits and Approvals', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Assist in obtaining necessary permits', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Builder\'s Risk Insurance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Maintain appropriate insurance coverage', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '3. Contractor\'s Responsibilities',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Performance of Work', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Execute work according to plans and specifications', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Procurement of Materials and Employment of Workers', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Source materials and hire qualified workers', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Subcontractor Payments', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Ensure timely payment to subcontractors', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Compliance with Laws and Standards', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Comply with all applicable laws and building codes', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '3.1. Cost of Work and Payments',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));
    widgets.add(
      pw.Text(
        'Cost Plus Fee',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'The Contractor\'s compensation under this Agreement shall be based on the cost of work. The Contractor shall receive a fee calculated as a negotiated percentage of the cost of work, exclusive of certain components.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'The Contractor\'s fee shall be calculated based solely on the following:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(
      pw.Bullet(
        text: '(a) The Contractor\'s costs for materials, labor, equipment, and other direct project expenses as directly related to the cost of work.',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: '(b) No markup shall be allowed on subcontracts for the execution of the cost of work.',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(
      pw.Bullet(
        text: '(c) Excluded from the calculation of the Contractor\'s fee are Contractor overhead, profit, salaries, and other indirect expenses.',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        'Payment Procedures',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'Payment to the Contractor shall be made through progress payments based on the Contractor\'s invoices, which shall accurately reflect the Cost of Work as defined in this Agreement.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'The final payment to the Contractor shall be made after the completion of the Work and the acceptance of the project by the Owner. Final payment shall be based on the final Cost of Work as determined in accordance with the terms of this Agreement.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '4. Delays and Extensions of Time',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'Procedures for Time Extensions:',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(
      pw.Text(
        'In the event that the Contractor is delayed in the progress of the Work for reasons beyond the Contractor\'s control, including but not limited to acts of God, strikes, material shortages, changes in the Work ordered by the Contractee, or other excusable delays, the Contractor shall promptly notify the Contractee in writing of the cause of the delay. The Contractee shall have the right to grant or deny time extensions, at the Contractee\'s sole discretion, for any delays that are found to be excusable.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'No Damages to the Contractor for Delay:',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(
      pw.Text(
        'The Contractor acknowledges and agrees that, except for the extension of time for completing the Work as provided herein, the Contractor shall not be entitled to any additional compensation, damages, or claims for any delays or interruptions in the progress of the Work, regardless of the cause of such delays. The Contractor further waives any right to recover consequential damages, lost profits, or any other indirect damages arising from any delay.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '5. Insurance and Bonds',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'Contractor\'s Insurance:',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(
      pw.Text(
        'The Contractor shall, at its own expense, procure and maintain insurance coverage during the term of this Agreement, in accordance with industry standards and with limits of liability as specified herein, and shall provide evidence of such insurance to the Contractee prior to commencing any work under this Contract. Such insurance shall include, but not be limited to:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'Performance and Payment Bonds',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(
      pw.Text(
        'The Contractor shall furnish to the Contractee, within ${ContractStyle.getFieldValue(fieldValues, 'Bond.TimeFrame')} days, performance and payment bonds executed by a surety company licensed to do business in the jurisdiction where the project is located. The performance bond shall be in an amount not less than PHP${ContractStyle.getFieldValue(fieldValues, 'Bond.PerformanceAmount')} and shall guarantee the faithful performance of all Work under this Agreement.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'The payment bond shall be in an amount not less than PHP${ContractStyle.getFieldValue(fieldValues, 'Bond.PaymentAmount')} and shall guarantee the payment to all subcontractors, laborers, and material suppliers for labor and materials furnished in connection with this Contract. The Contractor shall maintain these bonds in full force and effect throughout the duration of the project.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '6. Change Orders and Modifications',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        '6.1. Any changes to the scope of work, cost adjustments, or modifications to the project timeline must be mutually approved in writing through a formal change order process. All change orders must include: detailed description of changes, cost impact analysis, time impact assessment, and signatures from both parties.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '7. Termination and Disputes',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        '7.1. Either party may terminate this contract with ${ContractStyle.getFieldValue(fieldValues, 'Notice.Period')} days written notice. Upon termination, Contractor shall be compensated for all work completed and costs incurred up to the termination date.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        '7.2. Contractor provides a ${ContractStyle.getFieldValue(fieldValues, 'Warranty.Period')} months warranty on workmanship and materials from the date of project completion. This warranty covers defects in materials and workmanship under normal use and conditions.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        '7.3. Any disputes arising from this contract shall be resolved through mediation first, and if unsuccessful, through arbitration under Philippine law. All legal proceedings shall be conducted in the courts of ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Province')}, Republic of the Philippines.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    widgets.add(
      pw.Text(
        '8. Governing Law',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'This Contract shall be governed by and construed in accordance with the laws of the Republic of the Philippines, without regard to its conflict of law principles. Any legal action or proceeding arising under or in connection with this Contract shall be brought exclusively in the state or federal courts located within the Republic of the Philippines, and the parties hereby consent to the personal jurisdiction and venue of these courts.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    widgets.add(
      pw.Text(
        'The prevailing party in any such legal action or proceeding shall be entitled to recover its reasonable attorneys\' fees and costs incurred in connection with such action or proceeding.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 30));

    widgets.add(
      pw.Center(
        child: pw.Text(
          'Executed by the Parties on the date indicated below.',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.normal,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 30));

    widgets.add(
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(0.2),
          2: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: contracteeSignature != null
                        ? pw.Image(pw.MemoryImage(contracteeSignature))
                        : pw.Center(
                            child: pw.Text('Signature', style: pw.TextStyle(color: PdfColors.grey600)),
                          ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 25,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Center(
                      child: contracteeSignature != null
                          ? pw.Text(
                              DateTime.now().toString().substring(0, 10),
                              style: const pw.TextStyle(fontSize: 10),
                            )
                          : pw.Text('Date', style: pw.TextStyle(color: PdfColors.grey600)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${ContractStyle.getFieldValue(fieldValues, 'Contractee.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractee.LastName')}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Contractee',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Container(), 
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: contractorSignature != null
                        ? pw.Image(pw.MemoryImage(contractorSignature))
                        : pw.Center(
                            child: pw.Text('Signature', style: pw.TextStyle(color: PdfColors.grey600)),
                          ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 25,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Center(
                      child: contractorSignature != null
                          ? pw.Text(
                              DateTime.now().toString().substring(0, 10),
                              style: const pw.TextStyle(fontSize: 10),
                            )
                          : pw.Text('Date', style: pw.TextStyle(color: PdfColors.grey600)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${ContractStyle.getFieldValue(fieldValues, 'Contractor.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractor.LastName')}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Contractor',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 30));

    return widgets;
  }
}
