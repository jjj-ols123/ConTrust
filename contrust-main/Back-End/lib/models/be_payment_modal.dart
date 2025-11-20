// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/services/both services/be_payment_service.dart';
import 'package:backend/models/be_milestone_payment_modal.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentModal {
  static Future<void> show({
    required BuildContext context,
    required String projectId,
    required String projectTitle,
    required double amount,
    required VoidCallback onPaymentSuccess,
    double? customAmount,
    bool forceRegularModal = false,
  }) async {

    final paymentService = PaymentService();
    final isMilestone = !forceRegularModal && await paymentService.isMilestoneContract(projectId);

    if (isMilestone) {
      final milestoneInfo = await paymentService.getMilestonePaymentInfo(projectId);
      if (milestoneInfo != null) {
        try {
          final supabase = Supabase.instance.client;
          final projectData = await supabase
              .from('Projects')
              .select('contract_id')
              .eq('project_id', projectId)
              .single();
          
          final contractId = projectData['contract_id'] as String?;
          if (contractId != null) {
            await paymentService.initializeMilestones(
              projectId: projectId,
              contractId: contractId,
            );
          }
        } catch (e) {
          //
        }

        final contractInfo = milestoneInfo['contract_info'] as Map<String, dynamic>? ?? {};

        await MilestonePaymentModal.show(
          context: context,
          projectId: projectId,
          projectTitle: projectTitle,
          milestoneInfo: milestoneInfo,
          contractInfo: contractInfo,
          onPaymentSuccess: onPaymentSuccess,
        );
        return;
      }
    }

    await _showRegularPaymentModal(
      context: context,
      projectId: projectId,
      projectTitle: projectTitle,
      amount: amount,
      onPaymentSuccess: onPaymentSuccess,
      customAmount: customAmount,
    );
  }

  static Future<void> _showRegularPaymentModal({
    required BuildContext context,
    required String projectId,
    required String projectTitle,
    required double amount,
    required VoidCallback onPaymentSuccess,
    double? customAmount,
  }) async {
    final paymentAmount = customAmount ?? amount;
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    final nameController = TextEditingController();
    bool isProcessing = false;

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
              constraints: const BoxConstraints(maxWidth: 500),
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
                            Icons.payment,
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
                                'Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
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
                              _closePaymentDialogs(context);
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
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
                        const Text(
                          'Amount to Pay',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Card Number',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: cardNumberController,
                              enabled: !isProcessing,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                                _CardNumberFormatter(),
                              ],
                              decoration: InputDecoration(
                                hintText: '1234 5678 9012 3456',
                                prefixIcon: Icon(Icons.credit_card, color: Colors.amber.shade700),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.replaceAll(' ', '').length < 16) {
                                  return 'Enter a valid 16-digit card number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Expiry Date',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: expiryController,
                                        enabled: !isProcessing,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                          _ExpiryDateFormatter(),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: 'MM/YY',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.length < 5) {
                                            return 'Invalid date';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CVC',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: cvcController,
                                        enabled: !isProcessing,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: '123',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.length < 3) {
                                            return 'Invalid CVC';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'Cardholder Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: nameController,
                              enabled: !isProcessing,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'JUAN DELA CRUZ',
                                prefixIcon: Icon(Icons.person, color: Colors.amber.shade700),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter cardholder name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your payment is secure and encrypted via PayMongo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

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
                                if (!formKey.currentState!.validate()) return;

                                setState(() => isProcessing = true);

                                try {
                                  final expiry = expiryController.text.split('/');
                                  final expMonth = int.parse(expiry[0]);
                                  final expYear = int.parse('20${expiry[1]}');

                                  // Fetch user's email from Users table
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

                                  final paymentService = PaymentService();
                                  await paymentService.processPayment(
                                    projectId: projectId,
                                    cardNumber: cardNumberController.text.replaceAll(' ', ''),
                                    expMonth: expMonth,
                                    expYear: expYear,
                                    cvc: cvcController.text,
                                    cardholderName: nameController.text.trim(),
                                    billingEmail: billingEmail,
                                    customAmount: customAmount,
                                  );

                                  if (context.mounted) {
                                    _closePaymentDialogs(context);
                                    onPaymentSuccess();
                                    ConTrustSnackBar.success(
                                      context,
                                      'Payment successful. E-receipt created.',
                                    );
                                  }
                                } catch (e) {
                                  setState(() => isProcessing = false);
                                  if (context.mounted) {
                                    ConTrustSnackBar.error(context, 'Payment failed: ${e.toString().replaceAll('Exception: ', '')}');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.amber,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Pay ₱${paymentAmount.toStringAsFixed(2)}',
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

  static void _closePaymentDialogs(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((route) => route is! DialogRoute);
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

