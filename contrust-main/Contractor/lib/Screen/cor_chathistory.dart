import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:contractor/Screen/cor_messages.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractorChatHistoryPage extends StatefulWidget {
  const ContractorChatHistoryPage({super.key, String? contractorId});

  @override
  State<ContractorChatHistoryPage> createState() => _ContractorChatHistoryPageState();
}

class _ContractorChatHistoryPageState extends State<ContractorChatHistoryPage> {
  final supabase = Supabase.instance.client;
  String? contractorId;

  @override
  void initState() {
    super.initState();
    _loadContractorId();
  }

  Future<void> _loadContractorId() async {
    final id = await UserService().getContractorId();
    setState(() {
      contractorId = id;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation by accepting a project\nor wait for clients to message you',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Loading your messages...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Chat History"),
      body: contractorId == null
          ? _buildLoadingState()
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('ChatRoom')
                  .stream(primaryKey: ['chatroom_id'])
                  .eq('contractor_id', contractorId as Object)
                  .order('last_message_time', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final chatRooms = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chatRooms.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chatRooms[index];
                    final contractorId = chat['contractor_id'];
                    final contracteeId = chat['contractee_id'];

                    return FutureBuilder<bool>(
                      future: functionConstraint(contractorId, contracteeId),
                      builder: (context, constraintSnapshot) {
                        final canChat = constraintSnapshot.data ?? false;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FetchService().fetchContracteeData(contracteeId),
                          builder: (context, dataSnapshot) {
                            final contracteeName = dataSnapshot.data?['full_name'] ?? 'Client';
                            final contracteeProfile = dataSnapshot.data?['profile_photo'];
                            final lastMessage = chat['last_message'] ?? 'No messages yet';
                            final lastTime = chat['last_message_time'] != null
                                ? DateTime.tryParse(chat['last_message_time'])
                                : null;

                            return Container(
                              color: canChat ? Colors.transparent : Colors.grey.shade50,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: NetworkImage(
                                        contracteeProfile ??
                                            'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                      ),
                                    ),
                                    if (!canChat)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.block,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  contracteeName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: canChat ? Colors.black : Colors.grey,
                                  ),
                                ),
                                subtitle: Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: canChat ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (lastTime != null)
                                      Text(
                                        "${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: canChat ? Colors.grey : Colors.grey.shade400,
                                        ),
                                      ),
                                    if (!canChat)
                                      const SizedBox(height: 4),
                                    if (!canChat)
                                      Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                  ],
                                ),
                                enabled: canChat,
                                onTap: canChat
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MessagePageContractor(
                                              chatRoomId: chat['chatroom_id'],
                                              contractorId: contractorId!,
                                              contracteeId: contracteeId,
                                              contracteeName: contracteeName,
                                              contracteeProfile: contracteeProfile,
                                            ),
                                          ),
                                        );
                                      }
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Chat is not available for this conversation'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}