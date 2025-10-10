import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TimeAndMaterialsPDF {
  static String _getFieldValue(Map<String, String> fieldValues, String key) {
    return fieldValues[key]?.isNotEmpty == true ? fieldValues[key]! : '____________';
  }

  // Helpers to compute monetary values from form data
  static double _parseMoney(String? s) {
    if (s == null) return 0.0;
    final cleaned = s.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double _parsePercent(String? s) {
    if (s == null) return 0.0;
    final raw = s.trim();
    if (raw.isEmpty) return 0.0;
    final cleaned = raw.replaceAll('%', '').replaceAll(',', '');
    final v = double.tryParse(cleaned) ?? 0.0;
    if (v <= 0) return 0.0;
    // If >1 treat as percent (12 => 0.12), else fraction
    return v > 1.0 ? (v / 100.0) : v;
  }

  static double _computeSubtotal(Map<String, String> fieldValues) {
    // Prefer explicit Payment.Subtotal
    final explicit = _parseMoney(fieldValues['Payment.Subtotal']);
    if (explicit > 0) return explicit;

    // Fallback: try sum of item subtotals
    final itemCount = int.tryParse(fieldValues['ItemCount'] ?? '') ?? 3;
    double sum = 0.0;
    for (int i = 1; i <= itemCount; i++) {
      final sub = _parseMoney(fieldValues['Item.$i.Subtotal']);
      if (sub > 0) {
        sum += sub;
      } else {
        // compute from price * qty if subtotal missing
        final price = _parseMoney(fieldValues['Item.$i.Price']);
        final qty = _parseMoney(fieldValues['Item.$i.Quantity']);
        if (price > 0 && qty > 0) sum += price * qty;
      }
    }
    return sum;
  }

  static List<pw.Widget> buildTimeAndMaterialsPdf(Map<String, String> fieldValues) {
    List<pw.Widget> widgets = [];

    // Title
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

    // Opening paragraph
    widgets.add(
      pw.Text(
        'This time and materials contract (hereinafter referred to as the "Contract") is entered into and shall be effective this ${_getFieldValue(fieldValues, 'Contract.CreationDate')} ("Effective Date") by and between ${_getFieldValue(fieldValues, 'Contractee.FirstName')} ${_getFieldValue(fieldValues, 'Contractee.LastName')} ("Contractee") residing at ${_getFieldValue(fieldValues, 'Contractee.Address')}, ${_getFieldValue(fieldValues, 'Contractee.City')}, ${_getFieldValue(fieldValues, 'Contractee.PostalCode')} and ${_getFieldValue(fieldValues, 'Contractor.FirstName')} ${_getFieldValue(fieldValues, 'Contractor.LastName')} ("Contractor") with principal office at ${_getFieldValue(fieldValues, 'Contractor.Address')}, ${_getFieldValue(fieldValues, 'Contractor.City')}, ${_getFieldValue(fieldValues, 'Contractor.PostalCode')}.',
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
        'The Parties agree that the Contractor will complete the project described as: ${_getFieldValue(fieldValues, 'Project.ContractorDef')} ("Project"), and furnish all materials, supplies, services, labor, tools, transportation, equipment, and parts for said work in accordance with this Contract.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 24));

    // Terms and Conditions
    widgets.add(
      pw.Text(
        'Terms and Conditions',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    // 1. Relationship of Parties
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

    // 2. Contractor's Duties
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

    // Duties Table
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
                child: pw.Text(_getFieldValue(fieldValues, 'Project.Scope'), style: const pw.TextStyle(fontSize: 10)),
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
                child: pw.Text('${_getFieldValue(fieldValues, 'Project.LaborHours')} hours', style: const pw.TextStyle(fontSize: 10)),
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
                child: pw.Text(_getFieldValue(fieldValues, 'Materials.List'), style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    // 3. Completion Schedule
    widgets.add(
      pw.Text(
        '3. Completion Schedule',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'This Contract shall be effective as of the Effective Date herein and shall continue until Project completion or for ${_getFieldValue(fieldValues, 'Project.Duration')} unless terminated early or an extension is mutually agreed upon between the Parties with written consent.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'Schedule: ${_getFieldValue(fieldValues, 'Project.Schedule')}',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'Milestones: ${_getFieldValue(fieldValues, 'Project.MilestonesList')}',
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    // 4. Materials Supply and Delivery
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

    // 5. Timeliness
    widgets.add(
      pw.Text(
        '5. Timeliness',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'This Contract shall begin on the day specified and shall continue until the Project is completed or upon the set due date. Any delays incurred by the Contractor that are found to be unreasonable shall be determined a breach of this Contract. The Company shall impose a fine of up to ₱${_getFieldValue(fieldValues, 'Penalty.Amount')} for such a delay.',
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

    // 7. Rates & Payment
    widgets.add(
      pw.Text(
        '7. Rates & Payment',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Text(
        'The Contractor agrees to such standard pre-determined rates set by ${_getFieldValue(fieldValues, 'Contractee.FirstName')} ${_getFieldValue(fieldValues, 'Contractee.LastName')}. The following rates shall apply unless otherwise mutually modified by both parties:',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // Items Table
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
          // Header
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
          // Dynamic Items based on ItemCount
          ...(() {
            // Get the number of items from the form data
            int itemCount = int.tryParse(_getFieldValue(fieldValues, 'ItemCount')) ?? 3;
            
            // Filter out empty items to avoid showing blank rows
            List<pw.TableRow> itemRows = [];
            
            for (int i = 1; i <= itemCount; i++) {
              String itemName = _getFieldValue(fieldValues, 'Item.$i.Name');
              String itemPrice = _getFieldValue(fieldValues, 'Item.$i.Price');
              String itemQuantity = _getFieldValue(fieldValues, 'Item.$i.Quantity');
              String itemSubtotal = _getFieldValue(fieldValues, 'Item.$i.Subtotal');
              
              // Only add the row if at least the name or price is filled
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
                            pw.Text(_getFieldValue(fieldValues, 'Item.$i.Description'), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₱$itemPrice', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(itemQuantity, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₱$itemSubtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }
            }
            
            // If no items have data, show at least one row as placeholder
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
                      child: pw.Text('₱____________', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('____________', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('₱____________', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              );
            }
            
            return itemRows;
          })(),
          // Payment Summary
          // Payment Summary (computed to align with on-screen preview)
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
                  final sub = _computeSubtotal(fieldValues);
                  return pw.Text('₱${sub.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10));
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
                  final sub = _computeSubtotal(fieldValues);
                  final discRate = _parsePercent(fieldValues['Payment.Discount']);
                  final discAmt = sub * discRate;
                  return pw.Text('-₱${discAmt.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.red, fontSize: 10));
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
                  final sub = _computeSubtotal(fieldValues);
                  final taxRate = _parsePercent(fieldValues['Payment.Tax']);
                  final taxAmt = sub * taxRate;
                  return pw.Text('₱${taxAmt.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10));
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
                  final sub = _computeSubtotal(fieldValues);
                  final disc = sub * _parsePercent(fieldValues['Payment.Discount']);
                  final tax = sub * _parsePercent(fieldValues['Payment.Tax']);
                  final total = sub - disc + tax;
                  return pw.Text('₱${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12));
                }(),
              ),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    // Additional sections
    widgets.add(
      pw.Text(
        'All invoices shall be sent to ${_getFieldValue(fieldValues, 'Contractee.FirstName')} ${_getFieldValue(fieldValues, 'Contractee.LastName')} or the authorized personnel identified in this Contract. Payment will be made within 30 days of invoice receipt.',
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 40));

    // Acceptance Section
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

    // Signatures Table
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
                    child: pw.Center(
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
                      child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.grey600)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${_getFieldValue(fieldValues, 'Contractee.FirstName')} ${_getFieldValue(fieldValues, 'Contractee.LastName')}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Contractee',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Container(), // Spacer
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Center(
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
                      child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.grey600)),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${_getFieldValue(fieldValues, 'Contractor.FirstName')} ${_getFieldValue(fieldValues, 'Contractor.LastName')}',
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

    // Footer
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
