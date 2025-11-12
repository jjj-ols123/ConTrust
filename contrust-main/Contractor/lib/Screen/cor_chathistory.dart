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

  String selectedTab = 'Active'; 
  bool isFiltering = false;
  Map<String, String>? _cachedProjectStatuses; 
  String? _cachedStatusKey; 

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
      selectedTab: selectedTab,
      onTabChanged: (tab) {
        setState(() {
          selectedTab = tab;
          isFiltering = true; // Show loading immediately
        });
        
        // Fallback: Clear loading state after 10 seconds to prevent infinite loading
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && isFiltering) {
            setState(() => isFiltering = false);
          }
        });
      },
      isFiltering: isFiltering,
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
              // Add tabs for mobile
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('Active', selectedTab == 'Active'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton('Archived', selectedTab == 'Archived'),
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

                    // Filter chats based on selected tab
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _filterChatsByStatus(chats, selectedTab),
                      builder: (context, filterSnapshot) {
                        if (filterSnapshot.connectionState == ConnectionState.waiting) {
                          // Still filtering, show loading
                          return const Center(child: CircularProgressIndicator(color: Colors.amber));
                        }

                        // Filtering complete, clear loading state
                        if (isFiltering) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => isFiltering = false);
                            }
                          });
                        }

                        final filteredChats = filterSnapshot.data ?? [];

                        // Show empty state only after data has been received
                        if (snapshot.hasData && filteredChats.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selectedTab == 'Active' ? Icons.chat_bubble_outline : Icons.archive_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  selectedTab == 'Active' ? 'No active conversations' : 'No archived conversations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  selectedTab == 'Active' 
                                      ? 'Start chatting with your clients' 
                                      : 'Completed and cancelled projects appear here',
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
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
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
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  String _computeStatusCacheKey(List<Map<String, dynamic>> chats) {
    final buffer = StringBuffer();
    for (final chat in chats) {
      final id = chat['chatroom_id']?.toString() ?? '';
      final ts = chat['last_message_time']?.toString() ?? '';
      buffer.write(id);
      buffer.write('|');
      buffer.write(ts);
      buffer.write(';');
    }
    return buffer.toString();
  }

  Future<Map<String, String>> _batchFetchProjectStatuses(List<String> chatRoomIds) async {
    if (chatRoomIds.isEmpty) return {};

    try {
      final response = await supabase
          .from('ChatRoom')
          .select('''
            chatroom_id,
            project:Projects(status)
          ''')
          .inFilter('chatroom_id', chatRoomIds);

      final Map<String, String> statusMap = {};
      for (var chat in response) {
        final chatRoomId = chat['chatroom_id'] as String?;
        final project = chat['project'];
        final status = project?['status'] as String?;
        if (chatRoomId != null && status != null) {
          statusMap[chatRoomId] = status;
        }
      }
      return statusMap;
    } catch (e) {
      debugPrint('Error batch fetching project statuses: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _filterChatsByStatus(List<Map<String, dynamic>> chats, String tab) async {
    if (chats.isEmpty) return [];

    final currentKey = _computeStatusCacheKey(chats);

    // Use cached statuses if available and cache key matches
    Map<String, String> statusMap;
    if (_cachedProjectStatuses != null && _cachedStatusKey == currentKey) {
      statusMap = _cachedProjectStatuses!;
    } else {
      // Fetch new statuses and cache them
      final chatRoomIds = chats
          .map((chat) => chat['chatroom_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      statusMap = await _batchFetchProjectStatuses(chatRoomIds);
      _cachedProjectStatuses = statusMap;
      _cachedStatusKey = currentKey;
    }

    List<Map<String, dynamic>> filteredChats = [];

    for (final chat in chats) {
      final chatRoomId = chat['chatroom_id'] as String?;
      if (chatRoomId == null) continue;

      final projectStatus = statusMap[chatRoomId] ?? 'unknown';

      bool shouldInclude = false;

      if (tab == 'Active') {
        // Active chats: show all except confirmed cancelled or completed
        shouldInclude = projectStatus != 'cancelled' && projectStatus != 'completed';
      } else {
        // Archived chats: only confirmed cancelled or completed
        shouldInclude = projectStatus == 'cancelled' || projectStatus == 'completed';
      }

      if (shouldInclude) {
        filteredChats.add(chat);
      }
    }

    return filteredChats;
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return InkWell(
      onTap: isFiltering ? null : () {
        setState(() {
          selectedTab = title;
          isFiltering = true; // Show loading immediately
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.amber.shade300 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: isFiltering && isSelected
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                  ),
                )
              : Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.amber.shade800 : Colors.grey.shade700,
                  ),
                ),
        ),
      ),
    );
  }
}