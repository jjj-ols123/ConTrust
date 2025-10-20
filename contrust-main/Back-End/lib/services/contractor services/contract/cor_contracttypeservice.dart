// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/Screen/cor_createcontract.dart';
import 'package:contractor/Screen/cor_viewcontract.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:flutter/material.dart';

class ContractTypeService {

  static final SuperAdminErrorService _errorService = SuperAdminErrorService();
  
  static Future<bool?> navigateToCreateContract({
    required BuildContext context,
    required Map<String, dynamic> template,
    required String contractorId,
  }) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateContractPage(
            contractType: template['template_name'] ?? '',
            template: template,
            contractorId: contractorId,
          ),
        ),
      );
      return result;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to navigate to create contract: ',
        module: 'Contract Type Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Navigate to Create Contract',
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<void> navigateToViewContract({
    required BuildContext context,
    required String contractId,
    required String contractorId,
  }) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractorViewContractPage(
            contractId: contractId,
            contractorId: contractorId,
          ),
        ),
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to navigate to view contract: ',
        module: 'Contract Type Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Navigate to View Contract',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  static Future<bool?> navigateToEditContract({
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String contractorId,
  }) async {
    try {
      final contractTypes = await FetchService().fetchContractTypes();
      final contractType = contractTypes.firstWhere(
        (type) => type['contract_type_id'] == contract['contract_type_id'],
        orElse: () => <String, dynamic>{},
      );

      if (contractType.isEmpty) {
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Error: Contract type not found');
        }
        return false;
      }

      final editResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateContractPage(
            template: contractType,
            contractType: contractType['template_name'] ?? '',
            contractorId: contractorId,
            existingContract: contract,
          ),
        ),
      );
      return editResult;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to navigate to edit contract: ',
        module: 'Contract Type Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Navigate to Edit Contract',
          'contractor_id': contractorId,
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error loading contract for editing: ');
      }
      return false;
    }
  }

  static Future<void> sendContractToContractee({
    required BuildContext context,
    required Map<String, dynamic> contract,
  }) async {
    try {
      String? contracteeId = contract['contractee_id'] as String? ?? 
          (await FetchService().fetchProjectDetails(contract['project_id'] as String))?['contractee_id'] as String?;
      
      await ContractService.sendContractToContractee(
        contractId: contract['contract_id'] as String,
        contracteeId: contracteeId!,
        message: 'Please review the following contract.',
      );
      
      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Contract sent successfully.');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to send contract to contractee: ',
        module: 'Contract Type Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Send Contract to Contractee',
          'contract_id': contract['contract_id'],
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error sending contract. Please try again.');
      }
    }
  }

  static Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    try {
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
      return shouldDelete ?? false;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to show delete confirmation dialog: ',
        module: 'Contract Type Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Show Delete Confirmation Dialog',
        },
      );
      return false;
    }
  }

  static Future<void> deleteContract({
    required BuildContext context,
    required String contractId,
  }) async {
    try {
      await ContractService.deleteContract(contractId: contractId);
      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Contract deleted successfully');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete contract: ',
        module: 'Contract Type Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Delete Contract',
          'contract_id': contractId,
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error deleting contract. Please try again.');
      }
    }
  }

  static void showContractMenu({
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) {
    try {
      final contractStatus = contract['status'] as String? ?? 'draft';
      
      final RenderBox button = context.findRenderObject() as RenderBox;
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );

      final List<PopupMenuEntry<String>> menuItems = [];

      if (contractStatus == 'draft') {
        menuItems.add(
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
        );
      }

      menuItems.addAll([
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
      ]);

      showMenu<String>(
        context: context,
        position: position,
        items: menuItems,
      ).then((choice) async {
        if (choice != null) {
          await _handleMenuAction(
            choice: choice,
            context: context,
            contract: contract,
            contractorId: contractorId,
            onRefreshContracts: onRefreshContracts,
          );
        }
      });
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to show contract menu: ',
        module: 'Contract Type Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Show Contract Menu',
          'contractor_id': contractorId,
        },
      );
    }
  }

  static Future<void> _handleMenuAction({
    required String choice,
    required BuildContext context,
    required Map<String, dynamic> contract,
    required String contractorId,
    required VoidCallback onRefreshContracts,
  }) async {
    try {
      switch (choice) {
        case 'send':
          await sendContractToContractee(context: context, contract: contract);
          break;
        case 'edit':
          final editResult = await navigateToEditContract(
            context: context,
            contract: contract,
            contractorId: contractorId,
          );
          if (editResult == true) {
            onRefreshContracts();
          }
          break;
        case 'delete':
          final shouldDelete = await showDeleteConfirmationDialog(context);
          if (shouldDelete) {
            await deleteContract(
              context: context,
              contractId: contract['contract_id'] as String,
            );
            onRefreshContracts();
          }
          break;
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to handle menu action:',
        module: 'Contract Type Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Handle Menu Action',
          'choice': choice,
          'contractor_id': contractorId,
        },
      );
    }
  }
}