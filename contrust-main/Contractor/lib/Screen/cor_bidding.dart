// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import '../build/buildbidding.dart';
import 'package:flutter/material.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key, required String contractorId});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final _biddingService = CorBiddingService();
  final Set<String> finalizedProjects = {};

  List<Map<String, dynamic>> projects = [];
  Map<String, double> highestBids = {};
  Map<String, Map<String, dynamic>> contracteeInfo = {};
  bool isLoading = true;
  String? contractorId;
  Map<String, dynamic>? selectedProject;
  List<Map<String, dynamic>> contractorBids = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);

    try {
      final data = await _biddingService.loadBiddingData();
      
      if (!mounted) return;
      
      if (data['success']) {
        setState(() {
          contractorId = data['contractorId'];
          projects = data['projects'];
          contracteeInfo = data['contracteeInfo'];
          highestBids = data['highestBids'];
          contractorBids = data['contractorBids'];
          isLoading = false;
        });
      } else {
        if (mounted) {
          ConTrustSnackBar.error(context, data['error'] ?? 'Error loading data');
        }
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading data: ');
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    final builder = BiddingUIBuildMethods(
      context: context,
      isLoading: isLoading,
      projects: projects,
      highestBids: highestBids,
      onRefresh: loadData,
      hasAlreadyBid: _biddingService.hasAlreadyBid,
      finalizedProjects: finalizedProjects,
      selectedProject: selectedProject,
      contracteeInfo: contracteeInfo,
      contractorBids: contractorBids,
      onProjectSelected: (project) {
        if (mounted) {
          setState(() {
            selectedProject = project;
          });
        }
      },
    );
    return Scaffold(
      body: builder.buildBiddingUI(),
    );
  }
}
