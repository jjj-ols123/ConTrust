// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:backend/build/buildmessage.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/utils/be_snackbar.dart';
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

  bool _canSend = false;
  String? _contracteeName;
  String? _contracteeProfile;
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
    await _loadContracteeData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadContracteeData() async {
    try {
      final contracteeData = await MessageService().fetchContracteeData(widget.contracteeId);
      if (mounted) {
        setState(() {
          _contracteeName = contracteeData?['full_name'] ?? widget.contracteeName;
          _contracteeProfile = contracteeData?['profile_photo'];
        });
      }
    } catch (e) {
      ConTrustSnackBar.error(context, 'Failed to load contractee data');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_canSend) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
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
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to send message: $e');
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('Messages')
          .stream(primaryKey: ['msg_id'])
          .eq('chatroom_id', widget.chatRoomId)
          .order('timestamp', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final allMessages = snapshot.data!;
        final contractMessages = allMessages.where((msg) => msg['message_type'] == 'contract').toList();

        if (contractMessages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No contracts sent yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contractMessages.length,
          itemBuilder: (context, index) {
            final contractMsg = contractMessages[index];
            return FutureBuilder<Map<String, dynamic>?>(
              future: ContractService.getContractById(contractMsg['contract_id']),
              builder: (context, contractSnapshot) {
                if (!contractSnapshot.hasData || contractSnapshot.data == null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.description, color: Colors.grey, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Loading contract...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final contract = contractSnapshot.data!;
                final messageStatus = contractMsg['contract_status']?.toString();
                final displayStatus = messageStatus ?? contract['status']?.toString() ?? 'Unknown';
                final statusColor = _getContractStatusColor(displayStatus);
                final statusLabel = _getContractStatusLabel(displayStatus);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 20,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              contract['title']?.toString() ?? 'Contract',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        contractMsg['message']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatContractTime(contractMsg['timestamp']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
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
        );
      },
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
          ? DateTime.parse(timestamp).toLocal()
          : (timestamp as DateTime).toLocal();
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

  void _showProjectInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [ 
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Project Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: const TabBar(
                        labelColor: Colors.amber,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.amber,
                        tabs: [
                          Tab(text: 'Project Info'),
                          Tab(text: 'Contracts'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          FutureBuilder<Map<String, dynamic>?>(
                            future: FetchService().fetchProjectDetailsByChatRoom(widget.chatRoomId),
                            builder: (context, projectSnapshot) {
                              if (projectSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(color: Colors.amber),
                                );
                              }

                              if (!projectSnapshot.hasData || projectSnapshot.data == null) {
                                return const Center(
                                  child: Text(
                                    'No project information available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              final project = projectSnapshot.data!;
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project['title']?.toString() ?? 'Project',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Type', project['type']?.toString() ?? 'N/A'),
                                    _buildInfoRow('Location', project['location']?.toString() ?? 'N/A'),
                                    _buildInfoRow('Duration', project['duration']?.toString() ?? 'N/A'),
                                    _buildInfoRow('Budget', 
                                      '₱${project['min_budget']?.toString() ?? '0'} - ₱${project['max_budget']?.toString() ?? '0'}'),
                                    _buildInfoRow('Status', project['status']?.toString() ?? 'N/A'),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Description:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      project['description']?.toString() ?? 'No description available',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          _buildContractsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                  color: Colors.amber,
                  strokeWidth: 3,
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
      userId: widget.contractorId,
      userRole: 'contractor',
      chatRoomId: widget.chatRoomId,
      otherUserId: widget.contracteeId,
      userName: _contracteeName ?? widget.contracteeName,
      userProfile: _contracteeProfile ?? widget.contracteeProfile,
      messageController: _messageController,
      scrollController: _scrollController,
      projectStatus: _projectStatus,
      onSelectChat: (chatRoomId, contracteeId, contracteeName, contracteeProfile) {
        return;
      },
      onSendMessage: _sendMessage,
      onScrollToBottom: _scrollToBottom,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
         title: Row(
           children: [
             CircleAvatar(
               radius: 16,
               backgroundColor: Colors.white,
               backgroundImage: (_contracteeProfile ?? widget.contracteeProfile) != null
                   ? NetworkImage(_contracteeProfile ?? widget.contracteeProfile!)
                   : const NetworkImage(profileUrl),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 _contracteeName ?? widget.contracteeName,
                 style: const TextStyle(
                   fontSize: 18,
                   fontWeight: FontWeight.w600,
                 ),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
         ),
         actions: [
           IconButton(
             icon: const Icon(Icons.info_outline),
             onPressed: () {
               _showProjectInfoModal(context);
             },
           ),
         ],
      ),
      body: messageUIBuilder.buildMessagesUI(),
    );
  }
}
