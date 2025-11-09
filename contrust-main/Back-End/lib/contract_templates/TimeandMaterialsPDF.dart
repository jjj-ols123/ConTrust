// ignore_for_file: file_names

import 'package:backend/utils/be_contractformat.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class TimeAndMaterialsPDF {

  static List<pw.Widget> buildTimeAndMaterialsPdf(
    Map<String, String> fieldValues, {
    Uint8List? contractorSignature,
    Uint8List? contracteeSignature,
  }) {
    List<pw.Widget> widgets = [];

    widgets.add(
      pw.Center(
        child: pw.Text(
          'TIME AND MATERIALS CONSTRUCTION CONTRACT',
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
        'This time and materials contract (hereinafter referred to as the "Contract") is entered into and shall be effective this ${ContractStyle.getFieldValue(fieldValues, 'Contract.CreationDate')} ("Effective Date") by and between ${ContractStyle.getFieldValue(fieldValues, 'Contractee.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractee.LastName')} ("Contractee") residing at ${ContractStyle.getFieldValue(fieldValues, 'Contractee.Address')}, ${ContractStyle.getFieldValue(fieldValues, 'Contractee.City')}, ${ContractStyle.getFieldValue(fieldValues, 'Contractee.PostalCode')} and ${ContractStyle.getFieldValue(fieldValues, 'Contractor.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractor.LastName')} ("Contractor") with principal office at ${ContractStyle.getFieldValue(fieldValues, 'Contractor.Address')}, ${ContractStyle.getFieldValue(fieldValues, 'Contractor.City')}, ${ContractStyle.getFieldValue(fieldValues, 'Contractor.PostalCode')}.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    widgets.add(
      pw.Text(
        'The Contractee and Contractor are collectively referred to as the "Parties" and individually as "Party" throughout this Contract.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    widgets.add(
      pw.Text(
        'The Parties agree that the Contractor will complete the project described as: ${ContractStyle.getFieldValue(fieldValues, 'Project.ContractorDef')} ("Project"), and furnish all materials, supplies, services, labor, tools, transportation, equipment, and parts for said work in accordance with this Contract.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 24));

    widgets.add(
      pw.Text(
        'Terms and Conditions',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '1. Relationship of Parties',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'The Contractor, in the fulfillment of this Contract, shall act in the capacity of an independent contractor and not as an agent, employee, or partner, of the Contractee.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '2. Contractor\'s Duties',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'The Contractor agrees to provide the time and materials required to complete the Project as defined in this Contract.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Duties', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Scope of Work', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(ContractStyle.getFieldValue(fieldValues, 'Project.Scope'), style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Time', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${ContractStyle.getFieldValue(fieldValues, 'Project.LaborHours')} hours', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Materials', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(ContractStyle.getFieldValue(fieldValues, 'Materials.List'), style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '3. Completion Schedule',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'This Contract shall be effective as of the Effective Date herein and shall continue until Project completion or for ${ContractStyle.getFieldValue(fieldValues, 'Project.Duration')} unless terminated early or an extension is mutually agreed upon between the Parties with written consent.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'Schedule: ${ContractStyle.getFieldValue(fieldValues, 'Project.Schedule')}',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'Milestones: ${ContractStyle.getFieldValue(fieldValues, 'Project.MilestonesList')}',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '4. Materials Supply and Delivery',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    
    widgets.add(
      pw.Text(
        '4.1 Quality of Materials:',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'The Contractor shall inspect all materials used for the Project to ensure they are of acceptable quality. If a quality issue occurs as a result of improper or lack of inspection, the Contractor will be responsible for any damages that occur and the expenses to replace said materials with appropriate substitutes.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    
    widgets.add(
      pw.Text(
        '4.2 Delivery of Materials:',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'The Contract may deliver materials in installments if the Parties agree to do so in the Contract, in which case materials should be invoiced and paid for separately. The Contract shall provide that each material delivery is accompanied by a delivery note showing the quantity and type of materials included.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '5. Timeliness',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'This Contract shall begin on the day specified and shall continue until the Project is completed or upon the set due date. Any delays incurred by the Contractor that are found to be unreasonable shall be determined a breach of this Contract. The Company shall impose a fine of up to PHP${ContractStyle.getFieldValue(fieldValues, 'Penalty.Amount')} for such a delay.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );

    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '6. Representation and Warranties',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Bullet(
        text: 'The Contractor represents they have the expertise, knowledge, and experience needed to provide the labor and materials outlined in this Contract.',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Bullet(
        text: 'The Contractor agrees to uphold all legal requirements and laws of the Republic of the Philippines.',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Bullet(
        text: 'The Contractor shall conform to all materials with regards to their description and any applicable specification, ensure defect-free material in terms of material, design, and workmanship, and ensure they are of satisfactory quality according to Contractor standards.',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        '7. Rates & Payment',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'The Contractor agrees to such standard pre-determined rates set by ${ContractStyle.getFieldValue(fieldValues, 'Contractee.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractee.LastName')}. The following rates shall apply unless otherwise mutually modified by both parties:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('QTY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          ...(() {
            int itemCount = int.tryParse(ContractStyle.getFieldValue(fieldValues, 'ItemCount')) ?? 3;

            List<pw.TableRow> itemRows = [];
            
            for (int i = 1; i <= itemCount; i++) {
              String itemName = ContractStyle.getFieldValue(fieldValues, 'Item.$i.Name');
              String itemPrice = ContractStyle.getFieldValue(fieldValues, 'Item.$i.Price');
              String itemQuantity = ContractStyle.getFieldValue(fieldValues, 'Item.$i.Quantity');
              String itemSubtotal = ContractStyle.getFieldValue(fieldValues, 'Item.$i.Subtotal');
              
              if (itemName != '____________' || itemPrice != '____________') {
                itemRows.add(
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(itemName, style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10)),
                            pw.SizedBox(height: 2),
                            pw.Text(ContractStyle.getFieldValue(fieldValues, 'Item.$i.Description'), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('PHP$itemPrice', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(itemQuantity, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('PHP$itemSubtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }
            }
            
            if (itemRows.isEmpty) {
              itemRows.add(
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('____________', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('PHP____________', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('____________', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('PHP[Item 1 price]', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              );
            }
            
            return itemRows;
          })(),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey50),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.Container(),
              pw.Container(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: () {
                  final sub = ContractStyle.computeSubtotal(fieldValues);
                  return pw.Text('PHP${sub.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10));
                }(),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Discount', style: const pw.TextStyle(color: PdfColors.red, fontSize: 10)),
              ),
              pw.Container(),
              pw.Container(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: () {
                  final sub = ContractStyle.computeSubtotal(fieldValues);
                  final discRate = ContractStyle.parsePercent(fieldValues['Payment.Discount']);
                  final discAmt = sub * discRate;
                  return pw.Text('-PHP${discAmt.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.red, fontSize: 10));
                }(),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Tax', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(),
              pw.Container(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: () {
                  final sub = ContractStyle.computeSubtotal(fieldValues);
                  final taxRate = ContractStyle.parsePercent(fieldValues['Payment.Tax']);
                  final taxAmt = sub * taxRate;
                  return pw.Text('PHP${taxAmt.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10));
                }(),
              ),
            ],
          ),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Container(),
              pw.Container(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: () {
                  final sub = ContractStyle.computeSubtotal(fieldValues);
                  final disc = sub * ContractStyle.parsePercent(fieldValues['Payment.Discount']);
                  final tax = sub * ContractStyle.parsePercent(fieldValues['Payment.Tax']);
                  final total = sub - disc + tax;
                  return pw.Text('PHP${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12));
                }(),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(
      pw.Text(
        'All invoices shall be sent to ${ContractStyle.getFieldValue(fieldValues, 'Contractee.FirstName')} ${ContractStyle.getFieldValue(fieldValues, 'Contractee.LastName')} or the authorized personnel identified in this Contract. Payment will be made within 30 days of invoice receipt.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 40));
    widgets.add(
      pw.Text(
        'Acceptance',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'The Parties agree to the terms and conditions set forth in this Contract as demonstrated by their signatures as follows:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
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
                        ? pw.Image(pw.MemoryImage(contracteeSignature), fit: pw.BoxFit.contain)
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
                      child: pw.Text(
                        contracteeSignature != null
                            ? DateTime.now().toString().split(' ')[0]
                            : 'Date',
                        style: pw.TextStyle(
                          color: contracteeSignature != null ? PdfColors.black : PdfColors.grey600,
                          fontSize: contracteeSignature != null ? 10 : 12,
                        ),
                      ),
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
                        ? pw.Image(pw.MemoryImage(contractorSignature), fit: pw.BoxFit.contain)
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
                      child: pw.Text(
                        contractorSignature != null
                            ? DateTime.now().toString().split(' ')[0]
                            : 'Date',
                        style: pw.TextStyle(
                          color: contractorSignature != null ? PdfColors.black : PdfColors.grey600,
                          fontSize: contractorSignature != null ? 10 : 12,
                        ),
                      ),
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
    widgets.add(pw.SizedBox(height: 40));
    widgets.add(
      pw.Center(
        child: pw.Text(
          'Generated on ${DateTime.now().toString().split(' ')[0]}',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ),
    );

    return widgets;
  }
}
