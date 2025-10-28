import 'package:flutter/material.dart';

class DashboardProjectTabs extends StatefulWidget {
  final List<Map<String, dynamic>> activeProjects;
  final Widget Function(Map<String, dynamic> selectedProject) buildProjectSection;
  final Widget Function(Map<String, dynamic> selectedProject) buildContracteeSection;
  final Widget Function(Map<String, dynamic> selectedProject) buildTasksSection;

  const DashboardProjectTabs({
    super.key,
    required this.activeProjects,
    required this.buildProjectSection,
    required this.buildContracteeSection,
    required this.buildTasksSection,
  });

  @override
  State<DashboardProjectTabs> createState() => _DashboardProjectTabsState();
}

class _DashboardProjectTabsState extends State<DashboardProjectTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.activeProjects.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeProjects.isEmpty || widget.activeProjects.first['isPlaceholder'] == true) {
      return Column(
        children: [
          widget.buildProjectSection(widget.activeProjects.first),
          const SizedBox(height: 20),
          widget.buildContracteeSection(widget.activeProjects.first),
          const SizedBox(height: 20),
          widget.buildTasksSection(widget.activeProjects.first),
        ],
      );
    }

    if (widget.activeProjects.length == 1) {
      return Column(
        children: [
          widget.buildProjectSection(widget.activeProjects.first),
          const SizedBox(height: 20),
          widget.buildContracteeSection(widget.activeProjects.first),
          const SizedBox(height: 20),
          widget.buildTasksSection(widget.activeProjects.first),
        ],
      );
    }

    final selectedProject = widget.activeProjects[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.center,
          child: IntrinsicWidth(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Colors.amber.shade400,
                  width: 3,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 12),
              ),
              labelColor: Colors.amber.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 0),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              dividerHeight: 0,
              tabs: widget.activeProjects.map((project) {
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.work_outline, size: 16),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            project['title'] ?? 'Project',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              ),
            ),
          ),
        ),
        widget.buildProjectSection(selectedProject),
        const SizedBox(height: 20),
        widget.buildContracteeSection(selectedProject),
        const SizedBox(height: 20),
        widget.buildTasksSection(selectedProject),
      ],
    );
  }
}

