// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/services/both services/be_payment_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MilestonePaymentModal {
  static Future<void> show({
    required BuildContext context,
    required String projectId,
    required String projectTitle,
    required Map<String, dynamic> milestoneInfo,
    required Map<String, dynamic> contractInfo,
    required VoidCallback onPaymentSuccess,
  }) async {
    final milestones = List<Map<String, dynamic>>.from(milestoneInfo['milestones'] ?? []);
    final currentMilestone = milestoneInfo['current_milestone'] as Map<String, dynamic>? ?? {};
  
    if (currentMilestone.isEmpty) {
      ConTrustSnackBar.error(context, 'No pending milestones found');
      return;
    }

    // 
    final totalContractPrice = (contractInfo['total_price'] as num?)?.toDouble() ?? 0.0;
    final paidMilestones = milestones.where((m) => m['status'] == 'paid').toList();
    final paidMilestoneTotal = paidMilestones.fold<double>(0.0, (sum, m) => sum + ((m['amount'] as num?)?.toDouble() ?? 0.0));
    final currentMilestoneAmount = (currentMilestone['amount'] as num?)?.toDouble() ?? 0.0;

    // Calculate remaining milestone payments
    final totalMilestoneAmount = milestones.fold<double>(0.0, (sum, m) => sum + ((m['amount'] as num?)?.toDouble() ?? 0.0));

    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    final nameController = TextEditingController();
    bool isProcessing = false;

    final milestoneAmount = (currentMilestone['amount'] as num?)?.toDouble() ?? 0.0;
    final milestoneNumber = currentMilestone['milestone_number'] as int? ?? 1;
    final milestoneDescription = currentMilestone['description'] as String? ?? 'Milestone $milestoneNumber';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.amber.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Milestone Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                projectTitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isProcessing)
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                      ],
                    ),
                  ),

                  // Milestone Info Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.amber.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Milestone $milestoneNumber',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0), // Blue shade
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    milestoneDescription,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  '₱${milestoneAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMilestoneProgress(milestones),
                      ],
                    ),
                  ),

                  // Payment Breakdown Section
                  if (totalContractPrice > 0) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.blue.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Breakdown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Total Contract Price
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Contract Price',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '₱${totalContractPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Payment Components
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              // Milestones Paid
                              _buildPaymentRow('Milestones Paid', '${paidMilestones.length}/${milestones.length}', paidMilestoneTotal),

                              const Divider(height: 12),

                              // Current Milestone (Pending)
                              _buildPaymentRow(
                                'Current Milestone',
                                'Milestone ${currentMilestone['milestone_number']}',
                                currentMilestoneAmount,
                                highlight: true,
                              ),

                              const Divider(height: 12),

                              // Final Payment (Remaining milestones)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: _buildPaymentRow(
                                  'Remaining Milestones',
                                  '${milestones.length - paidMilestones.length - 1} milestones left',
                                  totalMilestoneAmount - paidMilestoneTotal - currentMilestoneAmount,
                                  isTotal: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.amber.shade600, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Paying this milestone brings total payments to ₱${(paidMilestoneTotal + currentMilestoneAmount).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: cardNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                                _CardNumberFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Card Number',
                                hintText: '1234 5678 9012 3456',
                                prefixIcon: Icon(Icons.credit_card),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card number';
                                }
                                final digitsOnly = value.replaceAll(' ', '');
                                if (digitsOnly.length < 16) {
                                  return 'Card number must be 16 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: expiryController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                      _ExpiryDateFormatter(),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry Date',
                                      hintText: 'MM/YY',
                                      prefixIcon: Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter expiry date';
                                      }
                                      if (value.length < 5) {
                                        return 'Invalid expiry date';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: cvcController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'CVC',
                                      hintText: '123',
                                      prefixIcon: Icon(Icons.lock),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter CVC';
                                      }
                                      if (value.length != 3) {
                                        return 'CVC must be 3 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Cardholder Name',
                                hintText: 'John Doe',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter cardholder name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Payment Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() => isProcessing = true);
                                  try {
                                    final expiry = expiryController.text.split('/');
                                    final expMonth = int.parse(expiry[0]);
                                    final expYear = 2000 + int.parse(expiry[1]);

                                    final supabase = Supabase.instance.client;
                                    final userId = supabase.auth.currentUser?.id;
                                    String? billingEmail;
                                    
                                    if (userId != null) {
                                      try {
                                        final userData = await supabase
                                            .from('Users')
                                            .select('email')
                                            .eq('users_id', userId)
                                            .maybeSingle();
                                        billingEmail = userData?['email'] as String?;
                                      } catch (e) {
                                        //
                                      }
                                    }

                                    await PaymentService().processMilestonePayment(
                                      projectId: projectId,
                                      milestoneNumber: milestoneNumber,
                                      cardNumber: cardNumberController.text.replaceAll(' ', ''),
                                      expMonth: expMonth,
                                      expYear: expYear,
                                      cvc: cvcController.text,
                                      cardholderName: nameController.text,
                                      billingEmail: billingEmail,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ConTrustSnackBar.success(
                                        context,
                                        'Milestone payment processed successfully!',
                                      );
                                      onPaymentSuccess();
                                    }
                                  } catch (e) {
                                    setState(() => isProcessing = false);
                                    if (context.mounted) {
                                      ConTrustSnackBar.error(
                                        context,
                                        'Payment failed: ${e.toString()}',
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Pay Milestone $milestoneNumber - ₱${milestoneAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    cardNumberController.dispose();
    expiryController.dispose();
    cvcController.dispose();
    nameController.dispose();
  }

  static Widget _buildPaymentRow(String label, String subtitle, double amount, {bool highlight = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? Colors.green.shade700 : Colors.black87,
                  fontSize: isTotal ? 14 : 13,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: highlight ? Colors.green.shade600 : Colors.grey.shade600,
                    fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: highlight ? Colors.green.shade700 : (isTotal ? Colors.green.shade700 : Colors.black87),
            fontSize: isTotal ? 15 : 14,
          ),
        ),
      ],
    );
  }

  static Widget _buildMilestoneProgress(List<Map<String, dynamic>> milestones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestone Progress',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            final isPaid = milestone['status'] == 'paid';
            final isCurrent = milestone['status'] == 'pending' && 
                             milestones.where((m) => m['status'] == 'paid').length == index;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < milestones.length - 1 ? 8 : 0),
                child: Column(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green
                            : isCurrent
                                ? Colors.green.shade700
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPaid
                            ? Colors.green
                            : isCurrent
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '${milestones.where((m) => m['status'] == 'paid').length} of ${milestones.length} milestones completed',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}