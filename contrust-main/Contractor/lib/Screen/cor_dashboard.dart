// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use
import 'dart:async';
import 'dart:typed_data';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/services/contractor services/cor_dashboardservice.dart';
import 'package:backend/services/both services/be_realtime_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/builddashboard.dart';
import 'package:flutter/material.dart' hide BottomNavigationBar;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'cor_verification.dart';

class DashboardScreen extends StatefulWidget {
  final String contractorId;
  const DashboardScreen({super.key, required this.contractorId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.user.id.isEmpty) {
        context.go('/logincontractor');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.contractorId.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : DashboardUI(contractorId: widget.contractorId);
  }
}

class DashboardUI extends StatefulWidget {
  final String? contractorId;
  const DashboardUI({super.key, required this.contractorId});

  @override
  State<DashboardUI> createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI>
    with TickerProviderStateMixin {

  final dashboardService = CorDashboardService();
  final realtimeService = RealtimeSubscriptionService();
  
  Map<String, dynamic>? contractorData;
  int activeProjects = 0;
  int completedProjects = 0;
  double rating = 0.0;
  int totalReviews = 0;
  bool loading = true;
  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> localTasks = [];
  double totalEarnings = 0.0;
  List<Map<String, dynamic>> allPayments = [];
  int totalClients = 0;
  Timer? _debounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Verification state
  final List<Map<String, dynamic>> _verificationFiles = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    fetchDashboardData();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.contractorId != null) {
      realtimeService.unsubscribeFromUserChannels(widget.contractorId!);
    }
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    try {
      if (widget.contractorId == null) {
        setState(() => loading = false);
        return;
      }

      setState(() => loading = true);
      
      final data = await dashboardService.loadDashboardData(widget.contractorId!);
      
      setState(() {
        contractorData = data['contractorData'];
        activeProjects = data['activeProjects'];
        completedProjects = data['completedProjects'];
        rating = data['rating'];
        totalReviews = data['totalReviews'] ?? 0;
        recentActivities = data['recentActivities'];
        totalEarnings = data['totalEarnings'];
        allPayments = List<Map<String, dynamic>>.from(data['allPayments'] ?? []);
        totalClients = data['totalClients'];
        localTasks = data['localTasks'];
        loading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ConTrustSnackBar.error(context, 'Error loading dashboard data. Please try again.');
      }
    }
  }

  Future<void> _setupRealtimeSubscriptions() async {
    if (widget.contractorId == null) return;

    void debouncedFetchData() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          fetchDashboardData();
        }
      });
    }

    void debouncedVerificationCheck() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {});
        }
      });
    }

    realtimeService.subscribeToNotifications(
      userId: widget.contractorId!,
      onUpdate: debouncedFetchData,
    );

    realtimeService.subscribeToContractorProjects(
      userId: widget.contractorId!,
      onUpdate: debouncedFetchData,
    );

    realtimeService.subscribeToContractorBids(
      userId: widget.contractorId!,
      onUpdate: debouncedFetchData,
    );

    realtimeService.subscribeToContractorVerification(
      contractorId: widget.contractorId!,
      onUpdate: debouncedVerificationCheck,
    );

    realtimeService.subscribeToUserVerification(
      userId: widget.contractorId!,
      onUpdate: debouncedVerificationCheck,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text('Loading your dashboard...'),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    if (isDesktop) {
      return RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: buildDesktopProjectsAndTasks(),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerificationBanner(),
                const SizedBox(height: 20),
                buildWelcomeCard(),
                const SizedBox(height: 20),
                buildStatsGrid(),
                const SizedBox(height: 20),
                buildHiringRequestContainer(),
                const SizedBox(height: 20),
                buildMobileProjectsAndTasks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return FutureBuilder<Map<String, bool>>(
      future: _checkVerificationStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        final result = snapshot.data ?? {'verified': false, 'hasSubmitted': false};
        final isVerified = result['verified']!;
        if (isVerified) {
          return const SizedBox.shrink();
        }

        final status = result['hasSubmitted']! ? 'submitted' : 'pending';
        final title = status == 'submitted' ? 'Verification Submitted' : 'Account Pending Verification';
        final description = status == 'submitted' 
            ? 'Your documents are under review. You can resubmit if needed.'
            : 'Your account is being reviewed. Please submit verification documents to complete your registration.';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showVerificationDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        minimumSize: const Size(double.infinity, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Manual'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'manual\nwait for the Super Admin to verify your account',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to verification page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const VerificationPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        minimumSize: const Size(double.infinity, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Automatic'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'automatic\nmake sure your name is the same as the one in the photo',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, bool>> _checkVerificationStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return {'verified': false, 'hasSubmitted': false};

      final userResp = await Supabase.instance.client
          .from('Users')
          .select('verified')
          .eq('users_id', session.user.id)
          .maybeSingle();

      final userVerified = userResp != null && (userResp['verified'] == true);

      final verificationResp = await Supabase.instance.client
          .from('Verification')
          .select('verify_id')
          .eq('contractor_id', session.user.id)
          .maybeSingle();

      final hasSubmitted = verificationResp != null;

      return {'verified': userVerified, 'hasSubmitted': hasSubmitted};
    } catch (e) {
      return {'verified': false, 'hasSubmitted': false};
    }
  }

  Widget buildWelcomeCard() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
      totalReviews,
      onDataRefresh: fetchDashboardData,
      onShowVerificationDialog: _showVerificationDialog,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.allPayments = allPayments;
    return buildMethods.buildWelcomeCard();
  }

  Widget buildStatsGrid() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
      totalReviews,
      onDataRefresh: fetchDashboardData,
      onShowVerificationDialog: _showVerificationDialog,
    );
    buildMethods.allPayments = allPayments;
    return buildMethods.buildStatsGrid();
  }

  Widget buildDesktopProjectsAndTasks() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
      totalReviews,
      onDataRefresh: fetchDashboardData,
      onShowVerificationDialog: _showVerificationDialog,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.allPayments = allPayments;
    buildMethods.localTasks = localTasks;
    return buildMethods.buildDesktopProjectsAndTasks();
  }

  Widget buildHiringRequestContainer() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
      totalReviews,
      onDataRefresh: fetchDashboardData,
      onShowVerificationDialog: _showVerificationDialog,
    );
    return buildMethods.buildHiringRequestContainer();
  }

  Widget buildMobileProjectsAndTasks() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
      totalReviews,
      onDataRefresh: fetchDashboardData,
      onShowVerificationDialog: _showVerificationDialog,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.allPayments = allPayments;
    buildMethods.localTasks = localTasks;
    return buildMethods.buildMobileProjectsAndTasks();
  }

  void _showVerificationDialog(BuildContext context) async {
    // Create a local copy of files for the dialog
    List<Map<String, dynamic>> dialogFiles = List.from(_verificationFiles);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.upload_file,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Upload Verification Document',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Please upload your identification documents (ID, business permit, etc.) for verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 20),

                            // Display selected file
                            if (dialogFiles.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      dialogFiles.first['extension']?.toLowerCase() == 'pdf'
                                          ? Icons.picture_as_pdf
                                          : Icons.image,
                                      color: dialogFiles.first['extension']?.toLowerCase() == 'pdf'
                                          ? Colors.red
                                          : Colors.blue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        dialogFiles.first['name'] as String? ?? 'Unknown file',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          dialogFiles.clear();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                    allowMultiple: false,
                                  );

                                  if (result != null) {
                                    final newFiles = result.files.map((file) => {
                                      'name': file.name,
                                      'bytes': file.bytes,
                                      'extension': file.extension,
                                    }).toList();

                                    setState(() {
                                      dialogFiles.clear();
                                      dialogFiles.addAll(newFiles);
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error picking files: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Select File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: dialogFiles.isNotEmpty
                                        ? () => Navigator.of(context).pop({'files': dialogFiles})
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Done'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await _handleVerificationSubmission(List<Map<String, dynamic>>.from(result['files'] ?? []));
    }
  }

  Future<void> _handleVerificationSubmission(List<Map<String, dynamic>> files) async {
    if (files.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      final contractorId = widget.contractorId;

      if (contractorId == null) {
        throw Exception('Contractor ID is null');
      }

      final existing = await supabase
          .from('Verification')
          .select('verify_id')
          .eq('contractor_id', contractorId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ConTrustSnackBar.error(context, 'You have already submitted verification documents. Please wait for review or contact support if needed.');
        }
        return;
      }

      final uploadResults = <Map<String, dynamic>>[];

      for (final file in files) {
        final fileData = file;
        final fileBytes = fileData['bytes'] as Uint8List;
        final fileName = fileData['name'] as String;
        final extension = fileData['extension'] as String? ?? '';
        final isImage = ['jpg', 'jpeg', 'png'].contains(extension.toLowerCase());

        final url = await UserService().uploadImage(
          fileBytes,
          'verification',
          folderPath: contractorId,
          fileName: fileName,
        );

        uploadResults.add({
          'file_name': file['name'],
          'file_path': url,
          'file_type': isImage ? 'image' : 'document',
          'uploaded_at': DateTime.now().toIso8601String(),
        });
      }

      // Insert verification records
      for (final uploadResult in uploadResults) {
        await supabase.from('Verification').insert({
          'contractor_id': contractorId,
          'doc_url': uploadResult['file_path'],
          'uploaded_at': DateTime.now().toUtc().toIso8601String(),
          'file_type': uploadResult['file_type'],
        });
      }

      await supabase.from('Contractor').update({
        'verification_status': 'submitted',
      }).eq('contractor_id', contractorId);

      if (mounted) {
        ConTrustSnackBar.show(
          context,
          'Verification documents submitted successfully! Your account will be reviewed shortly.',
          type: SnackBarType.success,
        );

        // Refresh dashboard data
        await fetchDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to submit verification documents: $e');
      }
    }
  }
}
