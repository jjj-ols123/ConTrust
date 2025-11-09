// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/build/buildongoing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html if (dart.library.html) 'dart:html';
import 'dart:ui_web' as ui_web if (dart.library.html) 'dart:ui_web';


class CeeProjectDashboard extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? projectData;
  final Future<String?> Function(String?) createSignedPhotoUrl;
  final VoidCallback? onPayment;
  final bool isPaid;
  final VoidCallback? onViewPaymentHistory;
  final String? paymentButtonText;

  const CeeProjectDashboard({
    super.key,
    required this.projectId,
    this.projectData,
    required this.createSignedPhotoUrl,
    this.onPayment,
    this.isPaid = false,
    this.onViewPaymentHistory,
    this.paymentButtonText,
  });

  @override
  State<CeeProjectDashboard> createState() => _CeeProjectDashboardState();
}

class _CeeProjectDashboardState extends State<CeeProjectDashboard> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _materials = [];
  bool _isLoading = true;
  
  String? _contractorName;
  String? _contractType;
  DateTime? _startDate;
  DateTime? _estimatedCompletion;
  List<DateTime> _milestoneDates = [];
  Map<String, dynamic>? _contractData;
  final FetchService _fetchService = FetchService();
  
  String _selectedTab = 'Tasks';
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
  void didUpdateWidget(CeeProjectDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectData != null && widget.projectData != oldWidget.projectData) {
      _updateFromProjectData(widget.projectData!);
    }
  }

  @override
  void dispose() {
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
      _isLoading = false;
    });

    _updateContractInfo(projectDetails);
  }

  Future<void> _updateContractInfo(Map<String, dynamic>? projectDetails) async {
    if (projectDetails == null) return;

    final contractorId = projectDetails['contractor_id'] as String?;
    if (contractorId != null) {
      try {
        final contractorData = await _fetchService.fetchContractorData(contractorId);
        if (mounted) {
          setState(() {
            _contractorName = contractorData?['firm_name'] as String?;
          });
        }
      } catch (e) {
        // Continue without contractor name
      }
    }

    final contractId = projectDetails['contract_id'] as String?;
    if (contractId != null) {
      try {
        final contract = await _fetchService.fetchContractWithDetails(
          contractId,
          contracteeId: Supabase.instance.client.auth.currentUser?.id,
        );
        if (contract != null && mounted) {
          setState(() {
            _contractData = contract;
            final contractTypeData = contract['contract_type'] as Map<String, dynamic>?;
            _contractType = contractTypeData?['template_name'] as String?;
          });

          // Extract milestone dates from contract field_values (only for Lump Sum)
          if (_contractType?.toLowerCase() == 'lump sum') {
            final fieldValues = contract['field_values'] as Map<String, dynamic>?;
            if (fieldValues != null) {
              _milestoneDates = [];
              // Check up to 10 possible milestones
              for (int i = 1; i <= 10; i++) {
                final milestoneDateStr = fieldValues['Milestone.$i.Date'] as String?;
                if (milestoneDateStr != null && milestoneDateStr.isNotEmpty) {
                  try {
                    final dateStr = milestoneDateStr.split(' ')[0]; // Take only date part
                    final parsed = DateTime.parse(dateStr);
                    _milestoneDates.add(DateTime(parsed.year, parsed.month, parsed.day));
                  } catch (_) {
                    // Skip invalid dates
                  }
                }
              }
            }
          } else {
            _milestoneDates = [];
          }
        }
      } catch (e) {
        // Continue without contract data
      }
    }

    if (mounted) {
      final isCustomContract = _contractType?.toLowerCase() == 'custom';
      
      setState(() {
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
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final projectDetails = await _fetchService.fetchProjectDetails(widget.projectId);
      if (projectDetails == null) {
        setState(() => _isLoading = false);
        return;
      }

      final contractorId = projectDetails['contractor_id'] as String?;
      if (contractorId != null) {
        try {
          final contractorData = await _fetchService.fetchContractorData(contractorId);
          _contractorName = contractorData?['firm_name'] as String?;
        } catch (e) {
          // Continue without contractor name
        }
      }

      final contractId = projectDetails['contract_id'] as String?;
      if (contractId != null) {
        try {
          final contract = await _fetchService.fetchContractWithDetails(
            contractId,
            contracteeId: Supabase.instance.client.auth.currentUser?.id,
          );
          if (contract != null) {
            _contractData = contract;
            final contractTypeData = contract['contract_type'] as Map<String, dynamic>?;
            _contractType = contractTypeData?['template_name'] as String?;
          }
        } catch (e) {
          // Continue without contract data
        }
      }

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

      final tasks = await _fetchService.fetchProjectTasks(widget.projectId);
      final reports = await _fetchService.fetchProjectReports(widget.projectId);
      final photos = await _fetchService.fetchProjectPhotos(widget.projectId);
      final costs = await _fetchService.fetchProjectCosts(widget.projectId);

      setState(() {
        _tasks = tasks;
        _reports = reports;
        _photos = photos;
        _materials = costs;
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
              // Info icon at top
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
              // Calendar and Recent Activities with horizontal navigation
              _buildMobileCalendarAndActivities(),
              const SizedBox(height: 16),
              // Tab Navigation
              _buildMobileTabNavigation(_selectedTab, (tab) {
                setState(() {
                  _selectedTab = tab;
                });
              }),
              const SizedBox(height: 8),
              // Tab Content
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

  /// Show Project Info Dialog
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

  /// Mobile Calendar and Activities with Horizontal Navigation
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
      child: CeeOngoingBuildMethods.buildRecentActivityFeed(
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
  Widget _buildMobileTabContent(String tab) {
    switch (tab) {
      case 'Tasks':
        return _buildMobileTasksContainer();
      case 'Reports':
        return _buildMobileReportsContainer();
      case 'Photos':
        return _buildMobilePhotosContainer();
      case 'Materials':
        return _buildMobileMaterialsContainer();
      default:
        return const Center(child: Text('Unknown tab'));
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
                      children: _tasks.map((task) => _buildTaskItem(task)).toList(),
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

  Widget _buildTwoColumnLayout() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 
              MediaQuery.of(context).padding.top - 
              MediaQuery.of(context).padding.bottom,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _buildLeftColumn(),
          ),
          Container(
            width: 1,
            color: Colors.grey.shade300,
          ),
          Expanded(
            flex: 3,
            child: _buildRightColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    final project = widget.projectData?['projectDetails'] as Map<String, dynamic>?;
    final projectTitle = project?['title'] ?? 'Project';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleContainer(projectTitle),
          const SizedBox(height: 16),
          _buildCalendarWidget(),
          const SizedBox(height: 16),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildTitleContainer(String title) {
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
                      'By: ${_contractorName ?? 'Contractor'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isPaid)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Paid',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onViewPaymentHistory != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: widget.onViewPaymentHistory,
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('Payment History', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                )
              else if (widget.onPayment != null)
                ElevatedButton.icon(
                  onPressed: widget.onPayment,
                  icon: const Icon(Icons.payment, size: 16),
                  label: Text(widget.paymentButtonText ?? 'Pay Now', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
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
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

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
                dayDate = DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth + dayNumber);
                isCurrentMonth = false;
              } else if (dayNumber > daysInMonth) {
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
                    // Skip invalid date formats
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
                      child: CeeOngoingBuildMethods.buildRecentActivityFeed(
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

  Widget _buildRightColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          const Row(
            children: [
              Icon(Icons.task, color: Colors.black87, size: 24),
              SizedBox(width: 12),
              Text(
                'To-Dos & Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final taskText = task['task'] ?? 'Untitled Task';
    final isDone = task['done'] == true;
    final expectFinish = task['expect_finish'] as String?;
    final taskDone = task['task_done'] as String?;

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
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey,
            size: 20,
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

  List<Map<String, dynamic>> _getSortedTasks() {
    final sortedTasks = List<Map<String, dynamic>>.from(_tasks);
    sortedTasks.sort((a, b) {
      final aDone = a['done'] == true;
      final bDone = b['done'] == true;
      
      if (!aDone && bDone) return -1;
      if (aDone && !bDone) return 1;
      
      return 0;
    });
    return sortedTasks;
  }

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
          const Row(
            children: [
              Icon(Icons.description, color: Colors.black87, size: 24),
              SizedBox(width: 12),
              Text(
                'Progress Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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

  Widget _buildReportItem(Map<String, dynamic> report) {
    final title = report['title'] as String? ?? 'Progress Report';
    final content = report['content'] ?? 'No content';
    final createdAt = report['created_at'] ?? DateTimeHelper.getLocalTimeISOString();
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
        try {
          signedUrl = await Supabase.instance.client.storage
              .from('reports')
              .createSignedUrl(pdfUrl, 3600);
        } catch (e) {
          try {
            signedUrl = Supabase.instance.client.storage
                .from('reports')
                .getPublicUrl(pdfUrl);
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
                constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 900),
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
          const Row(
            children: [
              Icon(Icons.photo_library, color: Colors.black87, size: 24),
              SizedBox(width: 12),
              Text(
                'Project Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.amber),
            onPressed: () => _showPhotoInfoDialog(photo),
            tooltip: 'View Photo Details',
          ),
        ],
      ),
    );
  }

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
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

  Widget _buildMaterialsContainer() {
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
          const Row(
            children: [
              Icon(Icons.inventory, color: Colors.black87, size: 24),
              SizedBox(width: 12),
              Text(
                'Materials & Costs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
          Text(
            '₱${unitPrice.toStringAsFixed(2)} × ${quantity.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
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

  Future<void> _showMaterialDetailsDialog(Map<String, dynamic> material) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildMaterialDetailsDialog(dialogContext, material),
    );
  }

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
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMaterialDetailField('Material Name', name),
                    if (brand != null && brand.isNotEmpty)
                      _buildMaterialDetailField('Brand', brand),
                    _buildMaterialDetailField('Quantity', '${quantity.toStringAsFixed(1)} $unit'),
                    _buildMaterialDetailField('Unit Price', '₱${unitPrice.toStringAsFixed(2)}'),
                    _buildMaterialDetailField('Total Cost', '₱${totalCost.toStringAsFixed(2)}'),
                    if (notes != null && notes.isNotEmpty)
                      _buildMaterialDetailField('Notes', notes),
                    if (createdAt != null) ...[
                      const SizedBox(height: 24),
                      _buildMaterialDetailField('Created', _formatMaterialDate(createdAt)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialDetailField(String label, String value) {
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
}

