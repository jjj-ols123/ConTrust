// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:backend/services/contractor services/cor_ongoingservices.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/buildongoing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html if (dart.library.html) 'dart:html';
import 'dart:ui_web' as ui_web if (dart.library.html) 'dart:ui_web';

class CorProjectDashboard extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? projectData;
  final String? contractorFirmName;
  final CorOngoingService ongoingService;
  final Future<String?> Function(String?) createSignedPhotoUrl;

  const CorProjectDashboard({
    super.key,
    required this.projectId,
    this.projectData,
    this.contractorFirmName,
    required this.ongoingService,
    required this.createSignedPhotoUrl,
  });

  @override
  State<CorProjectDashboard> createState() => _CorProjectDashboardState();
}

class _CorProjectDashboardState extends State<CorProjectDashboard> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _materials = [];
  bool _isLoading = true;
  
  String? _contracteeName;
  String? _contractType;
  DateTime? _startDate;
  DateTime? _estimatedCompletion;
  List<DateTime> _milestoneDates = []; 
  Map<String, dynamic>? _contractData; 
  String? _projectStatus;
  final FetchService _fetchService = FetchService();
  final TextEditingController _reportController = TextEditingController();

  void _extractMilestoneDates(Map<String, dynamic> contract) {
    final contractTypeData = contract['contract_type'] as Map<String, dynamic>?;
    final contractType = contractTypeData?['template_name'] as String?;
      
    if (contractType?.toLowerCase().contains('lump sum') == true) {
      final fieldValues = contract['field_values'] as Map<String, dynamic>?;
      if (fieldValues != null) {
        _milestoneDates = [];
        for (int i = 1; i <= 10; i++) {
          final milestoneDateStr = fieldValues['Milestone.$i.Date'] as String?;
          if (milestoneDateStr != null && milestoneDateStr.isNotEmpty) {
            try {
              final dateStr = milestoneDateStr.split(' ')[0];
              final parsed = DateTime.parse(dateStr);
              _milestoneDates.add(DateTime(parsed.year, parsed.month, parsed.day));
            } catch (e) {
              //
            }
          }
        }
      } else {
        _milestoneDates = [];
      }
    } else {
      _milestoneDates = [];
    }
  }
  
  String _selectedTab = 'Tasks';
  PageController? _activitiesPageController;
  PageController? _calendarActivitiesPageController;

  @override
  void initState() {
    super.initState();
    if (widget.projectData != null) {
      _updateFromProjectData(widget.projectData!);
    } else {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(CorProjectDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectData != null && widget.projectData != oldWidget.projectData) {
      _updateFromProjectData(widget.projectData!);
    }
  }

  @override
  void dispose() {
    _reportController.dispose();
    _activitiesPageController?.dispose();
    _calendarActivitiesPageController?.dispose();
    super.dispose();
  }

  void _updateFromProjectData(Map<String, dynamic> data) {
    final projectDetails = data['projectDetails'] as Map<String, dynamic>?;
    
    setState(() {
      _tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
      _reports = List<Map<String, dynamic>>.from(data['reports'] ?? []);
      _photos = List<Map<String, dynamic>>.from(data['photos'] ?? []);
      _materials = List<Map<String, dynamic>>.from(data['costs'] ?? []);
      _projectStatus = projectDetails?['status'] as String?;
      _isLoading = false;
    });

    _updateContractInfo(projectDetails);
  }

  Future<void> _updateContractInfo(Map<String, dynamic>? projectDetails) async {
    if (projectDetails == null) {
      return;
    }

    final contracteeId = projectDetails['contractee_id'] as String?;
    if (contracteeId != null) {
      final contracteeData = await _fetchService.fetchContracteeData(contracteeId);
      if (mounted) {
        setState(() {
          _contracteeName = contracteeData?['full_name'] as String?;
        });
      }
    }

    final contractId = projectDetails['contract_id'] as String?;
    if (contractId != null) {
      final contract = await _fetchService.fetchContractWithDetails(
        contractId,
        contractorId: Supabase.instance.client.auth.currentUser?.id,
      );
      if (contract != null && mounted) {
        setState(() {
          _contractData = contract;
          final contractTypeData = contract['contract_type'] as Map<String, dynamic>?;
          _contractType = contractTypeData?['template_name'] as String?;
        });
        _extractMilestoneDates(contract);
      }
    }
    if (mounted) {
      final isCustomContract = _contractType?.toLowerCase() == 'custom';

      setState(() {
        if (_contractData != null && !isCustomContract) {
          final fieldValues = _contractData!['field_values'] as Map<String, dynamic>?;
          if (fieldValues != null) {
            final startDateStr = fieldValues['Project.StartDate'] as String?;
            if (startDateStr != null && startDateStr.isNotEmpty) {
              try {
                final dateStr = startDateStr.split(' ')[0];
                final parsed = DateTime.parse(dateStr);
                _startDate = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                _startDate = null;
              }
            }

            final completionDateStr = fieldValues['Project.CompletionDate'] as String?;
            if (completionDateStr != null && completionDateStr.isNotEmpty) {
              try {
                final dateStr = completionDateStr.split(' ')[0];
                final parsed = DateTime.parse(dateStr);
                _estimatedCompletion = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                _estimatedCompletion = null;
              }
            }
          }
        }

        if (_startDate == null) {
          final startDateStr = projectDetails['start_date'] as String?;
          if (startDateStr != null && startDateStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(startDateStr);
              _startDate = DateTime(parsed.year, parsed.month, parsed.day);
            } catch (_) {
              _startDate = null;
            }
          }
        }

        if (_estimatedCompletion == null) {
          final estimatedCompletionStr = projectDetails['estimated_completion'] as String?;
          if (estimatedCompletionStr != null && estimatedCompletionStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(estimatedCompletionStr);
              _estimatedCompletion = DateTime(parsed.year, parsed.month, parsed.day);
            } catch (_) {
              _estimatedCompletion = null;
            }
          }
        }
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final data = await widget.ongoingService.loadProjectData(
        widget.projectId,
        contractorId: Supabase.instance.client.auth.currentUser?.id,
      );

      final projectDetails = data['projectDetails'] as Map<String, dynamic>?;
      final contracteeId = projectDetails?['contractee_id'] as String?;
      
      if (contracteeId != null) {
        final contracteeData = await _fetchService.fetchContracteeData(contracteeId);
        _contracteeName = contracteeData?['full_name'] as String?;
      }
      
      final contractId = projectDetails?['contract_id'] as String?;
      if (contractId != null) {
        final contract = await _fetchService.fetchContractWithDetails(
          contractId,
          contractorId: Supabase.instance.client.auth.currentUser?.id,
        );
        if (contract != null) {
          _contractData = contract;
          final contractTypeData = contract['contract_type'] as Map<String, dynamic>?;
          _contractType = contractTypeData?['template_name'] as String?;
          _extractMilestoneDates(contract);
        }
      }
      
      if (projectDetails != null) {
        final isCustomContract = _contractType?.toLowerCase() == 'custom';
        
        if (isCustomContract) {
          final startDateStr = projectDetails['start_date'] as String?;
          if (startDateStr != null && startDateStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(startDateStr);
              _startDate = DateTime(parsed.year, parsed.month, parsed.day);
            } catch (_) {
              _startDate = null;
            }
          } else {
            _startDate = null;
          }
          
          final estimatedCompletionStr = projectDetails['estimated_completion'] as String?;
          if (estimatedCompletionStr != null && estimatedCompletionStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(estimatedCompletionStr);
              _estimatedCompletion = DateTime(parsed.year, parsed.month, parsed.day);
            } catch (_) {
              _estimatedCompletion = null;
            }
          } else {
            _estimatedCompletion = null;
          }
        } else if (_contractData != null) {
          final fieldValues = _contractData!['field_values'] as Map<String, dynamic>?;
          if (fieldValues != null) {
            final startDateStr = fieldValues['Project.StartDate'] as String?;
            if (startDateStr != null && startDateStr.isNotEmpty) {
              try {
                final dateStr = startDateStr.split(' ')[0]; 
                final parsed = DateTime.parse(dateStr);
                _startDate = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                _startDate = null;
              }
            } else {
              _startDate = null;
            }

            final completionDateStr = fieldValues['Project.CompletionDate'] as String?;
            if (completionDateStr != null && completionDateStr.isNotEmpty) {
              try {
                final dateStr = completionDateStr.split(' ')[0]; 
                final parsed = DateTime.parse(dateStr);
                _estimatedCompletion = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                _estimatedCompletion = null;
              }
            } else {
              _estimatedCompletion = null;
            }
          } else {
            final startDateStr = projectDetails['start_date'] as String?;
            if (startDateStr != null && startDateStr.isNotEmpty) {
              try {
                final parsed = DateTime.parse(startDateStr);
                _startDate = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                _startDate = null;
              }
            } else {
              _startDate = null;
            }

            final estimatedCompletionStr = projectDetails['estimated_completion'] as String?;
            if (estimatedCompletionStr != null && estimatedCompletionStr.isNotEmpty) {
              try {
                final parsed = DateTime.parse(estimatedCompletionStr);
                _estimatedCompletion = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                _estimatedCompletion = null;
              }
            } else {
              _estimatedCompletion = null;
            }
          }
        } else {
          final startDateStr = projectDetails['start_date'] as String?;
          if (startDateStr != null && startDateStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(startDateStr);
              _startDate = DateTime(parsed.year, parsed.month, parsed.day);
            } catch (_) {
              _startDate = null;
            }
          } else {
            _startDate = null;
          }

          final estimatedCompletionStr = projectDetails['estimated_completion'] as String?;
          if (estimatedCompletionStr != null && estimatedCompletionStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(estimatedCompletionStr);
              _estimatedCompletion = DateTime(parsed.year, parsed.month, parsed.day);
            } catch (_) {
              _estimatedCompletion = null;
            }
          } else {
            _estimatedCompletion = null;
          }
        }
      } else {
        _startDate = null;
        _estimatedCompletion = null;
      }

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
        _reports = List<Map<String, dynamic>>.from(data['reports'] ?? []);
        _photos = List<Map<String, dynamic>>.from(data['photos'] ?? []);
        _materials = List<Map<String, dynamic>>.from(data['costs'] ?? []);
        _projectStatus = projectDetails?['status'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildTwoColumnLayout();
    }
  }

  /// Mobile Layout
  Widget _buildMobileLayout() {
    final project = widget.projectData?['projectDetails'] as Map<String, dynamic>?;
    final projectTitle = project?['title'] ?? 'Project';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.amber, size: 28),
                      onPressed: () => _showProjectInfoDialog(projectTitle),
                      tooltip: 'Project Information',
                    ),
                  ],
                ),
              ),
              _buildMobileCalendarAndActivities(),
              const SizedBox(height: 16),
              _buildMobileTabNavigation(_selectedTab, (tab) {
                setState(() {
                  _selectedTab = tab;
                });
              }),
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: _buildMobileTabContent(_selectedTab),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProjectInfoDialog(String projectTitle) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                              Icons.info,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Project Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildTitleContainer(projectTitle),
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
  }

  Widget _buildMobileCalendarAndActivities() {
    _calendarActivitiesPageController ??= PageController();
    
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      currentPage == 0 ? Icons.calendar_today : Icons.timeline,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentPage == 0 ? 'Calendar' : 'Recent Activities',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 24),
                      onPressed: currentPage > 0
                          ? () {
                              _calendarActivitiesPageController!.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      color: currentPage > 0 ? Colors.amber.shade700 : Colors.grey,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24),
                      onPressed: currentPage < 1
                          ? () {
                              _calendarActivitiesPageController!.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      color: currentPage < 1 ? Colors.amber.shade700 : Colors.grey,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 400,
                child: PageView(
                  controller: _calendarActivitiesPageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  children: [
                    // Calendar Page
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: _buildCalendarWidget(),
                    ),
                    // Recent Activities Page
                    _buildMobileRecentActivitiesContent(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mobile Recent Activities Content
  Widget _buildMobileRecentActivitiesContent() {
    final activities = _tasks.isEmpty && _reports.isEmpty && _photos.isEmpty;

    if (activities) {
      return const Center(
        child: Text('No recent activities'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: OngoingBuildMethods.buildRecentActivityFeed(
        tasks: _tasks,
        reports: _reports,
        photos: _photos,
        maxItems: 20,
      ),
    );
  }

  /// Mobile Tab Navigation
  Widget _buildMobileTabNavigation(String selectedTab, Function(String) onTabChanged) {
    final tabs = ['Tasks', 'Reports', 'Photos', 'Materials'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = selectedTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isActive ? Colors.amber.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Mobile Tab Content
  Widget _buildMobileTabContent(String selectedTab) {
    switch (selectedTab) {
      case 'Tasks':
        return _buildMobileTasksContainer();
      case 'Reports':
        return _buildMobileReportsContainer();
      case 'Photos':
        return _buildMobilePhotosContainer();
      case 'Materials':
        return _buildMobileMaterialsContainer();
      default:
        return _buildMobileTasksContainer();
    }
  }

  /// Mobile Tasks Container
  Widget _buildMobileTasksContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.task, color: Colors.black87, size: MediaQuery.of(context).size.width < 400 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : 12),
                  Text(
                    'To-Dos & Tasks',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _addTask,
                  tooltip: 'Add Task',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text('No tasks added yet'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _getSortedTasks().map((task) => _buildTaskItem(task)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Mobile Reports Container
  Widget _buildMobileReportsContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.black87, size: MediaQuery.of(context).size.width < 400 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : 12),
                  Text(
                    'Progress Reports',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _addReport,
                  tooltip: 'Add Report & Generate PDF',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text('No reports added yet'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _reports.map((report) => _buildReportItem(report)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Mobile Photos Container
  Widget _buildMobilePhotosContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.black87, size: MediaQuery.of(context).size.width < 400 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : 12),
                  Text(
                    'Project Photos',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _addPhoto,
                  tooltip: 'Add Photo',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _photos.isEmpty
                ? const Center(
                    child: Text('No photos added yet'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _photos.map((photo) => _buildPhotoListItem(photo)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Mobile Materials Container
  Widget _buildMobileMaterialsContainer() {
    double totalCost = 0;
    for (var material in _materials) {
      final quantity = (material['quantity'] as num?)?.toDouble() ?? 0.0;
      final unitPrice = (material['unit_price'] as num?)?.toDouble() ?? 0.0;
      totalCost += quantity * unitPrice;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.black87, size: MediaQuery.of(context).size.width < 400 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : 12),
                  Text(
                    'Materials & Costs',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _goToMaterials,
                  tooltip: 'Add Material',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _materials.isEmpty
                ? const Center(
                    child: Text('No materials added yet'),
                  )
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 70),
                        child: Column(
                          children: _materials.map((material) => _buildMaterialItem(material)).toList(),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Cost:',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '₱${totalCost.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Main two-column layout with flex 1 (left) and flex 3 (right)
  Widget _buildTwoColumnLayout() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 
              MediaQuery.of(context).padding.top - 
              MediaQuery.of(context).padding.bottom,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - flex 1
          Expanded(
            flex: 1,
            child: _buildLeftColumn(),
          ),
          // Vertical Divider
          Container(
            width: 1,
            color: Colors.grey.shade300,
          ),
          // Right Column - flex 3
          Expanded(
            flex: 3,
            child: _buildRightColumn(),
          ),
        ],
      ),
    );
  }

  /// Left Column: Title Container, Calendar, Recent Activities
  Widget _buildLeftColumn() {
    final project = widget.projectData?['projectDetails'] as Map<String, dynamic>?;
    final projectTitle = project?['title'] ?? 'Project';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Container with Switch Project
          _buildTitleContainer(projectTitle),
          const SizedBox(height: 16),
          // Calendar Widget
          _buildCalendarWidget(),
          const SizedBox(height: 16),
          // Recent Activities Container
          _buildRecentActivities(),
        ],
      ),
    );
  }

  /// Title Container with Switch Project
  Widget _buildTitleContainer(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By: ${_contracteeName ?? 'Client'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View Contract Button
              IconButton(
                onPressed: _viewContract,
                icon: const Icon(Icons.description, size: 24),
                tooltip: 'View Contract',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.amber.shade700,
                ),
              ),
              if (_projectStatus != 'completed') ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _switchProject,
                  icon: const Icon(Icons.swap_horiz, size: 24),
                  tooltip: 'Switch Project',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.amber.shade700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  /// View Contract Function
  Future<void> _viewContract() async {
    final project = widget.projectData?['projectDetails'] as Map<String, dynamic>?;
    final contractId = project?['contract_id'] as String?;

    if (contractId != null) {
      context.go('/viewcontract/$contractId');
    }
  }

  /// Switch Project Function
  Future<void> _switchProject() async {
    try {
      final contractorId = Supabase.instance.client.auth.currentUser?.id;
      if (contractorId == null) return;

      final projects = await _fetchService.fetchContractorProjectsIncludingCompleted(contractorId);

      if (projects.isEmpty) {
        if (mounted) {
          ConTrustSnackBar.info(context, 'No projects found.');
        }
        return;
      }

      if (projects.length == 1) {
        if (mounted) {
          ConTrustSnackBar.warning(context, 'You only have one project.');
        }
        return;
      }

      final selectedProjectId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Center(
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
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Switch Project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
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
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final isCurrentProject = project['project_id'] == widget.projectId;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isCurrentProject ? Colors.amber.shade50 : null,
                            child: ListTile(
                              selected: isCurrentProject,
                              title: Text(
                                project['title'] ?? 'Untitled Project',
                                style: TextStyle(
                                  fontWeight: isCurrentProject ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(isCurrentProject 
                                ? 'Current Project • ${project['status'] ?? 'N/A'}' 
                                : 'Status: ${project['status'] ?? 'N/A'}'),
                              leading: isCurrentProject 
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : Icon(Icons.folder, color: Colors.amber.shade700),
                              trailing: isCurrentProject 
                                ? null 
                                : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade700),
                              onTap: isCurrentProject 
                                ? null 
                                : () {
                                    Navigator.of(dialogContext).pop(project['project_id']);
                                  },
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
        ),
      );

      if (selectedProjectId != null && selectedProjectId != widget.projectId) {
        if (mounted) {
          context.go('/project-management/$selectedProjectId');
        }
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to switch project');
      }
    }
  }

  Widget _buildCalendarWidget() {
    final isCustomContract = _contractType?.toLowerCase() == 'custom';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (isCustomContract)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editEstimatedCompletion,
                  tooltip: 'Edit Estimated Completion',
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarGrid(),
        ],
      ),
    );
  }
  
  Future<void> _editEstimatedCompletion() async {
    OngoingBuildMethods.showEditCompletionDialog(
      context: context,
      currentCompletion: _estimatedCompletion,
      onSave: (selectedDate) async {
        await widget.ongoingService.updateEstimatedCompletion(
          projectId: widget.projectId,
          estimatedCompletion: selectedDate,
          context: context,
          onSuccess: () {
            setState(() {
              _estimatedCompletion = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
            });
            // Real-time subscription will update the data automatically
          },
        );
      },
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    // Calculate days from previous month to show
    final daysBefore = firstDayWeekday - 1;
    final prevMonth = DateTime(_focusedDate.year, _focusedDate.month - 1);
    final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;

    return Column(
      children: [
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - daysBefore + 1;
              bool isCurrentMonth = true;

              late DateTime dayDate;
              if (dayNumber <= 0) {
                // Previous month
                dayDate = DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth + dayNumber);
                isCurrentMonth = false;
              } else if (dayNumber > daysInMonth) {
                // Next month
                dayDate = DateTime(_focusedDate.year, _focusedDate.month + 1, dayNumber - daysInMonth);
                isCurrentMonth = false;
              } else {
                dayDate = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
              }

              final isSelected = dayDate.year == _selectedDate.year &&
                  dayDate.month == _selectedDate.month &&
                  dayDate.day == _selectedDate.day;
              final isToday = dayDate.year == DateTime.now().year &&
                  dayDate.month == DateTime.now().month &&
                  dayDate.day == DateTime.now().day;
              
              // Check if this date is start_date or estimated_completion
              // Normalize dayDate to only compare date parts (ignore time)
              final normalizedDayDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
              
              bool isStartDate = false;
              bool isCompletionDate = false;
              bool isMilestoneDate = false;
              if (_startDate != null) {
                final normalizedStartDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
                isStartDate = normalizedDayDate == normalizedStartDate;
              }
              if (_estimatedCompletion != null) {
                final normalizedCompletionDate = DateTime(
                  _estimatedCompletion!.year,
                  _estimatedCompletion!.month,
                  _estimatedCompletion!.day
                );
                isCompletionDate = normalizedDayDate == normalizedCompletionDate;
              }
              // Check if this date is a milestone date
              if (_milestoneDates.isNotEmpty) {
                for (final milestoneDate in _milestoneDates) {
                  final normalizedMilestoneDate = DateTime(milestoneDate.year, milestoneDate.month, milestoneDate.day);
                  if (normalizedDayDate == normalizedMilestoneDate) {
                    isMilestoneDate = true;
                    break;
                  }
                }
              }

              List<String> taskNamesForDate = [];
              List<String> doneTaskNamesForDate = [];
              List<String> undoneTaskNamesForDate = [];
              for (var task in _tasks) {
                final expectFinishStr = task['expect_finish'] as String?;
                final isDone = task['done'] == true;
                if (expectFinishStr != null && expectFinishStr.isNotEmpty) {
                  try {
                    final expectFinishDate = DateTime.parse(expectFinishStr);
                    final normalizedExpectFinish = DateTime(
                      expectFinishDate.year,
                      expectFinishDate.month,
                      expectFinishDate.day,
                    );
                    if (normalizedDayDate == normalizedExpectFinish) {
                      final taskName = task['task'] as String? ?? 'Untitled Task';
                      taskNamesForDate.add(taskName);
                      if (isDone) {
                        doneTaskNamesForDate.add(taskName);
                      } else {
                        undoneTaskNamesForDate.add(taskName);
                      }
                    }
                  } catch (e) {
                    //
                  }
                }
              }
              final isTaskDueDate = taskNamesForDate.isNotEmpty;
              final hasDoneTasks = doneTaskNamesForDate.isNotEmpty;
              final hasUndoneTasks = undoneTaskNamesForDate.isNotEmpty;

              String? tooltipText;
              if (isStartDate) {
                tooltipText = 'Start Date';
              } else if (isCompletionDate) {
                tooltipText = 'Estimated Completion';
              } else if (isMilestoneDate) {
                tooltipText = 'Milestone Due Date';
              } else if (isTaskDueDate) {
                List<String> tooltipParts = [];
                if (hasDoneTasks) {
                  tooltipParts.add('Done: ${doneTaskNamesForDate.join(', ')}');
                }
                if (hasUndoneTasks) {
                  tooltipParts.add('Pending: ${undoneTaskNamesForDate.join(', ')}');
                }
                tooltipText = tooltipParts.join(' | ');
              } else if (isToday) {
                tooltipText = 'Today';
              }

              return Expanded(
                child: Tooltip(
                  message: tooltipText ?? '',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = dayDate;
                        if (!isCurrentMonth) {
                          _focusedDate = dayDate;
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.amber.shade700
                            : isStartDate
                                ? Colors.blue.shade100
                                : isCompletionDate
                                    ? Colors.green.shade100
                                    : isMilestoneDate
                                        ? Colors.purple.shade100
                                        : isTaskDueDate
                                        ? (hasUndoneTasks && !hasDoneTasks
                                            ? Colors.red.shade200
                                            : hasDoneTasks && !hasUndoneTasks
                                                ? Colors.green.shade200
                                                : Colors.orange.shade200) 
                                        : isToday
                                            ? Colors.amber.shade50
                                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: isToday && !isSelected
                            ? Border.all(color: Colors.amber.shade700, width: 1)
                            : isStartDate && !isSelected
                                ? Border.all(color: Colors.blue.shade700, width: 1.5)
                                : isCompletionDate && !isSelected
                                    ? Border.all(color: Colors.green.shade700, width: 1.5)
                                    : isMilestoneDate && !isSelected
                                        ? Border.all(color: Colors.purple.shade700, width: 1.5)
                                        : isTaskDueDate && !isSelected
                                        ? Border.all(
                                            color: hasUndoneTasks && !hasDoneTasks
                                                ? Colors.red.shade700
                                                : hasDoneTasks && !hasUndoneTasks
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                            width: 1.5)
                                        : null,
                      ),
                      child: Center(
                        child: Text(
                          dayDate.day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected || isToday || isStartDate || isCompletionDate || isTaskDueDate
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : isStartDate
                                    ? Colors.blue.shade900
                                    : isCompletionDate
                                        ? Colors.green.shade900
                                        : isTaskDueDate
                                            ? (hasUndoneTasks && !hasDoneTasks
                                                ? Colors.red.shade900
                                                : hasDoneTasks && !hasUndoneTasks
                                                    ? Colors.green.shade900
                                                    : Colors.orange.shade900)
                                            : !isCurrentMonth
                                                ? Colors.grey.shade400
                                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  /// Recent Activities Container
  Widget _buildRecentActivities() {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: (_tasks.isEmpty && _reports.isEmpty && _photos.isEmpty)
                  ? const Center(
                      child: Text('No recent activities'),
                    )
                  : SingleChildScrollView(
                      child: OngoingBuildMethods.buildRecentActivityFeed(
                        tasks: _tasks,
                        reports: _reports,
                        photos: _photos,
                        maxItems: 10,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Right Column: Tasks, Reports, Photos, Materials in 2x2 Grid
  Widget _buildRightColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column of Grid
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildTasksContainer(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildProgressReportsContainer(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right Column of Grid
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildProjectPhotosContainer(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildMaterialsContainer(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// To-Dos & Tasks Container (scrollable)
  Widget _buildTasksContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.task, color: Colors.black87, size: MediaQuery.of(context).size.width < 700 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 700 ? 8 : 12),
                  Text(
                    'To-Dos & Tasks',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 700 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _addTask,
                  tooltip: 'Add Task',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text('No tasks added yet'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _getSortedTasks().map((task) => _buildTaskItem(task)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Individual Task Item with expect_finish
  Widget _buildTaskItem(Map<String, dynamic> task) {
    final taskText = task['task'] ?? 'Untitled Task';
    final isDone = task['done'] == true;
    final expectFinish = task['expect_finish'] as String?;
    final taskDone = task['task_done'] as String?;
    final taskId = task['task_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _markTaskDone(taskId, !isDone),
            child: Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
                if (expectFinish != null && expectFinish.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expected: ${_formatDate(expectFinish)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (isDone && taskDone != null && taskDone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Completed: ${_formatDate(taskDone)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get sorted tasks (undone first, then done)
  List<Map<String, dynamic>> _getSortedTasks() {
    final sortedTasks = List<Map<String, dynamic>>.from(_tasks);
    sortedTasks.sort((a, b) {
      final aDone = a['done'] == true;
      final bDone = b['done'] == true;
      
      // Undone tasks come first (return -1 if a is undone and b is done)
      if (!aDone && bDone) return -1;
      if (aDone && !bDone) return 1;
      
      // If both have same status, maintain original order (or sort by creation date)
      return 0;
    });
    return sortedTasks;
  }

  /// Mark task as done/undone
  Future<void> _markTaskDone(String taskId, bool done) async {
    if (done) {
      // Marking as done - show multi-select dialog if there are multiple undone tasks
      final undoneTasks = _tasks.where((t) => t['done'] != true).toList();
      
      if (undoneTasks.length > 1) {
        // Show multi-select dialog for marking multiple tasks as done
        await OngoingBuildMethods.showMarkTasksDoneDialog(
          context: context,
          undoneTasks: undoneTasks,
          onConfirm: (selectedTaskIds) async {
            // Update all selected tasks
            for (final selectedTaskId in selectedTaskIds) {
              await widget.ongoingService.updateTaskStatus(
                projectId: widget.projectId,
                taskId: selectedTaskId,
                done: true,
                allTasks: _tasks,
                context: context,
              );
            }
            // Real-time subscription will update the data automatically
          },
        );
      } else {
        // Single task update
        await widget.ongoingService.updateTaskStatus(
          projectId: widget.projectId,
          taskId: taskId,
          done: true,
          allTasks: _tasks,
          context: context,
        );
      }
    } else {
      // Marking as undone - single task update
      await widget.ongoingService.updateTaskStatus(
        projectId: widget.projectId,
        taskId: taskId,
        done: false,
        allTasks: _tasks,
        context: context,
      );
    }
  }

  /// Progress Reports Container with Make Report button
  Widget _buildProgressReportsContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.black87, size: MediaQuery.of(context).size.width < 700 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 700 ? 8 : 12),
                  Text(
                    'Progress Reports',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 700 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _addReport,
                  tooltip: 'Add Report & Generate PDF',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text('No reports added yet'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _reports.map((report) => _buildReportItem(report)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Report Item
  Widget _buildReportItem(Map<String, dynamic> report) {
    final title = report['title'] as String? ?? 'Progress Report';
    final content = report['content'] ?? 'No content';
    final createdAt = report['created_at'] ?? DateTime.now().toIso8601String();
    final pdfUrl = report['pdf_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (pdfUrl != null)
                IconButton(
                  onPressed: () => _showPdfDialog(pdfUrl, title),
                  icon: const Icon(Icons.visibility, color: Colors.amber, size: 24),
                  tooltip: 'View PDF',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(createdAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.length > 200 ? '${content.substring(0, 200)}...' : content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _showPdfDialog(String pdfUrl, String reportTitle) async {
    try {
      String? signedUrl;
      if (pdfUrl.startsWith('http://') || pdfUrl.startsWith('https://')) {
        signedUrl = pdfUrl;
      } else {
        signedUrl = await widget.ongoingService.getSignedReportUrl(pdfUrl);
        
        if (signedUrl == null) {
          try {
            final publicUrl = Supabase.instance.client.storage
                .from('reports')
                .getPublicUrl(pdfUrl);
            signedUrl = publicUrl;
          } catch (publicError) {
            // Ignore
          }
        }
      }
      
      if (signedUrl == null || signedUrl.isEmpty || !mounted) {
        if (mounted) {
          ConTrustSnackBar.error(
            context,
            'Error loading PDF. The file may not exist or you may not have permission to view it.',
          );
        }
        return;
      }

      await showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        useSafeArea: true,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                                Icons.picture_as_pdf,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reportTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 800,
                            minHeight: 400,
                          ),
                          child: _buildPdfViewer(signedUrl!),
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
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(
          context,
          'Error opening PDF: $e',
        );
      }
    }
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
        child: kIsWeb
            ? _buildWebPdfViewer(pdfUrl)
            : _buildMobilePdfViewer(pdfUrl),
      ),
    );
  }

  Widget _buildWebPdfViewer(String pdfUrl) {
    if (!kIsWeb) {
      // This should never happen, but return placeholder for safety
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
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'fullscreen'
            ..onError.listen((event) {});
          
          return iframe;
        });
      }
    } catch (e) {
      // Continue
    }
    
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
    
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: HtmlElementView(viewType: viewType),
    );
  }

  Widget _buildMobilePdfViewer(String pdfUrl) {
    return FutureBuilder<Uint8List?>(
      future: _downloadPdfBytes(pdfUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade50,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the button below to open in external app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _launchPdfUrl(pdfUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SfPdfViewer.memory(
            snapshot.data!,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        );
      },
    );
  }

  Future<Uint8List?> _downloadPdfBytes(String pdfUrl) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _launchPdfUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ConTrustSnackBar.error(
            context,
            'Could not open PDF URL',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(
          context,
          'Error opening PDF: $e',
        );
      }
    }
  }

  /// Project Photos Container
  Widget _buildProjectPhotosContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.black87, size: MediaQuery.of(context).size.width < 700 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 700 ? 8 : 12),
                  Text(
                    'Project Photos',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 700 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _addPhoto,
                  tooltip: 'Add Photo',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _photos.isEmpty
                ? const Center(
                    child: Text('No photos added yet'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _photos.map((photo) => _buildPhotoListItem(photo)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Photo List Item (like task items)
  Widget _buildPhotoListItem(Map<String, dynamic> photo) {
    final description = photo['description'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Photo thumbnail on the left
          FutureBuilder<String?>(
            future: widget.createSignedPhotoUrl(photo['photo_url']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                    ),
                  ),
                );
              }
              
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: snapshot.hasData && snapshot.data != null
                      ? DecorationImage(
                          image: NetworkImage(snapshot.data!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[200],
                ),
                child: snapshot.hasData && snapshot.data != null
                    ? null
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 24),
                      ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Photo info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description.length > 50 ? '${description.substring(0, 50)}...' : description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Info icon on the right
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.amber),
            onPressed: () => _showPhotoInfoDialog(photo),
            tooltip: 'View Photo Details',
          ),
        ],
      ),
    );
  }

  /// Show Photo Info Dialog with enlarged photo and description
  Future<void> _showPhotoInfoDialog(Map<String, dynamic> photo) async {
    final photoUrl = photo['photo_url'];
    final description = photo['description'] as String?;
    
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                              Icons.photo_library,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Photo Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          // Photo takes most of the space
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: FutureBuilder<String?>(
                                future: widget.createSignedPhotoUrl(photoUrl),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: Colors.amber),
                                      ),
                                    );
                                  }
                                  
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[200],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          boundaryMargin: const EdgeInsets.all(20),
                                          child: Image.network(
                                            snapshot.data!,
                                            fit: BoxFit.contain,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  color: Colors.amber,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(Icons.error, size: 64, color: Colors.red),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[200],
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Description section in separate container below
                          Container(
                            margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description, size: 18, color: Colors.grey.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (description != null && description.isNotEmpty)
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  )
                                else
                                  Text(
                                    'No description provided',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
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
  }

  /// Materials & Costs Container
  Widget _buildMaterialsContainer() {
    // Calculate total cost
    double totalCost = 0;
    for (var material in _materials) {
      final quantity = (material['quantity'] as num?)?.toDouble() ?? 0.0;
      final unitPrice = (material['unit_price'] as num?)?.toDouble() ?? 0.0;
      totalCost += quantity * unitPrice;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.black87, size: MediaQuery.of(context).size.width < 700 ? 20 : 24),
                  SizedBox(width: MediaQuery.of(context).size.width < 700 ? 8 : 12),
                  Text(
                    'Materials & Costs',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 700 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_projectStatus != 'completed')
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.amber),
                  onPressed: _goToMaterials,
                  tooltip: 'Add Material',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _materials.isEmpty
                ? const Center(
                    child: Text('No materials added yet'),
                  )
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 70), // Space for sticky total
                        child: Column(
                          children: _materials.map((material) => _buildMaterialItem(material)).toList(),
                        ),
                      ),
                      // Sticky total container at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Cost:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '₱${totalCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Material Item
  Widget _buildMaterialItem(Map<String, dynamic> material) {
    final name = material['material_name'] ?? 'Unknown Material';
    final quantity = (material['quantity'] as num?)?.toDouble() ?? 0.0;
    final unitPrice = (material['unit_price'] as num?)?.toDouble() ?? 0.0;
    final unit = material['unit'] ?? 'pcs';
    final brand = material['brand'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, color: Colors.black87, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (brand != null && brand.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Brand: $brand',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          // Unit price x quantity text
          Text(
            '₱${unitPrice.toStringAsFixed(2)} × ${quantity.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          // Eye icon at the far end
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.amber),
            onPressed: () => _showMaterialDetailsDialog(material),
            tooltip: 'View Material Details',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Show Material Details Dialog
  Future<void> _showMaterialDetailsDialog(Map<String, dynamic> material) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildMaterialDetailsDialog(dialogContext, material),
    );
  }

  /// Build Material Details Dialog (similar to project details dialog)
  Widget _buildMaterialDetailsDialog(BuildContext dialogContext, Map<String, dynamic> material) {
    final name = material['material_name'] ?? 'Unknown Material';
    final quantity = (material['quantity'] as num?)?.toDouble() ?? 0.0;
    final unitPrice = (material['unit_price'] as num?)?.toDouble() ?? 0.0;
    final unit = material['unit'] ?? 'pcs';
    final brand = material['brand'] as String?;
    final notes = material['notes'] as String?;
    final totalCost = quantity * unitPrice;
    final createdAt = material['created_at'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: 650),
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
            // Header
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
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
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
            // Content area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Material details in vertical column
                    Column(
                      children: [
                        _buildMaterialDetailField('Material Name', name),
                        const SizedBox(height: 16),
                        _buildMaterialDetailField('Quantity', '${quantity.toStringAsFixed(1)} $unit'),
                        const SizedBox(height: 16),
                        _buildMaterialDetailField('Unit Price', '₱${unitPrice.toStringAsFixed(2)}'),
                        const SizedBox(height: 16),
                        _buildMaterialDetailField('Total Cost', '₱${totalCost.toStringAsFixed(2)}'),
                        if (brand != null && brand.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildMaterialDetailField('Brand', brand),
                        ],
                        if (notes != null && notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildMaterialDetailField('Notes', notes),
                        ],
                        if (createdAt != null) ...[
                          const SizedBox(height: 16),
                          _buildMaterialDetailField('Created', _formatMaterialDate(createdAt)),
                        ],
                      ],
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

  /// Build Material Detail Field (for vertical layout)
  Widget _buildMaterialDetailField(String label, String value) {
    return Column(
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
    );
  }

  /// Format Material Date
  String _formatMaterialDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      DateTime date;
      if (dateString.endsWith('Z')) {
        date = DateTime.parse(dateString).toLocal();
      } else {
        date = DateTime.parse(dateString);
      }
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _addTask() async {
    await OngoingBuildMethods.showAddTaskDialog(
      context: context,
      onAdd: (taskList) async {
        int successCount = 0;
        int errorCount = 0;
        
        for (final taskData in taskList) {
          final task = taskData['task'] as String;
          final expectFinish = taskData['expect_finish'] as DateTime?;
          try {
            await widget.ongoingService.addTask(
              projectId: widget.projectId,
              task: task,
              context: context,
              expectFinish: expectFinish,
              showSuccessMessage: false, 
              onSuccess: () {},
            );
            successCount++;
          } catch (e) {
            errorCount++;
          }
        }
        
        if (context.mounted) {
          if (successCount > 0 && errorCount == 0) {
            ConTrustSnackBar.success(
              context,
              successCount == 1 
                  ? 'Task added successfully!'
                  : '$successCount tasks added successfully!',
            );
          } else if (successCount > 0 && errorCount > 0) {
            ConTrustSnackBar.warning(
              context,
              '$successCount task(s) added, $errorCount task(s) failed',
            );
          }
        }
        
        _loadData();
      },
    );
  }

  Future<void> _addReport() async {
    final titleController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
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
                              Icons.description,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Generate Progress Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Report Title:',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: titleController,
                                decoration: InputDecoration(
                                  hintText: 'Enter report title...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Select time period for the report:',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPeriodOption(dialogContext, titleController, 'hour', 'Last Hour', Icons.access_time),
                              const SizedBox(height: 8),
                              _buildPeriodOption(dialogContext, titleController, 'today', 'Today', Icons.today),
                              const SizedBox(height: 8),
                              _buildPeriodOption(dialogContext, titleController, 'week', 'This Week', Icons.date_range),
                              const SizedBox(height: 8),
                              _buildPeriodOption(dialogContext, titleController, 'month', 'This Month', Icons.calendar_month),
                              const SizedBox(height: 8),
                              _buildPeriodOption(dialogContext, titleController, 'year', 'This Year', Icons.calendar_today),
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
        );
      },
    ).then((_) {
      titleController.dispose();
    });
  }

  Widget _buildPeriodOption(BuildContext dialogContext, TextEditingController titleController, String period, String label, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        final title = titleController.text.trim();
        if (title.isEmpty) {
          ConTrustSnackBar.warning(
            dialogContext,
            'Please enter a report title',
          );
          return;
        }
        Navigator.of(dialogContext).pop();
        _generateAndSaveReport(period, title);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade50,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.amber.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSaveReport(String periodType, String reportTitle) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      String periodLabel;

      switch (periodType) {
        case 'hour':
          startDate = now.subtract(const Duration(hours: 1));
          periodLabel = 'Last Hour';
          break;
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          periodLabel = 'Today';
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          periodLabel = 'This Week';
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          periodLabel = 'This Month';
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          periodLabel = 'This Year';
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          periodLabel = 'Today';
      }

      final activities = <Map<String, dynamic>>[];

      for (final task in _tasks) {
        if (task['done'] == true && task['task_done'] != null) {
          try {
            final taskDate = DateTime.parse(task['task_done']).toLocal();
            if (taskDate.isAfter(startDate) || taskDate.isAtSameMomentAs(startDate)) {
              activities.add({
                'type': 'task_done',
                'date': task['task_done'],
                'description': task['task'] ?? 'Task completed',
              });
            }
          } catch (e) {
            //
          }
        }
      }

      for (final task in _tasks) {
        if (task['created_at'] != null) {
          try {
            final taskDate = DateTime.parse(task['created_at']).toLocal();
            if (taskDate.isAfter(startDate) || taskDate.isAtSameMomentAs(startDate)) {
              bool alreadyIncluded = activities.any((activity) =>
                activity['type'] == 'task_done' &&
                activity['description'] == (task['task'] ?? 'Task completed'));

              if (!alreadyIncluded) {
                activities.add({
                  'type': 'task_added',
                  'date': task['created_at'],
                  'description': task['task'] ?? 'Task added',
                });
              }
            }
          } catch (e) {
            //
          }
        }
      }

      for (final photo in _photos) {
        try {
          final photoDate = DateTime.parse(photo['created_at']).toLocal();
          if (photoDate.isAfter(startDate) || photoDate.isAtSameMomentAs(startDate)) {
            activities.add({
              'type': 'photo',
              'date': photo['created_at'],
              'description': photo['description'] ?? 'Progress photo uploaded',
            });
          }
        } catch (e) {
          //
        }
      }

      for (final material in _materials) {
        try {
          final materialDate = material['created_at'] != null
              ? DateTime.parse(material['created_at']).toLocal()
              : DateTime.now();
          if (materialDate.isAfter(startDate) || materialDate.isAtSameMomentAs(startDate)) {
            activities.add({
              'type': 'material',
              'date': material['created_at'] ?? DateTime.now().toIso8601String(),
              'description': 'Material added: ${material['material_name'] ?? 'Unknown'}',
            });
          }
        } catch (e) {
          //
        }
      }

      activities.sort((a, b) {
        try {
          final aDate = DateTime.parse(a['date']);
          final bDate = DateTime.parse(b['date']);
          return bDate.compareTo(aDate);
        } catch (e) {
          return 0;
        }
      });

      if (activities.isEmpty) {
        if (mounted) {
          ConTrustSnackBar.warning(
            context,
            'No activities found for the selected period. Cannot create an empty report.',
          );
        }
        return;
      }

      final pdf = pw.Document();
      final project = widget.projectData?['projectDetails'] as Map<String, dynamic>?;
      final projectTitle = project?['title'] ?? 'Project';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Project: $projectTitle',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Period: $periodLabel',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 30),
              ...activities.map((activity) {
                  final date = _formatDate(activity['date']);
                  final type = activity['type'] as String;
                  final description = activity['description'] as String;

                  String typeLabel = '';
                  if (type == 'task_done') {
                    typeLabel = 'Task completed at $date';
                  } else if (type == 'task_added') {
                    typeLabel = 'Task added at $date';
                  } else if (type == 'photo') {
                    typeLabel = 'Progress photo uploaded at $date';
                  } else if (type == 'material') {
                    typeLabel = 'Material added at $date';
                  }

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          typeLabel,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          description,
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
            ];
          },
        ),
      );

      // Save PDF bytes
      final pdfBytes = await pdf.save();

      // Upload PDF to storage and save report
      await widget.ongoingService.addReportWithPdf(
        projectId: widget.projectId,
        title: reportTitle,
        content: 'Progress Report - $periodLabel (${activities.length} activities)',
        pdfBytes: pdfBytes,
        periodType: periodType,
        context: context,
        onSuccess: () {
          //
        },
      );
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(
          context,
          'Error generating report: $e',
        );
      }
    }
  }

  Future<void> _addPhoto() async {
    final descriptionController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
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
                              Icons.add_photo_alternate,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Add a description for this photo (optional)',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: TextField(
                                  controller: descriptionController,
                                  maxLines: null,
                                  minLines: 4,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter photo description...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _uploadPhotoWithDescription(descriptionController.text.trim());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB300),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Select Photo'),
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
        );
      },
    ).then((_) {
      descriptionController.dispose();
    });
  }

  Future<void> _uploadPhotoWithDescription(String description) async {
    await widget.ongoingService.uploadPhoto(
      projectId: widget.projectId,
      context: context,
      description: description.isEmpty ? null : description,
      onSuccess: () {
        //
      },
    );
  }

  void _goToMaterials() {
    context.go('/project-management/${widget.projectId}/materials');
  }
}

