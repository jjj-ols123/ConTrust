// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:backend/utils/supabase_config.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final NotificationService _notificationService = NotificationService();

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String projectId,
    required String description,
  }) async {
    try {
      if (amount < SupabaseConfig.minPaymentAmount) {
        throw Exception('Amount must be at least ₱${SupabaseConfig.minPaymentAmount}');
      }

      final amountInCentavos = (amount * 100).toInt();

      final response = await http.post(
        Uri.parse('${SupabaseConfig.paymongoBaseUrl}/payment_intents'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${SupabaseConfig.paymongoSecretKey}:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'attributes': {
              'amount': amountInCentavos,
              'payment_method_allowed': SupabaseConfig.paymentMethodsAllowed,
              'currency': SupabaseConfig.currency,
              'description': description,
              'statement_descriptor': 'ConTrust Payment',
              'metadata': {
                'project_id': projectId,
              },
            }
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        await _auditService.logAuditEvent(
          action: 'PAYMENT_INTENT_CREATED',
          details: 'Payment intent created for project',
          category: 'Payment',
          metadata: {
            'project_id': projectId,
            'amount': amount,
            'payment_intent_id': data['data']['id'],
          },
        );
        
        return data;
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to create payment intent: $e',
        module: 'Payment Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Create Payment Intent',
          'project_id': projectId,
          'amount': amount,
        },
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _determinePaymentAmount({
    required String projectId,
    required String? contractId,
    required String bidId,
    double? customAmount,
  }) async {
    try { 
      if (contractId == null) {
        final bidData = await _supabase
            .from('Bids')
            .select('bid_amount')
            .eq('bid_id', bidId)
            .single();
        
        return {
          'amount': (bidData['bid_amount'] as num).toDouble(),
          'contract_type': 'bid_based',
          'payment_structure': 'single',
        };
      }

      final contractData = await _supabase
          .from('Contracts')
          .select('contract_type_id, field_values')
          .eq('contract_id', contractId)
          .single();

    final contractTypeData = await _supabase
      .from('ContractTypes')
      .select('template_name')
      .eq('contract_type_id', contractData['contract_type_id'])
      .maybeSingle();

    final String contractType = ((contractTypeData?['template_name'])?.toString() ?? 'custom').toLowerCase();
      final fieldValues = contractData['field_values'] as Map<String, dynamic>? ?? {};


      final milestonePaymentInfo = _detectMilestonePayments(contractType, fieldValues);
      if (milestonePaymentInfo != null) {
        return milestonePaymentInfo;
      }

      if (contractType.contains('lump sum')) {
        final contractPrice = fieldValues['Project.ContractPrice'];
        if (contractPrice == null || contractPrice.toString().isEmpty) {
          throw Exception('Contract price not found in Lump Sum contract');
        }
        
        return {
          'amount': double.parse(contractPrice.toString()),
          'contract_type': 'lump_sum',
          'payment_structure': 'single',
        };
      } else if (contractType.contains('time and materials')) {
        if (customAmount == null) {
          throw Exception('Time & Materials contracts require a custom payment amount. Please specify the amount to pay.');
        }
        
        return {
          'amount': customAmount,
          'contract_type': 'time_and_materials',
          'payment_structure': 'variable',
        };
      } else if (contractType.contains('cost-plus') || contractType.contains('cost plus')) {
        if (customAmount == null) {
          throw Exception('Cost Plus contracts require a custom payment amount. Please specify the amount to pay.');
        }
        
        return {
          'amount': customAmount,
          'contract_type': 'cost_plus',
          'payment_structure': 'variable',
        };
      } else {
        if (customAmount == null) {
          throw Exception('Custom contracts require a custom payment amount. Please specify the amount to pay.');
        }
        
        return {
          'amount': customAmount,
          'contract_type': 'custom',
          'payment_structure': 'custom',
        };
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to determine payment amount: $e',
        module: 'Payment Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Determine Payment Amount',
          'project_id': projectId,
          'contract_id': contractId,
        },
      );
      rethrow;
    }
  }

  Map<String, dynamic>? _detectMilestonePayments(String contractType, Map<String, dynamic> fieldValues) {

    final isMilestoneContract = contractType.contains('milestone') || 
                               contractType.contains('phased') ||
                               contractType.contains('progressive');

    final hasMilestoneFields = fieldValues.keys.any((key) => 
        key.toLowerCase().contains('milestone') || 
        key.toLowerCase().contains('payment.milestone') ||
        key.toLowerCase().contains('phase'));

    if (!isMilestoneContract && !hasMilestoneFields) {
      return null;
    }

    final milestones = <Map<String, dynamic>>[];
    double totalContractAmount = 0.0;

    final contractPriceKeys = ['Payment.Total', 'Project.ContractPrice', 'Total.Amount', 'Contract.TotalAmount'];
    for (final key in contractPriceKeys) {
      if (fieldValues.containsKey(key) && fieldValues[key] != null) {
        try {
          totalContractAmount = double.parse(fieldValues[key].toString());
          break;
        } catch (e) {
          // 
        }
      }
    }

    for (int i = 1; i <= 10; i++) { 
      final milestoneKeys = [
        'Payment.Milestone$i',
        'Milestone.$i.Amount',
        'Milestone$i.Payment',
        'Phase.$i.Amount',
      ];

      double? milestoneAmount;
      String? description;
      String? dueDate;

      for (final key in milestoneKeys) {
        if (fieldValues.containsKey(key) && fieldValues[key] != null) {
          try {
            milestoneAmount = double.parse(fieldValues[key].toString());
            break;
          } catch (e) {
            // Continue to next key
          }
        }
      }

      // Look for description and due date
      description = fieldValues['Milestone.$i.Description']?.toString() ?? 
                   fieldValues['Phase.$i.Description']?.toString() ??
                   'Milestone $i';

      dueDate = fieldValues['Milestone.$i.Date']?.toString() ?? 
               fieldValues['Phase.$i.Date']?.toString();

      if (milestoneAmount != null && milestoneAmount > 0) {
        milestones.add({
          'milestone_number': i,
          'amount': milestoneAmount,
          'description': description,
          'due_date': dueDate,
          'status': 'pending',
        });
      }
    }

    if (milestones.isEmpty) {
      return null;
    }

    // Calculate next due milestone
    final nextMilestone = milestones.firstWhere(
      (milestone) => milestone['status'] == 'pending',
      orElse: () => milestones.first,
    );

    return {
      'amount': nextMilestone['amount'],
      'contract_type': 'milestone_based',
      'payment_structure': 'milestone',
      'total_contract_amount': totalContractAmount,
      'milestones': milestones,
      'current_milestone': nextMilestone,
      'total_milestones': milestones.length,
    };
  }

  Future<String> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    String? cardholderName,
    String? billingEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.paymongoBaseUrl}/payment_methods'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${SupabaseConfig.paymongoPublicKey}:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'attributes': {
              'type': 'card',
              'details': {
                'card_number': cardNumber,
                'exp_month': expMonth,
                'exp_year': expYear,
                'cvc': cvc,
              },
              'billing': {
                if (cardholderName != null) 'name': cardholderName,
                if (billingEmail != null) 'email': billingEmail,
              },
            }
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['id'] as String;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['detail'] ?? 'Failed to create payment method';
        throw Exception(errorMessage);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to create payment method: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Create Payment Method',
        },
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.paymongoBaseUrl}/payment_intents/$paymentIntentId/attach'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${SupabaseConfig.paymongoSecretKey}:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'attributes': {
              'payment_method': paymentMethodId,
            }
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['detail'] ?? 'Failed to attach payment method';
        throw Exception(errorMessage);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to attach payment method: $e',
        module: 'Payment Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Attach Payment Method',
          'payment_intent_id': paymentIntentId,
        },
      );
      rethrow;
    }
  }

  Future<void> processPayment({
    required String projectId,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    String? cardholderName,
    String? billingEmail,
    double? customAmount,
  }) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('bid_id, contractor_id, contractee_id, title, projectdata, contract_id')
          .eq('project_id', projectId)
          .single();

      if (projectData['bid_id'] == null) {
        throw Exception('No bid associated with this project');
      }

      String? email = billingEmail;
      if (email == null) {
        try {
          final contracteeData = await _supabase
              .from('Contractee')
              .select('email')
              .eq('contractee_id', projectData['contractee_id'])
              .single();
          email = contracteeData['email'] as String?;
        } catch (_) {
          email = 'payment@contrust.com';
        }
      }

      final paymentInfo = await _determinePaymentAmount(
        projectId: projectId,
        contractId: projectData['contract_id'],
        bidId: projectData['bid_id'],
        customAmount: customAmount,
      );

      final amount = paymentInfo['amount'] as double;
      final contractType = paymentInfo['contract_type'] as String;
      final projectTitle = projectData['title'] as String? ?? 'Untitled Project';

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      if (projectdata['payment_status'] == 'paid') {
        throw Exception('This project has already been paid');
      }

      final paymentIntent = await createPaymentIntent(
        amount: amount,
        projectId: projectId,
        description: 'Payment for $projectTitle',
      );

      final paymentIntentId = paymentIntent['data']['id'] as String;

      final paymentMethodId = await createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
        billingEmail: email,
      );

      final result = await attachPaymentMethod(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      final paymentStatus = result['data']['attributes']['status'] as String;

      if (paymentStatus == 'succeeded' || paymentStatus == 'awaiting_payment_method') {
        final updatedProjectdata = Map<String, dynamic>.from(projectdata);
        
        final payments = List<Map<String, dynamic>>.from(
          updatedProjectdata['payments'] ?? []
        );
        
        payments.add({
          'payment_id': paymentIntentId,
          'amount': amount,
          'date': DateTimeHelper.getLocalTimeISOString(),
          'reference': paymentIntentId,
          'contract_type': contractType,
          'payment_structure': paymentInfo['payment_structure'],
        });
        

        final totalPaid = payments.fold<double>(
          0.0,
          (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0),
        );
        

        updatedProjectdata['payments'] = payments;
        updatedProjectdata['total_paid'] = totalPaid;
        updatedProjectdata['last_payment_date'] = DateTimeHelper.getLocalTimeISOString();
        updatedProjectdata['last_payment_reference'] = paymentIntentId;
        updatedProjectdata['contract_type'] = contractType;
        updatedProjectdata['payment_structure'] = paymentInfo['payment_structure'];
        
   
        if (contractType == 'lump_sum') {
 
          updatedProjectdata['payment_status'] = 'paid';
        } else {
          updatedProjectdata['payment_status'] = 'partial';
        }

        await _supabase.from('Projects').update({
          'projectdata': updatedProjectdata,
        }).eq('project_id', projectId);

        await _auditService.logAuditEvent(
          userId: projectData['contractee_id'],
          action: 'PAYMENT_COMPLETED',
          details: 'Payment completed for project ($contractType)',
          category: 'Payment',
          metadata: {
            'project_id': projectId,
            'amount': amount,
            'payment_reference': paymentIntentId,
            'contract_type': contractType,
            'payment_structure': paymentInfo['payment_structure'],
          },
        );

        if (projectData['contractor_id'] != null) {
          await _notificationService.createNotification(
            receiverId: projectData['contractor_id'],
            receiverType: 'contractor',
            senderId: projectData['contractee_id'],
            senderType: 'contractee',
            type: 'Payment Received',
            message: 'Payment of ₱${amount.toStringAsFixed(2)} has been received for "$projectTitle".',
            information: {
              'project_id': projectId,
              'amount': amount,
              'payment_date': DateTimeHelper.getLocalTimeISOString(),
            },
          );
        }
      } else {
        throw Exception('Payment failed with status: $paymentStatus');
      }
    } catch (e) {
      try {
        final projectData = await _supabase
            .from('Projects')
            .select('projectdata')
            .eq('project_id', projectId)
            .single();

        final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
        final updatedProjectdata = Map<String, dynamic>.from(projectdata);
        updatedProjectdata['payment_status'] = 'failed';
        updatedProjectdata['last_payment_attempt'] = DateTimeHelper.getLocalTimeISOString();

        await _supabase.from('Projects').update({
          'projectdata': updatedProjectdata,
        }).eq('project_id', projectId);
      } catch (_) {}

      await _errorService.logError(
        errorMessage: 'Payment processing failed: $e',
        module: 'Payment Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Process Payment',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<bool> isProjectPaid(String projectId) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('projectdata')
          .eq('project_id', projectId)
          .single();

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final status = projectdata['payment_status'];
      // Consider both 'paid' (fully paid) and 'partial' (milestone payments) as paid
      return status == 'paid' || status == 'partial';
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check payment status: $e',
        module: 'Payment Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Check Payment Status',
          'project_id': projectId,
        },
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPaymentDetails(String projectId) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('projectdata')
          .eq('project_id', projectId)
          .single();

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      
      if (projectdata['payment_status'] == 'paid') {
        return {
          'status': projectdata['payment_status'],
          'date': projectdata['payment_date'],
          'reference': projectdata['payment_reference'],
          'amount': projectdata['payment_amount'],
          'contract_type': projectdata['contract_type'],
          'payment_structure': projectdata['payment_structure'],
        };
      }
      
      return null;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get payment details: $e',
        module: 'Payment Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Payment Details',
          'project_id': projectId,
        },
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> getPaymentInfo(String projectId) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('contract_id, bid_id')
          .eq('project_id', projectId)
          .single();

      final paymentInfo = await _determinePaymentAmount(
        projectId: projectId,
        contractId: projectData['contract_id'],
        bidId: projectData['bid_id'],
        customAmount: null,
      );

      return paymentInfo;
    } catch (e) {
      if (e.toString().contains('require a custom payment amount')) {
        return {
          'amount': null,
          'contract_type': 'variable',
          'payment_structure': 'variable',
          'requires_custom_amount': true,
        };
      }

      await _errorService.logError(
        errorMessage: 'Failed to get payment info: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Payment Info',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  /// Gets payment history for a project
  Future<List<Map<String, dynamic>>> getPaymentHistory(String projectId) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('projectdata')
          .eq('project_id', projectId)
          .single();

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final payments = projectdata['payments'] as List<dynamic>? ?? [];
      
      return List<Map<String, dynamic>>.from(payments);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get payment history: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Payment History',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  /// Gets payment summary for a project
  Future<Map<String, dynamic>> getPaymentSummary(String projectId) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('projectdata, bid_id')
          .eq('project_id', projectId)
          .single();

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final payments = projectdata['payments'] as List<dynamic>? ?? [];
      
      final totalPaid = payments.fold<double>(
        0.0,
        (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0),
      );
      
      // Get total contract amount
      double? totalAmount;
      
      // First, try to get contract price from the signed contract
      if (projectData['contract_id'] != null) {
        try {
          final contractData = await _supabase
              .from('Contracts')
              .select('field_values')
              .eq('contract_id', projectData['contract_id'])
              .single();
          
          final fieldValues = contractData['field_values'] as Map<String, dynamic>? ?? {};
          
          // Try to get contract price from different contract types
          if (fieldValues['Project.ContractPrice'] != null) {
            // Lump Sum contract
            totalAmount = double.tryParse(fieldValues['Project.ContractPrice'].toString());
          } else if (fieldValues['Payment.Total'] != null) {
            // Time & Materials contract
            totalAmount = double.tryParse(fieldValues['Payment.Total'].toString());
          } else if (fieldValues['Estimated Total'] != null) {
            // Cost Plus contract
            totalAmount = double.tryParse(fieldValues['Estimated Total'].toString());
          }
        } catch (_) {}
      }
      
      // Fallback to bid amount if contract price not found
      if (totalAmount == null && projectData['bid_id'] != null) {
        try {
          final bidData = await _supabase
              .from('Bids')
              .select('bid_amount')
              .eq('bid_id', projectData['bid_id'])
              .single();
          totalAmount = (bidData['bid_amount'] as num?)?.toDouble();
        } catch (_) {}
      }
      
      return {
        'payment_status': projectdata['payment_status'] ?? 'unpaid',
        'total_paid': totalPaid,
        'total_amount': totalAmount,
        'payment_count': payments.length,
        'remaining': totalAmount != null ? totalAmount - totalPaid : null,
        'percentage_paid': totalAmount != null && totalAmount > 0 
            ? (totalPaid / totalAmount * 100).toStringAsFixed(1) 
            : null,
        'last_payment_date': projectdata['last_payment_date'],
        'contract_type': projectdata['contract_type'],
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get payment summary: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Payment Summary',
          'project_id': projectId,
        },
      );
      return {
        'payment_status': 'unpaid',
        'total_paid': 0.0,
        'payment_count': 0,
      };
    }
  }

  Future<Map<String, dynamic>?> getMilestonePaymentInfo(String projectId) async {
    try {
      final projectData = await _supabase
          .from('Projects')
          .select('contract_id, bid_id, projectdata')
          .eq('project_id', projectId)
          .single();

      if (projectData['contract_id'] == null) {
        return null;
      }

      final paymentInfo = await _determinePaymentAmount(
        projectId: projectId,
        contractId: projectData['contract_id'],
        bidId: projectData['bid_id'],
      );

      if (paymentInfo['payment_structure'] != 'milestone') {
        return null; 
      }

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final payments = projectdata['payments'] as List<dynamic>? ?? [];
      final milestones = List<Map<String, dynamic>>.from(paymentInfo['milestones'] ?? []);

      for (var milestone in milestones) {
        final milestoneNumber = milestone['milestone_number'];
        final paidPayments = payments.where((payment) => 
          payment['milestone_number'] == milestoneNumber).toList();
        
        if (paidPayments.isNotEmpty) {
          milestone['status'] = 'paid';
          milestone['paid_amount'] = paidPayments.fold<double>(0.0, 
            (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0));
          milestone['payment_date'] = paidPayments.last['created_at'];
        }
      }

      // Find next due milestone
      final nextMilestone = milestones.firstWhere(
        (milestone) => milestone['status'] == 'pending',
        orElse: () => milestones.isNotEmpty ? milestones.last : {},
      );

      return {
        'milestones': milestones,
        'current_milestone': nextMilestone,
        'total_milestones': milestones.length,
        'completed_milestones': milestones.where((m) => m['status'] == 'paid').length,
        'total_contract_amount': paymentInfo['total_contract_amount'],
        'payment_structure': 'milestone',
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get milestone payment info: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {'project_id': projectId},
      );
      return null;
    }
  }

  Future<void> processMilestonePayment({
    required String projectId,
    required int milestoneNumber,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    String? cardholderName,
    String? billingEmail,
  }) async {
    try {
      final milestoneInfo = await getMilestonePaymentInfo(projectId);
      if (milestoneInfo == null) {
        throw Exception('Project does not have milestone-based payments');
      }

      final milestones = List<Map<String, dynamic>>.from(milestoneInfo['milestones']);
      final targetMilestone = milestones.firstWhere(
        (milestone) => milestone['milestone_number'] == milestoneNumber,
        orElse: () => throw Exception('Milestone $milestoneNumber not found'),
      );

      if (targetMilestone['status'] == 'paid') {
        throw Exception('Milestone $milestoneNumber has already been paid');
      }

      final amount = targetMilestone['amount'] as double;

      await processPayment(
        projectId: projectId,
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
        billingEmail: billingEmail,
        customAmount: amount,
      );

      final projectData = await _supabase
          .from('Projects')
          .select('projectdata')
          .eq('project_id', projectId)
          .single();

      final projectdata = Map<String, dynamic>.from(projectData['projectdata'] ?? {});
      final payments = List<Map<String, dynamic>>.from(projectdata['payments'] ?? []);

      if (payments.isNotEmpty) {
        final lastPayment = payments.last;
        lastPayment['milestone_number'] = milestoneNumber;
        lastPayment['milestone_description'] = targetMilestone['description'];
      }

      await _supabase
          .from('Projects')
          .update({'projectdata': projectdata})
          .eq('project_id', projectId);

      await _auditService.logAuditEvent(
        userId: _supabase.auth.currentUser?.id,
        action: 'MILESTONE_PAYMENT_PROCESSED',
        details: 'Milestone $milestoneNumber payment processed for project $projectId',
        metadata: {
          'project_id': projectId,
          'milestone_number': milestoneNumber,
          'amount': amount,
          'description': targetMilestone['description'],
        },
      );

    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to process milestone payment: $e',
        module: 'Payment Service',
        severity: 'High',
        extraInfo: {
          'project_id': projectId,
          'milestone_number': milestoneNumber,
        },
      );
      rethrow;
    }
  }

  Future<bool> isMilestoneContract(String projectId) async {
    try {
      final milestoneInfo = await getMilestonePaymentInfo(projectId);
      return milestoneInfo != null;
    } catch (e) {
      return false;
    }
  }
}

