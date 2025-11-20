// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:async';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_payment_service.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/models/be_payment_modal.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/services/both services/be_receipt_service.dart';
import 'package:contractee/build/buildongoing.dart';
import 'package:contractee/pages/cee_project_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:backend/build/html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:backend/build/ui_web_stub.dart' if (dart.library.html) 'dart:ui_web' as ui_web;
import 'package:supabase_flutter/supabase_flutter.dart';

class CeeOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CeeOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CeeOngoingProjectScreen> createState() => _CeeOngoingProjectScreenState();
}

class _CeeOngoingProjectScreenState extends State<CeeOngoingProjectScreen> {
  final TextEditingController reportController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController costNoteController = TextEditingController();
  final TextEditingController progressController = TextEditingController();

  bool isEditing = false;
  String selectedTab = 'Tasks'; 
  bool _hasSignedOff = false;
  bool _isSigningOff = false;

  final _fetchService = FetchService();
  final _paymentService = PaymentService();
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? projectData;
  bool isLoading = true;
  Map<String, dynamic>? _paymentSummary;
  Set<DateTime> _paidMilestoneDates = {};
  final List<StreamSubscription> _subscriptions = [];
  Timer? _debounceTimer;
  StreamController<Map<String, dynamic>>? _controller;
  Stream<Map<String, dynamic>>? _projectStream;
  bool _isRetryingRealtime = false;
  bool _isPaymentLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _disposeRealtime();
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _projectStream = _controller!.stream;
    _attachRealtimeListeners();
    _emitAggregatedData();
    _getChatRoomId();
  }

  void _debouncedEmitAggregatedData() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _emitAggregatedData();
    });
  }

  @override
  void dispose() {
    _disposeRealtime();
    reportController.dispose();
    costAmountController.dispose();
    costNoteController.dispose();
    progressController.dispose();
    super.dispose();
  }

  void _disposeRealtime() {
    _debounceTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _controller?.close();
    _controller = null;
    _isRetryingRealtime = false;
  }

  void _attachRealtimeListeners() {
    final supabase = Supabase.instance.client;
    
    void safeListen(Stream stream, String tableName) {
      _subscriptions.add(
        stream.listen(
          (_) => _debouncedEmitAggregatedData(),
          onError: (error) {
            if (mounted && !_isRetryingRealtime) {
              debugPrint('Realtime subscription error for $tableName: $error');
              _isRetryingRealtime = true;
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  for (final sub in _subscriptions) {
                    sub.cancel();
                  }
                  _subscriptions.clear();
                  _isRetryingRealtime = false;
                  _attachRealtimeListeners();
                } else {
                  _isRetryingRealtime = false;
                }
              });
            }
          },
          cancelOnError: false,
        ),
      );
    }
    
    try {
      safeListen(
        supabase
            .from('Projects')
            .stream(primaryKey: ['project_id'])
            .eq('project_id', widget.projectId),
        'Projects',
      );
      safeListen(
        supabase
            .from('ProjectTasks')
            .stream(primaryKey: ['task_id'])
            .eq('project_id', widget.projectId),
        'ProjectTasks',
      );
      safeListen(
        supabase
            .from('ProjectReports')
            .stream(primaryKey: ['report_id'])
            .eq('project_id', widget.projectId),
        'ProjectReports',
      );
      safeListen(
        supabase
            .from('ProjectPhotos')
            .stream(primaryKey: ['photo_id'])
            .eq('project_id', widget.projectId),
        'ProjectPhotos',
      );
      safeListen(
        supabase
            .from('ProjectMaterials')
            .stream(primaryKey: ['material_id'])
            .eq('project_id', widget.projectId),
        'ProjectMaterials',
      );
      safeListen(
        supabase
            .from('Contracts')
            .stream(primaryKey: ['contract_id'])
            .eq('project_id', widget.projectId),
        'Contracts',
      );
    } catch (e) {
      debugPrint('Error setting up realtime listeners: $e');
    }
  }

  Future<void> _emitAggregatedData() async {
    try {
      final data = await _loadProjectData();
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
    } catch (e) {
      // 
    }
  }

  Future<void> refreshProjectData({VoidCallback? onComplete}) async {
    await loadData();
    await _emitAggregatedData();
    onComplete?.call();
  }

  Future<Map<String, dynamic>> _loadProjectData() async {
    final projectDetails = await _fetchService.fetchProjectDetails(widget.projectId);
    if (projectDetails == null) {
      return {
        'projectDetails': {},
        'tasks': [],
        'reports': [],
        'photos': [],
        'costs': [],
        'contracts': [],
        'progress': 0.0,
      };
    }

    final tasks = await _fetchService.fetchProjectTasks(widget.projectId);
    final reports = await _fetchService.fetchProjectReports(widget.projectId);
    final photos = await _fetchService.fetchProjectPhotos(widget.projectId);
    final costs = await _fetchService.fetchProjectCosts(widget.projectId);

    Map<String, dynamic>? contractData;
    final contractId = projectDetails['contract_id'];
    if (contractId != null) {
      try {
        contractData = await _fetchService.fetchContractWithDetails(
          contractId,
          contracteeId: supabase.auth.currentUser?.id,
        );
      } catch (e) {
        //
      }
    }

    final progress = (projectDetails['progress'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'projectDetails': projectDetails,
      'tasks': tasks,
      'reports': reports,
      'photos': photos,
      'costs': costs,
      'contracts': contractData != null ? [contractData] : [],
      'progress': progress,
    };
  }

  Future<void> _getChatRoomId() async {
    try {
      await _fetchService.fetchChatRoomId(widget.projectId);
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error getting chatroom_id:');
      }
    }
  }

  Future<void> _checkChatPermission(Map<String, dynamic>? project) async {
    try {
      if (project != null) {
        final contractorId = project['contractor_id'];
        final contracteeId = supabase.auth.currentUser?.id;
        if (contractorId != null && contracteeId != null) {
          await functionConstraint(contractorId, contracteeId);
        }
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error checking chat permission: ');
      }
    }
  }

  Future<void> _loadContractorData(Map<String, dynamic>? project) async {
    try {
      if (project != null) {
        final contractorId = project['contractor_id'];
        if (contractorId != null && contractorId.toString().isNotEmpty) {
          await supabase
              .from('Contractor')
              .select('firm_name, profile_photo')
              .eq('contractor_id', contractorId.toString())
              .maybeSingle();
        }
      }
    } catch (e) {
      debugPrint('Error loading contractor data: $e');
    }
  }

  Future<void> loadData() async {
    try {
      setState(() => isLoading = true);
      
      final results = await Future.wait<dynamic>([
        _loadProjectData(),
        _paymentService.getPaymentSummary(widget.projectId),
        _paymentService.getPaymentHistory(widget.projectId),
      ]);
      
      final data = results[0] as Map<String, dynamic>;
      final paymentSummary = results[1] as Map<String, dynamic>;
      final paymentHistoryRaw = results[2] as List;
      final paymentHistory = List<Map<String, dynamic>>.from(paymentHistoryRaw);
      final paidMilestoneDates = _calculatePaidMilestoneDates(paymentHistory);
      
      final projectDetails = data['projectDetails'] as Map<String, dynamic>?;
      if (projectDetails == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          projectData = null;
        });
        ConTrustSnackBar.error(context, 'Project not found. Please check the project ID.');
      }
        return;
      }
      
      final contracts = data['contracts'] as List?;
      if (contracts != null && contracts.isNotEmpty) {
      }
      
      if (mounted) {
        setState(() {
          projectData = projectDetails;
          _paymentSummary = paymentSummary;
          _paidMilestoneDates = paidMilestoneDates;
          isLoading = false;
        });
      }
      
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
      
      _checkChatPermission(projectDetails);
      _loadContractorData(projectDetails);
    } catch (e) {
      debugPrint('Error in loadData: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          projectData = null;
        });
        ConTrustSnackBar.error(context, 'Error loading project data. Please try again. $e');
      }
    }
  }

  void onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  Set<DateTime> _calculatePaidMilestoneDates(List<Map<String, dynamic>> payments) {
    final paidDates = <DateTime>{};

    for (final payment in payments) {
      final status = payment['payment_status']?.toString().toLowerCase();
      if (status != 'completed') {
        continue;
      }

      final type = payment['payment_type']?.toString().toLowerCase();
      final hasMilestoneInfo = type == 'milestone' || payment['milestone_number'] != null;
      if (!hasMilestoneInfo) {
        continue;
      }

      final paidAtRaw = payment['paid_at'] ?? payment['payment_date'] ?? payment['date'] ?? payment['created_at'];
      DateTime? parsed;
      if (paidAtRaw is String && paidAtRaw.isNotEmpty) {
        parsed = DateTime.tryParse(paidAtRaw);
      } else if (paidAtRaw is DateTime) {
        parsed = paidAtRaw;
      }

      if (parsed != null) {
        final local = parsed.toLocal();
        paidDates.add(DateTime(local.year, local.month, local.day));
      }
    }

    return paidDates;
  }

  static const int _signedUrlExpirationSeconds = 60 * 60 * 24;

  Future<String?> createSignedPhotoUrl(String? path) async {
    if (path == null) return null;
    try {
      final response = await supabase.storage
          .from('projectphotos')
          .createSignedUrl(path, _signedUrlExpirationSeconds);
      return response;
    } catch (e) {
      debugPrint('Error creating signed photo URL: $e');
      return null;
    }
  }

  void onViewReport(Map<String, dynamic> report) {
    CeeOngoingBuildMethods.showReportDialog(context, report);
  }

  void onViewPhoto(Map<String, dynamic> photo) {
    CeeOngoingBuildMethods.showPhotoDialog(context, photo, createSignedPhotoUrl);
  }

  void onViewMaterial(Map<String, dynamic> material) {
    CeeOngoingBuildMethods.showMaterialDetailsDialog(context, material);
  }

  Future<void> _showPaymentHistory() async {
    try {
      final paymentSummary = await _paymentService.getPaymentSummary(widget.projectId);
      final payments = await _paymentService.getPaymentHistory(widget.projectId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Payment History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Paid:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            '₱${(paymentSummary['total_paid'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      if (paymentSummary['total_amount'] != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Contract Amount:', style: TextStyle(fontSize: 14)),
                            Text(
                              '₱${(paymentSummary['total_amount'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remaining:', style: TextStyle(fontSize: 14)),
                            Text(
                              '₱${(paymentSummary['remaining'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: double.parse(paymentSummary['percentage_paid'] ?? '0') / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${paymentSummary['percentage_paid']}% Paid',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: payments.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No payments have been recorded for this project.'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: payments.length,
                            itemBuilder: (context, index) {
                              final payment = payments[index];
                              final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
                              final paidAtRaw = payment['paid_at'] ?? payment['payment_date'] ?? payment['date'] ?? payment['created_at'];
                              DateTime? paidAt;
                              if (paidAtRaw is String && paidAtRaw.isNotEmpty) {
                                paidAt = DateTime.tryParse(paidAtRaw);
                              } else if (paidAtRaw is DateTime) {
                                paidAt = paidAtRaw;
                              }

                              final paymentType = payment['payment_type']?.toString() ?? 'payment';
                              final status = (payment['payment_status']?.toString().toUpperCase() ?? 'COMPLETED');
                              final isCompleted = status == 'COMPLETED';
                              final isMobile = MediaQuery.of(context).size.width < 700;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: isCompleted
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 20,
                                        )
                                      : null,
                                  title: Text(
                                    '₱${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (paidAt != null)
                                        Text(
                                          DateFormat('MMM d, yyyy • h:mm a').format(paidAt),
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        paymentType == 'milestone'
                                            ? (payment['milestone_description']?.toString() ?? 'Milestone payment')
                                            : (payment['description']?.toString() ?? 'Project payment'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: isMobile
                                      ? null
                                      : Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                          ),
                                        ),
                                  onTap: () => _showPaymentDetailsDialog(payment),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading payment history: $e');
      }
    }
  }

  void _showPaymentDetailsDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildPaymentDetailsDialog(dialogContext, payment),
    );
  }

  Widget _buildPaymentDetailsDialog(BuildContext dialogContext, Map<String, dynamic> payment) {
    final receiptPath = payment['receipt_path'] as String?;
    final hasReceipt = receiptPath != null && receiptPath.isNotEmpty;
    final amountValue = (payment['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final reference = (payment['payment_reference'] ?? payment['payment_intent_id'] ?? 'N/A').toString();
    final rawDate = payment['paid_at'] ?? payment['payment_date'] ?? payment['date'] ?? payment['created_at'];
    final paymentDate = _formatPaymentDate(rawDate);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black.withOpacity(0.5),
            width: 0.5,
          ),
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
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Payment Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasReceipt) ...[
                      Text(
                        'Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 320, maxHeight: 480),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<String?>(
                            future: ReceiptService.getReceiptSignedUrl(receiptPath, expirationSeconds: 3600),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Unable to load the receipt at this time.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return _buildPdfViewer(snapshot.data!);
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          'No e-receipt was provided for this transaction.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildPaymentDetailField('Amount Paid', '₱$amountValue'),
                    _buildPaymentDetailField('Reference', reference),
                    _buildPaymentDetailField('Payment Date', paymentDate),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPaymentDate(dynamic value) {
    if (value == null) return 'N/A';
    try {
      final dt = DateTime.parse(value.toString());
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildPaymentDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer(String pdfUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: kIsWeb ? _buildWebPdfViewer(pdfUrl) : _buildMobilePdfViewer(pdfUrl),
      ),
    );
  }

  Widget _buildWebPdfViewer(String pdfUrl) {
    if (!kIsWeb) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade50,
        child: const Center(
          child: Text('PDF viewer not available on this platform'),
        ),
      );
    }

    final viewType = 'pdf-viewer-${pdfUrl.hashCode.abs()}';

    try {
      if (kIsWeb) {
        ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
          final iframe = html.IFrameElement()
            ..src = pdfUrl
            ..style.border = 'none';

          return iframe;
        });
      }
    } catch (_) {
      // ignore registration errors
    }

    return HtmlElementView(viewType: viewType);
  }

  Widget _buildMobilePdfViewer(String pdfUrl) {
    return SfPdfViewer.network(pdfUrl);
  }

  Future<void> _handlePayment() async {
    if (_isPaymentLoading) return;
    
    setState(() => _isPaymentLoading = true);
    
    try {
      final projectDetails = projectData!['projectDetails'] as Map<String, dynamic>? ?? projectData!;
      final projectTitle = (projectDetails['title'] as String?) ?? 'Untitled Project';

      final paymentService = PaymentService();
      final paymentSummary = _paymentSummary ?? await paymentService.getPaymentSummary(widget.projectId);
      _paymentSummary ??= paymentSummary;

      final contractType = (paymentSummary['contract_type'] as String?) ?? '';

      final isMilestone = await paymentService.isMilestoneContract(widget.projectId);

      if (!mounted) return;

      Future<void> onPaymentSuccess() async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          await refreshProjectData();
        }
      }

      if (isMilestone) {
        await PaymentModal.show(
          context: context,
          projectId: widget.projectId,
          projectTitle: projectTitle,
          amount: 0.0,
          onPaymentSuccess: onPaymentSuccess,
        );
        return;
      }

      final customAmount = await _showAmountInputDialog(contractType);
      if (customAmount == null) return;

      if (!mounted) return;

      await PaymentModal.show(
        context: context,
        projectId: widget.projectId,
        projectTitle: projectTitle,
        amount: customAmount,
        customAmount: customAmount,
        onPaymentSuccess: onPaymentSuccess,
        forceRegularModal: true,
      );
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error processing payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPaymentLoading = false);
      }
    }
  }

  Future<void> _handleSignOff() async {
    // Prevent multiple sign-off attempts while one is in progress or already completed
    if (_isSigningOff || _hasSignedOff) return;

    if (mounted) {
      setState(() {
        _isSigningOff = true;
      });
    } else {
      _isSigningOff = true;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ConTrustSnackBar.error(
              context, 'Please sign in again to sign off the project.');
        }
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Container(
                  width: double.infinity,
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
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Sign off project?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This will mark the project as completed. You can still make payments afterwards if needed.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Sign off'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (confirm != true) return;

      await ProjectService().signOffProject(widget.projectId, userId);

      if (mounted) {
        setState(() {
          _hasSignedOff = true;
        });
        ConTrustSnackBar.success(
            context, 'Project signed off successfully.');
        await refreshProjectData();
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to sign off project: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOff = false;
        });
      } else {
        _isSigningOff = false;
      }
    }
  }

  Future<double?> _showAmountInputDialog(String? contractType) async {
    final controller = TextEditingController();
    String dialogTitle = 'Enter Payment Amount';
    String dialogMessage = 'Please enter the amount you want to pay for this project.';

    final normalizedType = (contractType ?? '')
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .toLowerCase();
    final allowsVariableAmount = {
      'time_and_materials',
      'cost_plus',
      'custom',
    }.contains(normalizedType);

    if (allowsVariableAmount) {
      if (normalizedType == 'time_and_materials') {
        dialogTitle = 'Time & Materials Payment';
        dialogMessage = 'Enter the payment amount based on hours worked and materials used.';
      } else if (normalizedType == 'cost_plus') {
        dialogTitle = 'Cost Plus Payment';
        dialogMessage = 'Enter the payment amount based on actual costs plus overhead.';
      } else {
        dialogTitle = 'Custom Contract Payment';
        dialogMessage = 'Enter the payment amount as agreed in the custom contract.';
      }
    } else if ((contractType ?? '').isNotEmpty) {
      dialogMessage = 'Enter the exact remaining balance to complete this payment.';
    }

    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dialogMessage,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Builder(
                      builder: (context) {
                        final contractType = _paymentSummary?['contract_type'] as String? ?? '';
                        final isLumpSum = contractType.toLowerCase().contains('lump') || 
                                         contractType.toLowerCase() == 'lump_sum';
                        final isMilestone = contractType.toLowerCase().contains('milestone') || 
                                              contractType.toLowerCase() == 'lump_sum';
                        
                        if (!isLumpSum && _paymentSummary != null && _paymentSummary!['remaining'] != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isMilestone ? Colors.red.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isMilestone ? Colors.red.shade200 : Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: isMilestone ? Colors.red.shade700 : Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Amount to be Paid',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${(_paymentSummary!['remaining'] as num).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isMilestone ? Colors.red.shade700 : Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱',
                        hintText: _paymentSummary != null && _paymentSummary!['remaining'] != null
                            ? (_paymentSummary!['remaining'] as num).toStringAsFixed(2)
                            : '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        helperText: 'Minimum: ₱100.00',
                        helperStyle: TextStyle(color: Colors.grey.shade600),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) {
                                ConTrustSnackBar.warning(context, 'Please enter an amount');
                                return;
                              }
                              
                              final amount = double.tryParse(text);
                              if (amount == null) {
                                ConTrustSnackBar.error(context, 'Invalid amount format');
                                return;
                              }
                              
                              if (amount < 100) {
                                ConTrustSnackBar.warning(context, 'Minimum payment amount is ₱100.00');
                                return;
                              }

                              // No longer require amount to exactly match remaining balance
                              
                              Navigator.pop(context, amount);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _projectStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.amber,
                ),
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              final isRealtimeError = error.toString().contains('RealtimeSubscribeException');
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: isRealtimeError ? Colors.orange.shade300 : Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRealtimeError 
                          ? 'Connection issue - retrying...' 
                          : 'Error loading project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _initializeStreams();
                          });
                        }
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

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Project not found.'),
              );
            }

            final data = snapshot.data!;
            projectData = data;

            final projectDetails = data['projectDetails'] as Map<String, dynamic>?;
            if (projectDetails != null) {
              _checkChatPermission(projectDetails);
              _loadContractorData(projectDetails);
            }

            return _buildResponsiveContent();
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveContent() {
    return _buildDesktopContent();
  }

  Widget _buildDesktopContent() {
    final projectDetails =
        projectData!['projectDetails'] as Map<String, dynamic>? ?? projectData!;
    final projectStatus = projectDetails['status'] ?? '';
    final remaining = (_paymentSummary?['remaining'] as num?)?.toDouble();
    final hasRemainingBalance = remaining == null ? true : remaining > 0;
    final isFullyPaid = remaining != null && remaining <= 0;

    final canMakePayment = hasRemainingBalance;
    final canSignOff = projectStatus != 'completed' && !_hasSignedOff;
    
    return RefreshIndicator(
      onRefresh: () async {
        await _emitAggregatedData();
        await _getChatRoomId();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: CeeProjectDashboard(
            projectId: widget.projectId,
            projectData: projectData,
            createSignedPhotoUrl: createSignedPhotoUrl,
            onPayment: canMakePayment
                ? () async {
                    await _handlePayment();
                    await refreshProjectData();
                  }
                : null,
            isPaid: isFullyPaid,
            onViewPaymentHistory: () async {
              await _showPaymentHistory();
              await refreshProjectData();
            },
            paymentButtonText: null,
            paidMilestoneDates: _paidMilestoneDates,
            isPaymentLoading: _isPaymentLoading,
            onSignOff: canSignOff
                ? () async {
                    await _handleSignOff();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
