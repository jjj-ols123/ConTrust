import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:backend/models/appbar.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

class CreateContractPage extends StatefulWidget {
  final Map<String, dynamic>? contractType;
  final String contractorId;

  const CreateContractPage({
    super.key,
    this.contractType,
    required this.contractorId,
  });

  @override
  State<CreateContractPage> createState() => _CreateContractPageState();
}

class _CreateContractPageState extends State<CreateContractPage> {
  final QuillController _controller = QuillController.basic();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  void _loadTemplate() {
    final contractType = widget.contractType;

    if (contractType != null && contractType['template_content'] != null) {
      String htmlTemplate = contractType['template_content'];

      htmlTemplate = _replacePlaceholders(htmlTemplate);

      try {
        final converter = HtmlToDelta();
        final delta = converter.convert(htmlTemplate);

        final document = Document.fromDelta(Delta.fromJson(delta as List));
        _controller.document = document;

      } catch (e) {
        String plainText = _stripHtmlTags(htmlTemplate);
        _controller.document.insert(0, plainText);
        _applyBasicFormatting();
      }
    }
  }

  void _applyBasicFormatting() {
    final text = _controller.document.toPlainText();
    final lines = text.split('\n');
    int currentPos = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isNotEmpty) {
        if (line == line.toUpperCase() && line.contains('CONTRACT') && line.length > 10) {
          _controller.formatText(currentPos, line.length, Attribute.bold);
          _controller.formatText(currentPos, line.length, Attribute.centerAlignment);
        }
        else if (RegExp(r'^\d+\.\s+[A-Z]').hasMatch(line)) {
          _controller.formatText(currentPos, line.length, Attribute.bold);
        }
        else if (line.endsWith(':') && line.length < 50) {
          _controller.formatText(currentPos, line.length, Attribute.bold);
        }
        else if (line == line.toUpperCase() && line.length > 5 && line.length < 50 && !line.contains('\$')) {
          _controller.formatText(currentPos, line.length, Attribute.bold);
        }
      }
      
      final placeholderRegex = RegExp(r'\[([^\]]+)\]');
      final matches = placeholderRegex.allMatches(lines[i]);
      
      for (final match in matches) {
        final placeholderStart = currentPos + match.start;
        final placeholderLength = match.end - match.start;
        _controller.formatText(placeholderStart, placeholderLength, Attribute.bold);
        _controller.formatText(placeholderStart, placeholderLength, Attribute.italic);
      }
      
      final currencyRegex = RegExp(r'₱[0-9,]+\.?[0-9]*');
      final currencyMatches = currencyRegex.allMatches(lines[i]);
      
      for (final match in currencyMatches) {
        final amountStart = currentPos + match.start;
        final amountLength = match.end - match.start;
        _controller.formatText(amountStart, amountLength, Attribute.bold);
      }
      
      currentPos += lines[i].length + 1; 
    }
  }

  String _replacePlaceholders(String template) {
    String result = template;
    final contractTypeName = widget.contractType?['template_name'] ?? '';
    
    if (result.contains('[CONTRACTOR_ID]')) {
      result = result.replaceAll('[CONTRACTOR_ID]', widget.contractorId);
    }
    if (result.contains('[DATE]')) {
      result = result.replaceAll('[DATE]', DateTime.now().toLocal().toString().split(' ')[0]);
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
    }
    else if (contractTypeName.toLowerCase().contains('cost-plus') || contractTypeName.toLowerCase().contains('cost plus')) {
      Map<String, String> costPlusPlaceholders = {
        '[Contractor Fee Percentage]': '[Contractor Fee Percentage]',
        '[Fixed Fee Amount]': '[Fixed Fee Amount]',
        '[Maximum Budget]': '[Maximum Budget]',
      };
      commonPlaceholders.addAll(costPlusPlaceholders);
    }
    else if (contractTypeName.toLowerCase().contains('time and materials') || contractTypeName.toLowerCase().contains('time & materials')) {
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

  String _stripHtmlTags(String htmlString) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Create Contract"),
      body: Column(
        children: [
          QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              embedButtons: FlutterQuillEmbeds.toolbarButtons(),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: QuillEditor(
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                controller: _controller,
                config: QuillEditorConfig(
                  placeholder: 'Start typing your contract...',
                  padding: const EdgeInsets.all(16),
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }
}
