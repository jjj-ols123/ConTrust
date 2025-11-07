// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiddingUIBuildMethods {
  BiddingUIBuildMethods({
    required this.context,
    required this.projects,
    required this.highestBids,
    required this.onRefresh,
    required this.hasAlreadyBid,
    required this.finalizedProjects,
    required this.selectedProject,
    required this.contracteeInfo,
    required this.contractorBids,
    required this.onProjectSelected, 
    required this.bidController,
    required this.messageController,
    this.isVerified = true,
  }) ;

  String _getProjectPhotoUrl(dynamic photoUrl) {
    if (photoUrl == null || photoUrl.toString().isEmpty) {
      return '';
    }
    final raw = photoUrl.toString();
    if (raw.startsWith('data:') || raw.startsWith('http')) {
      return raw;
    }
    try {
      return Supabase.instance.client.storage
          .from('projectphotos')
          .getPublicUrl(raw);
    } catch (_) {
      return raw;
    }
  }

  final bool isVerified;

  final BuildContext context;
  final List<Map<String, dynamic>> projects;
  final Map<String, double> highestBids;
  final VoidCallback onRefresh;
  final Future<bool> Function(String, String) hasAlreadyBid;
  final Set<String> finalizedProjects;
  final Map<String, dynamic>? selectedProject;
  final Map<String, Map<String, dynamic>> contracteeInfo;
  final Function(Map<String, dynamic>?) onProjectSelected;
  final CorBiddingService _service = CorBiddingService();
  final List<Map<String, dynamic>> contractorBids;
  final TextEditingController bidController;
  final TextEditingController messageController;
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  // Filters
  final ValueNotifier<String> filterType = ValueNotifier<String>('');
  final ValueNotifier<String> filterLocation = ValueNotifier<String>('');
  final ValueNotifier<String> minBudgetText = ValueNotifier<String>('');
  final ValueNotifier<String> maxBudgetText = ValueNotifier<String>('');

  Widget buildBiddingUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1000;

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // header removed
          buildContractorBidsOverview(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onRefresh,

                  label: Text('Refresh', style: const TextStyle(fontSize: 14)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber[800],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: Icon(
                          Icons.filter_list,
                          color: Colors.amber[700],
                          size: 20,
                          ),
                          tooltip: 'Filters',
                          onSelected: (value) async {
                            if (value == 'type') {
                              await _openTypePicker();
                            } else if (value == 'location') {
                              await _openLocationPicker();
                            } else if (value == 'budget') {
                              await _openBudgetDialog();
                            } else if (value == 'clear') {
                              filterType.value = '';
                              filterLocation.value = '';
                              minBudgetText.value = '';
                              maxBudgetText.value = '';
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'type',
                              child: Text('Filter by Type'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'location',
                              child: Text('Filter by Location'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'budget',
                              child: Text('Filter by Budget'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'clear',
                              child: Text('Clear Filters'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) => searchQuery.value = value.trim().toLowerCase(),
                            decoration: const InputDecoration(
                              hintText: "Search projects...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.amber[700], size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLargeScreen
                    ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: buildProjectGrid(),
                        ),
                        Container(
                          width: 1,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        Expanded(flex: 1, child: buildProjectDetails()),
                      ],
                    )
                    : buildProjectGrid(),
          ),
        ],
      ),
    );
  }

  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final double maxWidth = size.width * 0.9;
        final double maxHeight = size.height * 0.85;

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset('assets/images/kitchen.jpg', fit: BoxFit.contain);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildContractorBidsOverview() {
    final displayBids = contractorBids.take(5).toList();
    final hasMoreBids = contractorBids.length > 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.assignment, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Your Bids',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: contractorBids.isEmpty
                ? Center(
            child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'No bids yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    itemCount: displayBids.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 280,
                        child: buildBidItem(displayBids[index]),
                      );
                    },
                  ),
                ),
                if (hasMoreBids) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: TextButton(
                        onPressed: () => _showAllBidsDialog(context, contractorBids),
                        child: const Text(
                          'SEE MORE',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAllBidsDialog(BuildContext context, List<Map<String, dynamic>> allBids) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.85;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 800, maxHeight: maxDialogHeight),
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
                        Icons.assignment,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'All Your Bids',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: allBids.isEmpty
                    ? const SizedBox(
                        height: 400,
                        child: Center(
                          child: Text('No bids found'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: allBids.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return buildBidItem(allBids[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBidItem(Map<String, dynamic> bid) {
    final project = bid['project'] ?? {};
    final status = bid['status'] ?? 'pending';
    final amount = bid['bid_amount'] ?? 0;
    final projectType = project['type'] ?? 'Unknown Project';
    final projectTitle = project['title'] ?? 'Untitled';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'stopped':
        statusColor = Colors.grey;
        statusIcon = Icons.stop_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    projectTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              projectType,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₱${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProjectGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    return ValueListenableBuilder<String>(
      valueListenable: searchQuery,
      builder: (context, query, _) {
        return ValueListenableBuilder<String>(
          valueListenable: filterType,
          builder: (context, typeFilter, _) {
            return ValueListenableBuilder<String>(
              valueListenable: filterLocation,
              builder: (context, locationFilter, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: minBudgetText,
                  builder: (context, minBudgetStr, _) {
                    return ValueListenableBuilder<String>(
                      valueListenable: maxBudgetText,
                      builder: (context, maxBudgetStr, _) {
                        final List<Map<String, dynamic>> source = projects;
                        final String q = query;
                        final String t = typeFilter.trim().toLowerCase();
                        final String loc = locationFilter.trim().toLowerCase();
                        final double? minF = double.tryParse(minBudgetStr.trim());
                        final double? maxF = double.tryParse(maxBudgetStr.trim());

                        List<Map<String, dynamic>> filtered = source.where((p) {
                          // Title filter
                          final String title = (p['title']?.toString() ?? '').toLowerCase();
                          if (q.isNotEmpty && !title.contains(q)) return false;

                          // Type filter (exact match)
                          if (t.isNotEmpty) {
                            final String pt = (p['type']?.toString() ?? '').toLowerCase();
                            if (pt != t) return false;
                          }

                          // Location filter (exact match)
                          if (loc.isNotEmpty) {
                            final String ploc = (p['location']?.toString() ?? '').toLowerCase();
                            if (ploc != loc) return false;
                          }

                          // Budget filter: ensure overlap with filter range
                          final double? pMin = _parseBudget(p['min_budget']);
                          final double? pMax = _parseBudget(p['max_budget']);

                          if (minF != null) {
                            // project max must be >= filter min
                            if (pMax != null && pMax < minF) return false;
                          }
                          if (maxF != null) {
                            // project min must be <= filter max
                            if (pMin != null && pMin > maxF) return false;
                          }

                          return true;
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(child: Text("No projects available"));
                        }

                        return GridView.builder(
          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth > 1200 ? 3 : 1,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
                            childAspectRatio: screenWidth > 1200 ? 1.3 : 1.6,
          ),
          itemBuilder: (ctx, index) {
                            final project = filtered[index];
            final screenWidth = MediaQuery.of(context).size.width;
            final isLargeScreen = screenWidth > 1000;

            return GestureDetector(
              onTap: () {
                if (isLargeScreen) {
                  if (selectedProject != null &&
                      selectedProject!['project_id'] == project['project_id']) {
                    onProjectSelected(null);
                  } else {
                    onProjectSelected(project);
                  }
                } else {
                  showDetails(project);
                }
              },
              child: buildProjectCard(project),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
            );
          },
        );
  }

  double? _parseBudget(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  Future<void> _openTypePicker() async {
    final List<String> types = _getTypes();
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Type'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('All Types'),
          ),
          ...types.map((t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Text(t),
              )),
        ],
      ),
    );
    if (chosen != null) {
      filterType.value = chosen.trim();
    }
  }

  Future<void> _openLocationPicker() async {
    final List<String> locations = _getLocations();
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Location'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('All Locations'),
          ),
          ...locations.map((l) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, l),
                child: Text(l),
              )),
        ],
      ),
    );
    if (chosen != null) {
      filterLocation.value = chosen.trim();
    }
  }

  Future<void> _openBudgetDialog() async {
    final TextEditingController minCtrl = TextEditingController(text: minBudgetText.value);
    final TextEditingController maxCtrl = TextEditingController(text: maxBudgetText.value);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Min Budget',
                prefixText: '₱',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Max Budget',
                prefixText: '₱',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result == true) {
      minBudgetText.value = minCtrl.text.trim();
      maxBudgetText.value = maxCtrl.text.trim();
    }
  }

  List<String> _getTypes() {
    final set = <String>{};
    for (final p in projects) {
      final t = (p['type']?.toString() ?? '').trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _getLocations() {
    final set = <String>{};
    for (final p in projects) {
      final l = (p['location']?.toString() ?? '').trim();
      if (l.isNotEmpty) set.add(l);
    }
    final list = set.toList()..sort();
    return list;
  }

  Widget buildProjectDetails() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          selectedProject == null
              ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  height: 600,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a project to view details',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Builder(
                          builder: (context) {
                            final String photoUrl = _getProjectPhotoUrl(selectedProject!['photo_url']);
                            final Widget imageWidget = photoUrl.isNotEmpty
                            ? Image.network(
                                    photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset('assets/images/kitchen.jpg', fit: BoxFit.cover);
                                },
                              )
                                : Image.asset('assets/images/kitchen.jpg', fit: BoxFit.cover);

                            return Stack(
                              children: [
                                Positioned.fill(child: imageWidget),
                                if (photoUrl.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () => _showFullPhoto(photoUrl),
                                      icon: const Icon(Icons.info_outline, color: Colors.white),
                                      tooltip: 'View photo',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedProject!['type'] ?? 'Project',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedProject!['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D6D7E),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.shade100,
                            ),
                            child: ClipOval(
                              child:
                                  contracteeInfo[selectedProject!['contractee_id']]?['profile_photo'] !=
                                          null
                                      ? Image.network(
                                        contracteeInfo[selectedProject!['contractee_id']]!['profile_photo'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            'assets/images/defaultpic.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        'assets/images/defaultpic.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posted by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7D7D7D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contracteeInfo[selectedProject!['contractee_id']]?['full_name'] ??
                                      'Unknown Contractee',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Location:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${selectedProject!['location']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Minimum Budget:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${selectedProject!['min_budget']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Maximum Budget:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${selectedProject!['max_budget']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    buildBidInput(),
                  ],
                ),
              ),
    );
  }

  Widget buildBidInput({BuildContext? dialogContext, Map<String, dynamic>? project}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    
    if (isMobile) {
      return buildBidInputMobile(dialogContext: dialogContext, project: project);
    }
    
    final projectToUse = project ?? selectedProject;
     
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submit Your Bid',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          enabled: isVerified,
          controller: bidController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Bid Amount',
            prefixText: '₱',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isVerified ? Colors.white : Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          enabled: isVerified,
          controller: messageController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Message to the contractee on what you can offer!',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isVerified ? Colors.white : Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isVerified ? Colors.amber[600] : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            onPressed: isVerified ? () async {
              final user = Supabase.instance.client.auth.currentUser?.id;
              
              if (user == null || projectToUse == null || projectToUse['contractee_id'] == null) {
                ConTrustSnackBar.error(context, 'Missing IDs');
                return;
              }
              
              final already = await hasAlreadyBid(
                user,
                projectToUse['project_id'].toString(),
              );
              if (already) {
                ConTrustSnackBar.warning(context, 'You have already placed a bid on this project.');
                return;
              }
              final bidAmount = int.tryParse(bidController.text.trim()) ?? 0;
              final message = messageController.text.trim();
              if (!validateBidRequest(
                context,
                bidController.text.trim(),
                message,
              )) {
                return;
              }
              
              try {
                await _service.postBid(
                  contractorId: user,
                  projectId: projectToUse['project_id'].toString(),
                  bidAmount: bidAmount,
                  message: message,
                  context: context,
                );
                bidController.clear();
                messageController.clear();
                onProjectSelected(null);
              } catch (e) {
                // Error handled by service
              }
            } : null,
            child: const Text(
              'Submit Bid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBidInputMobile({BuildContext? dialogContext, Map<String, dynamic>? project}) {
    final projectToUse = project ?? selectedProject;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
                    'Submit Your Bid',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          const SizedBox(height: 12),
                        TextField(
                          enabled: isVerified,
                          controller: bidController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
              labelText: 'Bid Amount',
                            prefixText: '₱',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: isVerified ? Colors.white : Colors.grey.shade200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
            'Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          enabled: isVerified,
                          controller: messageController,
                          maxLines: 3,
                          decoration: InputDecoration(
              labelText: 'Message to the contractee on what you can offer!',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: isVerified ? Colors.white : Colors.grey.shade200,
                          ),
                        ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVerified ? const Color(0xFFFFB300) : Colors.grey.shade400,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isVerified ? () async {
                            final user = Supabase.instance.client.auth.currentUser?.id;
                            
                            if (user == null || projectToUse == null || projectToUse['contractee_id'] == null) {
                              ConTrustSnackBar.error(context, 'Missing IDs');
                              return;
                            }
                            
                            final already = await hasAlreadyBid(
                              user,
                              projectToUse['project_id'].toString(),
                            );
                            if (already) {
                              ConTrustSnackBar.warning(context, 'You have already placed a bid on this project.');
                              return;
                            }
                            final bidAmount = int.tryParse(bidController.text.trim()) ?? 0;
                            final message = messageController.text.trim();
                    if (bidAmount <= 0) {
                      ConTrustSnackBar.warning(context, 'Enter a bid amount greater than 0');
                      return;
                    }
                            
                            if (!validateBidRequest(
                              context,
                              bidController.text.trim(),
                              message,
                            )) {
                              return;
                            }
                            
                            try {
                              await _service.postBid(
                                contractorId: user,
                                projectId: projectToUse['project_id'].toString(),
                                bidAmount: bidAmount,
                                message: message,
                                context: context,
                              );
                              bidController.clear();
                              messageController.clear();
                              onProjectSelected(null);

                              final dialogCtx = dialogContext;
                              if (dialogCtx != null) {
                                // Close the dialog first
                                Navigator.pop(dialogCtx);
                                
                                // Show success message after dialog closes
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (context.mounted) {
                                    ConTrustSnackBar.success(context, 'Bid submitted successfully!');
                                  }
                                });
                              } else {
                                // Fallback if dialogContext is null
                                if (context.mounted) {
                                  ConTrustSnackBar.success(context, 'Bid submitted successfully!');
                                }
                              }
                            } catch (e) {
                              final dialogCtx = dialogContext;
                              if (dialogCtx != null) {
                                String errorMessage = e.toString();
                                if (errorMessage.startsWith('Exception: ')) {
                          errorMessage = errorMessage.substring(11);
                                }
                                
                                Navigator.pop(dialogCtx);
                                
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (context.mounted) {
                                    bidController.clear();
                                    messageController.clear();
                                    ConTrustSnackBar.warning(context, errorMessage);
                                  }
                                });
                                return;
                              } else {
                                // Fallback if dialogContext is null
                                if (context.mounted) {
                                  String errorMessage = e.toString();
                                  if (errorMessage.startsWith('Exception: ')) {
                                    errorMessage = errorMessage.substring(11);
                                  }
                                  bidController.clear();
                                  messageController.clear();
                                  ConTrustSnackBar.warning(context, errorMessage);
                                }
                              }
                            }
                          } : null,
                            child: const Text('Submit Bid'),
            ),
          ),
        ],
      ),
    );
  }

  void showDetails(Map<String, dynamic> project) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (ctx) {
        final dialogScreenWidth = MediaQuery.of(ctx).size.width;
        final isDialogMobile = dialogScreenWidth < 700;
        
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDialogMobile ? 500 : 700,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
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
                            Icons.description,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            project['title'] ?? 'Project Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: isDialogMobile ? 140 : 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Builder(
                                      builder: (context) {
                                        final String photoUrl = _getProjectPhotoUrl(project['photo_url']);
                                        final Widget imageWidget = photoUrl.isNotEmpty
                                        ? Image.network(
                                                photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset('assets/images/kitchen.jpg', fit: BoxFit.cover);
                                            },
                                          )
                                            : Image.asset('assets/images/kitchen.jpg', fit: BoxFit.cover);

                                        return Stack(
                                          children: [
                                            Positioned.fill(child: imageWidget),
                                            if (photoUrl.isNotEmpty)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  onPressed: () => _showFullPhoto(photoUrl),
                                                  icon: const Icon(Icons.info_outline, color: Colors.white),
                                                  tooltip: 'View photo',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Text(
                                project['type'] ?? 'Project',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                project['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5D6D7E),
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.amber.shade100,
                                      ),
                                      child: ClipOval(
                                        child:
                                            contracteeInfo[project['contractee_id']]?['profile_photo'] !=
                                                    null
                                                ? Image.network(
                                                  contracteeInfo[project['contractee_id']]!['profile_photo'],
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Image.asset(
                                                      'assets/images/defaultpic.png',
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                                : Image.asset(
                                                  'assets/images/defaultpic.png',
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Posted by',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7D7D7D),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            contracteeInfo[project['contractee_id']]?['full_name'] ??
                                                'Unknown Contractee',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Location:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${project['location']}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Minimum Budget:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '₱${project['min_budget']}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Maximum Budget:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '₱${project['max_budget']}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        buildBidInput(dialogContext: ctx, project: project),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget buildProjectCard(Map<String, dynamic> project) {
    final isSelected =
        selectedProject != null &&
        selectedProject!['project_id'] == project['project_id'];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isSelected
                  ? [Colors.amber.shade100, Colors.amber.shade200]
                  : [Colors.white, Colors.amber.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            isSelected
                ? Border.all(color: Colors.amber.shade600, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.1),
            blurRadius: isSelected ? 20 : 15,
            offset: const Offset(0, 5),
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                _getProjectPhotoUrl(project['photo_url']).isNotEmpty
                    ? Image.network(
                        _getProjectPhotoUrl(project['photo_url']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.amber,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/kitchen.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/kitchen.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
          "${project['title'] ?? 'Unknown'}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[600]!, Colors.amber[800]!],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Time left:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D6D7E),
                      ),
                    ),
                    StreamBuilder<Duration>(
                      stream: _service.getBiddingCountdownStream(
                        DateTime.parse(project['created_at']).toLocal(),
                        project['duration'],
                      ),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF85929E),
                            ),
                          );
                        }
                        if (!snap.hasData) {
                          return const Text(
                            'Calculating...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF85929E),
                            ),
                          );
                        }
                        final remaining = snap.data!;
                        if (remaining.isNegative &&
                            !finalizedProjects.contains(
                              project['project_id'].toString(),
                            )) {
                          finalizedProjects.add(
                            project['project_id'].toString(),
                          );
                          _service.finalizeBidding(project['project_id'].toString());
                        }
                        if (remaining.isNegative) {
                          return const Text(
                            'Ended',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        final days = remaining.inDays;
                        final hours = remaining.inHours
                            .remainder(24)
                            .toString()
                            .padLeft(2, '0');
                        final minutes = remaining.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        final seconds = remaining.inSeconds
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        return Text(
                          '$days d $hours:$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Highest Bid:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D6D7E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[100]!, Colors.amber[200]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₱${highestBids[project['project_id'].toString()]?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD68910),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
