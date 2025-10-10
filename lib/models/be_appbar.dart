// ignore_for_file: unused_field, use_build_context_synchronously
import 'dart:async';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_pagetransition.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_about.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:contractee/pages/cee_materials.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractee/pages/cee_transaction.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';
import 'package:contractor/Screen/cor_notification.dart';
import 'package:flutter/material.dart';
import 'package:backend/build/buildnotification.dart';

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
        ConTrustSnackBar.error(context, 'Failed to load notifications');
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
      ConTrustSnackBar.error(context, 'Error identifying user type.');
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
      backgroundColor: Colors.amber[500],
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: (_userType?.toLowerCase() == 'contractee') ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ) : null,
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
                      if (!context.mounted || _receiverId == null) return;
                      final width = MediaQuery.of(context).size.width;
                      if (width > 1200) {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'Notifications',
                          barrierColor: Colors.black54,
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (ctx, anim1, anim2) {
                            final overlayBuilder = NotificationUIBuildMethods(
                              context: ctx,
                              receiverId: _receiverId!,
                            );
                            return SafeArea(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: 450,
                                  height: 500,
                                  margin: const EdgeInsets.all(16),
                                  child: Material(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Notifications',
                                            style: Theme.of(ctx).textTheme.titleLarge,
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        Flexible(
                                          child: overlayBuilder.buildNotificationList(
                                            NotificationService().listenToNotifications(_receiverId!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        String? userType = _userType?.toLowerCase();
                        if (userType == 'contractee') {
                          transitionBuilder(context, const ContracteeNotificationPage());
                        } else if (userType == 'contractor') {
                          transitionBuilder(context, const ContractorNotificationPage());
                        } else {
                          ConTrustSnackBar.error(context, 'Unknown user type');
                        }
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
}

class MenuDrawerContractee extends StatelessWidget {
  const MenuDrawerContractee({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber),
            child: Text(
              '',
              style: TextStyle(
                color: Colors.black,
                fontSize: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blueGrey),
            title: const Text(
              'Home',
              style: TextStyle(
                fontSize: 18,
              ),
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
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            onTap: () => transitionBuilder(context, const TransactionPage()),
          ),
          const SizedBox(height: 0.5),
          ListTile(
            leading: const Icon(Icons.handyman, color: Colors.blueGrey),
            title: const Text(
              'Materials',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            onTap: () => transitionBuilder(context, const Buildingmaterial()),
          ),
          const SizedBox(height: 0.5),
          ListTile(
            leading: const Icon(Icons.work, color: Colors.blueGrey),
            title: const Text(
              'Ongoing',
              style: TextStyle(
                fontSize: 18,
              ),
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
                        projectId: activeProject['project_id']),
                  );
                } else if (context.mounted) {
                  ConTrustSnackBar.projectError(context);
                }
              }
            },
          ),
          const SizedBox(height: 0.5),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blueGrey),
            title: const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            onTap: () => transitionBuilder(context, const AboutPage()),
          ),
          const SizedBox(height: 0.5),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            onTap: () => transitionBuilder(
                context,
                LoginPage(
                  modalContext: context,
                )),
          ),
        ],
      ),
    );
  }
}
