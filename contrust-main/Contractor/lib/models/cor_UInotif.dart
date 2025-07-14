// ignore_for_file: file_names

import 'package:flutter/material.dart';

class UINotifCor { 

   void showProjectDetails(BuildContext context, Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info['project_title'] ?? 'Project Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildNotification('Type:', info['project_type']),
            buildNotification('Location:', info['project_location']),
            const SizedBox(height: 8),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(info['project_description'] ?? 'No description provided'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget buildNotification(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value ?? 'Not specified'),
          ),
        ],
      ),
    );
  }

}