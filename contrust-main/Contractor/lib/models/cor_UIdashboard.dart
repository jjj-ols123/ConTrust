// ignore_for_file: file_names, deprecated_member_use, use_build_context_synchronously, unused_element, library_private_types_in_public_api
import 'package:contractor/Screen/cor_bidding.dart';
import 'package:contractor/Screen/cor_chathistory.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
import 'package:contractor/Screen/cor_product.dart';
import 'package:flutter/material.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractor/Screen/cor_clienthistory.dart';
import 'package:contractor/Screen/cor_profile.dart';
import 'package:backend/services/be_fetchservice.dart';

class DashboardUI extends StatefulWidget {
  final String? contractorId;
  const DashboardUI({super.key, required this.contractorId});

  @override
  State<DashboardUI> createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI>
    with TickerProviderStateMixin {
  Map<String, dynamic>? contractorData;
  int activeProjects = 0;
  int completedProjects = 0;
  double rating = 0.0;
  bool loading = true;
  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> localTasks = [];
  double totalEarnings = 0.0;
  int totalClients = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    fetchDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    try {
      if (widget.contractorId == null) {
        setState(() => loading = false);
        return;
      }

      final data = await FetchService().fetchContractorData(
        widget.contractorId!,
      );
      final projects = await FetchService().fetchContractorProjectInfo(
        widget.contractorId!,
      );

      final completed =
          projects.where((p) => p['status'] == 'completed').length;
      final active = projects.where((p) => p['status'] == 'active').length;
      final ratingVal = data?['rating'] ?? 0.0;
      final recent = projects.take(3).toList();

      totalEarnings = completed * 50000.0;
      totalClients = projects.map((p) => p['contractee_id']).toSet().length;

      localTasks = [];
      final activeProjectList =
          projects.where((p) => p['status'] == 'active').toList();

      for (final project in activeProjectList) {
        final tasks = await FetchService().fetchProjectTasks(
          project['project_id'],
        );
        for (final task in tasks) {
          localTasks.add({
            ...task,
            'project_title': project['title'] ?? 'Project',
          });
        }
      }

      localTasks = localTasks.take(3).toList();

      setState(() {
        contractorData = data;
        activeProjects = active;
        completedProjects = completed;
        rating = ratingVal.toDouble();
        recentActivities = recent;
        loading = false;
      });
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text('Loading your dashboard...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildStatsGrid(),
                const SizedBox(height: 20),
                _buildRecentProjects(),
                const SizedBox(height: 20),
                _buildProjectTasks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.amber.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isTablet ? 50 : 40,
                backgroundColor: Colors.white,
                backgroundImage:
                    contractorData?['profile_photo'] != null
                        ? NetworkImage(contractorData!['profile_photo'])
                        : null,
                child:
                    contractorData?['profile_photo'] == null
                        ? Icon(
                          Icons.business,
                          size: isTablet ? 50 : 40,
                          color: Colors.amber.shade700,
                        )
                        : null,
              ),
            ),
            SizedBox(width: isTablet ? 24 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contractorData?['firm_name'] ?? 'Contractor',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($completedProjects reviews)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 700 && screenWidth < 1200;

    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isDesktop) {
      crossAxisCount = 4;
      childAspectRatio = 1.8;
      spacing = 20;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 2.4;
      spacing = 16;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
      spacing = 12;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          'Active Projects',
          activeProjects.toString(),
          Icons.work,
          Colors.blue,
          'Currently working on',
        ),
        _buildStatCard(
          'Completed',
          completedProjects.toString(),
          Icons.check_circle,
          Colors.green,
          'Successfully finished',
        ),
        _buildStatCard(
          'Total Earnings',
          '₱${totalEarnings.toStringAsFixed(0)}',
          Icons.money,
          Colors.orange,
          'From all projects',
        ),
        _buildStatCard(
          'Number of Clients',
          totalClients.toString(),
          Icons.people,
          Colors.purple,
          'Satisfied customers',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 900 && screenWidth < 1200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isDesktop ? 20 : (isTablet ? 10 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 15.2 : (isTablet ? 14 : 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isDesktop ? 14 : (isTablet ? 14 : 12),
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isDesktop ? 12 : (isTablet ? 16 : 8),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isDesktop ? 22 : (isTablet ? 22 : 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 23 : (isTablet ? 20 : 8)),
            Text(
              value,
              style: TextStyle(
                fontSize: isDesktop ? 17 : (isTablet ? 15 : 18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isDesktop && isTablet) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjects() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.recent_actors,
                  color: Colors.amber.shade700,
                  size: isTablet ? 28 : 24,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  'Recent Projects',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            if (recentActivities.isEmpty)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 60 : 40,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: isTablet ? 64 : 48,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      Text(
                        'No projects yet',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center, 
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        'Start by creating your first project',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isTablet ? 16 : 14,
                        ),
                        textAlign: TextAlign.center, 
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentActivities.map(
                (project) => ContractorProjectView(project: project),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTasks() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: Colors.green.shade700,
                  size: isTablet ? 28 : 24,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  'Project Tasks',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            if (localTasks.isEmpty)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 60 : 40,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(
                        Icons.inbox,
                        size: isTablet ? 64 : 48,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        'Start by adding your first task',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isTablet ? 16 : 14,
                        ),
                        textAlign: TextAlign.center, 
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ...localTasks.map(
                (task) => ListTile(
                  leading: Icon(
                    task['done'] == true
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task['done'] == true ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    task['task'] ?? '',
                    style: TextStyle(
                      decoration:
                          task['done'] == true
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                  ),
                  subtitle: Text(
                    'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'More on the Project Management Page...',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContractorProjectView extends StatelessWidget {
  final Map<String, dynamic> project;
  const ContractorProjectView({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('View Project Management'),
                content: const Text(
                  'Do you want to go to Project Management Page?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
        );
        if (confirmed == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      CorOngoingProjectScreen(projectId: project['project_id']),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 18),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.amber.shade100,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project['title'] ?? 'No title given',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Description: ${project['description'] ?? 'No description'}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'Type: ${project['type'] ?? 'No type'}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        project['status'],
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Status: ${_getStatusLabel(project['status'])}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(project['status']),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'awaiting_contract':
        return 'Awaiting for Contract';
      case 'awaiting_agreement':
        return 'Awaiting Agreement';
      case 'closed':
        return 'Closed';
      case 'ended':
        return 'Ended';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'awaiting_contract':
        return Colors.blue;
      case 'awaiting_agreement':
        return Colors.purple;
      case 'closed':
        return Colors.redAccent;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class PersistentDashboardDrawer extends StatefulWidget {
  final String? contractorId;
  const PersistentDashboardDrawer({super.key, this.contractorId});

  @override
  State<PersistentDashboardDrawer> createState() =>
      _PersistentDashboardDrawerState();
}

class _PersistentDashboardDrawerState extends State<PersistentDashboardDrawer>
    with TickerProviderStateMixin {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  late AnimationController _iconController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final double initialSize = 0.10;
    final double expandedSize = isDesktop ? 0.39 : 0.48;
    final double toggleThreshold = screenHeight > 600 ? 0.2 : 0.25;

    return Stack(
      children: [
        DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: initialSize,
          minChildSize: initialSize,
          maxChildSize: expandedSize,
          builder: (context, scrollController) {
            return Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Container(
                  width: double.infinity,
                  height: 93.5,
                  color: Colors.transparent,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_controller.size < toggleThreshold) {
                          _controller.animateTo(
                            expandedSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                          _iconController.forward();
                        } else {
                          _controller.animateTo(
                            initialSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                          _iconController.reverse();
                        }
                      },
                      child: Container(
                        width: screenWidth > 600 ? 110 : screenWidth * 0.18,
                        height: 22,
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber[600],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: AnimatedBuilder(
                          animation: _iconRotation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _iconRotation.value * 3.14159,
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white,
                                size: screenWidth > 600 ? 22 : 16,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded( 
                  child: Material(
                    elevation: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    color: Colors.white,
                    child: DashboardDrawer(
                      scrollController: scrollController,
                      contractorId: widget.contractorId,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DashboardDrawer extends StatelessWidget {
  final ScrollController? scrollController;
  final String? contractorId;
  const DashboardDrawer({super.key, this.scrollController, this.contractorId});

  Future<void> _openMaterials(BuildContext context) async {
    if (contractorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No contractor detected')));
      return;
    }

    try {
      final projects = await FetchService().fetchContractorProjectInfo(
        contractorId!,
      );

      final active =
          projects.where((p) {
            final s = (p['status'] as String? ?? '').toLowerCase();
            return s == 'active' || s == 'ongoing';
          }).toList();

      if (active.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active/ongoing projects detected')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductPanelScreen(
                  contractorId: contractorId!,
                  projectId: null,
                ),
          ),
        );
        return;
      }
      final selectedId = active.first['project_id']?.toString();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProductPanelScreen(
                contractorId: contractorId!,
                projectId: selectedId,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading projects: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int crossAxisCount;
    double iconSize;
    double fontSize;
    double spacing;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 6;
      iconSize = screenHeight < 800 ? 24.0 : 28.0; 
      fontSize = screenHeight < 800 ? 12.0 : 14.0; 
      spacing = 16.0;
      childAspectRatio = screenHeight < 800 ? 1.1 : 0.95;
    } else if (screenWidth > 900) {
      crossAxisCount = 5;
      iconSize = screenHeight < 800 ? 22.0 : 26.0;
      fontSize = screenHeight < 800 ? 11.0 : 13.0;
      spacing = 14.0;
      childAspectRatio = screenHeight < 800 ? 1.1 : 0.95;
    } else if (screenWidth > 600) {
      crossAxisCount = 4;
      iconSize = screenHeight < 800 ? 20.0 : 24.0;
      fontSize = screenHeight < 800 ? 10.0 : 12.0;
      spacing = 12.0;
      childAspectRatio = screenHeight < 800 ? 1.2 : 1.0;
    } else {
      crossAxisCount = 3;
      iconSize = screenHeight < 800 ? 18.0 : 20.0;
      fontSize = screenHeight < 800 ? 9.0 : 11.0;
      spacing = 1.0;
      childAspectRatio = screenHeight < 800 ? 1.3 : 1.1;
    }

    return SizedBox(
      height: double.infinity, 
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight < 800 ? 8 : 15, 
          horizontal: screenWidth > 1200 ? 32 : (screenWidth > 600 ? 20 : 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Expanded( 
              child: GridView.count(
                controller: scrollController,
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
                children: [
                  _DrawerIcon(
                    icon: Icons.message,
                    label: 'Messages',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractorChatHistoryPage(
                            contractorId: contractorId,
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.assignment,
                    label: 'Contracts',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractType(contractorId: contractorId!),
                        ),
                      );
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.gavel,
                    label: 'Bidding',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BiddingScreen(contractorId: contractorId!),
                        ),
                      );
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.history,
                    label: 'History',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.person,
                    label: 'Profile',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractorUserProfileScreen(
                            contractorId: contractorId!,
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.build,
                    label: 'Material Page',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.indigo,
                    onTap: () => _openMaterials(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;
  final Color color;

  const _DrawerIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconSize,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
