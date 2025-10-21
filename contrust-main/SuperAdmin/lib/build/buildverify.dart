// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/verify_service.dart';

class BuildVerifyMethods {
  static Widget buildUnverifiedContractorsList({
    required List<Map<String, dynamic>> contractors,
    required Function(String) onContractorTap,
  }) {
    if (contractors.isEmpty) {
      return const Center(
        child: Text('No contractors up for verification.'),
      );
    }

    return ListView.builder(
      itemCount: contractors.length,
      itemBuilder: (context, index) {
        final contractor = contractors[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(contractor['firm_name'] ?? 'Unknown Firm'),
            subtitle: Text('Contact: ${contractor['contact_number'] ?? 'N/A'}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => onContractorTap(contractor['contractor_id']),
          ),
        );
      },
    );
  }

  static Widget buildVerificationDocuments({
    required String contractorId,
    required BuildContext context,
  }) {
    return FutureBuilder<List<String>>(
      future: VerifyService().getVerificationDocs(contractorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading documents'));
        }
        final docUrls = snapshot.data ?? [];
        if (docUrls.isEmpty) {
          return const Center(
            child: Text(
              'No verification documents submitted.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submitted Verification Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: docUrls.length,
              itemBuilder: (context, index) {
                final url = docUrls[index];
                return GestureDetector(
                  onTap: () => _showFullScreenImage(context, url),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await VerifyService().verifyContractor(contractorId, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contractor approved')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Approve'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await VerifyService().verifyContractor(contractorId, false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contractor rejected')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}