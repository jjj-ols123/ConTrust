// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_about.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractee/pages/cee_transaction.dart';
import 'package:flutter/material.dart';

enum ContracteePage {
  home,
  transactions,
  ongoing,
  about,
  notifications
}

class ContracteeShell extends StatelessWidget {
  final ContracteePage currentPage;
  final String contracteeId;
  final Widget child;
  final EdgeInsets? contentPadding;

  const ContracteeShell({
    super.key,
    required this.currentPage,
    required this.contracteeId,
    required this.child,
    this.contentPadding,
  });

  String title() {
    switch (currentPage) {
      case ContracteePage.home:
        return 'Home';
      case ContracteePage.transactions:
        return 'Transaction History';
      case ContracteePage.ongoing:
        return 'Ongoing Projects';
      case ContracteePage.about:
        return 'About';
      case ContracteePage.notifications:
        return 'Notifications';
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
        title: Text(
          title(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: !isDesktop && !Navigator.canPop(context) ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ) : Navigator.canPop(context) ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ) : null,
        backgroundColor: Colors.amber,
        centerTitle: true,
        elevation: 4,
        automaticallyImplyLeading: false,
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
                  height: kToolbarHeight,
                  color: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_outline, color: Colors.amber[700]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contractee',
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                color: Colors.amber[700],
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
                  child: SideDashboardDrawer(
                    contracteeId: contracteeId,
                    currentPage: currentPage,
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[500],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person_outline, color: Colors.amber[700]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contractee',
                                style: TextStyle(
                                  color: Colors.amber[900],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome back!',
                                style: TextStyle(
                                  color: Colors.amber[700],
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

  Future<void> goToOngoing() async {
    if (widget.contracteeId == null) return;
    setState(() => _loadingOngoing = true);

    try {
      final projects = await FetchService().fetchUserProjects();
      final activeProject = projects.firstWhere(
        (project) => project['status'] == 'active',
        orElse: () => {},
      );

      setState(() => _loadingOngoing = false);

      if (activeProject.isEmpty) {
        if (mounted) {
          ConTrustSnackBar.error(context, 'No active project found');
        }
        return;
      }

      if (!mounted) return;

      if (widget.currentPage != ContracteePage.ongoing) {
        navigateToPage(
          ContracteeShell(
            currentPage: ContracteePage.ongoing,
            contracteeId: widget.contracteeId ?? '',
            child: CeeOngoingProjectScreen(
              projectId: activeProject['project_id'],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    
    return Container(
      color: isDesktop ? Colors.white : Colors.amber[50],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SidebarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            active: widget.currentPage == ContracteePage.home,
            onTap: () {
              if (widget.currentPage != ContracteePage.home) {
                navigateToPage(HomePage(contracteeId: widget.contracteeId ?? ''));
              }
            },
          ),
          _SidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            active: widget.currentPage == ContracteePage.transactions,
            onTap: () {
              if (widget.currentPage != ContracteePage.transactions) {
                navigateToPage(
                  ContracteeShell(
                    currentPage: ContracteePage.transactions,
                    contracteeId: widget.contracteeId ?? '',
                    child: const TransactionPage(),
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
            icon: Icons.info_outline,
            label: 'About',
            active: widget.currentPage == ContracteePage.about,
            onTap: () {
              if (widget.currentPage != ContracteePage.about) {
                navigateToPage(
                  ContracteeShell(
                    currentPage: ContracteePage.about,
                    contracteeId: widget.contracteeId ?? '',
                    child: const AboutPage(),
                  ),
                );
              }
            },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final color = active ? Colors.amber.shade700 : Colors.grey.shade700;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active 
              ? (isDesktop ? Colors.amber.shade100 : Colors.white)
              : Colors.transparent,
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
