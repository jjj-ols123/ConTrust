// ignore_for_file: deprecated_member_use, unnecessary_null_comparison
import 'dart:async';
import 'package:backend/build/buildmessagesdesign.dart';
import 'package:backend/build/buildmessage.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/build/buildceeprofile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagePageContractee extends StatefulWidget {
  final String chatRoomId;
  final String contracteeId;
  final String contractorId;
  final String contractorName;
  final String? contractorProfile;

  const MessagePageContractee({
    super.key,
    required this.chatRoomId,
    required this.contracteeId,
    required this.contractorId,
    required this.contractorName,
    this.contractorProfile,
  });

  @override
  State<MessagePageContractee> createState() => _MessagePageContracteeState();
}

class _MessagePageContracteeState extends State<MessagePageContractee> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _chatRoomChannel;
  RealtimeChannel? _projectsChannel;
  RealtimeChannel? _contractsChannel;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  bool _canSend = false;
  bool _isLoading = true;
  bool _isSending = false;

  late Future<String?> _projectStatus;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupRealtimeSubscriptions();
    _messageController.addListener(() {
      setState(() {
        _canSend = _messageController.text.trim().isNotEmpty;
      });
    });
  }
  
  Future<void> _initializeData() async {
    setState(() {
      _projectStatus = FetchService().fetchProjectStatus(widget.chatRoomId);
    });
    await _projectStatus;
    await MessageService().markMessagesAsRead(
      chatRoomId: widget.chatRoomId,
      userId: widget.contracteeId,
    );
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _setupRealtimeSubscriptions() async {
    _messagesChannel = supabase
        .channel('messages:${widget.chatRoomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chatroom_id',
            value: widget.chatRoomId,
          ),
          callback: (payload) {
            if (!mounted) return;
            _scrollToBottom();
            if (payload.newRecord != null && 
                payload.newRecord['sender_id'] != widget.contracteeId) {
              MessageService().markMessagesAsRead(
                chatRoomId: widget.chatRoomId,
                userId: widget.contracteeId,
              );
            }
          },
        )
        .subscribe();

    _chatRoomChannel = supabase
        .channel('chatroom:${widget.chatRoomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ChatRoom',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chatroom_id',
            value: widget.chatRoomId,
          ),
          callback: (payload) {
            if (!mounted) return;
          },
        )
        .subscribe();

    _projectsChannel = supabase
        .channel('projects_status:${widget.chatRoomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'Projects',
          callback: (payload) {
            if (!mounted) return;
            final oldStatus = payload.oldRecord != null ? payload.oldRecord['status'] : null;
            final newStatus = payload.newRecord != null ? payload.newRecord['status'] : null;
            if (oldStatus != newStatus) {
              setState(() {
                _projectStatus = Future.value(newStatus?.toString());
              });
            }
          },
        )
        .subscribe();

    _contractsChannel = supabase
        .channel('contracts_status:${widget.chatRoomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'Contracts',
          callback: (payload) {
            if (!mounted) return;

            final oldStatus = payload.oldRecord != null ? payload.oldRecord['status'] : null;
            final newStatus = payload.newRecord != null ? payload.newRecord['status'] : null;
            if (oldStatus != newStatus) {
              setState(() {
                _projectStatus = FetchService().fetchProjectStatus(widget.chatRoomId);
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await supabase.from('Messages').insert({
        'chatroom_id': widget.chatRoomId,
        'sender_id': widget.contracteeId,
        'receiver_id': widget.contractorId,
        'message': text,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await supabase
          .from('ChatRoom')
          .update({
            'last_message': text,
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .eq('chatroom_id', widget.chatRoomId);

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to send message');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _chatRoomChannel?.unsubscribe();
    _projectsChannel?.unsubscribe();
    _contractsChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: screenWidth > 1200 ? null : AppBar(
          elevation: 1,
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 22,
                child: Icon(Icons.person, color: Colors.amber[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.contractorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Loading conversation...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return _buildMessageContent();
  }

  Widget _buildMessageContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final messageUIBuilder = MessageUIBuildMethods(
      context: context,
      supabase: supabase,
      userId: widget.contracteeId,
      userRole: 'contractee',
      chatRoomId: widget.chatRoomId,
      otherUserId: widget.contractorId,
      userName: widget.contractorName,
      userProfile: widget.contractorProfile,
      messageController: _messageController,
      scrollController: _scrollController,
      projectStatus: _projectStatus,
      onSelectChat: (chatRoomId, otherUserId, userName, userProfile) {
      },
      onSendMessage: _sendMessage,
      onScrollToBottom: _scrollToBottom,
      isSending: _isSending,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: screenWidth > 1200 ? null : AppBar(
        elevation: 1,
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                widget.contractorProfile ?? profileUrl,
              ),
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.contractorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: screenWidth > 1200 
        ? CustomScrollView(
            slivers: [
              CeeProfileBuildMethods.buildStickyHeader('Messages'),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Row(
                  children: [
                    messageUIBuilder.buildChatHistoryUI(),
                    messageUIBuilder.buildMessagesUI(),
                    messageUIBuilder.buildProjectInfoUI(),
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              CeeProfileBuildMethods.buildStickyHeader('Messages'),
              FutureBuilder<String?>(
                future: _projectStatus,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)));
                  } else if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  } else {
                    final projectStatus = snapshot.data ?? 'pending';

                    if (projectStatus == 'awaiting_contract' || projectStatus == 'active') {
                      return ContractAgreementBanner(
                        chatRoomId: widget.chatRoomId,
                        userRole: 'contractee', 
                        onActiveProjectPressed: () {
                          ConTrustSnackBar.info(context, 'Navigate to Ongoing Projects');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }
                },
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('Messages')
                      .stream(primaryKey: ['msg_id'])
                      .eq('chatroom_id', widget.chatRoomId)
                      .order('timestamp', ascending: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    final messages = snapshot.data!;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());
                    if (messages.isEmpty) {
                      return Container();
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == widget.contracteeId;
                        return UIMessage.buildContractMessage(
                          context,
                          msg,
                          isMe,
                          widget.contracteeId,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: "Type your message...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) {
                              if (_canSend && !_isSending) {
                                _sendMessage();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        backgroundColor: (_canSend && !_isSending) ? Colors.blue[700] : Colors.grey[400],
                        radius: 24,
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: (_canSend && !_isSending) ? _sendMessage : null,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
