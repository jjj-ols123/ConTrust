import 'package:flutter/material.dart';
import '../build/buildaudit.dart';

class Auditlogs extends StatelessWidget {
  const Auditlogs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey.shade50,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.history_outlined, color: Colors.grey, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Audit Logs',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BuildAudit.buildAuditLogsTable(context),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}