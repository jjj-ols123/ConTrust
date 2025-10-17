// ignore_for_file: deprecated_member_use

import 'package:backend/services/superadmin%20services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:superadmin/pages/login.dart';
import '../pages/dashboard.dart';
import '../pages/auditlogs.dart';
import '../pages/errorlog.dart';
import '../pages/users.dart';
import '../pages/projects.dart';
import '../pages/systemmonitor.dart';

enum SuperAdminPage {
  dashboard,
  users,
  projects,
  auditLogs,
  errorLogs,
  systemMonitor,
}

class SuperAdminShell extends StatelessWidget {
  final SuperAdminPage currentPage;
  final Widget child;
  final EdgeInsets? contentPadding;

  const SuperAdminShell({
    super.key,
    required this.currentPage,
    required this.child,
    this.contentPadding,
  });

  String title() {
    switch (currentPage) {
      case SuperAdminPage.dashboard:
        return 'Dashboard';
      case SuperAdminPage.users:
        return 'Users Management';
      case SuperAdminPage.projects:
        return 'Projects Management';
      case SuperAdminPage.auditLogs:
        return 'Audit Logs';
      case SuperAdminPage.errorLogs:
        return 'Error Logs';
      case SuperAdminPage.systemMonitor:
        return 'System Monitor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
        automaticallyImplyLeading: false,
        title: Text(
          title(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AdminLoginService().signOut();
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SuperAdminLoginScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: !isDesktop ? Builder(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(
            drawerTheme: const DrawerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          child: Drawer(
            elevation: 0,
            child: Column(
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[500],
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
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'SuperAdmin',
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
                          currentPage: currentPage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ) : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.deepPurple[500],
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
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'SuperAdmin',
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
  final SuperAdminPage currentPage;

  const SideDashboardDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  State<SideDashboardDrawer> createState() => _SideDashboardDrawerState();
}

class _SideDashboardDrawerState extends State<SideDashboardDrawer> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            active: widget.currentPage == SuperAdminPage.dashboard,
            onTap: () {
              if (widget.currentPage != SuperAdminPage.dashboard) {
                navigateToPage(
                  const SuperAdminShell(
                    currentPage: SuperAdminPage.dashboard,
                    child: SuperAdminDashboard(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.people_outlined,
            label: 'Users',
            active: widget.currentPage == SuperAdminPage.users,
            onTap: () {
              if (widget.currentPage != SuperAdminPage.users) {
                navigateToPage(
                  SuperAdminShell(
                    currentPage: SuperAdminPage.users,
                    child: UsersManagementPage(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.work_outline,
            label: 'Projects',
            active: widget.currentPage == SuperAdminPage.projects,
            onTap: () {
              if (widget.currentPage != SuperAdminPage.projects) {
                navigateToPage(
                  SuperAdminShell(
                    currentPage: SuperAdminPage.projects,
                    child: ProjectsManagementPage(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.history_outlined,
            label: 'Audit Logs',
            active: widget.currentPage == SuperAdminPage.auditLogs,
            onTap: () {
              if (widget.currentPage != SuperAdminPage.auditLogs) {
                navigateToPage(
                  SuperAdminShell(
                    currentPage: SuperAdminPage.auditLogs,
                    child: Auditlogs(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.error_outline,
            label: 'Error Logs',
            active: widget.currentPage == SuperAdminPage.errorLogs,
            onTap: () {
              if (widget.currentPage != SuperAdminPage.errorLogs) {
                navigateToPage(
                  SuperAdminShell(
                    currentPage: SuperAdminPage.errorLogs,
                    child: ErrorLogs(),
                  ),
                );
              }
            },
          ),
          _SidebarItem(
            icon: Icons.monitor_outlined,
            label: 'System Monitor',
            active: widget.currentPage == SuperAdminPage.systemMonitor,
            onTap: () {
              if (widget.currentPage != SuperAdminPage.systemMonitor) {
                navigateToPage(
                  const SuperAdminShell(
                    currentPage: SuperAdminPage.systemMonitor,
                    child: SystemMonitorPage(),
                  ),
                );
              }
            },
          )
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
    final color = active ? Colors.deepPurple.shade700 : Colors.grey.shade700;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active ? Colors.deepPurple.shade100 : Colors.transparent,
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

class BottomDashboardDrawer extends StatefulWidget {
  const BottomDashboardDrawer({super.key});

  @override
  State<BottomDashboardDrawer> createState() => _BottomDashboardDrawerState();
}

class _BottomDashboardDrawerState extends State<BottomDashboardDrawer>
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
                    child: InkWell(
                      onTap: () {
                        final currentSize = _controller.size;
                        if (currentSize < toggleThreshold) {
                          _controller.animateTo(
                            expandedSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _iconController.forward();
                        } else {
                          _controller.animateTo(
                            initialSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _iconController.reverse();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _iconRotation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _iconRotation.value * 3.14159,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
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
                    child: const DashboardDrawer(),
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
  const DashboardDrawer({super.key});

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
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
                children: [
                  DrawerIcon(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const SuperAdminShell(
                                currentPage: SuperAdminPage.dashboard,
                                child: SuperAdminDashboard(),
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.people,
                    label: 'Users',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              SuperAdminShell(
                                currentPage: SuperAdminPage.users,
                                child: UsersManagementPage(),
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.work,
                    label: 'Projects',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              SuperAdminShell(
                                currentPage: SuperAdminPage.projects,
                                child: ProjectsManagementPage(),
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.history,
                    label: 'Audit Logs',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              SuperAdminShell(
                                currentPage: SuperAdminPage.auditLogs,
                                child: const Auditlogs(),
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.error,
                    label: 'Error Logs',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const SuperAdminShell(
                                currentPage: SuperAdminPage.errorLogs,
                                child: ErrorLogs(),
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  DrawerIcon(
                    icon: Icons.monitor,
                    label: 'System Monitor',
                    iconSize: iconSize,
                    fontSize: fontSize,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const SuperAdminShell(
                                currentPage: SuperAdminPage.systemMonitor,
                                child: SystemMonitorPage(),
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
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