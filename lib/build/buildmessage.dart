// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:backend/build/buildmessagesdesign.dart';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_contract_service.dart';
import 'package:backend/services/both%20services/be_project_service.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_status.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractor/build/builddrawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageBuildMethods {}

class MessageUIBuildMethods {
  MessageUIBuildMethods({
    required this.context,
    required this.supabase,
    required this.userId,
    required this.userRole,
    required this.chatRoomId,
    required this.otherUserId,
    required this.userName,
    required this.userProfile,
    required this.messageController,
    required this.scrollController,
    required this.projectStatus,
    required this.onSelectChat,
    required this.onSendMessage,
    required this.onScrollToBottom,
  });

  final BuildContext context;
  final SupabaseClient supabase;
  final String? userId;
  final String userRole;
  final String? chatRoomId;
  final String? otherUserId;
  final String? userName;
  final String? userProfile;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final Future<String?> projectStatus;
  final Function(String, String, String, String?) onSelectChat;
  final VoidCallback onSendMessage;
  final VoidCallback onScrollToBottom;

  Color get accentColor =>
      userRole == 'contractor' ? Colors.amber : Colors.amber;
  String get chatStreamColumn =>
      userRole == 'contractor' ? 'contractor_id' : 'contractee_id';
  
  double get screenWidth => MediaQuery.of(context).size.width;
  bool get isDesktop => screenWidth >= 1000;
  bool get isTablet => screenWidth >= 700 && screenWidth < 1000;
  bool get isMobile => screenWidth < 700;
  
  double get headerHeight => isDesktop ? 60 : (isTablet ? 55 : 50);
  double get iconSize => isDesktop ? 24 : (isTablet ? 22 : 20);
  double get fontSize => isDesktop ? 18 : (isTablet ? 16 : 14);
  double get titleFontSize => isDesktop ? 18 : (isTablet ? 16 : 14);
  double get subtitleFontSize => isDesktop ? 14 : (isTablet ? 13 : 12);
  double get avatarRadius => isDesktop ? 28 : (isTablet ? 24 : 20);
  

  Widget buildChatHistoryUI() {
    return Container(
      width: screenWidth > 1200 ? 300 : screenWidth * 0.2,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Container(  
            height: headerHeight,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : (isTablet ? 12 : 8),
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.chat, color: accentColor, size: iconSize),
                SizedBox(width: isDesktop ? 8 : 4),
                if (!isMobile || screenWidth > 350)
                  Expanded(
                    child: Text(
                      isMobile ? 'Chats' : 'Chat History',
                      style: TextStyle(
                        fontSize: titleFontSize,
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
                  .eq(chatStreamColumn, userId as Object)
                  .order('last_message_time', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: isDesktop ? 80 : (isTablet ? 60 : 40),
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: isDesktop ? 24 : (isTablet ? 16 : 12)),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: isDesktop ? 24 : (isTablet ? 20 : 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 12 : 8),
                          if (!isMobile)
                            Text(
                              'Start a conversation by accepting a project or wait for clients to message you',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final chatRooms = snapshot.data!;

                return ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: isDesktop ? 0 : 4),
                  itemCount: chatRooms.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0,
                    indent: avatarRadius + (isDesktop ? 16 : 8),
                    endIndent: isDesktop ? 16 : 8,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chatRooms[index];
                    final otherUserId = userRole == 'contractor'
                        ? chat['contractee_id']
                        : chat['contractor_id'];
                    final isSelected =
                        chatRoomId == chat['chatroom_id'];

                    return FutureBuilder<bool>(
                      future: functionConstraint(
                        userRole == 'contractor'
                            ? chat['contractor_id']
                            : chat['contractor_id'],
                        userRole == 'contractor'
                            ? chat['contractee_id']
                            : chat['contractee_id'],
                      ),
                      builder: (context, constraintSnapshot) {
                        final canChat = constraintSnapshot.data ?? false;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: loadUserData(otherUserId),
                          builder: (context, userSnapshot) {
                            final userName = userSnapshot.data?[
                                    userRole == 'contractor'
                                        ? 'full_name'
                                        : 'firm_name'] ??
                                (userRole == 'contractor'
                                    ? 'Client'
                                    : 'Contractor');
                            final userProfile =
                                userSnapshot.data?['profile_photo'];
                            final lastMessage =
                                chat['last_message'] ?? 'No messages yet';
                            final lastTime = chat['last_message_time'] != null &&
                                    screenWidth > 1000
                                ? DateTime.tryParse(chat['last_message_time'])
                                : null;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withOpacity(0.05)
                                    : (canChat
                                        ? Colors.transparent
                                        : Colors.grey.shade50),
                                border: isSelected
                                    ? Border(
                                        right: BorderSide(
                                          color: accentColor,
                                          width: 3,
                                        ),
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                dense: isMobile,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 16 : (isTablet ? 12 : 8),
                                  vertical: isDesktop ? 8 : (isTablet ? 6 : 4),
                                ),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundImage: NetworkImage(
                                        userProfile ??
                                            'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                      ),
                                    ),
                                    if (!canChat)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: buildConstraintIcon(),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: canChat ? Colors.black : Colors.grey,
                                    fontSize: subtitleFontSize + 1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: isMobile && screenWidth < 400 ? null : Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: canChat
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                    fontSize: subtitleFontSize - 1,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (lastTime != null && (!isMobile || screenWidth > 350))
                                      Text(
                                        "${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          fontSize: subtitleFontSize - 2,
                                          color: canChat
                                              ? Colors.grey
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    if (!canChat) SizedBox(height: isMobile ? 2 : 4),
                                    if (!canChat)
                                      Icon(
                                        Icons.lock,
                                        size: isDesktop ? 16 : 14,
                                        color: Colors.grey.shade400,
                                      ),
                                  ],
                                ),
                                enabled: canChat,
                                onTap: () {
                                  if (canChat) {
                                    onSelectChat(
                                      chat['chatroom_id'],
                                      otherUserId,
                                      userName,
                                      userProfile,
                                    );
                                  }
                                },
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
          ),
        ],
      ),
    );
  }

  Widget buildMessagesUI() {
    return Expanded(
      flex: isMobile ? 3 : 2,
      child: chatRoomId == null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_outlined,
                      size: isDesktop ? 80 : (isTablet ? 60 : 40),
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: isDesktop ? 24 : (isTablet ? 16 : 12)),
                    Text(
                      'Select a conversation',
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : (isTablet ? 20 : 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 12 : 8),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(  
                  height: headerHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : (isTablet ? 12 : 8),
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: iconSize / 2,
                        backgroundImage: NetworkImage(
                          userProfile ??
                              'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                        ),
                      ),
                      SizedBox(width: isDesktop ? 8 : 4),
                      if (!isMobile || screenWidth > 350)
                        Expanded(
                          child: Text(
                            userName ?? 'User',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (userRole == 'contractor')
                  FutureBuilder<String?>(
                    future: projectStatus,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && (snapshot.data == 'awaiting_contract' || snapshot.data == 'active')) {
                        return ContractAgreementBanner(
                          chatRoomId: chatRoomId!,
                          userRole: userRole,
                          onActiveProjectPressed: () async {
                            if (userId == null) return;
                            try {
                              final activeProjects = await FetchService().fetchContractorActiveProjects(userId!);
                              if (activeProjects.isEmpty) {
                                ConTrustSnackBar.error(context, 'No active projects found.');
                                return;
                              }
                              final projectId = activeProjects.first['project_id'];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContractorShell(
                                    currentPage: ContractorPage.projectManagement,
                                    contractorId: userId!,
                                    child: CorOngoingProjectScreen(projectId: projectId ?? ''),
                                  ),
                                ),
                              );
                            } catch (e) {
                              ConTrustSnackBar.error(context, 'Error navigating to project management: ');
                            }
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                if (userRole == 'contractee')
                  FutureBuilder<String?>(
                    future: projectStatus,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && (snapshot.data == 'awaiting_contract' || snapshot.data == 'active')) {
                        return ContractAgreementBanner(
                          chatRoomId: chatRoomId!,
                          userRole: userRole,
                          onActiveProjectPressed: () async {
                            try {
                              final projectId = await ProjectService().getProjectId(chatRoomId!);
                              if (projectId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CeeOngoingProjectScreen(projectId: projectId),
                                  ),
                                );
                              }
                            } catch (e) {
                              ConTrustSnackBar.error(context, 'Error navigating to project:');
                            }
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('Messages')
                        .stream(primaryKey: ['msg_id'])
                        .eq('chatroom_id', chatRoomId!)
                        .order('timestamp', ascending: true),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      final messages = snapshot.data!;
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => onScrollToBottom(),
                      );
                      if (messages.isEmpty) {
                        return Container();
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 12 : (isTablet ? 8 : 6),
                          horizontal: isDesktop ? 8 : (isTablet ? 6 : 4),
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['sender_id'] == userId;
                          return UIMessage.buildContractMessage(
                            context,
                            msg,
                            isMe,
                            userId!,
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : (isTablet ? 6 : 4),
                    vertical: isDesktop ? 8 : (isTablet ? 6 : 4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(isDesktop ? 24 : (isTablet ? 20 : 16)),
                          ),
                          child: TextField(
                            controller: messageController,
                            minLines: 1,
                            maxLines: isMobile ? 3 : 4,
                            style: TextStyle(fontSize: subtitleFontSize),
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              hintStyle: TextStyle(fontSize: subtitleFontSize),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 16 : (isTablet ? 12 : 8),
                                vertical: isDesktop ? 12 : (isTablet ? 10 : 8),
                              ),
                            ),
                            onSubmitted: (_) => onSendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 6 : 4),
                      CircleAvatar(
                        backgroundColor: accentColor,
                        radius: isDesktop ? 24 : (isTablet ? 20 : 16),
                        child: IconButton(
                          icon: Icon(
                            Icons.send, 
                            color: Colors.white,
                            size: isDesktop ? 20 : (isTablet ? 18 : 16),
                          ),
                          onPressed: onSendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildProjectInfoUI() {
    return Container(
      width: screenWidth > 1100 ? 300 : screenWidth * 0.15,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Container(  
            height: headerHeight,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : (isTablet ? 12 : 8),
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: accentColor, size: iconSize),
                SizedBox(width: isDesktop ? 8 : 4),
                if (!isMobile || screenWidth > 350)
                  Expanded(
                    child: Text(
                      isMobile ? 'Info' : 'Project Information',
                      style: TextStyle(
                        fontSize: titleFontSize,
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
            child: chatRoomId == null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isDesktop ? 12 : 8),
                          if (!isMobile)
                            Text(
                              'Select a chat to view\nits project information',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : userRole == 'contractor'
                    ? buildContractorProjectInfo()
                    : buildContracteeProjectInfo(),
          ),
        ],
      ),
    );
  }

  Widget buildContractorProjectInfo() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: FetchService()
                .fetchProjectDetailsByChatRoom(chatRoomId!),
            builder: (context, projectSnapshot) {
              if (!projectSnapshot.hasData || projectSnapshot.data == null) {
                return Container();
              }

              final project = projectSnapshot.data!;

              return buildProjectInfoSection(project);
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: buildContractsSent(),
        ),
      ],
    );
  }

  Widget buildContracteeProjectInfo() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: loadUserData(otherUserId!),
            builder: (context, contractorSnapshot) {
              if (!contractorSnapshot.hasData ||
                  contractorSnapshot.data == null) {
                return Container();
              }

              final contractor = contractorSnapshot.data!;

              return buildContractorInfoSection(contractor);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: FetchService()
                .fetchProjectDetailsByChatRoom(chatRoomId!),
            builder: (context, projectSnapshot) {
              if (!projectSnapshot.hasData || projectSnapshot.data == null) {
                return Container();
              }

              final project = projectSnapshot.data!;

              return buildProjectInfoSection(project);
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: buildContractsSent(),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> loadUserData(String userId) async {
    try {
      if (userRole == 'contractor') {
        return await FetchService().fetchContracteeData(userId);
      } else {
        return await FetchService().fetchContractorData(userId);
      }
    } catch (e) {
      return null;
    }
  }

  Widget buildContractsSent() {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contracts',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('Messages')
                  .stream(primaryKey: ['msg_id'])
                  .eq('chatroom_id', chatRoomId!)
                  .order('timestamp', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : (isTablet ? 10 : 8)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  );
                }

                final allMessages = snapshot.data!;
                final contractMessages = allMessages.where((msg) => msg['message_type'] == 'contract').toList();

                if (contractMessages.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : (isTablet ? 10 : 8)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: isDesktop ? 48 : (isTablet ? 36 : 24),
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: isDesktop ? 12 : 8),
                          Text(
                            'No contracts sent yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: subtitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : (isTablet ? 10 : 8)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.all(isDesktop ? 12 : (isTablet ? 8 : 4)),
                    itemCount: contractMessages.length,
                    separatorBuilder: (_, __) => Divider(
                      height: isDesktop ? 16 : (isTablet ? 12 : 8),
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final contractMsg = contractMessages[index];
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: ContractService.getContractById(contractMsg['contract_id']),
                        builder: (context, contractSnapshot) {
                          if (!contractSnapshot.hasData || contractSnapshot.data == null) {
                            return Container(
                              padding: EdgeInsets.all(isDesktop ? 12 : (isTablet ? 8 : 4)),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: isDesktop ? 24 : (isTablet ? 20 : 16),
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: isDesktop ? 12 : 8),
                                  Expanded(
                                    child: Text(
                                      'Loading contract...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: subtitleFontSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final contract = contractSnapshot.data!;

                          final messageStatus = contractMsg['contract_status']?.toString();
                          final displayStatus = messageStatus;
                          final statusColor = _getContractStatusColor(displayStatus!);
                          final statusLabel = _getContractStatusLabel(displayStatus);

                          return Container(
                            padding: EdgeInsets.all(isDesktop ? 12 : (isTablet ? 8 : 4)),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: isDesktop ? 20 : (isTablet ? 18 : 16),
                                      color: accentColor,
                                    ),
                                    SizedBox(width: isDesktop ? 8 : 4),
                                    Expanded(
                                      child: Text(
                                        contract['title']?.toString() ?? 'Contract',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: subtitleFontSize,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktop ? 8 : 6,
                                        vertical: isDesktop ? 4 : 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: subtitleFontSize - 2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isDesktop ? 8 : 4),
                                Text(
                                  contract['message']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: subtitleFontSize - 1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isDesktop ? 8 : 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: isDesktop ? 14 : 12,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: isDesktop ? 4 : 2),
                                    Text(
                                      _formatContractTime(contractMsg['timestamp']),
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: subtitleFontSize - 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildConstraintIcon() {
    return Container(
      padding: EdgeInsets.all(isMobile ? 1 : 2),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.block,
        color: Colors.white,
        size: isMobile ? 10 : 12,
      ),
    );
  }

  Color _getContractStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'awaiting_signature':
        return Colors.blue;
      case 'active':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }

  String _getContractStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'awaiting_signature':
        return 'Awaiting Signature';
      case 'active':
        return 'Active';
      default:
        return status;
    }
  }

  String _formatContractTime(dynamic timestamp) {
    try {
      final date = timestamp is String
          ? DateTime.parse(timestamp)
          : timestamp as DateTime;
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget buildProjectInfoSection(Map<String, dynamic> project) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Information',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 12 : 8)),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(isDesktop ? 12 : (isTablet ? 10 : 8)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['title']?.toString() ?? 'Project',
                      style: TextStyle(
                        fontSize: subtitleFontSize + 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 12 : (isTablet ? 10 : 8)),
                    buildInfoRow('Type', project['type']?.toString() ?? 'N/A'),
                    buildInfoRow('Location', project['location']?.toString() ?? 'N/A'),
                    buildInfoRow('Duration', project['duration']?.toString() ?? 'N/A'),
                    buildInfoRow('Budget', 
                      '₱${project['min_budget']?.toString() ?? '0'} - ₱${project['max_budget']?.toString() ?? '0'}'),
                    buildInfoRow('Status', ProjectStatus().getStatusLabel(project['status']?.toString())),
                    SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: subtitleFontSize,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 8 : 4),
                    Text(
                      project['description']?.toString() ?? 'No description available',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: subtitleFontSize,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 8.0 : (isTablet ? 6.0 : 4.0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isDesktop ? 80 : (isTablet ? 70 : 60),
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: subtitleFontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: subtitleFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContractorInfoSection(Map<String, dynamic> contractor) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contractor Information',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: accentColor.withOpacity(0.8),
            ),
          ),
          SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 12 : 8)),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isDesktop ? 12 : (isTablet ? 10 : 8)),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: isDesktop ? 30 : (isTablet ? 25 : 20),
                          backgroundImage: NetworkImage(
                            contractor['profile_photo']?.toString() ??
                                'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                          ),
                        ),
                        SizedBox(width: isDesktop ? 12 : (isTablet ? 10 : 8)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contractor['firm_name']?.toString() ?? 'Contractor',
                                style: TextStyle(
                                  fontSize: subtitleFontSize + 2,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (contractor['specialization'] != null)
                                Text(
                                  contractor['specialization'].toString(),
                                  style: TextStyle(
                                    color: accentColor.withOpacity(0.8),
                                    fontSize: subtitleFontSize,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
                    if (contractor['experience'] != null)
                      Text(
                        'Experience: ${contractor['experience'].toString()} years',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: subtitleFontSize,
                        ),
                      ),
                    SizedBox(height: isDesktop ? 8 : 4),
                    if (contractor['description'] != null)
                      Text(
                        contractor['description'].toString(),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: subtitleFontSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
