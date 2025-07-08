// ignore_for_file: unused_field
import 'dart:async';
import 'package:backend/services/be_notification_service.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:backend/utils/be_pagetransition.dart';
import 'package:contractee/pages/cee_about.dart';
import 'package:contractee/pages/cee_materials.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractee/pages/cee_transaction.dart';
import 'package:contractee/services/cee_checkuser.dart';
import 'package:contractor/Screen/cor_chathistory.dart';
import 'package:contractor/Screen/cor_clienthistory.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
import 'package:contractor/Screen/cor_notification.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
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
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSub;
  int _unreadCount = 0;
  String? _receiverId;

  @override
  void initState() {
    super.initState();
    _loadReceiverId();
  }

  Future<void> _loadReceiverId() async {
    try {
      final id = await UserService().getContracteeId();
      if (id == null || !mounted) return;

      setState(() => _receiverId = id);
      _initializeNotifications(id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load notifications')),
      );
    }
  }

  void _initializeNotifications(String receiverId) {
    _notificationSub = NotificationService().listenToNotifications(receiverId).listen((notifs) {
      if (mounted) {
        setState(() {
          _unreadCount = notifs.where((n) => n['is_read'] == false).length;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.amber,
      centerTitle: true,
      automaticallyImplyLeading: true,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
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
            decoration: BoxDecoration(color: Colors.yellow),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Transaction History'),
            onTap: () => transitionBuilder(context, const TransactionPage()),
          ),
          ListTile(
            leading: const Icon(Icons.handyman),
            title: const Text('Materials'),
            onTap: () => transitionBuilder(context, const Buildingmaterial()),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () => transitionBuilder(context, const AboutPage()),
          ),
        ],
      ),
    );
  }
}

class MenuDrawerContractor extends StatelessWidget {

  final String contractorId; 

  const MenuDrawerContractor({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
            child: const Text(
              'Contractor Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              transitionBuilder(context, ContractorChatHistoryPage());
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Contract Types'),
            onTap: () {
              transitionBuilder(context, ContractType(contractorId: contractorId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Ongoing Projects'),
            onTap: () {
              transitionBuilder(context, OngoingProjectScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Client History'),
            onTap: () {
              transitionBuilder(context, ClientHistoryScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              transitionBuilder(context, ContractorNotificationPage());
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
            },
          ),
        ],
      ),
    );
  }
}