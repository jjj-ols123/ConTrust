// ignore_for_file: use_build_context_synchronously


import 'package:backend/services/enterdata.dart';
import 'package:backend/services/getuserdata.dart';
import 'package:backend/services/notification.dart';
import 'package:backend/utils/pagetransition.dart';
import 'package:backend/utils/validatefields.dart';
import 'package:backend/services/projectbidding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_product.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final supabase = Supabase.instance.client;
  final projectbidding = ProjectBidding();
  final Set<String> _finalizedProjects = {};

  List<Map<String, dynamic>> projects = [];
  Map<String, double> highestBids = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProjects();
    fetchHighestBids();
  }

  Future<void> fetchProjects() async {
    try {
      final response = await supabase
          .from('Projects')
          .select(
            'project_id, type, description, duration, min_budget, max_budget, created_at',
          );

      if (response.isNotEmpty) {
        setState(() {
          projects = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchHighestBids() async {
    final highestBidsData = await projectbidding.highestBid();
    setState(() {
      highestBids = highestBidsData;
    });

    debugPrint("Highest Bids: $highestBids");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Bidding',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Image.asset('logo.png', width: 100),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.amber.shade200,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => transitionBuilder(context, DashboardScreen()),
                    child: Text(
                      "Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("|", style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap:
                        () => transitionBuilder(context, ProductPanelScreen()),
                    child: Text(
                      "Product Panel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bidding",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.black54),
                      SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(Icons.search, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : projects.isEmpty
                      ? Center(child: Text("No projects available"))
                      : GridView.builder(
                        itemCount: projects.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.3,
                        ),

                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final projectId = project['project_id'].toString();
                          final highestBid = highestBids[projectId] ?? 0.0;

                          return GestureDetector(
                            onTap: () => _showDetails(project),
                            child: _contracteeProjects(
                              projectId: projectId,
                              type: project['type'] ?? 'Unknown',
                              durationDays: project['duration'] ?? 0,
                              imagePath: 'kitchen.jpg',
                              highestBid: highestBid,
                              createdAt: DateTime.parse(
                                project['created_at'].toString(),
                              )..toIso8601String(),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> project) {
    final TextEditingController bidController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      barrierDismissible: true,
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            contentPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: Image.asset(
                        "kitchen.jpg",
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      project["type"] ?? "Project",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      project["description"] ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 15),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Time left:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          project["duration"].toString(),
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Minimum Budget:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "₱${project["min_budget"]}",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Maximum Budget:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "₱${project["max_budget"]}",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: bidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter your bid",
                        prefixText: "₱",
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    SizedBox(height: 50),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: "Enter your message",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Close"),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            final enterData = EnterDatatoDatabase();
                            final user =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (user == null) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User not authenticated'),
                                ),
                              );
                              return;
                            }

                            final bidAmount = bidController.text.trim();
                            num bidAmountNum = int.parse(bidAmount);
                            final message = messageController.text.trim();

                            if (validateBidRequest(
                              context,
                              bidAmount,
                              message,
                            )) {
                              await enterData.postBid(
                                contractorId: user,
                                projectId: project['project_id'],
                                bidAmount: bidAmountNum,
                                message: message,
                                context: context,
                              );

                              final NotificationService notif =
                                  NotificationService();
                              final GetUserId getUser = GetUserId();

                              final contracteeId = await getUser.getContracteeId();

                              await notif.createNotification(
                                receiverId: contracteeId,
                                receiverType: 'contractee',
                                senderId: user,
                                senderType: 'contractor',
                                type:
                                    'bid_placed',
                                message:
                                    'New bid placed on your project: ${project['type']}',
                                information: {
                                  'bid_amount': bidAmountNum,
                                  
                                },
                              );
                            }
                          },
                          child: Text("Bid"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _contracteeProjects({
    required String projectId,
    required String type,
    required int durationDays,
    required String imagePath,
    required double highestBid,
    required DateTime createdAt,
  }) {
    return SizedBox(
      height: 250,
      child: Card(
        color: Colors.amber.shade200,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    type,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Divider(color: Colors.black38),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Time left:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      StreamBuilder<Duration>(
                        stream: projectbidding.countdownStream(createdAt, durationDays),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "Loading...",
                              style: TextStyle(fontSize: 14),
                            );
                          }

                          final remaining = snapshot.data!;

                          if (remaining.isNegative &&
                              !_finalizedProjects.contains(projectId)) {
                            _finalizedProjects.add(projectId);
                            projectbidding.durationBidding(projectId);
                          }

                          if (remaining.isNegative) {
                            return Text(
                              "Ended",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.redAccent,
                              ),
                            );
                          }

                          final days = remaining.inDays;
                          final hours = remaining.inHours
                              .remainder(24)
                              .toString()
                              .padLeft(2, '0');
                          final minutes = remaining.inMinutes
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');
                          final seconds = remaining.inSeconds
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');

                          return Text(
                            '$days d $hours:$minutes:$seconds',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Highest Bid: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "₱${highestBid.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
