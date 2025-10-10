// ignore_for_file: deprecated_member_use

import 'package:backend/services/contractor services/contract/cor_contracttypeservice.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class ContractTypeBuild {
  static Widget buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.handyman_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Choose your Contract',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTypeCarousel({
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ContractTypeService.fetchContractTypes(),
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
          return _buildContractTypesList(
            context: context,
            contractTypes: contractTypes,
            contractorId: contractorId,
            onRefreshContracts: onRefreshContracts,
          );
        },
      ),
    );
  }

  static Widget _buildContractTypesList({
    required BuildContext context,
    required List<Map<String, dynamic>> contractTypes,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
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
          return _buildContractTypeCard(
            context: context,
            template: template,
            contractorId: contractorId,
            onRefreshContracts: onRefreshContracts,
          );
        },
      ),
    );
  }

  static Widget _buildContractTypeCard({
    required BuildContext context,
    required Map<String, dynamic> template,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final result = await ContractTypeService.navigateToCreateContract(
            context: context,
            template: template,
            contractorId: contractorId,
          );
          if (result == true) {
            onRefreshContracts();
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
            border: Border.all(color: Colors.amber[100]!, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 38, color: Colors.amber[700]),
                const SizedBox(height: 18),
                Text(
                  template['template_name'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildContractListContainer({
    required String contractorId,
    required Key contractListKey,
    required VoidCallback onRefreshContracts,
  }) {
    return Expanded(
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
          key: contractListKey,
          future: ContractTypeService.fetchCreatedContracts(contractorId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final contracts = snapshot.data!;
            if (contracts.isEmpty) {
              return const Center(child: Text('No contracts created yet.'));
            }
            return _buildContractsList(
              context: context,
              contracts: contracts,
              contractorId: contractorId,
              onRefreshContracts: onRefreshContracts,
            );
          },
        ),
      ),
    );
  }

  static Widget _buildContractsList({
    required BuildContext context,
    required List<Map<String, dynamic>> contracts,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: contracts.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Colors.amberAccent,
        thickness: 0.7,
      ),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return _buildContractListItem(
          context: context,
          contract: contract,
          contractorId: contractorId,
          theme: theme,
          onRefreshContracts: onRefreshContracts,
        );
      },
    );
  }

  static Widget _buildContractListItem({
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String contractorId,
    required ThemeData theme,
    required VoidCallback onRefreshContracts,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Colors.amber[100],
        child: Icon(Icons.assignment_turned_in, color: Colors.amber[700]),
      ),
      title: Text(
        contract['title'] ?? 'Untitled Contract',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${contract['created_at'] ?? ''}',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
      ),
      trailing: Builder(
        builder: (buttonContext) {
          return IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ContractTypeService.showContractMenu(
                context: buttonContext,
                contract: contract,
                contractorId: contractorId,
                onRefreshContracts: onRefreshContracts,
              );
            },
          );
        },
      ),
      onTap: () async {
        final contractId = contract['contract_id'] as String;
        await ContractTypeService.navigateToViewContract(
          context: context,
          contractId: contractId,
          contractorId: contractorId,
        );
      },
    );
  }
}
