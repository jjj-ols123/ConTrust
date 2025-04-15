// request_modal.dart
// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:backend/enterdata.dart';
import 'package:backend/validatefields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      if (picked != null && picked != DateTime.now()) {
        startDateController.text = "${picked.toLocal()}".split(' ')[0];
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Form(
                key: formKey,
                child: Column(
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
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Post a request for Construction",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Type of Construction',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: constructionTypeController,
                            decoration: const InputDecoration(
                              hintText: 'Enter construction type (e.g., House)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Budget Range',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
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
                                    fontSize: 24, fontWeight: FontWeight.bold),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferred Start Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: startDateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'Select a start date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () => selectStartDate(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your location',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Message to Contractor',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Describe your project details',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bid Duration (in days)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
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
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final isValid =
                                formKey.currentState?.validate() ?? false;
                            if (!isValid) return;

                            String construction_type =
                                constructionTypeController.text.trim();
                            String min_budget = minBudgetController.text.trim();
                            String max_budget = maxBudgetController.text.trim();
                            String start_date = startDateController.text.trim();
                            String location = locationController.text.trim();
                            String description =
                                descriptionController.text.trim();
                            String duration = bidTimeController.text.trim();

                            if (validateFieldsPostRequest(
                              context,
                              construction_type,
                              min_budget,
                              max_budget,
                              start_date,
                              location,
                              description,
                              duration,
                            )) {
                              await enterData.postProject(
                                contracteeId: contracteeId,
                                type: construction_type,
                                description: description,
                                location: location,
                                minBudget: min_budget,
                                maxBudget: max_budget,
                                duration: duration,
                                startDate: start_date,
                                context: context);
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error submitting request'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
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
    return;
  }
}
