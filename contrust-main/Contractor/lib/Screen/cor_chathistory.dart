import 'dart:async';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/build/buildmessage.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool isSending = false;
  
  final Map<String, Map<String, dynamic>> _contracteeDataCache = {};
  final Map<String, int> _unreadCountCache = {};

  Future<void>? batchFuture;
  String? _batchKey;
  List<Map<String, dynamic>> _lastChatsSnapshot = const [];

  @override
  void initState() {
    super.initState();
    loadContractorId();
  }
  
  @override
  void dispose() {
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
    
    if (contractorId != null) {
      MessageService().markMessagesAsRead(
        chatRoomId: chatRoomId,
        userId: contractorId!,
      );
    }
  }

  Future<void> sendMessage() async {
    if (selectedChatRoomId == null || selectedContracteeId == null || isSending) return;
    
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);
    
    try {
      await supabase.from('Messages').insert({
        'chatroom_id': selectedChatRoomId,
        'sender_id': contractorId,
        'receiver_id': selectedContracteeId,
        'message': text,
        'timestamp': DateTimeHelper.getLocalTimeISOString(),
      });

      await supabase
          .from('ChatRoom')
          .update({
            'last_message': text,
            'last_message_time': DateTimeHelper.getLocalTimeISOString(),
          })
          .eq('chatroom_id', selectedChatRoomId!);

      messageController.clear();
      scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
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

  Future<void> _prefetchChatData(List<Map<String, dynamic>> chats, String userId) async {
    final contracteeIds = chats.map((chat) => chat['contractee_id'] as String).toSet().toList();
    final chatRoomIds = chats.map((chat) => chat['chatroom_id'] as String).toList();

    final futures = contracteeIds.map((id) => 
      MessageService().fetchContracteeData(id).then((data) => MapEntry(id, data))
    );
    final contracteeResults = await Future.wait(futures);
    

    for (final entry in contracteeResults) {
      if (entry.value != null) {
        _contracteeDataCache[entry.key] = entry.value!;
      }
    }

    final unreadFutures = chatRoomIds.map((chatRoomId) =>
      MessageService().getUnreadMessageCount(chatRoomId: chatRoomId, userId: userId)
        .then((count) => MapEntry(chatRoomId, count))
    );
    final unreadResults = await Future.wait(unreadFutures);
 
    for (final entry in unreadResults) {
      _unreadCountCache[entry.key] = entry.value;
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _computeBatchKey(List<Map<String, dynamic>> chats) {
    final parts = chats.map((c) => '${c['chatroom_id']}:${c['last_message_time'] ?? ''}').join('|');
    return parts;
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
      isSending: isSending,
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
              const SizedBox.shrink(),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('ChatRoom')
                      .stream(primaryKey: ['chatroom_id'])
                      .eq('contractor_id', contractorId!)
                      .order('last_message_time', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    // Show loading while waiting for initial data
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }

                    final incomingChats = snapshot.data ?? [];
                    final newKey = _computeBatchKey(incomingChats);
                    if (incomingChats.isNotEmpty && contractorId != null && newKey != _batchKey) {
                      _batchKey = newKey;
                      _lastChatsSnapshot = incomingChats;
                      batchFuture = _prefetchChatData(incomingChats, contractorId!);
                    }

                    final chats = (snapshot.connectionState == ConnectionState.waiting && _lastChatsSnapshot.isNotEmpty)
                        ? _lastChatsSnapshot
                        : incomingChats;

                    // Show empty state only after data has been received
                    if (snapshot.hasData && chats.isEmpty) {
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
                    
                    // If still no data but connection is active, show loading
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final contracteeId = chat['contractee_id'] as String;
                        final chatRoomId = chat['chatroom_id'] as String;

                        final contracteeData = _contracteeDataCache[contracteeId];
                        final contracteeName = contracteeData != null
                            ? contracteeData['full_name'] ?? 'Contractee'
                            : 'Contractee';
                        final contracteeProfile = contracteeData?['profile_photo'];
                        final lastMessage = chat['last_message'] ?? '';
                        final lastTime = chat['last_message_time'] != null
                            ? (() {
                                final parsed = DateTime.tryParse(chat['last_message_time']);
                                if (parsed == null) return null;
                                // Convert to local time if it's UTC
                                return parsed.isUtc ? parsed.toLocal() : parsed;
                              })()
                            : null;
                        final unreadCount = _unreadCountCache[chatRoomId] ?? 0;
                        final hasUnread = unreadCount > 0;

                        return Card(
                          key: ValueKey(chatRoomId),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                                    onTap: () {
                                      context.go('/chat/${Uri.encodeComponent(contracteeName)}', extra: {
                                        'chatRoomId': chat['chatroom_id'],
                                        'contractorId': contractorId,
                                        'contracteeId': contracteeId,
                                        'contracteeProfile': contracteeProfile,
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              ClipOval(
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: Colors.amber[100],
                                                  child: Image.network(
                                                  (contracteeProfile != null && contracteeProfile.isNotEmpty)
                                                      ? contracteeProfile
                                                      : 'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image(
                                                        image: const AssetImage('assets/images/defaultpic.png'),
                                                        width: 48,
                                                        height: 48,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: Colors.amber[100],
                                                            child: Icon(Icons.person, size: 24, color: Colors.grey.shade600),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              if (hasUnread)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 16,
                                                      minHeight: 16,
                                                    ),
                                                    child: Text(
                                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contracteeName,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                                    color: hasUnread ? Colors.black : Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  lastMessage,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: hasUnread ? Colors.black87 : Colors.grey[600],
                                                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
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
                ),
              ),
        ],
      ),
    );
  }
}