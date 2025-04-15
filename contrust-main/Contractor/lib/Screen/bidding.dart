// ignore_for_file: use_build_context_synchronously

import 'package:backend/enterdata.dart';
import 'package:backend/validatefields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/pagetransition.dart';
import 'package:contractor/Screen/dashboard_screen.dart';
import 'package:contractor/Screen/productpanel.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final response = await supabase
          .from('Projects')
          .select(
            'project_id, type, description, duration, min_budget, max_budget',
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
                          return GestureDetector(
                            onTap: () => _showDetails(project),
                            child: _contracteeProjects(
                              projectId: project['project_id'].toString(),
                              type: project['type'] ?? 'Unknown',
                              duration: project['duration'] ?? '',
                              imagePath: 'kitchen.jpg',
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
                          project["duration"] ?? "",
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
                            final message = messageController.text.trim();

                            if (validateBidRequest(
                              context,
                              bidAmount,
                              message,
                            )) {
                              await enterData.postBid(
                                contractorId: user,
                                projectId: project['project_id'],
                                bidAmount: bidAmount,
                                message: message,
                                context: context,
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
    required String duration,
    required String imagePath,
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
                      Text(
                        duration,
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ],
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Highest Bid:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        duration,
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
