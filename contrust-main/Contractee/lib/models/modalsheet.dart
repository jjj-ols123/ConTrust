// request_modal.dart
// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unnecessary_type_check, deprecated_member_use

import 'package:backend/services/enterdata.dart';
import 'package:backend/services/projectbidding.dart';
import 'package:backend/utils/validatefields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ProjectModal {
  static Future<void> show({
    required BuildContext context,
    required String contracteeId,
    required TextEditingController constructionTypeController,
    required TextEditingController minBudgetController,
    required TextEditingController maxBudgetController,
    required TextEditingController locationController,
    required TextEditingController descriptionController,
    required TextEditingController bidTimeController,
  }) async {
    final startDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final enterData = EnterDatatoDatabase();

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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                          label: 'Type of Construction',
                          child: TextFormField(
                            controller: constructionTypeController,
                            decoration: const InputDecoration(
                              hintText: 'Enter construction type (e.g., House)',
                              border: OutlineInputBorder(),
                            ),
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
                          child: TextFormField(
                            controller: bidTimeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Enter number of days (1–30)',
                              border: OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              try {
                                final startdate_format = DateTime.parse(startDateController.text.trim());
                                if (validateFieldsPostRequest(
                                  context,
                                  constructionTypeController.text.trim(),
                                  minBudgetController.text.trim(),
                                  maxBudgetController.text.trim(),
                                  startDateController.text.trim(),
                                  locationController.text.trim(),
                                  descriptionController.text.trim(),
                                  bidTimeController.text.trim(),
                                )) {
                                  await enterData.postProject(
                                    contracteeId: contracteeId,
                                    type: constructionTypeController.text.trim(),
                                    description: descriptionController.text.trim(),
                                    location: locationController.text.trim(),
                                    minBudget: minBudgetController.text.trim(),
                                    maxBudget: maxBudgetController.text.trim(),
                                    duration: bidTimeController.text.trim(),
                                    startDate: startdate_format,
                                    context: context,
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error submitting request'),
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
            );
          },
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
  static Future<void> show({
    required BuildContext context,
    required String projectId,
    required Future<void> Function(String projectId) finalizeBidding,
  }) async {

    final projectBidding = ProjectBidding();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[300],
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.grey[100],
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: projectBidding.fetchBids(projectId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading bids: ${snapshot.error}'));
                    }
                    final bids = snapshot.data ?? [];
                    if (bids.isEmpty) {
                      return const Center(child: Text('No bids for this project yet.'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: bids.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bid = bids[index];
                        final contractor = bid['contractor'] ?? {};
                        final dynamic profilePhotoRaw = contractor['profile_photo'];
                        final String profilePhoto = profilePhotoRaw is String
                            ? profilePhotoRaw
                            : profilePhotoRaw?.toString() ?? '';
                        final firmName = contractor['firm_name'] as String? ?? 'Unknown Firm';
                        final bidAmount = bid['bid_amount'] ?? 0;
                        final message = bid['message'] as String? ?? '';
                        final createdAtStr = bid['created_at'] as String? ?? '';
                        DateTime? createdAt;
                        try {
                          createdAt = DateTime.parse(createdAtStr);
                        } catch (_) {
                          createdAt = null;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade800, width: 2),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundImage: profilePhoto.isNotEmpty
                                          ? NetworkImage(profilePhoto)
                                          : const AssetImage('assets/defaultpic.png') as ImageProvider,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            firmName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Bid Amount: ₱$bidAmount',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
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
                                                ? DateFormat.yMMMd().add_jm().format(createdAt)
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: Colors.red.shade700, width: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await finalizeBidding(projectId);
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        side: BorderSide(color: Colors.green.shade700, width: 2),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
