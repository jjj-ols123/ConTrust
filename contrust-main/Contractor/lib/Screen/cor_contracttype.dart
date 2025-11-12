// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/contract/buildcontracttype.dart';
import 'package:flutter/material.dart';

class ContractType extends StatefulWidget {
  final String contractorId;
  final bool showNoProjectsMessage;

  const ContractType({
    super.key,
    required this.contractorId,
    this.showNoProjectsMessage = false,
  });

  @override
  State<ContractType> createState() => _ContractTypeState();
}

class _ContractTypeState extends State<ContractType> {
  final Key contractListKey = UniqueKey();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedProject = 'All';
  late final Key contractTypesKey;

  @override
  void initState() {
    super.initState();
    contractTypesKey = UniqueKey();

    if (widget.showNoProjectsMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ConTrustSnackBar.warning(
          context,
          'No projects available for contract creation. You must have projects with "awaiting contract" status to create contracts.',
          duration: const Duration(seconds: 4),
        );
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchContractorProjects(String contractorId) async {
    try {
      final projects = await FetchService().fetchContractorProjectInfo(contractorId);
      // Filter to only show projects with status "awaiting_contract"
      return projects.where((project) => project['status'] == 'awaiting_contract').toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContractTypeBuild.buildHeader(context),
        const SizedBox(height: 18),
        ContractTypeBuild.buildTypeCarousel(
          key: contractTypesKey,
          contractorId: widget.contractorId,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Contracts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Search bar and filters in the same row
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                                decoration: const InputDecoration(
                                  hintText: "Search contracts...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Icon(Icons.search, color: Colors.amber[700], size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Filter
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedStatus != 'All' ? Colors.blue[700] : Colors.amber[700],
                          size: 20,
                        ),
                      ),
                      tooltip: 'Filter by Status',
                      onSelected: (value) {
                        if (value == 'clear_status') {
                          setState(() => _selectedStatus = 'All');
                        } else {
                          setState(() => _selectedStatus = value);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'All',
                          child: Text('All Status'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'draft',
                          child: Text('Draft'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'sent',
                          child: Text('Sent'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'approved',
                          child: Text('Approved'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'rejected',
                          child: Text('Rejected'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'clear_status',
                          child: Text('Clear Status Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Project Filter
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchContractorProjects(widget.contractorId),
                      builder: (context, snapshot) {
                        return PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Icon(
                              Icons.business,
                              color: _selectedProject != 'All' ? Colors.blue[700] : Colors.amber[700],
                              size: 20,
                            ),
                          ),
                          tooltip: 'Filter by Project',
                          onSelected: (value) {
                            if (value == 'clear_project') {
                              setState(() => _selectedProject = 'All');
                            } else {
                              setState(() => _selectedProject = value);
                            }
                          },
                          itemBuilder: (context) {
                            List<PopupMenuEntry<String>> items = [
                              const PopupMenuItem<String>(
                                value: 'All',
                                child: Text('All Projects'),
                              ),
                            ];

                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              items.addAll(snapshot.data!.map((project) => PopupMenuItem<String>(
                                value: project['project_id'] as String,
                                child: Text(project['title'] as String? ?? 'Unknown Project'),
                              )));
                            }

                            items.add(const PopupMenuDivider());
                            items.add(const PopupMenuItem<String>(
                              value: 'clear_project',
                              child: Text('Clear Project Filter'),
                            ));

                            return items;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ContractTypeBuild.buildContractListContainer(
          contractorId: widget.contractorId,
          contractListKey: contractListKey,
          searchQuery: _searchQuery,
          selectedStatus: _selectedStatus,
          selectedProject: _selectedProject,
        ),
      ],
    );
  }
}
