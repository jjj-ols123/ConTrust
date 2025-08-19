// request_modal.dart
// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unnecessary_type_check, deprecated_member_use

import 'package:backend/services/be_bidding_service.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final List<String> constructionTypes = [
  'House',
  'Building',
  'Renovation',
  'Extension',
  'Interior',
  'Exterior',
  'Other',
];

class ProjectModal {
  static Future<void> show({
    required BuildContext context,
    required String contracteeId,
    required TextEditingController titleController,
    required TextEditingController constructionTypeController,
    required TextEditingController minBudgetController,
    required TextEditingController maxBudgetController,
    required TextEditingController locationController,
    required TextEditingController descriptionController,
    required TextEditingController bidTimeController,
  }) async {
    final startDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> selectStartDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2025),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }

    await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black,
                      width: 1.5,
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
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Text(
                                      "Post a request for Construction",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildLabeledField(
                                  label: 'Project Title',
                                  child: TextFormField(
                                    controller: titleController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter project title',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                            ? 'Please enter a project title'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLabeledField(
                                  label: 'Type of Construction',
                                  child: DropdownButtonFormField<String>(
                                    value: constructionTypeController
                                            .text.isNotEmpty
                                        ? constructionTypeController.text
                                        : null,
                                items: constructionTypes
                                    .map((type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  constructionTypeController.text = value ?? '';
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Select construction type',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Please select a type'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Estimated Budget Range',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: minBudgetController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Min Budget',
                                        prefixText: '₱',
                                        border: OutlineInputBorder(),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '-',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: maxBudgetController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Max Budget',
                                        prefixText: '₱',
                                        border: OutlineInputBorder(),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Preferred Start Date',
                              child: TextFormField(
                                controller: startDateController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText: 'Select a start date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: selectStartDate,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Location',
                              child: TextFormField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your location',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Message to Contractor',
                              child: TextFormField(
                                controller: descriptionController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Describe your project details',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Bid Duration (in days)',
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      int current = int.tryParse(
                                              bidTimeController.text) ??
                                          1;
                                      if (current > 1) {
                                        current--;
                                        bidTimeController.text =
                                            current.toString();
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: bidTimeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter number of days (1–20)',
                                        border: OutlineInputBorder(),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        int? val = int.tryParse(value);
                                        if (val == null || val < 1) {
                                          bidTimeController.text = '1';
                                        } else if (val > 20) {
                                          bidTimeController.text = '20';
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      int current = int.tryParse(
                                              bidTimeController.text) ??
                                          1;
                                      if (current < 20) {
                                        current++;
                                        bidTimeController.text =
                                            current.toString();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  try {
                                    final startdate_format = DateTime.parse(
                                        startDateController.text.trim());
                                    if (validateFieldsPostRequest(
                                      context,
                                      titleController.text.trim(),
                                      constructionTypeController.text.trim(),
                                      minBudgetController.text.trim(),
                                      maxBudgetController.text.trim(),
                                      startDateController.text.trim(),
                                      locationController.text.trim(),
                                      descriptionController.text.trim(),
                                      bidTimeController.text.trim(),
                                    )) {
                                      await ProjectService().postProject(
                                        contracteeId: contracteeId,
                                        title: titleController.text.trim(),
                                        type: constructionTypeController.text
                                            .trim(),
                                        description:
                                            descriptionController.text.trim(),
                                        location:
                                            locationController.text.trim(),
                                        minBudget:
                                            minBudgetController.text.trim(),
                                        maxBudget:
                                            maxBudgetController.text.trim(),
                                        duration: bidTimeController.text.trim(),
                                        startDate: startdate_format,
                                        context: context,
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error submitting request'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow[700],
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Submit Request"),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),
          );
            },
          ),
        )
        );
      },
    );
  }

  static Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class BidsModal {
  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  static Future<void> show({
    required BuildContext context,
    required String projectId,
    required Future<void> Function(String projectId, String bidId)
        acceptBidding,
    String? initialAcceptedBidId,
  }) async {
    String? acceptedBidId = initialAcceptedBidId;
    Future<List<Map<String, dynamic>>> bidsFuture =
        BiddingService().getBidsForProject(projectId);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: bidsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 400,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              if (snapshot.hasError) {
                                return SizedBox(
                                  height: 400,
                                  child: Center(
                                    child: Text('Error loading bids'),
                                  ),
                                );
                              }
                              final bids = snapshot.data ?? [];
                              if (bids.isEmpty) {
                                return const SizedBox(
                                  height: 400,
                                  child: Center(
                                      child: Text(
                                          'No bids for this project yet.')),
                                );
                              }
                              return SizedBox(
                                height: 500,
                                child: ListView.separated(
                                  itemCount: bids.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final bid = bids[index];
                                    final contractor = bid['contractor'] ?? {};
                                    final dynamic profilePhotoRaw =
                                        contractor['profile_photo'];
                                    final String profilePhoto =
                                        profilePhotoRaw is String
                                            ? profilePhotoRaw
                                            : profilePhotoRaw?.toString() ?? '';
                                    final firmName =
                                        contractor['firm_name'] as String? ??
                                            'Unknown Firm';
                                    final bidAmount = bid['bid_amount'] ?? 0;
                                    final message =
                                        bid['message'] as String? ?? '';
                                    final createdAtStr =
                                        bid['created_at'] as String? ?? '';
                                    final isAccepted =
                                        acceptedBidId == bid['bid_id'];
                                    DateTime? createdAt;
                                    if (createdAtStr.isNotEmpty) {
                                      try {
                                        createdAt = DateTime.parse(createdAtStr)
                                            .toLocal();
                                      } catch (_) {
                                        createdAt = null;
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.grey.shade800,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 32,
                                                  backgroundImage:
                                                      profilePhoto.isNotEmpty
                                                          ? NetworkImage(
                                                              profilePhoto)
                                                          : NetworkImage(
                                                              profileUrl),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        firmName,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Bid Amount: ₱$bidAmount',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        message,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        createdAt != null
                                                            ? DateFormat.yMMMd()
                                                                .add_jm()
                                                                .format(
                                                                    createdAt)
                                                            : '',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            isAccepted
                                                ? Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8,
                                                        horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.green.shade600,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Text(
                                                      'Accepted Bid',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          await BiddingService()
                                                              .deleteBid(bid[
                                                                  'bid_id']);
                                                          if (context.mounted) {
                                                            setState(() {
                                                              bidsFuture =
                                                                  BiddingService()
                                                                      .getBidsForProject(
                                                                          projectId);
                                                            });
                                                          }
                                                        },
                                                        style: TextButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .red.shade700,
                                                          foregroundColor:
                                                              Colors.white,
                                                          side: BorderSide(
                                                              color: Colors
                                                                  .red.shade700,
                                                              width: 2),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          textStyle:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        child: const Text(
                                                            'Reject'),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          await acceptBidding(
                                                              projectId,
                                                              bid['bid_id']);
                                                          if (context.mounted) {
                                                            setState(() {
                                                              acceptedBidId =
                                                                  bid['bid_id'];
                                                              bidsFuture =
                                                                  BiddingService()
                                                                      .getBidsForProject(
                                                                          projectId);
                                                            });
                                                          }
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.green
                                                                  .shade700,
                                                          side: BorderSide(
                                                              color: Colors
                                                                  .green
                                                                  .shade700,
                                                              width: 2),
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          textStyle:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        child: const Text(
                                                            'Accept'),
                                                      ),
                                                    ],
                                                  ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class HireModal {
  static Future<void> show({
    required BuildContext context,
    required String contracteeId,
    required String contractorId,
  }) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController typeController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController locationController = TextEditingController();

    final existingProjectWithContractor =
        await hasExistingProjectWithContractor(contracteeId, contractorId);
    final pendingProject = await hasPendingProject(contracteeId);

    if (existingProjectWithContractor == null) {
      titleController.text = pendingProject?['title'] ?? '';
      typeController.text = pendingProject?['type'] ?? '';
      descriptionController.text = pendingProject?['description'] ?? '';
      locationController.text = pendingProject?['location'] ?? '';
    } else {
      titleController.text = existingProjectWithContractor['title'] ?? '';
      typeController.text = existingProjectWithContractor['type'] ?? '';
      descriptionController.text =
          existingProjectWithContractor['description'] ?? '';
      locationController.text = existingProjectWithContractor['location'] ?? '';
    }

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Text(
                                  "Hire Contractor",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (existingProjectWithContractor != null ||
                                (existingProjectWithContractor == null &&
                                    pendingProject != null)) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info,
                                          color: Colors.blue.shade700,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Using details from your existing project.',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildLabeledField(
                              label: 'Project Title',
                              child: TextFormField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter project title',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Please enter a project title'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Type of Construction',
                              child: DropdownButtonFormField<String>(
                                value: typeController.text.isNotEmpty
                                    ? typeController.text
                                    : null,
                                items: constructionTypes
                                    .map((type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  typeController.text = value ?? '';
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Select construction type',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Please select a type'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Location',
                              child: TextFormField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter project location',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Please enter a location'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabeledField(
                              label: 'Project Description',
                              child: TextFormField(
                                controller: descriptionController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Describe your project details',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Please describe your project'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }

                                  try {
                                    await ProjectService().notifyContractor(
                                      contracteeId: contracteeId,
                                      contractorId: contractorId,
                                      title: titleController.text.trim(),
                                      type: typeController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                      location: locationController.text.trim(),
                                    );

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(existingProjectWithContractor !=
                                                null
                                            ? 'Hiring request sent using existing project!'
                                            : 'Hire request sent successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e
                                            .toString()
                                            .replaceFirst('Exception: ', '')),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Send Hire Request"),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
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

  static Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DialogLifecycleWatcher extends StatefulWidget {
  final Widget child;

  const _DialogLifecycleWatcher({required this.child});

  @override
  __DialogLifecycleWatcherState createState() =>
      __DialogLifecycleWatcherState();
}

class __DialogLifecycleWatcherState extends State<_DialogLifecycleWatcher> {
  bool _dialogShown = false;

  void _checkForDialog() {
    if (!_dialogShown) {
      _dialogShown = true;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contract Agreement'),
          content: const Text('Do you agree to proceed with the contract?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Agree'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Not now'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogShown = false;
    _checkForDialog();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
