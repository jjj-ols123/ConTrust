import 'package:flutter/material.dart';
import '../build/builderror.dart';

class ErrorLogs extends StatelessWidget {
  const ErrorLogs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Error Logs',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: ErrorLogsTable(),
            ),
          ],
        ),
      ),
    );
  }
}