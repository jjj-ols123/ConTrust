// ignore_for_file: use_build_context_synchronously
import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_bidding_service.dart';
import 'package:backend/models/be_UIbidding.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_pagetransition.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_product.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key, required String contractorId});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final supabase = Supabase.instance.client;
  final Set<String> _finalizedProjects = {};

  List<Map<String, dynamic>> projects = [];
  Map<String, double> highestBids = {};
  bool isLoading = true;
  String? contractorId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadContractorId() async {
    final id = await UserService().getContractorId();
    setState(() {
      contractorId = id;
    });
  }

  Future<void> _loadProjects() async {
    try {
      final response = await supabase
          .from('Projects')
          .select(
            'project_id, type, description, duration, min_budget, max_budget, created_at, contractee_id',
          )
          .eq('status', 'pending')
          .neq('duration', 0);

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

  Future<void> _loadHighestBids() async {
    final highestBidsData = await BiddingService().getProjectHighestBids();
    setState(() {
      highestBids = highestBidsData;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadContractorId(),
        _loadProjects(),
        _loadHighestBids(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Bidding"),
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
                    onTap: () => transitionBuilder(context, DashboardScreen(contractorId: contractorId!)),
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
                    onTap: () => transitionBuilder(context, ProductPanelScreen()),
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
                Row(
                  children: [
                    TextButton(
                      onPressed: _loadData,
                      child: Text(
                        "Refresh",
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
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
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
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
                        onTap: () => UIBidding.showDetails(context, project, hasAlreadyBid),
                        child: UIBidding.contracteeProjects(
                          projectId: project['project_id'].toString(),
                          type: project['type'] ?? 'Unknown',
                          durationDays: project['duration'] ?? 0,
                          imagePath: 'kitchen.jpg',
                          highestBid: highestBids[project['project_id'].toString()] ?? 0.0,
                          createdAt: (project['created_at'] != null && project['created_at'].toString().isNotEmpty)
                              ? DateTime.parse(project['created_at'].toString()).toLocal()
                              : DateTime.now(),
                          finalizedProjects: _finalizedProjects,
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
}
