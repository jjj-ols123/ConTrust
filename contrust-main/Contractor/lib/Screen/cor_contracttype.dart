// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:backend/services/fetchmethods.dart';
import 'package:contractor/Screen/cor_createcontract.dart';
import 'package:flutter/material.dart';

class ContractType extends StatefulWidget {
  final String contractorId;

  const ContractType({super.key, required this.contractorId});

  @override
  State<ContractType> createState() => _ContractTypeState();
}

class _ContractTypeState extends State<ContractType> {
  FetchClass fetchMethod = FetchClass();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Types'),
        backgroundColor: Colors.amber[700],
        elevation: 0,
        centerTitle: true,
      ),
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
              future: fetchMethod.fetchContractTypes(),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CreateContractPage(
                                      contractType: template,
                                      contractorId: widget.contractorId,
                                    ),
                              ),
                            );
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
                future: fetchMethod.fetchCreatedContracts(widget.contractorId),
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
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.amber[700],
                        ),
                        onTap: () {},
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
