// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:ui';
import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_contract_service.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:contractor/Screen/cor_createcontract.dart';
import 'package:flutter/material.dart';
import 'package:backend/models/be_UIcontract.dart';

class ContractType extends StatefulWidget {
  final String contractorId;

  const ContractType({super.key, required this.contractorId});

  @override
  State<ContractType> createState() => _ContractTypeState();
}

Future<List<Map<String, dynamic>>> _fetchCreatedContracts(String contractorId) async {
  return await FetchService().fetchCreatedContracts(contractorId);
}

class _ContractTypeState extends State<ContractType> {
  Key _contractListKey = UniqueKey(); 

  void _refreshContracts() {
    if (mounted) {
      setState(() {
        _contractListKey = UniqueKey(); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: ConTrustAppBar(headline: "Contract Types"),
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Choose a contract type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: FetchService().fetchContractTypes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No contract types available.'),
                  );
                }
                final contractTypes = snapshot.data!;
                return ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: contractTypes.length,
                    itemBuilder: (context, index) {
                      final template = contractTypes[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CreateContractPage(
                                      contractType : template['template_name'] ?? '',
                                      template: template,
                                      contractorId: widget.contractorId,
                                    ),
                              ),
                            );
                            if (result == true) {
                              _refreshContracts(); 
                            }
                          },
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.amber[100]!,
                                width: 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 38,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    template['template_name'] ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    template['template_description'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[700]),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Your Contracts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: _contractListKey,
                future: _fetchCreatedContracts(widget.contractorId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final contracts = snapshot.data!;
                  if (contracts.isEmpty) {
                    return const Center(
                      child: Text('No contracts created yet.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: contracts.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          height: 1,
                          color: Colors.amberAccent,
                          thickness: 0.7,
                        ),
                    itemBuilder: (context, index) {
                      final contract = contracts[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber[100],
                          child: Icon(
                            Icons.assignment_turned_in,
                            color: Colors.amber[700],
                          ),
                        ),
                        title: Text(
                          contract['title'] ?? 'Untitled Contract',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${contract['total_amount'] ?? ''} • ${contract['created_at'] ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        trailing: Builder(
                          builder: (buttonContext) {
                            return IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                final RenderBox button = buttonContext.findRenderObject() as RenderBox;
                                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                                final RelativeRect position = RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(Offset.zero, ancestor: overlay),
                                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                  ),
                                  Offset.zero & overlay.size,
                                );
                                
                                showMenu<String>(
                                  context: context,
                                  position: position,
                                  items: [
                                    const PopupMenuItem(
                                      value: 'send',
                                      child: Row(
                                        children: [
                                          Icon(Icons.send, size: 20),
                                          SizedBox(width: 8),
                                          Text('Send to Contractee'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit Contract'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delete Contract'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).then((choice) async {
                                  if (choice != null) {
                                    final contract = contracts[index];
                                    switch (choice) {
                                      case 'send':
                                        try {

                                          String? contracteeId = contract['contractee_id'] as String? ?? 
                                              (await FetchService().fetchProjectDetails(contract['project_id'] as String))?['contractee_id'] as String?;
                                       
                                          await ContractService.sendContractToContractee(
                                            contractId: contract['contract_id'] as String,
                                            contracteeId: contracteeId!,
                                            message: 'Please review the following contract.',
                                          );
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Sent to contractee')),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error sending contract')),
                                            );
                                          }
                                        }
                                        break;
                                      case 'edit':
                                        final editResult = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CreateContractPage(
                                              template: {
                                                'contract_type_id': contract['contract_type_id'],
                                                'template_content': contract['content'],
                                              },
                                              contractType: contract['contract_type_id'] as String,
                                              contractorId: widget.contractorId,
                                              existingContract: contract, 
                                            ),
                                          ),
                                        );
                                        if (editResult == true) {
                                          _refreshContracts();
                                        }
                                        break;
                                      case 'delete':
                                        final shouldDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Contract'),
                                            content: const Text('Are you sure you want to delete this contract? This action cannot be undone.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (shouldDelete == true) {
                                          try {
                                            await ContractService.deleteContract(contractId: contract['contract_id'] as String);
                                            
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Contract deleted successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              _refreshContracts(); 
                                            }
                                          } catch (e) {
                                          
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error deleting contract'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        break;
                                    }
                                  }
                                });
                              },
                            );
                          },
                        ),
                        onTap: () async {
                          final contractId = contract['contract_id'] as String;
                          await UIContract.viewContract(context, contractId);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
