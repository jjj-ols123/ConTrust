// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/verify_service.dart';
import 'package:superadmin/build/buildverify.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  _VerifyPageState createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  List<Map<String, dynamic>> _contractors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnverifiedContractors();
  }

  Future<void> _loadUnverifiedContractors() async {
    final contractors = await VerifyService().getUnverifiedContractors();
    setState(() {
      _contractors = contractors;
      _isLoading = false;
    });
  }

  void _onContractorTap(String contractorId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BuildVerifyMethods.buildVerificationDocuments(
            contractorId: contractorId,
            context: context,
          ),
        ),
      ),
    ).then((_) => _loadUnverifiedContractors()); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Contractors'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BuildVerifyMethods.buildUnverifiedContractorsList(
              contractors: _contractors,
              onContractorTap: _onContractorTap,
            ),
    );
  }
}