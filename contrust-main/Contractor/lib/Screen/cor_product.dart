// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:contractor/models/cor_UIproduct.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cor_productservice.dart';

class ProductPanelScreen extends StatefulWidget {
  final String? contractorId;
  final String? projectId;

  const ProductPanelScreen({super.key, this.contractorId, this.projectId});

  @override
  State<ProductPanelScreen> createState() => _ProductPanelScreenState();
}

class _ProductPanelScreenState extends State<ProductPanelScreen> {
  final ProductService _svc = ProductService();
  final ProjectService _projectSvc = ProjectService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> _catalog = const [
    {'name': 'Specify', 'icon': Icons.add},
    {'name': 'Wood', 'icon': Icons.forest},
    {'name': 'Steel', 'icon': Icons.construction},
    {'name': 'Glass', 'icon': Icons.window},
    {'name': 'Asphalt', 'icon': Icons.aod},
    {'name': 'Sand', 'icon': Icons.grain},
    {'name': 'Stone', 'icon': Icons.landscape},
    {'name': 'Concrete', 'icon': Icons.foundation},
    {'name': 'Cement', 'icon': Icons.architecture},
    {'name': 'Ceramics', 'icon': Icons.emoji_objects},
    {'name': 'Tile', 'icon': Icons.grid_on},
    {'name': 'Paint', 'icon': Icons.format_paint},
    {'name': 'Cool Roofing', 'icon': Icons.roofing},
  ];

  String _search = '';
  List<Map<String, dynamic>> inventory = [];
  List<Map<String, dynamic>> projects = [];
  Map<String, List<Map<String, dynamic>>> projectMaterials = {};

  String? contractorId;
  String? projectId;
  bool _isLoading = true;

  List<Map<String, dynamic>> get _filteredCatalog {
    if (_search.trim().isEmpty) return _catalog;
    final q = _search.toLowerCase();
    return _catalog
        .where((p) => (p['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    projectId = widget.projectId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await fetchContractorId();
    await Future.wait([_loadInventory(), _loadProjects()]);
    setState(() => _isLoading = false);
  }

  double getProjectTotal(String projectId) {
    final materials = projectMaterials[projectId] ?? [];
    return materials.fold<double>(
      0.0,
      (sum, it) => sum + ((it['total'] as num?)?.toDouble() ?? 0.0),
    );
  }

  void _openMaterialDialog(Map<String, dynamic> material, {int? editIndex}) {
    final existing = editIndex != null ? inventory[editIndex] : null;

    MaterialsOperations.show(
      context: context,
      material: material,
      existingItem: existing,
      contractorId: contractorId,
      projectId: projectId,
      onSuccess: _loadData,
    );
  }

  Future<void> _loadInventory() async {
    if (contractorId == null) return;

    try {
      final items = await _svc.getInventoryItems(contractorId!);
      setState(() {
        inventory = items.map((item) {
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
        
        projectMaterials = {};
        for (final item in inventory) {
          final projectId = item['project_id'] as String;
          if (!projectMaterials.containsKey(projectId)) {
            projectMaterials[projectId] = [];
          }
          projectMaterials[projectId]!.add(item);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading inventory: $e')),
      );
    }
  }

  Future<void> _loadProjects() async {
    if (contractorId == null) return;

    try {
      final response = await _supabase
          .from('Projects')
          .select()
          .eq('contractor_id', contractorId!)
          .order('created_at', ascending: false);

      setState(() {
        projects = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading projects: $e')),
      );
    }
  }

  void _showProjectMaterialsDialog(String projectId, String projectName) {
    final materials = List<Map<String, dynamic>>.from(projectMaterials[projectId] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Materials for $projectName'),
          content: SizedBox(
            width: double.maxFinite,
            child: materials.isEmpty
                ? const Center(child: Text('No materials added to this project yet.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: materials.length,
                    itemBuilder: (_, i) {
                      final it = materials[i];
                      final title = (it['brand'] as String).isNotEmpty
                          ? '${it['name']} - ${it['brand']}'
                          : it['name'] as String;
                      final qty = (it['qty'] as num?)?.toDouble() ?? 0.0;
                      final unit = it['unit'] as String? ?? 'pcs';
                      final total = (it['total'] as num?)?.toDouble() ?? 0.0;
                      final String? mid = (it['material_id'] ?? it['id'])?.toString();

                      return ListTile(
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Qty: $qty $unit'),
                            if (it['note'] != null && (it['note'] as String).isNotEmpty)
                              Text(it['note'], style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_money(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: (mid == null || mid.isEmpty)
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete material?'),
                                              content: Text('Remove "$title" from this project?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (!confirm) return;

                                      try {
                                        await _svc.deleteInventoryItem(mid);
                                        setDialogState(() {
                                          materials.removeAt(i);
                                        });
                                        setState(() {
                                          inventory.removeWhere((e) => (e['material_id']?.toString() ?? '') == mid);
                                          final updated = (projectMaterials[projectId] ?? [])
                                              .where((e) => (e['material_id']?.toString() ?? '') != mid)
                                              .toList();
                                          projectMaterials[projectId] = updated;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Material deleted')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error deleting: $e')),
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Tip: Use the "Specify" card in Materials Catalog to add a custom item.'),
            ),
            const SizedBox(height: 8),
            if (widget.projectId != null)
              ElevatedButton.icon(
                onPressed: () => _addAllCostsToProject(projectId),
                icon: const Icon(Icons.monetization_on),
                label: const Text('Add All as Costs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.black,
                ),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAllCostsToProject(String sourceProjectId) async {
    if (widget.projectId == null) return;
    
    final materials = projectMaterials[sourceProjectId] ?? [];
    if (materials.isEmpty) return;
    
    try {
      final fetchService = FetchService();
      final existingMaterials = await fetchService.fetchProjectCosts(widget.projectId!);
      final existingMaterialNames = existingMaterials.map((m) => m['material_name'] as String).toSet();
      
      int addedCount = 0;
      int skippedCount = 0;
      
      for (final item in materials) {
        final title = (item['brand'] as String).isNotEmpty
            ? '${item['name']} - ${item['brand']}'
            : item['name'] as String;
        
        if (existingMaterialNames.contains(title)) {
          skippedCount++;
          continue;
        }
        
        final note = item['note'] as String?;
        final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
        final unit = item['unit'] as String? ?? 'pcs';
        final total = (item['total'] as num?)?.toDouble() ?? 0.0;
        final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;

        String? formattedNote = note;
        if (qty > 0) {
          formattedNote = formattedNote != null 
              ? '$formattedNote\nQuantity: $qty $unit' 
              : 'Quantity: $qty $unit';
        }
        
        await _projectSvc.addCostToProject(
          contractor_id: contractorId!,
          projectId: widget.projectId!,
          material_name: title,
          unit_price: unitPrice,
          brand: item['brand'] as String?,
          unit: unit,
          quantity: total,
          notes: formattedNote,
        );
        addedCount++;
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding costs: $e')),
      );
    }
  }

  String _money(num v) => '₱${v.toStringAsFixed(2)}';

  Future<void> fetchContractorId() async {
    contractorId = widget.contractorId ?? await UserService().getContractorId();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount =
        width > 1400
            ? 6
            : width > 1200
            ? 5
            : width > 900
            ? 4
            : width > 600
            ? 3
            : 2;

    return Scaffold(
      appBar: ConTrustAppBar(headline: 'Project Materials'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search materials...',
                                prefixIcon: const Icon(Icons.search),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Inventory',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          projects.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No projects detected',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: projects.length,
                                  separatorBuilder: (_, __) => const Divider(height: 12),
                                  itemBuilder: (_, i) {
                                    final project = projects[i];
                                    final projectId = project['project_id'] as String;
                                    final projectName = project['title'] as String;
                                    final total = getProjectTotal(projectId);
                                    final materialsCount = projectMaterials[projectId]?.length ?? 0;

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        projectName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$materialsCount materials • Total: ${_money(total)}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'View Materials',
                                            icon: const Icon(
                                              Icons.visibility,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed: () => _showProjectMaterialsDialog(projectId, projectName),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Materials Catalog',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(4),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _filteredCatalog.length,
                      itemBuilder: (_, i) {
                        final p = _filteredCatalog[i];
                        return InkWell(
                          onTap: () => _openMaterialDialog(p),
                          borderRadius: BorderRadius.circular(16),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    p['icon'],
                                    size: 42,
                                    color: Colors.amber[800],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    p['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap to add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }
}
