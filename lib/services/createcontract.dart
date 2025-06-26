import 'package:flutter_quill/flutter_quill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // Add this import


class CreateContract {

  static final SupabaseClient _supabase = Supabase.instance.client;
  
  static String replacePlaceholders(String template, String contractorId, Map<String, dynamic>? contractType) {
    String result = template;
    final contractTypeName = contractType?['template_name'] ?? '';

    if (result.contains('[CONTRACTOR_ID]')) {
      result = result.replaceAll('[CONTRACTOR_ID]', contractorId);
    }
    if (result.contains('[DATE]')) {
      result = result.replaceAll(
          '[DATE]', DateTime.now().toLocal().toString().split(' ')[0]);
    }
    if (result.contains('[TEMPLATE_NAME]')) {
      result = result.replaceAll('[TEMPLATE_NAME]', contractTypeName);
    }

    Map<String, String> commonPlaceholders = {
      '[Client Name]': '[Client Name]',
      '[Client Address]': '[Client Address]',
      '[Client Title]': '[Client Title]',
      '[Contractor Name]': '[Contractor Name]',
      '[Contractor Address]': '[Contractor Address]',
      '[Contractor Title]': '[Contractor Title]',
      '[Project Description]': '[Project Description]',
      '[Project Location]': '[Project Location]',
      '[Start Date]': '[Start Date]',
      '[Completion Date]': '[Completion Date]',
      '[Duration]': '[Duration]',
      '[Warranty Period]': '[Warranty Period]',
      '[Notice Period]': '[Notice Period]',
      '[Payment Due Days]': '[Payment Due Days]',
      '[Witness Name]': '[Witness Name]',
    };

    if (contractTypeName.toLowerCase().contains('lump sum')) {
      Map<String, String> lumpSumPlaceholders = {
        '[Total Amount]': '[Total Amount]',
        '[Down Payment]': '[Down Payment]',
        '[Progress Payment 1]': '[Progress Payment 1]',
        '[Progress Payment 2]': '[Progress Payment 2]',
        '[Progress Payment 3]': '[Progress Payment 3]',
        '[Final Payment]': '[Final Payment]',
        '[Materials List]': '[Materials List]',
        '[Equipment List]': '[Equipment List]',
      };
      commonPlaceholders.addAll(lumpSumPlaceholders);
    } else if (contractTypeName.toLowerCase().contains('cost-plus') ||
        contractTypeName.toLowerCase().contains('cost plus')) {
      Map<String, String> costPlusPlaceholders = {
        '[Contractor Fee Percentage]': '[Contractor Fee Percentage]',
        '[Fixed Fee Amount]': '[Fixed Fee Amount]',
        '[Maximum Budget]': '[Maximum Budget]',
      };
      commonPlaceholders.addAll(costPlusPlaceholders);
    } else if (contractTypeName.toLowerCase().contains('time and materials') ||
        contractTypeName.toLowerCase().contains('time & materials')) {
      Map<String, String> timeMaterialsPlaceholders = {
        '[Hourly Rate]': '[Hourly Rate]',
        '[Position/Trade]': '[Position/Trade]',
        '[Material Markup]': '[Material Markup]',
        '[Equipment Markup]': '[Equipment Markup]',
        '[Supervisor Rate]': '[Supervisor Rate]',
        '[Skilled Rate]': '[Skilled Rate]',
        '[General Rate]': '[General Rate]',
        '[Overtime Multiplier]': '[Overtime Multiplier]',
        '[Invoice Frequency]': '[Invoice Frequency]',
        '[Late Fee Percentage]': '[Late Fee Percentage]',
        '[Estimated Budget]': '[Estimated Budget]',
        '[Work Description]': '[Work Description]',
      };
      commonPlaceholders.addAll(timeMaterialsPlaceholders);
    }

    commonPlaceholders.forEach((placeholder, replacement) {
      if (result.contains(placeholder)) {
        result = result.replaceAll(placeholder, replacement);
      }
    });

    return result;
  }

  static String stripHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<h[1-6]>'), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n\n')
        .replaceAll('<p>', '\n')
        .replaceAll('</p>', '\n')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<li>', '• ')
        .replaceAll('</li>', '\n')
        .replaceAll('<ul>', '\n')
        .replaceAll('</ul>', '\n')
        .replaceAll('<ol>', '\n')
        .replaceAll('</ol>', '\n')
        .replaceAll('<strong>', '')
        .replaceAll('</strong>', '')
        .replaceAll('<b>', '')
        .replaceAll('</b>', '')
        .replaceAll('<em>', '')
        .replaceAll('</em>', '')
        .replaceAll('<i>', '')
        .replaceAll('</i>', '')
        .replaceAll('<hr>', '\n─────────────────────────────────\n')
        .replaceAll(RegExp(r'<div[^>]*>'), '')
        .replaceAll('</div>', '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();
  }

  static void applyFormatting(QuillController controller) {
    final text = controller.document.toPlainText();
    final lines = text.split('\n');
    int currentPos = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isNotEmpty) {
        if (line == line.toUpperCase() && line.contains('CONTRACT') && line.length > 10) {
          controller.formatText(currentPos, line.length, Attribute.bold);
          controller.formatText(currentPos, line.length, Attribute.centerAlignment);
        }
        else if (RegExp(r'^\d+\.\s+[A-Z]').hasMatch(line)) {
          controller.formatText(currentPos, line.length, Attribute.bold);
        }
        else if (line.endsWith(':') && line.length < 50) {
          controller.formatText(currentPos, line.length, Attribute.bold);
        }
        else if (line == line.toUpperCase() && line.length > 5 && line.length < 50 && !line.contains('\$')) {
          controller.formatText(currentPos, line.length, Attribute.bold);
        }
      }
      
      final placeholderRegex = RegExp(r'\[([^\]]+)\]');
      final matches = placeholderRegex.allMatches(lines[i]);
      
      for (final match in matches) {
        final placeholderStart = currentPos + match.start;
        final placeholderLength = match.end - match.start;
        controller.formatText(placeholderStart, placeholderLength, Attribute.bold);
        controller.formatText(placeholderStart, placeholderLength, Attribute.italic);
      }
      
      final currencyRegex = RegExp(r'₱[0-9,]+\.?[0-9]*');
      final currencyMatches = currencyRegex.allMatches(lines[i]);
      
      for (final match in currencyMatches) {
        final amountStart = currentPos + match.start;
        final amountLength = match.end - match.start;
        controller.formatText(amountStart, amountLength, Attribute.bold);
      }
      
      currentPos += lines[i].length + 1; 
    }
  }

  static Future<void> saveContract({
    required String projectId,
    required String contractTypeId,
    required String title,
    required String content,
    required List<dynamic> deltaContent,
    double? totalAmount,
  }) async {
    
    await _supabase
    .from('Contracts')
    .insert({
      'project_id': projectId,
      'contract_type_id': contractTypeId,
      'title': title,
      'content': content,
      'delta_content': deltaContent,
      'total_amount': totalAmount,
      'status': 'draft',
    });
  }

  static Future<List<Map<String, dynamic>>> getContractorProjectInfo(String contractorId) async {

    
    final response = await _supabase
        .from('Projects')
        .select('project_id, contractee_id, description')
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> showSaveDialog(BuildContext context, String contractorId) async {
    final titleController = TextEditingController();
    final totalAmountController = TextEditingController();
    String? selectedProjectId;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Save Contract'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Contract Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: getContractorProjectInfo(contractorId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('No projects found. Create a project first.');
                        }
                        
                        return DropdownButtonFormField<String>(
                          value: selectedProjectId,
                          decoration: const InputDecoration(
                            labelText: 'Select Project *',
                            border: OutlineInputBorder(),
                          ),
                          items: snapshot.data!.map((project) => DropdownMenuItem<String>(
                            value: project['project_id'],
                            child: Text(
                              project['description'] ?? 'No Description',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedProjectId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: totalAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount (₱)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title is required')),
                      );
                      return;
                    }
                    
                    if (selectedProjectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project is required')),
                      );
                      return;
                    }
                    
                    Navigator.of(dialogContext).pop({
                      'title': titleController.text,
                      'projectId': selectedProjectId,
                      'totalAmount': totalAmountController.text.isNotEmpty 
                        ? double.tryParse(totalAmountController.text) 
                        : null,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
