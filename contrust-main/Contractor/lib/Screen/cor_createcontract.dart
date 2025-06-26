import 'package:backend/services/createcontract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContractType();
  }

  void _loadContractType() {
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
        CreateContract.applyFormatting(_controller);
      }
    }
  }

  Future<void> _saveContract() async {
    if (_controller.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final contractTypeId = widget.contractType?['contract_type_id'];
 
    setState(() {
      _isSaving = true;
    });

    try {
      final contractContent = _controller.document.toPlainText();
      final contractDelta = _controller.document.toDelta().toJson();
      
      final contractData = await _showSaveDialog();
      
      if (contractData != null) {
        await CreateContract.saveContract(
          projectId: contractData['projectId']!,
          contractTypeId: contractTypeId,
          title: contractData['title']!,
          content: contractContent,
          deltaContent: contractDelta,
          totalAmount: contractData['totalAmount'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contract: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _showSaveDialog() async {
    return CreateContract.showSaveDialog(context, widget.contractorId);
  }

  String _replacePlaceholders(String template) {
    return CreateContract.replacePlaceholders(template, widget.contractorId, widget.contractType);
  }

  String _stripHtmlTags(String htmlString) {
    return CreateContract.stripHtmlTags(htmlString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Contract"),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveContract,
            icon: _isSaving 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
            tooltip: 'Save Contract',
          ),
        ],
      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveContract,
        icon: _isSaving 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Contract'),
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
