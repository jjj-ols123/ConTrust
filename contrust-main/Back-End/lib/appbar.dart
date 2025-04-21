import 'dart:async';
import 'package:contractee/blocs/checkuseracc.dart';
import 'package:contractee/pages/about_page.dart';
import 'package:contractee/pages/buildingmaterial_page.dart';
import 'package:contractee/pages/transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:backend/getuserid.dart';
import 'package:backend/notification.dart';
import 'package:backend/pagetransition.dart';
import 'package:contractee/pages/notication_page.dart';

class ConTrustAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String headline;

  const ConTrustAppBar({
    super.key,
    required this.headline,
  });

  @override
  State<ConTrustAppBar> createState() => _ConTrustAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ConTrustAppBarState extends State<ConTrustAppBar> {
  // ignore: unused_field
  late StreamSubscription<List<Map<String, dynamic>>> _notificationSub;
  final NotificationConTrust notif = NotificationConTrust();
  final GetUserId getUserId = GetUserId();
  int _unreadCount = 0;
  String? _receiverId;

  @override
  void initState() {
    super.initState();
    _loadReceiverId();
  }

  Future<void> _loadReceiverId() async {
    try {
      final id = await getUserId.getContractreeId();
      if (id == null || !mounted) return;

      setState(() => _receiverId = id);
      _initializeNotifications(id);
    } catch (e) {
      debugPrint('Error loading receiver ID: $e');
    }
  }

  void _initializeNotifications(String receiverId) {
    _notificationSub = notif.listenNotification(receiverId).listen((notifs) {
      if (mounted) {
        setState(() {
          _unreadCount = notifs.where((n) => n['is_read'] == false).length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.amber,
      centerTitle: true,
      title: Text(
        widget.headline,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                CheckUserLogin.isLoggedIn(
                    context: context,
                    onAuthenticated: () async {
                      
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationPage(
                            receiverId: _receiverId!,
                          ),
                        ),
                      );
                    });
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Image.asset(
            'logo.png',
            width: 100,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

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
