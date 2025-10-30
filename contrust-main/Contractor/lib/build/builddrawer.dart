// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:backend/build/buildnotification.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/services/superadmin%20services/auditlogs_service.dart';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/Screen/cor_bidding.dart';
import 'package:contractor/Screen/cor_chathistory.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractor/Screen/cor_profile.dart';
import 'package:contractor/Screen/cor_startup.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ContractorPage {
  dashboard,
  messages,
  contracts,
  bidding,
  profile,
  projectManagement,
  materials,
}

class ContractorShell extends StatelessWidget {
  final ContractorPage currentPage;
  final String contractorId;
  final Widget child;
  final EdgeInsets? contentPadding;

  const ContractorShell({
    super.key,
    required this.currentPage,
    required this.contractorId,
    required this.child,
    this.contentPadding,
  });

  String title() {
    switch (currentPage) {
      case ContractorPage.dashboard:
        return 'Dashboard';
      case ContractorPage.messages:
        return 'Messages';
      case ContractorPage.contracts:
        return 'Contracts';
      case ContractorPage.bidding:
        return 'Bidding';
      case ContractorPage.profile:
        return 'Profile';
      case ContractorPage.projectManagement:
        return 'Project Management';
      case ContractorPage.materials:
        return 'Materials';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        elevation: 4,
        automaticallyImplyLeading: false,
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  if (currentPage != ContractorPage.dashboard) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/dashboard', 
                      (route) => false,
                    );
                  }
                },
              )
            : null,
        actions: const [NotificationButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
        children: [
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.amber[500],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.construction,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ConTrust',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SideDashboardDrawer(
                      contractorId: contractorId,
                      currentPage: currentPage,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Padding(
              padding: contentPadding ?? EdgeInsets.zero,
              child: child,
            ),
                ),
              ],
            ),
          ),
          if (!isDesktop)
            ModernBottomNavigationBar(
              contractorId: contractorId,
              currentPage: currentPage,
          ),
        ],
      ),
    );
  }
}

class SideDashboardDrawer extends StatefulWidget {
  final String? contractorId;
  final ContractorPage currentPage;
  const SideDashboardDrawer({
    super.key,
    required this.contractorId,
    required this.currentPage,
  });

  @override
  State<SideDashboardDrawer> createState() => _SideDashboardDrawerState();
}

class _SideDashboardDrawerState extends State<SideDashboardDrawer> {
  bool _loadingPM = false;
  bool _hasActiveSession = false;
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _hasActiveSession = session != null;
    });
  }

  Future<void> goProjectManagement() async {
    if (widget.contractorId == null) return;
    setState(() => _loadingPM = true);

    try {
      final activeProjects = await FetchService().fetchContractorActiveProjects(
        widget.contractorId!,
      );

      setState(() => _loadingPM = false);

      if (activeProjects.isEmpty) {
        ConTrustSnackBar.error(context, 'No current ongoing project found!');
        return;
      }

      String? projectId;
      if (activeProjects.length > 1) {
        projectId = await showDialog<String>(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                      color: Colors.amber.shade700,
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
                            Icons.folder,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Select Project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: activeProjects.length,
                        itemBuilder: (context, index) {
                          final project = activeProjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(project['title'] ?? 'Untitled Project'),
                              subtitle: Text('Status: ${project['status'] ?? 'N/A'}'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade700),
                              onTap: () {
                                Navigator.of(dialogContext).pop(project['project_id']);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
        if (projectId == null) return; 
      } else {
        projectId = activeProjects.first['project_id'];
      }

      if (widget.currentPage != ContractorPage.projectManagement) {
        navigateToPage(
          ContractorShell(
            currentPage: ContractorPage.projectManagement,
            contractorId: widget.contractorId ?? '',
            child: CorOngoingProjectScreen(projectId: projectId ?? ''),
          ),
        );
      }
    } catch (e) {
      setState(() => _loadingPM = false);
      return;
    }
  }

  void navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ToLoginScreen()),
        (route) => false,
      );

      await _auditService.logAuditEvent(
        userId: widget.contractorId,
        action: 'LOGOUT_ATTEMPT',
        details: 'Contractor logout',
        metadata: {
          'user_type': 'contractor',
        },
      );

    } catch (e) {
      if (!mounted) return;
        await _errorService.logError(
          errorMessage: 'Logout failed ',
          module: 'Logout Button Drawer', 
          severity: 'Medium', 
          extraInfo: { 
            'operation': 'Logout attempt',
            'error_id': widget.contractorId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.contractorId;
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            active: widget.currentPage == ContractorPage.dashboard,
            onTap: () {
              if (widget.currentPage != ContractorPage.dashboard) {
                navigateToPage(DashboardScreen(contractorId: id ?? ''));
              }
            },
          ),
          _SidebarItem(
            icon: Icons.message_outlined,
            label: 'Messages',
            active: widget.currentPage == ContractorPage.messages,
            onTap: () {
              if (widget.currentPage != ContractorPage.messages) {
                navigateToPage(
                  ContractorShell(
                    currentPage: ContractorPage.messages,
                    contractorId: id ?? '',
                    child: ContractorChatHistoryPage(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.assignment_outlined,
            label: 'Contracts',
            active: widget.currentPage == ContractorPage.contracts,
            onTap: () {
              if (widget.currentPage != ContractorPage.contracts) {
                navigateToPage(
                  ContractorShell(
                    currentPage: ContractorPage.contracts,
                    contractorId: id ?? '',
                    child: ContractType(contractorId: id ?? ''),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.gavel_outlined,
            label: 'Bidding',
            active: widget.currentPage == ContractorPage.bidding,
            onTap: () {
              if (widget.currentPage != ContractorPage.bidding) {
                navigateToPage(
                  ContractorShell(
                    currentPage: ContractorPage.bidding,
                    contractorId: id ?? '',
                    child: BiddingScreen(contractorId: id ?? ''),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.person_outline,
            label: 'Profile',
            active: widget.currentPage == ContractorPage.profile,
            onTap: () {
              if (widget.currentPage != ContractorPage.profile) {
                navigateToPage(
                  ContractorShell(
                    currentPage: ContractorPage.profile,
                    contractorId: id ?? '',
                    child: ContractorUserProfileScreen(contractorId: id ?? ''),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.work_outline,
            label: _loadingPM ? 'Loading...' : 'Project Management',
            active: widget.currentPage == ContractorPage.projectManagement,
            onTap: _loadingPM ? null : goProjectManagement,
          ),
          const Divider(), 
          _SidebarItem(
            icon: Icons.logout_outlined,
            label: 'Logout',
            active: _hasActiveSession, 
            onTap: _hasActiveSession ? logout : null,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.amber.shade700 : Colors.grey.shade700;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active ? Colors.amber.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (active) Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class ModernBottomNavigationBar extends StatefulWidget {
  final String? contractorId;
  final ContractorPage currentPage;
  const ModernBottomNavigationBar({
    super.key, 
    this.contractorId,
    required this.currentPage,
  });

  @override
  State<ModernBottomNavigationBar> createState() => _ModernBottomNavigationBarState();
}

class _ModernBottomNavigationBarState extends State<ModernBottomNavigationBar> {
  bool hasActiveProject = false;

  @override
  void initState() {
    super.initState();
    _checkActiveProjects();
  }

  Future<void> _checkActiveProjects() async {
    try {
      final response = await Supabase.instance.client
          .from('Projects')
          .select('project_id')
          .eq('contractor_id', widget.contractorId ?? '')
          .eq('status', 'active')
          .limit(1);
      
      setState(() {
        hasActiveProject = response.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        hasActiveProject = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
      children: [
              Expanded(
                child: _ModernNavItem(
                  icon: Icons.message_outlined,
                  activeIcon: Icons.message,
                  label: 'Messages',
                  isActive: widget.currentPage == ContractorPage.messages,
                  onTap: () => _navigateToPage(ContractorPage.messages),
                ),
              ),
              Expanded(
                child: _ModernNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Contracts',
                  isActive: widget.currentPage == ContractorPage.contracts,
                  onTap: () => _navigateToPage(ContractorPage.contracts),
                ),
              ),
              Expanded(
                child: _ProjectNavButton(
                  contractorId: widget.contractorId ?? '',
                  currentPage: widget.currentPage,
                  hasActiveProject: hasActiveProject,
                ),
              ),
              Expanded(
                child: _ModernNavItem(
                  icon: Icons.gavel_outlined,
                  activeIcon: Icons.gavel,
                  label: 'Bidding',
                  isActive: widget.currentPage == ContractorPage.bidding,
                  onTap: () => _navigateToPage(ContractorPage.bidding),
                ),
              ),
              Expanded(
                child: _ModernNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: widget.currentPage == ContractorPage.profile,
                  onTap: () => _navigateToPage(ContractorPage.profile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(ContractorPage page) {
    if (widget.currentPage == page) return;
    
    switch (page) {
      case ContractorPage.messages:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractorShell(
              currentPage: ContractorPage.messages,
              contractorId: widget.contractorId ?? '',
              child: ContractorChatHistoryPage(),
            ),
          ),
        );
        break;
      case ContractorPage.contracts:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractorShell(
              currentPage: ContractorPage.contracts,
              contractorId: widget.contractorId ?? '',
              child: ContractType(contractorId: widget.contractorId ?? ''),
            ),
          ),
        );
        break;
      case ContractorPage.bidding:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractorShell(
              currentPage: ContractorPage.bidding,
              contractorId: widget.contractorId ?? '',
              child: BiddingScreen(contractorId: widget.contractorId ?? ''),
            ),
          ),
        );
        break;
      case ContractorPage.profile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractorShell(
              currentPage: ContractorPage.profile,
              contractorId: widget.contractorId ?? '',
              child: ContractorUserProfileScreen(contractorId: widget.contractorId ?? ''),
            ),
          ),
        );
        break;
      default:
        break;
    }
  }
}

class _ModernNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModernNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
                      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                        ),
                              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectNavButton extends StatelessWidget {
  final String contractorId;
  final ContractorPage currentPage;
  final bool hasActiveProject;

  const _ProjectNavButton({
    required this.contractorId,
    required this.currentPage,
    required this.hasActiveProject,
  });

  @override
  Widget build(BuildContext context) {
    
    return GestureDetector(
      onTap: hasActiveProject ? () async {
        try {
          final response = await Supabase.instance.client
              .from('Projects')
              .select('project_id')
              .eq('contractor_id', contractorId)
              .eq('status', 'active')
              .limit(1)
              .maybeSingle();

          if (response != null && response['project_id'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContractorShell(
                  currentPage: ContractorPage.projectManagement,
                  contractorId: contractorId,
                  child: CorOngoingProjectScreen(projectId: response['project_id']),
                ),
              ),
            );
          } else {
            ConTrustSnackBar.error(context, 'No active project found');
          }
        } catch (e) {
          ConTrustSnackBar.error(context, 'Failed to load project data');
        }
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasActiveProject 
                    ? Colors.amber.shade400 
                    : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: hasActiveProject 
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.work_outline,
                    color: Colors.white,
            size: 28,
                    ),
                  ),
                ),
    );
  }
}

class DashboardDrawer extends StatefulWidget {
  final ScrollController? scrollController;
  final String? contractorId;
  const DashboardDrawer({super.key, this.scrollController, this.contractorId});

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  bool _loadingPM = false;
  bool _hasActiveSession = false;
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _hasActiveSession = session != null;
    });
  }

  Future<void> goProjectManagement() async {
    if (widget.contractorId == null) return;
    setState(() => _loadingPM = true);

    try {
      final activeProjects = await FetchService().fetchContractorActiveProjects(
        widget.contractorId!,
      );

      setState(() => _loadingPM = false);

      if (activeProjects.isEmpty) {
        ConTrustSnackBar.error(context, 'No current ongoing project found!');
        return;
      }

      String? projectId;
      if (activeProjects.length > 1) {
        projectId = await showDialog<String>(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                      color: Colors.amber.shade700,
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
                            Icons.folder,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Select Project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: activeProjects.length,
                        itemBuilder: (context, index) {
                          final project = activeProjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(project['title'] ?? 'Untitled Project'),
                              subtitle: Text('Status: ${project['status'] ?? 'N/A'}'),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade700),
                              onTap: () {
                                Navigator.of(dialogContext).pop(project['project_id']);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
        if (projectId == null) return;
      } else {
        projectId = activeProjects.first['project_id'];
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractorShell(
            currentPage: ContractorPage.projectManagement,
            contractorId: widget.contractorId!,
            child: CorOngoingProjectScreen(projectId: projectId ?? ''),
          ),
        ),
      );
    } catch (e) {
      setState(() => _loadingPM = false);
      return;
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ToLoginScreen()),
        (route) => false,
      );

      await _auditService.logAuditEvent(
        userId: widget.contractorId,
        action: 'CONTRACTOR_LOGOUT',
        details: 'Contractor logout',
        metadata: {
          'user_type': 'contractor',
        },
        category: 'Auth',
      );
    } catch (e) {
      if (!mounted) return;
        await _errorService.logError(
          errorMessage: 'Logout failed ',
          module: 'Logout Button Drawer', 
          severity: 'Medium', 
          extraInfo: { 
            'operation': 'Logout attempt',
            'error_id': widget.contractorId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      ConTrustSnackBar.error(context, 'Error logging out. Please try again.');
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

    return Flexible(
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
                controller: widget.scrollController,
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
                children: [
                  DrawerIcon(
                    icon: Icons.message,
                    label: 'Messages',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.black,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractorShell(
                            currentPage: ContractorPage.messages,
                            contractorId: widget.contractorId!,
                            child: ContractorChatHistoryPage(
                              contractorId: widget.contractorId,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.assignment,
                    label: 'Contracts',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.black,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractorShell(
                            currentPage: ContractorPage.contracts,
                            contractorId: widget.contractorId!,
                            child: ContractType(contractorId: widget.contractorId!),
                          ),
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.gavel,
                    label: 'Bidding',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.black,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractorShell(
                            currentPage: ContractorPage.bidding,
                            contractorId: widget.contractorId!,
                            child: BiddingScreen(contractorId: widget.contractorId!),
                          ),
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.person,
                    label: 'Profile',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.black,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractorShell(
                            currentPage: ContractorPage.profile,
                            contractorId: widget.contractorId!,
                            child: ContractorUserProfileScreen(
                              contractorId: widget.contractorId!,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.work_outline,
                    label: _loadingPM ? 'Loading...' : 'Projects',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.amber.shade700,
                    onTap: _loadingPM ? () {} : goProjectManagement,
                  ),
                  DrawerIcon(
                    icon: Icons.logout,
                    label: 'Logout',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: _hasActiveSession ? Colors.red.shade600 : Colors.grey.shade400,
                    onTap: _hasActiveSession ? logout : () {},
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

class DrawerIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;
  final Color color;

  const DrawerIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconSize,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
