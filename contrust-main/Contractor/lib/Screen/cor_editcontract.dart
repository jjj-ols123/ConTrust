import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:contractor/Screen/cor_createcontract.dart';

class CorEditContractScreen extends StatelessWidget {
  final String contractId;
  final Map<String, dynamic>? initialContract;
  final Map<String, dynamic>? initialTemplate;
  final String? initialContractTypeName;
  const CorEditContractScreen({
    super.key,
    required this.contractId,
    this.initialContract,
    this.initialTemplate,
    this.initialContractTypeName,
  });

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/logincontractor'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
      );
    }

    final contractorId = session.user.id;

    if (initialContract != null) {
      final contract = initialContract!;
      final contractType = (initialTemplate ?? (contract['contract_type'] as Map<String, dynamic>?)) ?? {};
      final contractTypeName = initialContractTypeName ?? contractType['template_name'] as String?;
      return CreateContractPage(
        contractorId: contractorId,
        contractType: contractTypeName,
        template: contractType.isNotEmpty ? contractType : null,
        existingContract: contract,
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadContract(contractorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
          );
        }
        final contract = snapshot.data;
        if (contract == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Contract not found'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/contracttypes'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300)),
                    child: const Text('Back to Contracts'),
                  ),
                ],
              ),
            ),
          );
        }

        final contractType = (contract['contract_type'] as Map<String, dynamic>?) ?? {};
        final contractTypeName = contractType['template_name'] as String?;

        return CreateContractPage(
          contractorId: contractorId,
          contractType: contractTypeName,
          template: contractType.isNotEmpty ? contractType : null,
          existingContract: contract,
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _loadContract(String contractorId) async {
    final fetch = FetchService();
    final id = Uri.decodeComponent(contractId).trim();
    Map<String, dynamic>? contract = await fetch.fetchContractWithDetails(id, contractorId: contractorId);
    contract ??= await fetch.fetchContractWithDetails(id);
    return contract;
  }
}


