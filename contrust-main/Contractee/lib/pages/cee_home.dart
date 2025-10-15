// ignore_for_file: use_build_context_synchronously

import 'package:backend/models/be_UIapp.dart';
import 'package:backend/services/both%20services/be_bidding_service.dart';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/both%20services/be_project_service.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:contractee/build/builddrawer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String contracteeId;

  const HomePage({super.key, required this.contracteeId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final modalSheet = ProjectModal();
  int selectedIndex = -1;

  Map<String, double> highestBids = {};
  Map<String, String?> acceptedBidIds = {};

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> contractors = [];
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;



  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedContractors = await FetchService().fetchContractors();
      final fetchedProjects = await FetchService().fetchUserProjects();
      final fetchedHighestBids = await BiddingService().getProjectHighestBids();

      setState(() {
        contractors = fetchedContractors;
        projects = fetchedProjects;
        highestBids = fetchedHighestBids;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Data')),
      );
    }
  }

  void _loadAcceptBidding(String projectId, String bidId) async {
    try {
      await BiddingService().acceptProjectBid(projectId, bidId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid has been accepted successfully.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error in accepting bid')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContracteeShell(
      currentPage: ContracteePage.home,
      contracteeId: widget.contracteeId,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                height: 50,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Suggested Contractor Firms",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 27,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 280,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : contractors.isEmpty
                      ? const Center(child: Text("No contractors found"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: contractors.length,
                          itemBuilder: (context, index) {
                            final contractor = contractors[index];
                            final profilePhoto = contractor['profile_photo'];
                            final profileImage =
                                (profilePhoto == null || profilePhoto.isEmpty)
                                    ? profileUrl
                                    : profilePhoto;
                            final isSelected = selectedIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex =
                                      (selectedIndex == index) ? -1 : index;
                                });
                              },
                              child: Container(
                                width: 200,
                                height: 250,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color.fromARGB(255, 99, 98, 98)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ContractorsView(
                                  id: contractor['contractor_id'] ?? '',
                                  name: contractor['firm_name'] ?? 'Unknown',
                                  profileImage: profileImage,
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Posted Projects",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 27,
                  ),
                ),
                TextButton(
                  onPressed: _loadData,
                  child: Text(
                    "Refresh",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : projects.isEmpty
                    ? const Center(
                        child: Text("You haven't posted any projects yet"),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final projectId = project['project_id'].toString();
                          final highestBid = highestBids[projectId] ?? 0.0;

                          return FutureBuilder<Map<String, dynamic>>(
                            future: supabase
                                .from('Projects')
                                .select('bid_id')
                                .eq('project_id', projectId)
                                .single(),
                            builder: (context, snapshot) {
                              String? acceptedBidId;
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                acceptedBidId = snapshot.data?['bid_id'];
                              }
                              return ProjectView(
                                project: project,
                                projectId: projectId,
                                highestBid: highestBid,
                                duration: project['duration'] ?? 0,
                                createdAt: DateTime.parse(
                                    project['created_at'].toString()),
                                onTap: () async {
                                  await BidsModal.show(
                                    context: context,
                                    projectId: projectId,
                                    acceptBidding: (projectId, bidId) async {
                                      _loadAcceptBidding(projectId, bidId);
                                      setState(() {
                                        acceptedBidIds[projectId] = bidId;
                                      });
                                    },
                                    initialAcceptedBidId: acceptedBidId,
                                  );
                                },
                                handleFinalizeBidding: (bidId) {
                                  return BiddingService()
                                      .acceptProjectBid(projectId, bidId);
                                },
                                onDeleteProject: (projectId) async {
                                  try {
                                    await ProjectService()
                                        .deleteProject(projectId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Project deleted successfully.'),
                                      ),
                                    );
                                    _loadData();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Failed to delete project'),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
          ],
        ),
      ),
    ));
  }


}
