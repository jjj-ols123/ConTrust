// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:contractor/build/contract/buildcontracttype.dart';
import 'package:flutter/material.dart';

class ContractType extends StatefulWidget {
  final String contractorId;

  const ContractType({super.key, required this.contractorId});

  @override
  State<ContractType> createState() => _ContractTypeState();
}

class _ContractTypeState extends State<ContractType> {
  Key contractListKey = UniqueKey();

  void refreshContracts() {
    if (mounted) {
      setState(() {
        contractListKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: screenWidth > 1200 ? null : AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          "",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          ContractTypeBuild.buildHeader(context),
          const SizedBox(height: 18),
          const SizedBox(height: 10),
          ContractTypeBuild.buildTypeCarousel(
            contractorId: widget.contractorId,
            onRefreshContracts: refreshContracts,
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
          ContractTypeBuild.buildContractListContainer(
            contractorId: widget.contractorId,
            contractListKey: contractListKey,
            onRefreshContracts: refreshContracts,
          ),
        ],
      ),
    );
  }
}
