// ignore_for_file: deprecated_member_use

import 'package:backend/build/buildnotification.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/services/superadmin%20services/auditlogs_service.dart';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_profile.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractee/pages/cee_chathistory.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ContracteePage {
  home,
  ongoing,
  profile,
  notifications,
  messages
}

class ContracteeShell extends StatelessWidget {
  final ContracteePage currentPage;
  final String? contracteeId;
  final Widget child;
  final EdgeInsets? contentPadding;

  const ContracteeShell({
    super.key,
    required this.currentPage,
    this.contracteeId,
    required this.child,
    this.contentPadding,
  });

  String title() {
    switch (currentPage) {
      case ContracteePage.home:
        return 'Home';
      case ContracteePage.ongoing:
        return 'Ongoing Projects';
      case ContracteePage.profile:
        return 'Profile';
      case ContracteePage.notifications:
        return 'Notifications';
      case ContracteePage.messages:
        return 'Messages';
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
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
        actions: const [NotificationButton()],
      ),
      drawer: !isDesktop ? Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
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
                  contracteeId: contracteeId,
                  currentPage: currentPage,
                ),
              ),
            ],
          ),
        ),
      ) : null,
      body: Row(
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
                      contracteeId: contracteeId,
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
    );
  }
}

class SideDashboardDrawer extends StatefulWidget {
  final String? contracteeId;
  final ContracteePage currentPage;

  const SideDashboardDrawer({
    super.key,
    this.contracteeId,
    required this.currentPage,
  });

  @override
  State<SideDashboardDrawer> createState() => _SideDashboardDrawerState();
}

class _SideDashboardDrawerState extends State<SideDashboardDrawer> {
  bool _loadingOngoing = false;
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

  Future<void> goToOngoing() async {
    if (widget.contracteeId == null) return;
    setState(() => _loadingOngoing = true);

    try {
      final projects = await FetchService().fetchUserProjects();
      final activeProjects = projects.where(
        (project) => project['status'] == 'active',
      ).toList();

      setState(() => _loadingOngoing = false);

      if (activeProjects.isEmpty) {
        if (mounted) {
          ConTrustSnackBar.error(context, 'No active project found');
        }
        return;
      }

      if (!mounted) return;

      if (activeProjects.length > 1) {
        _showProjectSelectionDialog(activeProjects);
        return;
      }

      final projectId = activeProjects.first['project_id'];
      if (widget.currentPage != ContracteePage.ongoing) {
        navigateToPage(
          ContracteeShell(
            currentPage: ContracteePage.ongoing,
            contracteeId: widget.contracteeId ?? '',
            child: CeeOngoingProjectScreen(
              projectId: projectId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _loadingOngoing = false);
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading ongoing project');
      }
    }
  }

  void _showProjectSelectionDialog(List<Map<String, dynamic>> projects) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Active Project'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                title: Text(project['title'] ?? 'Untitled Project'),
                subtitle: Text(project['location'] ?? 'No location'),
                onTap: () {
                  Navigator.pop(context);
                  navigateToPage(
                    ContracteeShell(
                      currentPage: ContracteePage.ongoing,
                      contracteeId: widget.contracteeId ?? '',
                      child: CeeOngoingProjectScreen(
                        projectId: project['project_id'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }

       await _auditService.logAuditEvent(
        userId: widget.contracteeId,
        action: 'LOGOUT_ATTEMPT',
        details: 'Contractee logout failed due to error',
        category: 'User',
        metadata: {
          'user_type': 'contractee',
        },
      );

    } catch (e) {
      if (mounted) {
        await _errorService.logError(
          errorMessage: 'Logout failed',
          module: 'Logout Button Drawer', 
          severity: 'Medium', 
          extraInfo: { 
            'operation': 'Logout attempt',
            'error_id': widget.contracteeId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.contracteeId;
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SidebarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            active: widget.currentPage == ContracteePage.home,
            onTap: () {
              if (widget.currentPage != ContracteePage.home) {
                navigateToPage(const HomePage());
              }
            },
          ),
          _SidebarItem(
            icon: Icons.message_outlined,
            label: 'Messages',
            active: widget.currentPage == ContracteePage.messages,
            onTap: () {
              if (widget.currentPage != ContracteePage.messages) {
                navigateToPage(
                  ContracteeShell(
                    currentPage: ContracteePage.messages,
                    contracteeId: id ?? '',
                    child: const ContracteeChatHistoryPage(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.work_outline,
            label: _loadingOngoing ? 'Loading...' : 'Ongoing Projects',
            active: widget.currentPage == ContracteePage.ongoing,
            onTap: _loadingOngoing ? null : goToOngoing,
          ),
          _SidebarItem(
            icon: Icons.person,
            label: 'Profile',
            active: widget.currentPage == ContracteePage.profile,
            onTap: () {
              if (widget.currentPage != ContracteePage.profile) {
                navigateToPage(
                  ContracteeShell(
                    currentPage: ContracteePage.profile,
                    contracteeId: widget.contracteeId ?? '',
                    child: CeeProfilePage(contracteeId: widget.contracteeId ?? ''),
                  ),
                );
              }
            },
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