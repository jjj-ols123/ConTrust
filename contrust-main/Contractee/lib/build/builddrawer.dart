// ignore_for_file: deprecated_member_use

import 'package:backend/build/buildnotification.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_chathistory.dart';
import 'package:contractee/pages/cee_ai_assistant.dart';
import 'package:contractee/pages/cee_profile.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDropdownMenuContractee extends StatefulWidget {
  final String? contracteeId;

  const UserDropdownMenuContractee({super.key, this.contracteeId});

  @override
  State<UserDropdownMenuContractee> createState() => _UserDropdownMenuContracteeState();
}

class _ContracteeBottomNavigationBar extends StatelessWidget {
  final ContracteePage currentPage;
  final VoidCallback onMessagesTap;
  final VoidCallback onAiTap;
  final VoidCallback onOngoingTap;
  final VoidCallback onProfileTap;
  final VoidCallback onHistoryTap;
  final bool isOngoingLoading;

  const _ContracteeBottomNavigationBar({
    required this.currentPage,
    required this.onMessagesTap,
    required this.onAiTap,
    required this.onOngoingTap,
    required this.onProfileTap,
    required this.onHistoryTap,
    required this.isOngoingLoading,
  });

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
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _ContracteeNavItem(
                  icon: Icons.message_outlined,
                  activeIcon: Icons.message,
                  label: 'Messages',
                  isActive: currentPage == ContracteePage.messages,
                  onTap: onMessagesTap,
                ),
              ),
              Expanded(
                child: _ContracteeNavItem(
                  icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy,
                  label: 'AI',
                  isActive: currentPage == ContracteePage.aiAssistant,
                  onTap: onAiTap,
                ),
              ),
              Expanded(
                child: _ContracteeOngoingNavItem(
                  isActive: currentPage == ContracteePage.ongoing,
                  isLoading: isOngoingLoading,
                  onTap: onOngoingTap,
                ),
              ),
              Expanded(
                child: _ContracteeNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: currentPage == ContracteePage.profile,
                  onTap: onProfileTap,
                ),
              ),
              Expanded(
                child: _ContracteeNavItem(
                  icon: Icons.history,
                  activeIcon: Icons.history_toggle_off,
                  label: 'History',
                  isActive: currentPage == ContracteePage.history,
                  onTap: onHistoryTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContracteeNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ContracteeNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
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
                color: isActive ? Colors.amber.shade100 : Colors.grey.shade200,
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

class _ContracteeOngoingNavItem extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _ContracteeOngoingNavItem({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [Colors.amber.shade700, Colors.amber.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.amber.shade200,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isActive ? Colors.white : Colors.amber.shade700,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.work_outline,
                      color: isActive ? Colors.white : Colors.amber.shade700,
                      size: 22,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ongoing',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDropdownMenuContracteeState extends State<UserDropdownMenuContractee> {
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.userMetadata?['full_name'] ?? 'Contractee';
          _userEmail = user.email ?? '';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _logout() async {
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
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ConTrustSnackBar.error(context, 'Error logging out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50), // Offset to position below the button
      onSelected: (value) {
        if (value == 'logout') {
          _logout();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName ?? 'Contractee',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: const AssetImage('assets/defaultpic.png'),
              child: _userName == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
            ),
            const SizedBox(width: 8),
            Text(
              _userName ?? 'Contractee',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.black,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

enum ContracteePage {
  home,
  ongoing,
  profile,
  notifications,
  messages,
  chatHistory,
  aiAssistant,
  history
}

class ContracteeShell extends StatefulWidget {
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

  @override
  State<ContracteeShell> createState() => _ContracteeShellState();
}

class _ContracteeShellState extends State<ContracteeShell> {
  late final List<Widget> _persistentPages;
  final FetchService _fetchService = FetchService();
  bool _isBottomNavOngoingLoading = false;

  @override
  void initState() {
    super.initState();
    _persistentPages = [
      const HomePage(),
      const ContracteeChatHistoryPage(),
      const ContracteeNotificationPage(),
      const AiAssistantPage(),
      CeeProfilePage(contracteeId: widget.contracteeId ?? ''),
    ];
  }

  int _indexFor(ContracteePage page) {
    switch (page) {
      case ContracteePage.home:
        return 0;
      case ContracteePage.messages:
        return 1;
      case ContracteePage.notifications:
        return 2;
      case ContracteePage.aiAssistant:
        return 3;
      case ContracteePage.profile:
        return 4;
      case ContracteePage.ongoing:
        return 0; // not used for stack
      case ContracteePage.chatHistory:
        return 1;
      case ContracteePage.history:
        return 0; // not used for stack, handled separately
    }
  }

  void _navigateToMessages() {
    if (widget.currentPage != ContracteePage.messages) {
      context.go('/messages');
    }
  }

  void _navigateToAiAssistant() {
    if (widget.currentPage != ContracteePage.aiAssistant) {
      context.go('/ai-assistant');
    }
  }

  void _navigateToProfile() {
    if (widget.currentPage != ContracteePage.profile) {
      context.go('/profile');
    }
  }

  void _navigateToHistory() {
    if (widget.currentPage != ContracteePage.history) {
      context.go('/history');
    }
  }

  void _handleDesktopNavigation(ContracteePage page) {
    switch (page) {
      case ContracteePage.home:
        if (widget.currentPage != ContracteePage.home) {
          context.go('/home');
        }
        break;
      case ContracteePage.messages:
        _navigateToMessages();
        break;
      case ContracteePage.aiAssistant:
        _navigateToAiAssistant();
        break;
      case ContracteePage.profile:
        _navigateToProfile();
        break;
      case ContracteePage.history:
        _navigateToHistory();
        break;
      case ContracteePage.ongoing:
      case ContracteePage.notifications:
      case ContracteePage.chatHistory:
        // Handled separately
        break;
    }
  }

  Future<void> _handleDesktopOngoingTap() {
    return _handleBottomNavOngoingTap();
  }

  Future<void> _handleBottomNavOngoingTap() async {
    if (_isBottomNavOngoingLoading) return;

    setState(() => _isBottomNavOngoingLoading = true);

    try {
      final projectsData = await _fetchService.fetchUserProjects();
      final projectsList = projectsData is List ? projectsData : <dynamic>[];
      final activeProjects = <Map<String, dynamic>>[];

      for (final project in projectsList) {
        if (project is Map<String, dynamic>) {
          final status = project['status']?.toString().toLowerCase();
          if (status == 'active') {
            activeProjects.add(project);
          }
        }
      }

      if (!mounted) return;

      if (activeProjects.isEmpty) {
        ConTrustSnackBar.infoToast(context, 'No active project found');
        return;
      }

      if (activeProjects.length == 1) {
        final projectId = activeProjects.first['project_id']?.toString();
        if (projectId != null && widget.currentPage != ContracteePage.ongoing) {
          context.go('/ongoing/$projectId');
        }
        return;
      }

      final selectedProjectId = await _showActiveProjectPicker(activeProjects);
      if (selectedProjectId != null && mounted) {
        context.go('/ongoing/$selectedProjectId');
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading ongoing project');
      }
    } finally {
      if (mounted) {
        setState(() => _isBottomNavOngoingLoading = false);
      } else {
        _isBottomNavOngoingLoading = false;
      }
    }
  }

  Future<String?> _showActiveProjectPicker(List<Map<String, dynamic>> projects) async {
    if (!mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Select Active Project',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final title = project['title']?.toString() ?? 'Untitled Project';
                        final location = project['location']?.toString();
                        final projectId = project['project_id']?.toString();

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.work_outline, color: Colors.amber.shade700),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: location != null && location.isNotEmpty
                                ? Text(location, style: const TextStyle(fontSize: 12))
                                : null,
                            trailing: Icon(Icons.chevron_right, color: Colors.amber.shade700),
                            onTap: projectId == null
                                ? null
                                : () => Navigator.of(context).pop(projectId),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String title() {
    switch (widget.currentPage) {
      case ContracteePage.home:
        return 'Home';
      case ContracteePage.ongoing:
        return 'Project';
      case ContracteePage.profile:
        return 'Profile';
      case ContracteePage.notifications:
        return 'Notifications';
      case ContracteePage.messages:
        return 'Messages';
      case ContracteePage.chatHistory:
        return 'Chat History';
      case ContracteePage.aiAssistant:
        return 'AI Assistant';
      case ContracteePage.history:
        return 'History';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final showBranding = screenWidth >= 700;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.amber,
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.black),
                tooltip: 'Home',
                onPressed: () {
                  if (widget.currentPage != ContracteePage.home) {
                    context.go('/home');
                  }
                },
              ),
              if (showBranding) ...[
                Container(
                  height: 32,
                  width: 32,
                  margin: const EdgeInsets.only(left: 8),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.business, color: Colors.black, size: 24);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 8),
                  child: const Text(
                    'ConTrust',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            UserDropdownMenuContractee(contracteeId: widget.contracteeId),
            const NotificationButton(),
          ],
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
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(3, 0),
                          ),
                        ],
                      ),
                      child: _DesktopDrawerContent(
                        contracteeId: widget.contracteeId,
                        currentPage: widget.currentPage,
                        onNavigate: _handleDesktopNavigation,
                        onOngoingTap: _handleDesktopOngoingTap,
                        isOngoingLoading: _isBottomNavOngoingLoading,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: widget.contentPadding ?? EdgeInsets.zero,
                      child: widget.currentPage == ContracteePage.ongoing ||
                              widget.currentPage == ContracteePage.history ||
                              GoRouter.of(context).routerDelegate.currentConfiguration.uri.path.startsWith('/contractor')
                          ? widget.child
                          : IndexedStack(
                              index: _indexFor(widget.currentPage),
                              children: _persistentPages,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isDesktop)
              _ContracteeBottomNavigationBar(
                currentPage: widget.currentPage,
                onMessagesTap: _navigateToMessages,
                onAiTap: _navigateToAiAssistant,
                onOngoingTap: _handleBottomNavOngoingTap,
                onProfileTap: _navigateToProfile,
                onHistoryTap: _navigateToHistory,
                isOngoingLoading: _isBottomNavOngoingLoading,
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopDrawerContent extends StatelessWidget {
  final String? contracteeId;
  final ContracteePage currentPage;
  final void Function(ContracteePage page) onNavigate;
  final Future<void> Function() onOngoingTap;
  final bool isOngoingLoading;

  const _DesktopDrawerContent({
    required this.contracteeId,
    required this.currentPage,
    required this.onNavigate,
    required this.onOngoingTap,
    required this.isOngoingLoading,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final isContractorPage = currentPath.startsWith('/contractor');

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SidebarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            active: currentPage == ContracteePage.home && !isContractorPage,
            onTap: () => onNavigate(ContracteePage.home),
          ),
          _SidebarItem(
            icon: Icons.message_outlined,
            label: 'Messages',
            active: currentPage == ContracteePage.messages,
            onTap: () => onNavigate(ContracteePage.messages),
          ),
          _SidebarItem(
            icon: Icons.work_outline,
            label: isOngoingLoading ? 'Loading...' : 'Project Overview',
            active: currentPage == ContracteePage.ongoing && !isContractorPage,
            onTap: isOngoingLoading ? null : onOngoingTap,
          ),
          _SidebarItem(
            icon: Icons.smart_toy_outlined,
            label: 'AI Assistant',
            active: currentPage == ContracteePage.aiAssistant,
            onTap: () => onNavigate(ContracteePage.aiAssistant),
          ),
          _SidebarItem(
            icon: Icons.person,
            label: 'Profile',
            active: currentPage == ContracteePage.profile,
            onTap: () => onNavigate(ContracteePage.profile),
          ),
          _SidebarItem(
            icon: Icons.history,
            label: 'History',
            active: currentPage == ContracteePage.history,
            onTap: () => onNavigate(ContracteePage.history),
          ),
          const Divider(),
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