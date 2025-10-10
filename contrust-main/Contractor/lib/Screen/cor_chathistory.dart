import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/build/buildmessage.dart';
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

  @override
  void initState() {
    super.initState();
    loadContractorId();
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
      appBar: screenWidth > 1200 ? null : AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          "",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          messageUIBuilder.buildChatHistoryUI(),
          messageUIBuilder.buildMessagesUI(),
          screenWidth > 1200 
           ? messageUIBuilder.buildProjectInfoUI()
           : const SizedBox.shrink()
        ],
      ),
    );
  }
}