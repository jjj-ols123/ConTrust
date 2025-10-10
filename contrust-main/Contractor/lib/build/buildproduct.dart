// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/services/contractor services/cor_productservice.dart';

class ProductBuildMethods {
  static Widget buildProductUI({
    required BuildContext context,
    required bool isLoading,
    required String search,
    required Function(String) onSearchChanged,
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> filteredCatalog,
    required Map<String, List<Map<String, dynamic>>> projectMaterials,
    required Function(String) getProjectTotal,
    required Function(Map<String, dynamic>, {int? editIndex})
    openMaterialDialog,
    required String? contractorId,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1200;
    final isTablet = width >= 700 && width < 1200;
    final crossAxisCount =
        width > 1200
            ? 4
            : width > 900
            ? 3
            : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: width > 800
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                buildProjectsOverview(
                                  context: context,
                                  projects: projects,
                                  projectMaterials: projectMaterials,
                                  getProjectTotal: getProjectTotal,
                                  contractorId: contractorId,
                                  isDesktop: isDesktop,
                                  isTablet: isTablet,
                                ),
                                 const SizedBox(height: 24),
                                buildSearchHeader(
                                  context: context,
                                  search: search,
                                  onSearchChanged: onSearchChanged,
                                  isDesktop: isDesktop,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: buildMaterialsCatalog(
                                      context: context,
                                      filteredCatalog: filteredCatalog,
                                      crossAxisCount: crossAxisCount,
                                      openMaterialDialog: openMaterialDialog,
                                      isDesktop: isDesktop,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          buildProjectsOverview(
                            context: context,
                            projects: projects,
                            projectMaterials: projectMaterials,
                            getProjectTotal: getProjectTotal,
                            contractorId: contractorId,
                            isDesktop: isDesktop,
                            isTablet: isTablet,
                          ),
                          const SizedBox(height: 24),
                          buildSearchHeader(
                            context: context,
                            search: search,
                            onSearchChanged: onSearchChanged,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: buildMaterialsCatalog(
                                  context: context,
                                  filteredCatalog: filteredCatalog,
                                  crossAxisCount: crossAxisCount,
                                  openMaterialDialog: openMaterialDialog,
                                  isDesktop: isDesktop,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
    );
  }

  static Widget buildSearchHeader({
    required BuildContext context,
    required String search,
    required Function(String) onSearchChanged,
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Colors.black,
                size: isDesktop ? 32 : 28,
              ),
              const SizedBox(width: 16),
              Text(
                'Materials Management',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track, manage, and organize your project materials',
            style: TextStyle(
              color: Colors.black.withOpacity(0.9),
              fontSize: isDesktop ? 16 : 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search materials...',
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildProjectsOverview({
    required BuildContext context,
    required List<Map<String, dynamic>> projects,
    required Map<String, List<Map<String, dynamic>>> projectMaterials,
    required Function(String) getProjectTotal,
    required String? contractorId,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.work,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Ongoing Project',
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),
            if (projects.isEmpty)
              buildEmptyProjectsState(isDesktop)
            else
              isDesktop
                  ? buildProjectsGrid(
                    context: context,
                    projects: projects,
                    projectMaterials: projectMaterials,
                    getProjectTotal: getProjectTotal,
                    contractorId: contractorId,
                  )
                  : buildProjectsList(
                    context: context,
                    projects: projects,
                    projectMaterials: projectMaterials,
                    getProjectTotal: getProjectTotal,
                    contractorId: contractorId,
                  ),
          ],
        ),
      ),
    );
  }

  static Widget buildEmptyProjectsState(bool isDesktop) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: isDesktop ? 64 : 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Ongoing Projects',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start working on projects to manage materials',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildProjectsGrid({
    required BuildContext context,
    required List<Map<String, dynamic>> projects,
    required Map<String, List<Map<String, dynamic>>> projectMaterials,
    required Function(String) getProjectTotal,
    required String? contractorId,
  }) {
    return buildProjectCard(
      context: context,
      project: projects.first,
      projectMaterials: projectMaterials,
      getProjectTotal: getProjectTotal,
      contractorId: contractorId,
    );
  }

  static Widget buildProjectsList({
    required BuildContext context,
    required List<Map<String, dynamic>> projects,
    required Map<String, List<Map<String, dynamic>>> projectMaterials,
    required Function(String) getProjectTotal,
    required String? contractorId,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final project = projects[index];
        return buildProjectListItem(
          context: context,
          project: project,
          projectMaterials: projectMaterials,
          getProjectTotal: getProjectTotal,
          contractorId: contractorId,
        );
      },
    );
  }

  static Widget buildProjectCard({
    required BuildContext context,
    required Map<String, dynamic> project,
    required Map<String, List<Map<String, dynamic>>> projectMaterials,
    required Function(String) getProjectTotal,
    required String? contractorId,
  }) {
    final projectId = project['project_id']?.toString() ?? '';
    final materialCount = projectMaterials[projectId]?.length ?? 0;
    final total = getProjectTotal(projectId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            () => showProjectMaterialsDialog(
              context,
              project,
              projectMaterials,
              contractorId,
            ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.construction,
                      color: Colors.amber.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project['title'] ?? 'Unnamed Project',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Materials',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$materialCount items',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'View Materials',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildProjectListItem({
    required BuildContext context,
    required Map<String, dynamic> project,
    required Map<String, List<Map<String, dynamic>>> projectMaterials,
    required Function(String) getProjectTotal,
    required String? contractorId,
  }) {
    final projectId = project['project_id']?.toString() ?? '';
    final materialCount = projectMaterials[projectId]?.length ?? 0;
    final total = getProjectTotal(projectId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap:
            () => showProjectMaterialsDialog(
              context,
              project,
              projectMaterials,
              contractorId,
            ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.construction,
                  color: Colors.amber.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['title'] ?? 'Unnamed Project',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$materialCount materials • ₱${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildMaterialsCatalog({
    required BuildContext context,
    required List<Map<String, dynamic>> filteredCatalog,
    required int crossAxisCount,
    required Function(Map<String, dynamic>, {int? editIndex})
    openMaterialDialog,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category,
                color: Colors.purple.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Materials Catalog',
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.9,
          ),
          itemCount: filteredCatalog.length,
          itemBuilder: (context, index) {
            final material = filteredCatalog[index];
            return buildMaterialCard(
              context: context,
              material: material,
              onTap: () => openMaterialDialog(material),
            );
          },
        ),
      ],
    );
  }

  static Widget buildMaterialCard({
    required BuildContext context,
    required Map<String, dynamic> material,
    required VoidCallback onTap,
  }) {
    final isSpecify = material['name'] == 'Specify';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: 
            isSpecify
                ? Border.all(color: Colors.amber.shade300, width: 2)
                : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSpecify ? Colors.amber.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  material['icon'] as IconData,
                  size: 32,
                  color:
                      isSpecify ? Colors.amber.shade600 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                material['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isSpecify
                          ? Colors.amber.shade700
                          : const Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              if (isSpecify) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void showProjectMaterialsDialog(
    BuildContext context,
    Map<String, dynamic> project,
    Map<String, List<Map<String, dynamic>>> projectMaterials,
    String? contractorId,
  ) {
    final projectId = project['project_id']?.toString() ?? '';
    final projectName = project['title'] ?? 'Unnamed Project';
    final materials = List<Map<String, dynamic>>.from(
      projectMaterials[projectId] ?? [],
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Materials for',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      projectName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 400),
                            child:
                                materials.isEmpty
                                    ? buildEmptyMaterialsState()
                                    : ListView.separated(
                                      padding: const EdgeInsets.all(20),
                                      itemCount: materials.length,
                                      separatorBuilder:
                                          (context, index) =>
                                              const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final material = materials[index];
                                        return buildMaterialListItem(material);
                                      },
                                    ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${materials.length} materials in this project',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  static Widget buildEmptyMaterialsState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Materials Added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add materials from the catalog below',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildMaterialListItem(Map<String, dynamic> material) {
    final name = material['name'] ?? 'Unknown Material';
    final brand = material['brand'] ?? '';
    final qty = material['qty'] ?? 0;
    final unit = material['unit'] ?? 'pcs';
    final unitPrice = material['unitPrice'] ?? 0;
    final total = material['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.construction,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    if (brand.isNotEmpty)
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              buildInfoChip('Qty: $qty $unit', true),
              const SizedBox(width: 8),
              buildInfoChip('₱${unitPrice.toStringAsFixed(2)}/$unit', false),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildInfoChip(String text, bool isQuantity) {
    final color = isQuantity ? Colors.blue : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.shade700,
        ),
      ),
    );
  }

  static void showMaterialDialog({
    required BuildContext context,
    required Map<String, dynamic> material,
    Map<String, dynamic>? existingItem,
    required String? contractorId,
    required String? projectId,
    required VoidCallback onSuccess,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => MaterialInputDialog(
            material: material,
            existingItem: existingItem,
            contractorId: contractorId,
            projectId: projectId,
            onSuccess: onSuccess,
          ),
    );
  }
}

class MaterialInputDialog extends StatefulWidget {
  final Map<String, dynamic> material;
  final Map<String, dynamic>? existingItem;
  final String? contractorId;
  final String? projectId;
  final VoidCallback onSuccess;

  const MaterialInputDialog({
    super.key,
    required this.material,
    this.existingItem,
    required this.contractorId,
    required this.projectId,
    required this.onSuccess,
  });

  @override
  State<MaterialInputDialog> createState() => _MaterialInputDialogState();
}

class _MaterialInputDialogState extends State<MaterialInputDialog> {
  final CorProductService _productService = CorProductService();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late String _unit;
  bool _isSaving = false;
  late final bool _isSpecific;

  final List<String> _units = [
    'pcs',
    'kg',
    'm',
    'm²',
    'm³',
    'L',
    'box',
    'pack',
  ];

  @override
  void initState() {
    super.initState();
    _isSpecific = (widget.material['name'] == 'Specify');
    final existing = widget.existingItem;

    _nameController = TextEditingController(text: existing?['name'] ?? '');
    _brandController = TextEditingController(text: existing?['brand'] ?? '');
    _qtyController = TextEditingController(
      text: (existing?['qty']?.toString() ?? '1'),
    );
    _priceController = TextEditingController(
      text: (existing?['unitPrice']?.toString() ?? '0'),
    );
    _noteController = TextEditingController(text: existing?['note'] ?? '');
    _unit = existing?['unit'] ?? 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> saveMaterial() async {
    if (widget.contractorId == null || widget.projectId == null) {
      _showSnackBar('Missing project or contractor information');
      return;
    }

    setState(() => _isSaving = true);

    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final note =
        _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim();
    final isEdit = widget.existingItem != null;
    final itemId = widget.existingItem?['material_id'] as String?;
    final materialName =
        _isSpecific
            ? _nameController.text.trim()
            : (widget.material['name'] as String? ?? '').trim();

    if (_isSpecific && materialName.isEmpty) {
      setState(() => _isSaving = false);
      _showSnackBar('Please enter a material name');
      return;
    }

    try {
      if (isEdit && itemId != null) {
        await _productService.updateInventoryItem(
          itemId: itemId,
          brand: _brandController.text.trim(),
          quantity: qty,
          unit: _unit,
          unitPrice: price,
          notes: note,
        );
      } else {
        await _productService.saveMaterial(
          projectId: widget.projectId!,
          contractorId: widget.contractorId!,
          materialName: materialName,
          brand: _brandController.text.trim(),
          quantity: qty,
          unit: _unit,
          unitPrice: price,
          notes: note,
        );
      }

      Navigator.pop(context);
      widget.onSuccess();
      _showSnackBar(
        isEdit
            ? 'Material updated successfully'
            : 'Material added to inventory',
      );
    } catch (e) {
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isDesktop ? 500 : screenWidth * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.material['icon'] as IconData? ??
                          Icons.construction,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Material' : 'Add Material',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _isSpecific
                              ? 'Custom Material'
                              : widget.material['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_isSpecific) ...[
                      buildTextField(
                        controller: _nameController,
                        label: 'Material Name',
                        icon: Icons.construction,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                    ],

                    buildTextField(
                      controller: _brandController,
                      label: 'Brand',
                      icon: Icons.branding_watermark,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: buildTextField(
                            controller: _qtyController,
                            label: 'Quantity',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              prefixIcon: Icon(
                                Icons.straighten,
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade400,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items:
                                _units
                                    .map(
                                      (unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _unit = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    buildTextField(
                      controller: _priceController,
                      label: 'Unit Price (₱)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    buildTextField(
                      controller: _noteController,
                      label: 'Notes (Optional)',
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : saveMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                isEdit ? 'Save Changes' : 'Add to Inventory',
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
