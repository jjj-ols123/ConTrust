// ignore_for_file: deprecated_member_use
import 'package:backend/build/buildmessagesdesign.dart';
import 'package:backend/build/buildmessage.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
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

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  bool _canSend = false;
  bool _isLoading = true;

  late Future<String?> _projectStatus;

  @override
  void initState() {
    super.initState();
    _initializeData();
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
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

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
              const Expanded(
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
                ),
              ),
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
    );

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
        ? Row(
            children: [
              messageUIBuilder.buildChatHistoryUI(),
              messageUIBuilder.buildMessagesUI(),
              messageUIBuilder.buildProjectInfoUI(),
            ],
          )
        : Column(
            children: [
              FutureBuilder<String?>(
                future: _projectStatus,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading status'));
                  } else {
                    final projectStatus = snapshot.data ?? 'pending';

                    if (projectStatus == 'awaiting_contract' || projectStatus == 'active') {
                      return ContractAgreementBanner(
                        chatRoomId: widget.chatRoomId,
                        userRole: 'contractee', 
                        onActiveProjectPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to Ongoing Projects')),
                          );
                        },
                      );
                    }
                  }
                  return Container();
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
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        backgroundColor: _canSend ? Colors.blue[700] : Colors.grey[400],
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _canSend ? _sendMessage : null,
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
