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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Chat History"),
      body: contractorId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('ChatRoom')
                  .stream(primaryKey: ['chatroom_id'])
                  .eq('contractor_id', contractorId as Object)
                  .order('last_message_time', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chatRooms = snapshot.data!;
                if (chatRooms.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: chatRooms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = chatRooms[index];
                    final contractorId = chat['contractor_id'];
                    final contracteeId = chat['contractee_id'];

                    return FutureBuilder<bool>(
                      future: functionConstraint(contractorId, contracteeId),
                      builder: (context, snapshot) {
                        final canChat = snapshot.data ?? false;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FetchService().fetchContracteeData(contracteeId),
                          builder: (context, snapshot) {
                            final contracteeName = snapshot.data?['full_name'] ?? 'Contractor';
                            final contracteeProfile = snapshot.data?['profile_photo'];
                            final lastMessage = chat['last_message'] ?? '';
                            final lastTime = chat['last_message_time'] != null
                                ? DateTime.tryParse(chat['last_message_time'])
                                : null;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  contracteeProfile ??
                                      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                ),
                              ),
                              title: Text(contracteeName),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: lastTime != null
                                  ? Text(
                                      "${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    )
                                  : null,
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
                                  : null,
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