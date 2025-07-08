// ignore_for_file: deprecated_member_use
import 'package:backend/models/be_UImessage.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagePageContractor extends StatefulWidget {
  final String chatRoomId;
  final String contractorId;
  final String contracteeId;
  final String contracteeName;
  final String? contracteeProfile;

  const MessagePageContractor({
    super.key,
    required this.chatRoomId,
    required this.contractorId,
    required this.contracteeId,
    required this.contracteeName,
    this.contracteeProfile,
  });

  @override
  State<MessagePageContractor> createState() => _MessagePageContractorState();
}

class _MessagePageContractorState extends State<MessagePageContractor> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  late Future<String?> _projectStatus;

  @override
  void initState() {
    super.initState();
    _projectStatus = FetchService().fetchProjectStatus(widget.chatRoomId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await supabase.from('Messages').insert({
      'chatroom_id': widget.chatRoomId,
      'sender_id': widget.contractorId,
      'receiver_id': widget.contracteeId,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                widget.contracteeProfile ?? profileUrl,
              ),
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.contracteeName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          FutureBuilder<String?>(
            future: _projectStatus,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error fetching status'));
              } else {
                final projectStatus = snapshot.data ?? 'pending';
                if (projectStatus == 'awaiting_contract') {
                  return ContractAgreementBanner(
                    chatRoomId: widget.chatRoomId,
                    userRole: 'contractor',
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
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
                if (messages.isEmpty) {
                  return Container();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == widget.contractorId;
                    return UIMessage.buildMessageBubble(
                      context,
                      msg,
                      isMe,
                      widget.contractorId,
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
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: Colors.amber[700],
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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
