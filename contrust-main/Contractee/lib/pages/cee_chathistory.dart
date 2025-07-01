import 'package:backend/models/be_appbar.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:contractee/pages/cee_messages.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContracteeChatHistoryPage extends StatefulWidget {
  const ContracteeChatHistoryPage({super.key});

  @override
  State<ContracteeChatHistoryPage> createState() => _ContracteeChatHistoryPageState();
}

class _ContracteeChatHistoryPageState extends State<ContracteeChatHistoryPage> {
  final supabase = Supabase.instance.client;

  String? contracteeId;

  @override
  void initState() {
    super.initState();
    _loadContracteeId();
  }

  Future<void> _loadContracteeId() async {
    setState(() {
      contracteeId = supabase.auth.currentUser?.id;
    });
  }

  Future<Map<String, dynamic>?> loadContractorData(String contractorId) async {
    final response = await supabase
        .from('Contractor')
        .select('firm_name, profile_photo')
        .eq('contractor_id', contractorId)
        .single();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Chat History"),
      drawer: const MenuDrawerContractee(),
      body: contracteeId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('ChatRoom')
                  .stream(primaryKey: ['chatroom_id'])
                  .eq('contractee_id', contracteeId as Object)
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
                          future: loadContractorData(contractorId),
                          builder: (context, snapshot) {
                            final contractorName =
                                snapshot.data?['firm_name'] ?? 'Contractor';
                            final contractorProfile =
                                snapshot.data?['profile_photo'];
                            final lastMessage = chat['last_message'] ?? '';
                            final lastTime = chat['last_message_time'] != null
                                ? DateTime.tryParse(chat['last_message_time'])
                                : null;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  contractorProfile ??
                                      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                ),
                              ),
                              title: Text(contractorName),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: lastTime != null
                                  ? Text(
                                      "${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    )
                                  : null,
                              enabled: canChat,
                              onTap: canChat
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MessagePageContractee(
                                            chatRoomId: chat['chatroom_id'],
                                            contracteeId: contracteeId!,
                                            contractorId: contractorId,
                                            contractorName: contractorName,
                                            contractorProfile: contractorProfile,
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
