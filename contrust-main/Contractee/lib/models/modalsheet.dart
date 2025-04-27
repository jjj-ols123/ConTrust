// request_modal.dart
// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:backend/services/enterdata.dart';
import 'package:backend/utils/validatefields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ModalClass {
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

                        // Type of Construction
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

                        // Budget Range
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

                        // Preferred Start Date
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

                        // Location
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

                        // Message
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

                        // Bid Duration
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
