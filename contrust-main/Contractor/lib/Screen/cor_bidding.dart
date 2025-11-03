// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
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

  // Preserve inputs across rebuilds
  final TextEditingController bidController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> projects = [];
  Map<String, double> highestBids = {};
  Map<String, Map<String, dynamic>> contracteeInfo = {};
  bool isLoading = true;
  String? contractorId;
  Map<String, dynamic>? selectedProject;
  List<Map<String, dynamic>> contractorBids = [];

  Stream<List<Map<String, dynamic>>>? _biddingStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _biddingStream = FetchService().streamBiddingProjects();
  }

  Future<void> _loadBiddingData(List<Map<String, dynamic>> streamProjects) async {
    try {
      final data = await _biddingService.loadBiddingData();
      
      if (!mounted) return;
      
      if (data['success']) {
        setState(() {
          contractorId = data['contractorId'];
          projects = streamProjects; 
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
        ConTrustSnackBar.error(context, 'Error loading data: $e');
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _biddingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading bidding data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeStream();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadBiddingData(snapshot.data!);
            }
          });

          final builder = BiddingUIBuildMethods(
            context: context,
            isLoading: isLoading,
            projects: projects,
            highestBids: highestBids,
            onRefresh: () {
              setState(() {
                _initializeStream();
              });
            },
            hasAlreadyBid: _biddingService.hasAlreadyBid,
            finalizedProjects: finalizedProjects,
            selectedProject: selectedProject,
            contracteeInfo: contracteeInfo,
            contractorBids: contractorBids,
            bidController: bidController,
            messageController: messageController,
            onProjectSelected: (project) {
              if (mounted) {
                setState(() {
                  selectedProject = project;
                });
              }
            },
          );
          return builder.buildBiddingUI();
        },
      ),
    );
  }

  @override
  void dispose() {
    bidController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
