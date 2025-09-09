import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

Future<void> saveMaterial({
  required String contractorId,
  required String projectId,
  required String materialName,
  String? brand,
  double quantity = 1,
  String unit = 'unit',
  required double unitPrice,
  String? notes,
}) async {
  await _supabase.from('ProjectMaterials').insert({
    'project_id': projectId,
    'contractor_id': contractorId,
    'material_name': materialName,
    'brand': brand,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'notes': notes,
    'created_at': DateTime.now().toIso8601String(),
  });
}

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
    await _supabase
        .from('ProjectMaterials')
        .delete()
        .eq('material_id', itemId);
  }
  
  Future<List<Map<String, dynamic>>> getInventoryItems(String contractorId) async {
    final response = await _supabase
        .from('ProjectMaterials')
        .select()
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
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

  double get total => qty * unitPrice;
}