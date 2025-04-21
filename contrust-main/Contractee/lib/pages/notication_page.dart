import 'package:backend/appbar.dart';
import 'package:backend/notification.dart';
import 'package:backend/pagetransition.dart';
import 'package:contractee/pages/buildingmaterial_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class NotificationPage extends StatefulWidget {
  final String receiverId;
  
  const NotificationPage({
    super.key,
    required this.receiverId,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationConTrust notif = NotificationConTrust();
  final SupabaseClient supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _notificationsStream;
  bool _showUnreadOnly = false;

 @override
  void initState() {
    super.initState();
    _initializeNotifications();
    print('Current user: ${Supabase.instance.client.auth.currentUser}');
    print('Receiver ID: ${widget.receiverId}');
    print('Context mounted: ${context.mounted}');
  }

  Future<void> _initializeNotifications() async {
    try {
      _notificationsStream = notif.listenNotification(widget.receiverId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConTrustAppBar(headline: 'Notifications'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildFilterChip('All', !_showUnreadOnly),
                const SizedBox(width: 8),
                _buildFilterChip('Unread', _showUnreadOnly),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data ?? [];
                final filteredNotifications = _showUnreadOnly
                    ? notifications.where((n) => n['is_read'] == false).toList()
                    : notifications;

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Text(
                      _showUnreadOnly 
                          ? 'No unread notifications'
                          : 'No notifications yet',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _showUnreadOnly = label == 'Unread';
        });
      },
    );
  }

 Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final createdAt = DateTime.parse(notification['created_at']);
    final senderId = notification['sender_id']?.toString() ?? ''; 
    final notificationType = notification['type'] ?? 'general';
    final extraData = notification['extra_data'] ?? {};

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchContractorData(senderId),
      builder: (context, snapshot) {
        final contractorData = snapshot.data ?? {};
        final bidAmount = extraData['bid_amount'] != null 
            ? ' (₱${NumberFormat().format(extraData['bid_amount'])}' 
            : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              contractorData['profile_photo']?.toString() ?? 'https://via.placeholder.com/150',
            ),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: contractorData['firm_name']?.toString() ?? 'Unknown contractor',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' ${notification['message']}$bidAmount'),
              ],
            ),
          ),
          subtitle: Text(
            DateFormat('MMM d, y').format(createdAt), 
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: _getNotificationIcon(notificationType),
          tileColor: isRead ? null : Colors.blue[50],
          onTap: () => _handleNotification(notification, isRead),
        );
      },
    );
  }

  Future<void> _handleNotification(
    Map<String, dynamic> notification, 
    bool isRead
  ) async {
    try {
      if (!isRead) {
        await notif.readNotification(notification['notification_id'].toString());
      }
      _handleNotificationTap(notification);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
Future<Map<String, dynamic>?> _fetchContractorData(String contractorId) async {
  try {
    final response = await supabase
        .from('Contractor')
        .select('firm_name, profile_photo')
        .eq('contractor_id', contractorId)
        .single();
    return response;
  } catch (e) {
    return null;
  }
}

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'bid_placed':
        return const Icon(Icons.money, color: Colors.blue);
      default:
        return const Icon(Icons.notifications);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];

    switch (type) {
      case 'bid_placed':
        transitionBuilder(context, Buildingmaterial());
        break;
      default:
        break;
    }
  }
}