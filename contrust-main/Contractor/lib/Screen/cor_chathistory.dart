import 'dart:async';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/build/buildmessage.dart';
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
  String? selectedChatRoomId;
  String? selectedContracteeId;
  String? selectedContracteeName;
  String? selectedContracteeProfile;
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late Future<String?> projectStatus;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    loadContractorId();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && selectedChatRoomId != null) {
        setState(() {
          projectStatus = FetchService().fetchProjectStatus(selectedChatRoomId!);
        });
      }
    });
  }
  
  @override
  void dispose() {
    _pollingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadContractorId() async {
    final id = await UserService().getContractorId();
    setState(() {
      contractorId = id;
    });
  }

  void selectChat(String chatRoomId, String contracteeId, String contracteeName, String? contracteeProfile) {
    setState(() {
      selectedChatRoomId = chatRoomId;
      selectedContracteeId = contracteeId;
      selectedContracteeName = contracteeName;
      selectedContracteeProfile = contracteeProfile;
      projectStatus = FetchService().fetchProjectStatus(chatRoomId);
    });
  }

  Future<void> sendMessage() async {
    if (selectedChatRoomId == null || selectedContracteeId == null) return;
    
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    await supabase.from('Messages').insert({
      'chatroom_id': selectedChatRoomId,
      'sender_id': contractorId,
      'receiver_id': selectedContracteeId,
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

  Future<Map<String, dynamic>?> _loadContracteeData(
      String contracteeId) async {
    return await MessageService().fetchContracteeData(contracteeId);
  }

  String formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (contractorId == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final messageUIBuilder = MessageUIBuildMethods(
      context: context,
      supabase: supabase,
      userId: contractorId,
      userRole: 'contractor',
      chatRoomId: selectedChatRoomId,
      otherUserId: selectedContracteeId,
      userName: selectedContracteeName,
      userProfile: selectedContracteeProfile,
      messageController: messageController,
      scrollController: scrollController,
      projectStatus: selectedChatRoomId != null ? projectStatus : Future.value(null),
      onSelectChat: selectChat,
      onSendMessage: sendMessage,
      onScrollToBottom: scrollToBottom,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: screenWidth > 1200 
        ? Row(
        children: [
          messageUIBuilder.buildChatHistoryUI(),
          messageUIBuilder.buildMessagesUI(),
              messageUIBuilder.buildProjectInfoUI(),
            ],
          )
        : Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chat History',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('ChatRoom')
                      .stream(primaryKey: ['chatroom_id'])
                      .eq('contractor_id', contractorId!)
                      .order('last_message_time', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final chats = snapshot.data ?? [];

                    if (chats.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start chatting with your clients',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final contracteeId = chat['contractee_id'] as String;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _loadContracteeData(contracteeId),
                          builder: (context, contracteeSnap) {
                            final contracteeName = contracteeSnap.data != null
                                ? contracteeSnap.data!['full_name'] ?? 'Contractee'
                                : 'Contractee';
                            final contracteeProfile = contracteeSnap.data?['profile_photo'];
                            final lastMessage = chat['last_message'] ?? '';
                            final lastTime = chat['last_message_time'] != null
                                ? DateTime.tryParse(chat['last_message_time'])
                                : null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
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
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.amber[100],
                                        backgroundImage: contracteeProfile != null
                                            ? NetworkImage(contracteeProfile)
                                            : null,
                                        child: contracteeProfile == null
                                            ? Icon(
                                                Icons.person,
                                                color: Colors.amber[700],
                                                size: 24,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              contracteeName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMessage,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (lastTime != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          formatTime(lastTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}