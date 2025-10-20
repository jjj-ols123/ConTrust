// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_project_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class CorProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updateInventoryItem({
    required String itemId,
    String? brand,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? notes,
  }) async {
    final updates = {
      if (brand != null) 'brand': brand,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (notes != null) 'notes': notes,
    };

    if (updates.isNotEmpty) {
      await _supabase
          .from('ProjectMaterials')
          .update(updates)
          .eq('material_id', itemId);
    }
  }

  Future<void> deleteInventoryItem(String itemId) async {
    await _supabase.from('ProjectMaterials').delete().eq('material_id', itemId);
  }

  Future<List<Map<String, dynamic>>> getInventoryItems(
    String contractorId,
  ) async {
    final response = await _supabase
        .from('ProjectMaterials')
        .select()
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> loadInventory(
    String contractorId,
    Function(Function()) setState,
    List<Map<String, dynamic>> inventory,
    Map<String, List<Map<String, dynamic>>> projectMaterials,
  ) async {
    final items = await getInventoryItems(contractorId);
    
    final mappedItems = items.map((item) {
      final qty = (item['quantity'] as num).toDouble();
      final price = (item['unit_price'] as num).toDouble();
      return {
        'material_id': item['material_id'],
        'project_id': item['project_id'],
        'name': item['material_name'],
        'brand': item['brand'] ?? '',
        'qty': qty,
        'unit': item['unit'] ?? 'pcs',
        'unitPrice': price,
        'total': qty * price,
        'note': item['notes'],
      };
    }).toList();

    final newProjectMaterials = <String, List<Map<String, dynamic>>>{};
    for (final item in mappedItems) {
      final projectId = item['project_id'] as String;
      if (!newProjectMaterials.containsKey(projectId)) {
        newProjectMaterials[projectId] = [];
      }
      newProjectMaterials[projectId]!.add(item);
    }
    
    setState(() {
      inventory.clear();
      inventory.addAll(mappedItems);
      projectMaterials.clear();
      projectMaterials.addAll(newProjectMaterials);
    });
  }

  Future<void> loadProjects(
    String contractorId,
    String projectId,
    Function(Function()) setState,
    List<Map<String, dynamic>> projectDetails,
  ) async {
    try {
      if (projectId.isNotEmpty) {

        final project = await FetchService().fetchProjectDetails(projectId);
        
        setState(() {
          projectDetails.clear();
          if (project is List) {
            projectDetails.addAll(List<Map<String, dynamic>>.from(project as Iterable));
          } else if (project is Map<String, dynamic>) {
            projectDetails.add(project);
          }
        });
      } else {

        final projects = await FetchService().fetchContractorActiveProjects(contractorId);
        
        setState(() {
          projectDetails.clear();
          projectDetails.addAll(List<Map<String, dynamic>>.from(projects));
        });
      }
    } catch (e) {
      setState(() {
        projectDetails.clear();
      });
    }
  }

  Future<void> addAllCostsToProject(
    String projectId,
    Map<String, List<Map<String, dynamic>>> projectMaterials,
    String? contractorId,
    BuildContext context,
  ) async {
    final materials = projectMaterials[projectId] ?? [];
    if (materials.isEmpty) {
      ConTrustSnackBar.error(context, 'No materials to add');
      return;
    }

    try {
      final fetchService = FetchService();
      final existingMaterials = await fetchService.fetchProjectCosts(
        projectId,
      );
      final existingMaterialNames =
          existingMaterials.map((m) => m['material_name'] as String).toSet();

      int addedCount = 0;
      int skippedCount = 0;

      for (final item in materials) {
        
        final materialName = item['name'] as String;

        if (existingMaterialNames.contains(materialName)) {
          skippedCount++;
          continue;
        }

        final note = item['note'] as String?;
        final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
        final unit = item['unit'] as String? ?? 'pcs';
        final total = (item['total'] as num?)?.toDouble() ?? 0.0;
        final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;

        await ProjectService().addCostToProject(
          contractor_id: contractorId!,
          projectId: projectId,
          material_name: materialName,
          unit_price: unitPrice,
          brand: item['brand'] as String?,
          unit: unit,
          quantity: total,
          notes: note,
        );
        addedCount++;
      }

      if (context.mounted) {
        if (addedCount > 0) {
          ConTrustSnackBar.success(
            context,
            'Successfully added $addedCount material${addedCount > 1 ? 's' : ''} to project costs${skippedCount > 0 ? ' ($skippedCount skipped - already exist)' : ''}',
          );
        } else if (skippedCount > 0) {
          ConTrustSnackBar.info(
            context,
            'All materials already exist in project costs ($skippedCount skipped)',
          );
        }
      }

      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Failed to add materials to project costs: ');
      }
    }
  }
}

class MaterialCostItem {
  final String name;
  final String brand;
  final double qty;
  final String unit;
  final double unitPrice;
  final String? note;

  const MaterialCostItem({
    required this.name,
    this.brand = '',
    this.qty = 0,
    this.unit = 'pcs',
    this.unitPrice = 0,
    this.note,
  });
}
