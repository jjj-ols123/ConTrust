import 'package:backend/models/be_UIcontract.dart';
import 'package:backend/services/be_contract_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

class CreateContractPage extends StatefulWidget {
  final String? contractType;
  final Map<String, dynamic>? template;
  final String contractorId;

  const CreateContractPage({
    super.key,
    this.template,
    required this.contractType,
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
    final template = widget.template;

    if (template != null && template['template_content'] != null) {
      String htmlTemplate = template['template_content'];

      htmlTemplate = _replacePlaceholders(htmlTemplate);

      try {
        final converter = HtmlToDelta();
        final delta = converter.convert(htmlTemplate);

        final document = Document.fromDelta(Delta.fromJson(delta as List));
        _controller.document = document;

      } catch (e) {
        String plainText = _stripHtmlTags(htmlTemplate);
        _controller.document.insert(0, plainText);
        ContractService.applyFormatting(_controller);
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

    final contractTypeId = widget.template?['contract_type_id'];  

    setState(() {
      _isSaving = true;
    });

    try {
      final contractContent = _controller.document.toPlainText();
      final contractDelta = _controller.document.toDelta().toJson();
      
      final contractData = await _showSaveDialog();
      
      if (contractData != null) {
        await ContractService.saveContract(
          projectId:   contractData['projectId']!,
          contractorId: widget.contractorId,
          contractTypeId: contractTypeId,
          title:       contractData['title']!,
          content:     contractContent,
          deltaContent: contractDelta,
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
    return UIContract.showSaveDialog(context, widget.contractorId);
  }

  String _replacePlaceholders(String template) {
    return ContractService.replacePlaceholders(template, widget.contractorId, widget.template);
  }

  String _stripHtmlTags(String htmlString) {
    return ContractService.stripHtmlTags(htmlString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Contract"), 
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

extension CreateContractDialog on ContractService {
  static Future<Map<String, dynamic>?> showSaveDialog(BuildContext context, String contractorId) async {
    final titleController = TextEditingController();
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
                      future: ContractService.getContractorProjectInfo(contractorId),
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
