// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import '../build/buildbidding.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/both services/be_realtime_service.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key, required String contractorId});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final _biddingService = CorBiddingService();
  final Set<String> finalizedProjects = {};
  final RealtimeSubscriptionService realtimeService = RealtimeSubscriptionService();

  // Preserve inputs across rebuilds
  final TextEditingController bidController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> projects = [];
  Map<String, double> highestBids = {};
  Map<String, Map<String, dynamic>> contracteeInfo = {};
  String? contractorId;
  Map<String, dynamic>? selectedProject;
  List<Map<String, dynamic>> contractorBids = [];
  bool _isLoadingData = true;

  Stream<List<Map<String, dynamic>>>? _biddingStream;
  RealtimeChannel? _contractorBidsChannel;
  RealtimeChannel? _allBidsChannel;

  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
    _initializeStream();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() {
          _isVerified = false;
        });
        return;
      }

      final resp = await Supabase.instance.client
          .from('Users')
          .select('verified')
          .eq('users_id', session.user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isVerified = resp != null && (resp['verified'] == true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerified = false;  
        });
      }
    }
  }

  void _initializeStream() {
    setState(() {
      _isLoadingData = true;
    });
    _biddingStream = FetchService().streamBiddingProjects();
  }

  void _ensureRealtimeForBids() {
    final String? uid = contractorId;
    if (uid != null && _contractorBidsChannel == null) {
      _contractorBidsChannel = realtimeService.subscribeToContractorBids(
        userId: uid,
        onUpdate: () async {
          try {
            final bids = await _biddingService.getContractorBids(uid);
            if (!mounted) return;
            setState(() {
              contractorBids = bids;
            });
          } catch (_) {}
        },
      );
    }

    _allBidsChannel ??= Supabase.instance.client
          .channel('bids_all')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'Bids',
            callback: (payload) async {
              try {
                final hb = await _biddingService.loadHighestBids();
                if (!mounted) return;
                setState(() {
                  highestBids = hb;
                });
              } catch (_) {}
            },
          )
          .subscribe();
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
          _isLoadingData = false;
        });
        _ensureRealtimeForBids();
      } else {
        setState(() {
          _isLoadingData = false;
        });
        if (mounted) {
          ConTrustSnackBar.error(context, data['error'] ?? 'Error loading data');
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
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

          if (_isLoadingData && snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isLoadingData) {
                _loadBiddingData(snapshot.data!);
              }
            });

            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (!_isLoadingData && snapshot.hasData) {
            final streamProjectIds = snapshot.data!.map((p) => p['project_id']?.toString()).toSet();
            final currentProjectIds = projects.map((p) => p['project_id']?.toString()).toSet();
            
            if (projects.isNotEmpty && 
                (currentProjectIds.length != streamProjectIds.length ||
                 !currentProjectIds.containsAll(streamProjectIds))) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isLoadingData = true;
                  });
                  _loadBiddingData(snapshot.data!);
                }
              });
            } else if (projects.isEmpty && snapshot.data!.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isLoadingData = true;
                  });
                  _loadBiddingData(snapshot.data!);
                }
              });
            }
          }

          // Keep selected project in sync with latest stream data
          Map<String, dynamic>? currentSelected;
          if (selectedProject != null) {
            final selId = selectedProject!['project_id']?.toString();
            currentSelected = projects.firstWhere(
              (p) => p['project_id']?.toString() == selId,
              orElse: () => selectedProject!,
            );
          }

          final builder = BiddingUIBuildMethods(
            context: context,
            projects: projects,
            highestBids: highestBids,
            onRefresh: () {
              setState(() {
                _initializeStream();
              });
            },
            hasAlreadyBid: _biddingService.hasAlreadyBid,
            finalizedProjects: finalizedProjects,
            selectedProject: currentSelected,
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
            isVerified: _isVerified,
          );
          return builder.buildBiddingUI();
        },
      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bidController.dispose();
    messageController.dispose();
    try {
      if (contractorId != null) {
        realtimeService.unsubscribeFromUserChannels(contractorId!);
      }
      _allBidsChannel?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }
}
