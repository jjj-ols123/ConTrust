// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:backend/build/buildmessage.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContracteeChatHistoryPage extends StatefulWidget {
  const ContracteeChatHistoryPage({super.key});

  @override
  _ContracteeChatHistoryPageState createState() =>
      _ContracteeChatHistoryPageState();
}

class _ContracteeChatHistoryPageState extends State<ContracteeChatHistoryPage> {
  final supabase = Supabase.instance.client;
  String? contracteeId;
  String? selectedChatRoomId;
  String? selectedContractorId;
  String? selectedContractorName;
  String? selectedContractorProfile;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late Future<String?> projectStatus;
  bool isSending = false;

  Future<Map<String, dynamic>>? _batchFuture;
  Map<String, dynamic>? _lastBatchData;
  String? _batchKey;

  String selectedTab = 'Active'; // Add this for tab management
  bool isFiltering = false; // Add loading state for tab switching
  double screenWidth = 0; // Screen width for responsive design

  @override
  void initState() {
    super.initState();
    _loadContracteeId();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContracteeId() async {
    setState(() {
      contracteeId = supabase.auth.currentUser?.id;
    });
  }

  void selectChat(String chatRoomId, String contractorId, String contractorName,
      String? contractorProfile) {
    setState(() {
      selectedChatRoomId = chatRoomId;
      selectedContractorId = contractorId;
      selectedContractorName = contractorName;
      selectedContractorProfile = contractorProfile;
      projectStatus = FetchService().fetchProjectStatus(chatRoomId);
    });
    if (contracteeId != null) {
      MessageService().markMessagesAsRead(
        chatRoomId: chatRoomId,
        userId: contracteeId!,
      );
    }
  }

  Future<void> sendMessage() async {
    if (selectedChatRoomId == null || selectedContractorId == null || isSending)
      return;

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);

    try {
      await supabase.from('Messages').insert({
        'chatroom_id': selectedChatRoomId,
        'sender_id': contracteeId,
        'receiver_id': selectedContractorId,
        'message': text,
        'timestamp': DateTimeHelper.getLocalTimeISOString(),
      });

      await supabase.from('ChatRoom').update({
        'last_message': text,
        'last_message_time': DateTimeHelper.getLocalTimeISOString(),
      }).eq('chatroom_id', selectedChatRoomId!);

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

  Future<Map<String, Map<String, dynamic>>> _loadAllContractorData(
      List<String> contractorIds) async {
    if (contractorIds.isEmpty) return {};

    try {
      final response = await supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo')
          .inFilter('contractor_id', contractorIds);

      final Map<String, Map<String, dynamic>> contractorMap = {};
      for (var contractor in response) {
        final id = contractor['contractor_id'] as String?;
        if (id != null) {
          contractorMap[id] = {
            'firm_name': contractor['firm_name'],
            'profile_photo': contractor['profile_photo'],
          };
        }
      }
      return contractorMap;
    } catch (e) {
      debugPrint('Error batch loading contractor data: $e');
      return {};
    }
  }

  // Batch fetch all chat permissions for better performance
  Future<Map<String, bool>> _loadAllChatPermissions(
      List<String> contractorIds, String contracteeId) async {
    if (contractorIds.isEmpty) return {};

    final Map<String, bool> permissionsMap = {};

    // Batch fetch all permissions in parallel
    final futures = contractorIds.map((contractorId) async {
      try {
        final canChat = await functionConstraint(contractorId, contracteeId);
        return MapEntry(contractorId, canChat);
      } catch (e) {
        debugPrint('Error checking chat permission for $contractorId: $e');
        return MapEntry(contractorId, false);
      }
    });

    final results = await Future.wait(futures);
    for (var entry in results) {
      permissionsMap[entry.key] = entry.value;
    }

    return permissionsMap;
  }

  // Batch fetch all unread message counts for better performance
  Future<Map<String, int>> _loadAllUnreadCounts(
      List<String> chatRoomIds, String userId) async {
    if (chatRoomIds.isEmpty) return {};

    final Map<String, int> unreadCountMap = {};

    // Batch fetch all unread counts in parallel
    final futures = chatRoomIds.map((chatRoomId) async {
      try {
        final count = await MessageService().getUnreadMessageCount(
          chatRoomId: chatRoomId,
          userId: userId,
        );
        return MapEntry(chatRoomId, count);
      } catch (e) {
        debugPrint('Error loading unread count for $chatRoomId: $e');
        return MapEntry(chatRoomId, 0);
      }
    });

    final results = await Future.wait(futures);
    for (var entry in results) {
      unreadCountMap[entry.key] = entry.value;
    }

    return unreadCountMap;
  }

  String formatTime(DateTime? time) {
    if (time == null) return '';
    final localTime = time.isUtc ? time.toLocal() : time;
    return DateFormat('hh:mm a').format(localTime);
  }

  String _computeBatchKey(List<Map<String, dynamic>> chatRooms) {
    final buffer = StringBuffer();
    for (final chat in chatRooms) {
      final id = chat['chatroom_id']?.toString() ?? '';
      final ts = chat['last_message_time']?.toString() ?? '';
      buffer.write(id);
      buffer.write('|');
      buffer.write(ts);
      buffer.write(';');
    }
    return buffer.toString();
  }

  Future<Map<String, dynamic>> _ensureBatchFuture(
      List<Map<String, dynamic>> chatRooms, String contracteeId) {
    final newKey = _computeBatchKey(chatRooms);
    if (_batchFuture == null || _batchKey != newKey) {
      _batchKey = newKey;
      _batchFuture = _loadBatchData(chatRooms, contracteeId).then((data) {
        _lastBatchData = data;
        return data;
      });
    }
    return _batchFuture!;
  }

  Future<Map<String, dynamic>> _loadBatchData(
      List<Map<String, dynamic>> chatRooms, String contracteeId) async {
    final contractorIds = chatRooms
        .map((chat) => chat['contractor_id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final chatRoomIds = chatRooms
        .map((chat) => chat['chatroom_id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    final results = await Future.wait([
      _loadAllContractorData(contractorIds),
      _loadAllChatPermissions(contractorIds, contracteeId),
      _loadAllUnreadCounts(chatRoomIds, contracteeId),
    ]);

    return {
      'contractors': results[0],
      'permissions': results[1],
      'unreadCounts': results[2],
    };
  }

  Future<List<Map<String, dynamic>>> _filterChatsByStatus(
      List<Map<String, dynamic>> chats, String tab) async {
    List<Map<String, dynamic>> filteredChats = [];

    const timeout = Duration(seconds: 5);

    for (final chat in chats) {
      try {
        final projectStatus = await FetchService()
            .fetchProjectStatus(chat['chatroom_id'])
            .timeout(
              timeout,
              onTimeout: () => 'unknown',
            );

        bool shouldInclude = false;

        if (tab == 'Active') {
          // Active chats: show all except confirmed cancelled or completed
          shouldInclude =
              projectStatus != 'cancelled' && projectStatus != 'completed';
        } else {
          // Archived chats: only confirmed cancelled or completed
          shouldInclude =
              projectStatus == 'cancelled' || projectStatus == 'completed';
        }

        if (shouldInclude) {
          filteredChats.add(chat);
        }
      } catch (e) {
        // If we can't fetch status, show in Active tab (better UX than hiding potentially active chats)
        if (tab == 'Active') {
          filteredChats.add(chat);
        }
        // Don't add to Archived tab if status can't be determined
      }
    }

    return filteredChats;
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return InkWell(
      onTap: isFiltering
          ? null
          : () {
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                  ),
                )
              : Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.amber.shade800
                        : Colors.grey.shade700,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    if (contracteeId == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
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
      projectStatus:
          selectedChatRoomId != null ? projectStatus : Future.value(null),
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
                        child:
                            _buildTabButton('Active', selectedTab == 'Active'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTabButton(
                            'Archived', selectedTab == 'Archived'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('ChatRoom')
                        .stream(primaryKey: ['chatroom_id'])
                        .eq('contractee_id', contracteeId as Object)
                        .order('last_message_time', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.amber));
                      }
                      if (snapshot.hasData && snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No conversations yet.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.amber));
                      }
                      final chatRooms = snapshot.data!;
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _ensureBatchFuture(chatRooms, contracteeId!),
                        builder: (context, batchSnap) {
                          Map<String, dynamic> batchData;
                          if (batchSnap.connectionState ==
                              ConnectionState.waiting) {
                            if (_lastBatchData != null) {
                              batchData = _lastBatchData!;
                            } else {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.amber));
                            }
                          } else {
                            batchData = batchSnap.data ?? _lastBatchData ?? {};
                          }
                          final contractorDataCache = batchData['contractors']
                                  as Map<String, Map<String, dynamic>>? ??
                              {};
                          final chatPermissionsCache =
                              batchData['permissions'] as Map<String, bool>? ??
                                  {};
                          final unreadCountsCache =
                              batchData['unreadCounts'] as Map<String, int>? ??
                                  {};

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future:
                                _filterChatsByStatus(chatRooms, selectedTab),
                            builder: (context, filterSnapshot) {
                              if (filterSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.amber));
                              }

                              if (isFiltering) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() => isFiltering = false);
                                  }
                                });
                              }

                              final filteredChats = filterSnapshot.data ?? [];

                              if (snapshot.hasData && filteredChats.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        selectedTab == 'Active'
                                            ? Icons.chat_bubble_outline
                                            : Icons.archive_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        selectedTab == 'Active'
                                            ? 'No active conversations'
                                            : 'No archived conversations',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        selectedTab == 'Active'
                                            ? 'Start chatting with contractors'
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
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredChats.length,
                                itemBuilder: (context, index) {
                                  final chat = filteredChats[index];
                                  final contractorId =
                                      chat['contractor_id'] as String?;
                                  final chatRoomId =
                                      chat['chatroom_id'] as String?;

                                  if (contractorId == null ||
                                      chatRoomId == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final contractorData =
                                      contractorDataCache[contractorId];
                                  final contractorName =
                                      contractorData?['firm_name'] ??
                                          'Contractor';
                                  final contractorProfile =
                                      contractorData?['profile_photo'];
                                  final canChat =
                                      chatPermissionsCache[contractorId] ??
                                          false;
                                  final unreadCount =
                                      unreadCountsCache[chatRoomId] ?? 0;
                                  final hasUnread = unreadCount > 0;

                                  final lastMessage =
                                      chat['last_message'] ?? '';
                                  final lastTime = DateTimeHelper.parseToLocal(
                                      chat['last_message_time'] as String?);

                          return InkWell(
                            onTap: () {
                              context.go('/chat/${Uri.encodeComponent(contractorName)}', extra: {
                                'chatRoomId': chatRoomId,
                                'contracteeId': contracteeId,
                                'contractorId': contractorId,
                                'contractorProfile': contractorProfile,
                                'canChat': canChat,
                              });
                            },
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
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      ClipOval(
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.blue.shade600,
                                          child: Image.network(
                                            contractorProfile ??
                                                'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image(
                                                image: const AssetImage('assets/defaultpic.png'),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.blue.shade600,
                                                    child: Icon(Icons.business, size: 28, color: Colors.white),
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
                                            color: hasUnread ? Colors.black87 : Colors.grey.shade700,
                                            fontSize: 14,
                                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (lastTime != null && screenWidth < 400) ...[
                                    Text(
                                      DateFormat('h:mm a').format(lastTime),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      formatTime(lastTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
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
                )
              ]
          )
          );
  }

  
}
