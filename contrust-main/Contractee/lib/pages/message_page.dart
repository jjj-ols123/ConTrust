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
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.contractorProfile != null)
              CircleAvatar(
                backgroundImage: NetworkImage(widget.contractorProfile!),
              ),
            if (widget.contractorProfile!= null) const SizedBox(width: 10),
            Text(widget.contractorName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('Messages')
                  .stream(primaryKey: ['msg_id'])
                  .eq('chatroom_id', widget.chatRoomId)
                  .order('timestamp', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Loading messages...'));
                  
                }
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == widget.contracteeId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber[200] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['message'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber),
                    onPressed: _sendMessage,
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