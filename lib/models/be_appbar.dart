// ignore_for_file: unused_field, use_build_context_synchronously
import 'dart:async';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_notification_service.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/services/contractee%20services/cee_checkuser.dart';
import 'package:backend/utils/be_pagetransition.dart';
import 'package:contractee/pages/cee_about.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractee/pages/cee_transaction.dart';
import 'package:contractor/Screen/cor_notification.dart';
import 'package:flutter/material.dart';

class ConTrustAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String headline;
  final List<Widget>? actions;

  const ConTrustAppBar({
    super.key,
    required this.headline,
    this.actions,
  });

  @override
  State<ConTrustAppBar> createState() => _ConTrustAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ConTrustAppBarState extends State<ConTrustAppBar> {
  Timer? _badgeTimer;
  int _unreadCount = 0;
  String? _receiverId;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadReceiverId();
    _loadUserType();
  }

  Future<void> _loadReceiverId() async {
    try {
      String? userType = await UserService().getCurrentUserType();
      String? id;

      if (userType?.toLowerCase() == 'contractee') {
        id = await UserService().getContracteeId();
      } else if (userType?.toLowerCase() == 'contractor') {
        id = await UserService().getContractorId();
      }

      if (id == null || !mounted) return;

      setState(() => _receiverId = id);

      _refreshBadge();

      _badgeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _refreshBadge();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notifications')),
        );
      }
    }
  }

  Future<void> _loadUserType() async {
    try {
      final userType = await UserService().getCurrentUserType();
      if (mounted) {
        setState(() => _userType = userType);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshBadge() async {
    if (_receiverId == null || !mounted) return;

    try {
      final count = await NotificationService().getUnreadCount(_receiverId!);
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _unreadCount = 0);
      }
    }
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.amber,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: (widget.headline == "Home" && _userType?.toLowerCase() == 'contractee')
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  // If the parent Scaffold provides a drawer, open it. Otherwise show a left-side modal
                  final scaffoldState = Scaffold.maybeOf(context);
                  if (scaffoldState != null && scaffoldState.widget.drawer != null) {
                    scaffoldState.openDrawer();
                  } else {
                    _openDrawerFallback(context);
                  }
                },
              ),
            )
          : Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : (_userType?.toLowerCase() == 'contractee')
                  ? Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () {
                          final scaffoldState = Scaffold.maybeOf(context);
                          if (scaffoldState != null && scaffoldState.widget.drawer != null) {
                            scaffoldState.openDrawer();
                          } else {
                            _openDrawerFallback(context);
                          }
                        },
                      ),
                    )
                  : null,
      elevation: 4,
      title: Text(
        widget.headline,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        if (widget.actions != null) ...widget.actions!,
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black),
              onPressed: () async {
                CheckUserLogin.isLoggedIn(
                  context: context,
                  onAuthenticated: () async {
                    if (!context.mounted) return;

                    String? userType = await UserService().getCurrentUserType();

                    if (userType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User type not found')),
                      );
                      return;
                    }

                    if (!context.mounted) return;

                    if (userType.toLowerCase() == 'contractee') {
                      transitionBuilder(context, ContracteeNotificationPage());
                    } else if (userType.toLowerCase() == 'contractor') {
                      transitionBuilder(context, ContractorNotificationPage());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unknown user type')),
                      );
                    }
                  },
                );
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _openDrawerFallback(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.78,
              child: Material(
                color: Theme.of(context).canvasColor,
                elevation: 8,
                child: const MenuDrawerContractee(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) {
        final curved = Curves.easeOut.transform(a1.value);
        return Transform.translate(
          offset: Offset(-200 * (1 - curved), 0),
          child: Opacity(opacity: a1.value, child: child),
        );
      },
    );
  }
}

class MenuDrawerContractee extends StatelessWidget {
  const MenuDrawerContractee({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        drawerTheme: const DrawerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, 
          ),
        ),
      ),
      child: Drawer(
        elevation: 0,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 70,
              color: Colors.yellow[700],
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: const Row(
                children: [
                  Text(""),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blueGrey),
              title: const Text(
                'Home',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 0.5),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.blueGrey),
              title: const Text(
                'Transaction History',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () => transitionBuilder(context, const TransactionPage()),
            ),
            const SizedBox(height: 0.5),
            ListTile(
              leading: const Icon(Icons.work, color: Colors.blueGrey),
              title: const Text(
                'Ongoing',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () async {
                final contracteeId = await UserService().getContracteeId();
                if (contracteeId != null) {
                  final projects = await FetchService().fetchUserProjects();
                  final activeProject = projects.firstWhere(
                    (project) => project['status'] == 'active',
                    orElse: () => {},
                  );
                  if (activeProject.isNotEmpty && context.mounted) {
                    transitionBuilder(
                      context,
                      CeeOngoingProjectScreen(
                        projectId: activeProject['project_id'],
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No active project found')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 0.5),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blueGrey),
              title: const Text(
                'About',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () => transitionBuilder(context, const AboutPage()),
            ),
            const SizedBox(height: 0.5),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () => transitionBuilder(
                context,
                LoginPage()),
              ),
            ],
            ),
          
        )
      );
  }
}