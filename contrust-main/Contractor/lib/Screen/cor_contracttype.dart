import 'package:backend/services/fetchmethods.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Types')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Choose a contract type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 140,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchMethod.fetchContractTypes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contractTypes = snapshot.data!;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contractTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final template = contractTypes[index];
                    return GestureDetector(
                      onTap: () {
                      },
                      child: Card(
                        elevation: 3,
                        child: Container(
                          width: 180,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(template['template_name'] ?? '',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(template['template_description'] ?? '',
                                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Your Contracts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchMethod.fetchCreatedContracts(widget.contractorId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contracts = snapshot.data!;
                if (contracts.isEmpty) {
                  return const Center(child: Text('No contracts created yet.'));
                }
                return ListView.separated(
                  itemCount: contracts.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    return ListTile(
                      title: Text(contract['title'] ?? ''),
                      subtitle: Text('${contract['total_amount'] ?? ''} • ${contract['created_at'] ?? ''}'),
                      onTap: () {
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}