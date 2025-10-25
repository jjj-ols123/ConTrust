// ignore_for_file: use_build_context_synchronously, unused_local_variable
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/buildproduct.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/contractor services/cor_productservice.dart';

class ProductPanelScreen extends StatefulWidget {
  final String? contractorId;
  final String? projectId;

  const ProductPanelScreen({super.key, this.contractorId, this.projectId});

  @override
  State<ProductPanelScreen> createState() => _ProductPanelScreenState();
}

class _ProductPanelScreenState extends State<ProductPanelScreen> {
  final List<Map<String, dynamic>> catalog = const [
    {'name': 'Specify', 'icon': Icons.add},
    {'name': 'Wood', 'icon': Icons.forest},
    {'name': 'Steel', 'icon': Icons.construction},
    {'name': 'Glass', 'icon': Icons.window},
    {'name': 'Cement', 'icon': Icons.architecture},
    {'name': 'Paint', 'icon': Icons.format_paint},
    {'name': 'Nails', 'icon': Icons.build}, 
    {'name': 'Steel Bars', 'icon': Icons.bar_chart}
  ];

  String search = '';
  List<Map<String, dynamic>> inventory = [];
  List<Map<String, dynamic>> projects = [];
  Map<String, List<Map<String, dynamic>>> projectMaterials = {};

  String? contractorId;
  String? projectId;

  bool isLoading = true;

  List<Map<String, dynamic>> get filteredCatalog {
    if (search.trim().isEmpty) return catalog;
    final q = search.toLowerCase();
    return catalog
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
    setState(() => isLoading = true);
    try {
      await fetchContractorId();
      await Future.wait([
        CorProductService().loadInventory(
          contractorId!,
          setState,
          inventory,
          projectMaterials,
        ),
        CorProductService().loadProjects(
          contractorId!,
          projectId ?? '',
          setState,
          projects,
        ),
      ]);
    } catch (e) {
      return;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchContractorId() async {
    contractorId = widget.contractorId ?? await UserService().getContractorId();
  }

  double getProjectTotal(String projectId) {
    final materials = projectMaterials[projectId] ?? [];
    return materials.fold<double>(
      0.0,
      (sum, it) => sum + ((it['total'] as num?)?.toDouble() ?? 0.0),
    );
  }

  void openMaterialDialog(Map<String, dynamic> material, {int? editIndex}) {
    if (projectId == null) {
      ConTrustSnackBar.error(context, 'No current ongoing project found!');
      return;
    }

    final existing = editIndex != null ? inventory[editIndex] : null;

    ProductBuildMethods.showMaterialDialog(
      context: context,
      material: material,
      existingItem: existing,
      contractorId: contractorId,
      projectId: projectId,
      onSuccess: (Map<String, dynamic> materialMap) {
        setState(() {
          if (projectMaterials[projectId] == null) {
            projectMaterials[projectId!] = [];
          }
          projectMaterials[projectId]!.add(materialMap);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.storage, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Materials & Inventory',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Project',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.amber,))
                    : ProductBuildMethods.buildProductUI(
                      context: context,
                      isLoading: isLoading,
                      search: search,
                      onSearchChanged:
                          (value) => setState(() => search = value),
                      projects: projects,
                      filteredCatalog: filteredCatalog,
                      projectMaterials: projectMaterials,
                      getProjectTotal: getProjectTotal,
                      openMaterialDialog: openMaterialDialog,
                      contractorId: contractorId,
                    ),
          ),
        ],
      ),
    );
  }
}
