// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:backend/services/be_contract_service.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractAgreementBanner extends StatefulWidget {
  final String chatRoomId;
  final String userRole;

  const ContractAgreementBanner({
    super.key,
    required this.chatRoomId,
    required this.userRole,
  });

  @override
  State<ContractAgreementBanner> createState() =>
      _ContractAgreementBannerState();
}

class _ContractAgreementBannerState extends State<ContractAgreementBanner> {
  final supabase = Supabase.instance.client;
  bool _dialogShown = false;

  late final StreamSubscription _projectSubscription;

  @override
  void initState() {
    super.initState();
    _checkProject();
  }

  void _checkProject() async {
    final projectId = await ProjectService().getProjectId(widget.chatRoomId);
    if (projectId == null) return;

    _projectSubscription = supabase
        .from('Projects')
        .stream(primaryKey: ['project_id'])
        .eq('project_id', projectId)
        .listen((event) {
          if (event.isNotEmpty) {
            final project = event.first;
            final initiated = project['contract_started'] == true;
            final contractorAgreed = project['contractor_agree'] == true;
            final contracteeAgreed = project['contractee_agree'] == true;

            if (initiated &&
                contractorAgreed &&
                contracteeAgreed &&
                widget.userRole == 'contractor') {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ContractType(
                      contractorId: project['contractor_id'] ?? '',
                    ),
                  ),
                );
              }
              return;
            }

            final isContractor = widget.userRole == 'contractor';
            final hasAgreed =
                isContractor ? contractorAgreed : contracteeAgreed;

            if (initiated && !hasAgreed && !_dialogShown) {
              _dialogShown = true;
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Contract Agreement'),
                      content: const Text(
                          'Do you agree to proceed with the contract?'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await _handleAgree(projectId);
                          },
                          child: const Text('Agree'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Not now'),
                        ),
                      ],
                    ),
                  );
                });
              }
            }
          }
        });
  }

  Future<void> _handleProceed() async {
    final projectId = await ProjectService().getProjectId(widget.chatRoomId);
    if (projectId == null) return;

    await supabase
        .from('Projects')
        .update({'contract_started': true}).eq('project_id', projectId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Waiting for the other party to agree...')),
    );

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) setState(() {});
  }

  Future<void> _handleAgree(String projectId) async {
    final column = widget.userRole == 'contractor'
        ? 'contractor_agree'
        : 'contractee_agree';

    await supabase
        .from('Projects')
        .update({column: true}).eq('project_id', projectId);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _projectSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "This project is awaiting contract agreement.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Proceed with Contract"),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UIMessage {
  static Widget buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> msg,
    bool isMe,
    String currentUserId,
  ) {
    if (msg['message_type'] == 'contract') {
      return Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isMe ? 40 : 8,
          right: isMe ? 8 : 40,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Contract Sent',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(msg['message'] ?? ''),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ContractService.viewContract(context, msg['contract_id']);
              },
              child: const Text('View Contract'),
            ),
          ],
        ),
      );
    }

    return buildNormalMessageBubble(msg, isMe);
  }

  static Widget buildNormalMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 40 : 0,
          right: isMe ? 0 : 40,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? Colors.amber[300] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg['message'] ?? '',
          style: TextStyle(
            fontSize: 16,
            color: isMe ? Colors.black : Colors.grey[900],
          ),
        ),
      ),
    );
  }
}
