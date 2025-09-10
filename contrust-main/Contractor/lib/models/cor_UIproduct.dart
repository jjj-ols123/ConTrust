// ignore_for_file: use_build_context_synchronously, file_names

import 'package:flutter/material.dart';
import '../services/cor_productservice.dart';

class MaterialsOperations extends StatefulWidget {
  final Map<String, dynamic> material;
  final Map<String, dynamic>? existingItem;
  final String? contractorId;
  final String? projectId;
  final Function() onSuccess;

  const MaterialsOperations({
    super.key,
    required this.material,
    this.existingItem,
    required this.contractorId,
    required this.projectId,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> material,
    Map<String, dynamic>? existingItem,
    required String? contractorId,
    required String? projectId,
    required Function() onSuccess,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => MaterialsOperations(
        material: material,
        existingItem: existingItem,
        contractorId: contractorId,
        projectId: projectId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<MaterialsOperations> createState() => _MaterialsOperationsState();
}

class _MaterialsOperationsState extends State<MaterialsOperations> {
  final ProductService productService = ProductService();
  late final TextEditingController nameCtrl; // NEW: for "Specify" name
  late final TextEditingController brandCtrl;
  late final TextEditingController qtyCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController noteCtrl;
  late String unit;
  bool _isSaving = false;
  late final bool _isSpecific; // NEW

  @override
  void initState() {
    super.initState();
    _isSpecific = (widget.material['name'] == 'Specify'); // NEW
    final existing = widget.existingItem;
    nameCtrl = TextEditingController(text: existing?['name'] ?? ''); // NEW
    brandCtrl = TextEditingController(text: existing?['brand'] ?? '');
    qtyCtrl = TextEditingController(text: (existing?['qty']?.toString() ?? '1'));
    priceCtrl = TextEditingController(text: (existing?['unitPrice']?.toString() ?? '0'));
    noteCtrl = TextEditingController(text: existing?['note'] ?? '');
    unit = existing?['unit'] ?? 'pcs';
  }

  @override
  void dispose() {
    nameCtrl.dispose(); // NEW
    brandCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> saveToInventory() async {
    // Basic guards to avoid null crash
    if (widget.contractorId == null || widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing project or contractor.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
    final isEdit = widget.existingItem != null;
    final itemId = widget.existingItem?['material_id'] as String?;
    final materialName = _isSpecific
        ? nameCtrl.text.trim()
        : (widget.material['name'] as String? ?? '').trim();

    if (_isSpecific && materialName.isEmpty) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a material name.')),
      );
      return;
    }

    try {
      if (isEdit && itemId != null) {
        await productService.updateInventoryItem(
          itemId: itemId,
          brand: brandCtrl.text.trim(),
          quantity: qty,
          unit: unit,
          unitPrice: price,
          notes: note,
        );
      } else {
        await productService.saveMaterial(
          projectId: widget.projectId!,
          contractorId: widget.contractorId!,
          materialName: materialName,
          brand: brandCtrl.text.trim(),
          quantity: qty,
          unit: unit,
          unitPrice: price,
          notes: note,
        );
      }

      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Inventory item updated.' : 'Added to inventory.')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return AlertDialog(
      title: Text(isEdit
          ? 'Edit ${_isSpecific ? "Material" : widget.material["name"]}'
          : (_isSpecific ? 'Add Material' : 'Add ${widget.material["name"]}')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(widget.material['icon'], color: Colors.amber[800], size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isSpecific ? 'Specify Material' : (widget.material['name'] as String? ?? 'Material'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // NEW: Material Name field when "Specify"
            if (_isSpecific) ...[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  hintText: 'e.g., Custom Material',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: brandCtrl,
              decoration: const InputDecoration(
                labelText: 'Brand / Specification',
                hintText: 'e.g., Brand X, Premium Grade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'bag', child: Text('bag')),
                      DropdownMenuItem(value: 'box', child: Text('box')),
                      DropdownMenuItem(value: 'm²', child: Text('m²')),
                      DropdownMenuItem(value: 'L', child: Text('L')),
                    ],
                    onChanged: (v) => setState(() => unit = v ?? 'pcs'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unit Price (₱)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : saveToInventory,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Save Changes' : 'Add to Inventory'),
        ),
      ],
    );
  }
}