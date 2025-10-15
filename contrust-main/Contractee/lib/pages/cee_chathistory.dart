// ignore_for_file: depend_on_referenced_packages

import 'package:backend/utils/be_constraint.dart';
import 'package:backend/build/buildmessage.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:contractee/pages/cee_messages.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ContracteeChatHistoryPage extends StatefulWidget {
  const ContracteeChatHistoryPage({super.key});

  @override
  _ContracteeChatHistoryPageState createState() => _ContracteeChatHistoryPageState();
}

class _ContracteeChatHistoryPageState
    extends State<ContracteeChatHistoryPage> {
  final supabase = Supabase.instance.client;
  String? contracteeId;
  String? selectedChatRoomId;
  String? selectedContractorId;
  String? selectedContractorName;
  String? selectedContractorProfile;
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late Future<String?> projectStatus;


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

  void selectChat(String chatRoomId, String contractorId, String contractorName, String? contractorProfile) {
    setState(() {
      selectedChatRoomId = chatRoomId;
      selectedContractorId = contractorId;
      selectedContractorName = contractorName;
      selectedContractorProfile = contractorProfile;
      projectStatus = FetchService().fetchProjectStatus(chatRoomId);
    });
  }

  Future<void> sendMessage() async {
    if (selectedChatRoomId == null || selectedContractorId == null) return;
    
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    await supabase.from('Messages').insert({
      'chatroom_id': selectedChatRoomId,
      'sender_id': contracteeId,
      'receiver_id': selectedContractorId,
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await supabase
        .from('ChatRoom')
        .update({
          'last_message': text,
          'last_message_time': DateTime.now().toIso8601String(),
        })
        .eq('chatroom_id', selectedChatRoomId!);

    messageController.clear();
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<Map<String, dynamic>?> _loadContractorData(
      String contractorId) async {
    final response = await supabase
        .from('Contractor')
        .select('firm_name, profile_photo')
        .eq('contractor_id', contractorId)
        .single();
    return response;
  }

  String formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('hh:mm a').format(time);
  }

   @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (contracteeId == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    final messageUIBuilder = MessageUIBuildMethods(
      context: context,
      supabase: supabase,
      userId: contracteeId,
      userRole: 'contractee',
      chatRoomId: selectedChatRoomId,
      otherUserId: selectedContractorId,
      userName: selectedContractorName,
      userProfile: selectedContractorProfile,
      messageController: messageController,
      scrollController: scrollController,
      projectStatus: selectedChatRoomId != null ? projectStatus : Future.value(null),
      onSelectChat: selectChat,
      onSendMessage: sendMessage,
      onScrollToBottom: scrollToBottom,
    );

    return Scaffold(
      appBar: screenWidth > 1200 ? null : AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text(
          "Messages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: screenWidth > 1200 
        ? Row(
            children: [
              messageUIBuilder.buildChatHistoryUI(),
              messageUIBuilder.buildMessagesUI(),
              messageUIBuilder.buildProjectInfoUI(),
            ],
          )
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
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final chat = chatRooms[index];
                  final contractorId = chat['contractor_id'];
                  final contracteeId = chat['contractee_id'];

                  return FutureBuilder<bool>(
                    future:
                        functionConstraint(contractorId, contracteeId),
                    builder: (context, canChatSnap) {
                      final canChat = canChatSnap.data ?? false;

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _loadContractorData(contractorId),
                        builder: (context, contractorSnap) {
                          final contractorName =
                              contractorSnap.data?['firm_name'] ??
                                  'Contractor';
                          final contractorProfile =
                              contractorSnap.data?['profile_photo'];
                          final lastMessage = chat['last_message'] ?? '';
                          final lastTime = chat['last_message_time'] != null
                              ? DateTime.tryParse(
                                  chat['last_message_time'])
                              : null;

                          return InkWell(
                            onTap: canChat
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MessagePageContractee(
                                          chatRoomId: chat['chatroom_id'],
                                          contracteeId: contracteeId!,
                                          contractorId: contractorId,
                                          contractorName: contractorName,
                                          contractorProfile:
                                              contractorProfile,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    // ignore: deprecated_member_use
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade600,
                                    backgroundImage: NetworkImage(
                                      contractorProfile ??
                                          'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contractorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lastMessage,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatTime(lastTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
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
