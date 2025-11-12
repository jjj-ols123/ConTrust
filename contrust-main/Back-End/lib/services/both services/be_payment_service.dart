// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:backend/utils/supabase_config.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/both services/be_receipt_service.dart';
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
            // 
          }
        }
      }

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

    // Option 1: Auto-adjust last milestone to ensure total adds up
    if (totalContractAmount > 0 && milestones.length > 1) {
      // Calculate what the total should be based on down payment and retention percentages
      final downPaymentPercent = fieldValues['Payment.DownPaymentPercentage'] ?? 0.0;
      final retentionPercent = fieldValues['Payment.RetentionPercentage'] ?? 0.0;
      
      double downPaymentAmount = 0.0;
      double retentionAmount = 0.0;
      
      try {
        downPaymentAmount = totalContractAmount * (_parsePercent(downPaymentPercent.toString()) / 100);
        retentionAmount = totalContractAmount * (_parsePercent(retentionPercent.toString()) / 100);
      } catch (e) {
        // Use 0 if parsing fails
      }

      // Calculate expected milestone total = total contract - down payment - retention
      final expectedMilestoneTotal = totalContractAmount - downPaymentAmount - retentionAmount;
      
      // Sum all milestones except the last one
      final sumOfMilestonesExceptLast = milestones.take(milestones.length - 1)
          .fold<double>(0.0, (sum, m) => sum + (m['amount'] as double));
      
      // Auto-adjust the last milestone to ensure total adds up
      if (sumOfMilestonesExceptLast < expectedMilestoneTotal) {
        final lastMilestone = milestones.last;
        lastMilestone['amount'] = expectedMilestoneTotal - sumOfMilestonesExceptLast;
        lastMilestone['description'] = '${lastMilestone['description']}';
      }
    }

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

      if (customAmount == null || customAmount <= 0) {
        throw Exception('Payment amount must be specified. Please enter the amount you want to pay.');
      }

      String? email = billingEmail;
      if (email == null) {
        try {
          final contracteeId = projectData['contractee_id'] as String?;
          {
            final contracteeData = await _supabase
                .from('Contractee')
                .select('email')
                .eq('contractee_id', contracteeId!)
                .single();
            email = contracteeData['email'] as String?;
          }
        } catch (_) {
          email = 'payment@contrust.com';
        }
      }

      final amount = customAmount;
      
      String contractType = 'manual';
      String paymentStructure = 'single';
      
      final contractId = projectData['contract_id'] as String?;
      if (contractId != null) {
        try {
          final contractData = await _supabase
              .from('Contracts')
              .select('contract_type_id')
              .eq('contract_id', contractId)
              .maybeSingle();
          
          if (contractData != null && contractData['contract_type_id'] != null) {
            final contractTypeData = await _supabase
                .from('ContractTypes')
                .select('template_name')
                .eq('contract_type_id', contractData['contract_type_id'])
                .maybeSingle();
            
            if (contractTypeData != null) {
              final templateName = ((contractTypeData['template_name'] as String?)?.toLowerCase() ?? 'custom');
              // Normalize contract type names to match _checkAndCompleteProject expectations
              if (templateName.contains('lump sum')) {
                contractType = 'lump_sum';
              } else if (templateName.contains('time and materials')) {
                contractType = 'time_and_materials';
              } else if (templateName.contains('cost-plus') || templateName.contains('cost plus')) {
                contractType = 'cost_plus';
              } else {
                contractType = templateName.replaceAll(' ', '_');
              }
            }
          }
        } catch (_) {
          // Use default values if contract lookup fails
        }
      }
      
      final projectTitle = projectData['title'] as String? ?? 'Untitled Project';

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final projectStatus = projectData['status'] as String?;
      
      // Use contractType from contract lookup (line 415), or fallback to projectdata if not found
      if (contractType == 'manual') {
        final projectdataContractType = projectdata['contract_type'] as String? ?? '';
        if (projectdataContractType.isNotEmpty) {
          contractType = projectdataContractType;
        }
      }
      
      // Check if project is already completed
      if (projectStatus == 'completed') {
        throw Exception('This project has already been completed');
      }
      
      // Check if project is already fully paid (only for non-milestone contracts)
      // Milestone contracts can have partial payments, so allow payment even if status is 'partial'
      final currentPaymentStatus = projectdata['payment_status'] as String?;
      if (currentPaymentStatus == 'paid' && !contractType.toLowerCase().contains('milestone')) {
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

      final stripePaymentStatus = result['data']['attributes']['status'] as String;

      if (stripePaymentStatus == 'succeeded' || stripePaymentStatus == 'awaiting_payment_method') {
        final contracteeId = projectData['contractee_id'] as String?;
        final contractorId = projectData['contractor_id'] as String?;
        final contractId = projectData['contract_id'] as String?;
        
        if (contracteeId == null || contractorId == null) {
          throw Exception('Missing contractee or contractor information');
        }

        String paymentType;
        if (contractType == 'lump_sum') {
          paymentType = 'lump_sum';
        } else if (contractType == 'cost_plus') {
          paymentType = 'cost_plus';
        } else if (contractType == 'time_and_materials') {
          paymentType = 'time_and_materials';
        } else {
          paymentType = 'custom';
        }

        final paymentRecord = await _supabase.from('Payments').insert({
          'project_id': projectId,
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
          'amount': amount,
          'payment_type': paymentType,
          'payment_status': 'completed',
          'payment_intent_id': paymentIntentId,
          'payment_method': 'card',
          'payment_reference': paymentIntentId,
          'description': 'Payment for $projectTitle',
          'paid_at': DateTimeHelper.getLocalTimeISOString(),
          'created_by': contracteeId,
        }).select().single();

        final paymentsData = await _supabase
            .from('Payments')
            .select('amount')
            .eq('project_id', projectId)
            .eq('payment_status', 'completed');
        
        final totalPaid = (paymentsData as List).fold<double>(
          0.0,
          (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0),
        );
        
        final updatedProjectdata = Map<String, dynamic>.from(projectdata);
        updatedProjectdata['total_paid'] = totalPaid;
        updatedProjectdata['last_payment_date'] = DateTimeHelper.getLocalTimeISOString();
        updatedProjectdata['last_payment_reference'] = paymentIntentId;
        updatedProjectdata['contract_type'] = contractType;
        updatedProjectdata['payment_structure'] = paymentStructure;
        
        if (contractType == 'lump_sum') {
          updatedProjectdata['payment_status'] = 'paid';
        } else {
          updatedProjectdata['payment_status'] = 'partial';
        }

        await _supabase.from('Projects').update({
          'projectdata': updatedProjectdata,
        }).eq('project_id', projectId);
        
        String? receiptPath = paymentRecord['receipt_path'] as String?;

        try {
          String contracteeName = 'Contractee';
          String contracteeEmail = '';
          String contractorName = 'Contractor';
          
          {
            try {
              final contracteeData = await _supabase
                  .from('Contractee')
                  .select('full_name')
                  .eq('contractee_id', contracteeId)
                  .maybeSingle();
              if (contracteeData != null) {
                contracteeName = contracteeData['full_name'] ?? 'Contractee';
              }
              
              final userData = await _supabase
                  .from('Users')
                  .select('email')
                  .eq('users_id', contracteeId)
                  .maybeSingle();
              if (userData != null) {
                contracteeEmail = userData['email'] ?? '';
              }
            } catch (e) {
              //
            }   
          }
          
          {
            try {
              final contractorData = await _supabase
                  .from('Contractor')
                  .select('firm_name')
                  .eq('contractor_id', contractorId)
                  .maybeSingle();
              if (contractorData != null) {
                contractorName = contractorData['firm_name'] ?? 'Contractor';
              }
            } catch (e) {
              // Use defaults if fetch fails
            }
          }
          
          // Generate receipt PDF
          final receiptPdf = await ReceiptService.generateReceiptPdf(
            paymentId: paymentIntentId,
            amount: amount,
            projectTitle: projectTitle,
            contractorName: contractorName,
            contracteeName: contracteeName,
            contracteeEmail: contracteeEmail,
            paymentDate: DateTimeHelper.getLocalTimeISOString(),
            paymentReference: paymentIntentId,
            contractType: contractType,
            paymentStructure: paymentStructure,
          );
          
          // Upload receipt to storage
          {
            receiptPath = await ReceiptService.uploadReceiptToStorage(
              pdfBytes: receiptPdf,
              projectId: projectId,
              contracteeId: contracteeId,
              paymentId: paymentIntentId,
            );
            
            // Update payment record with receipt path
            await _supabase.from('Payments').update({
              'receipt_path': receiptPath,
              'receipt_generated_at': DateTimeHelper.getLocalTimeISOString(),
            }).eq('payment_reference', paymentIntentId);
          }
        } catch (receiptError) {
          // Log error but don't fail payment
          await _errorService.logError(
            errorMessage: 'Failed to generate receipt: $receiptError',
            module: 'Payment Service',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Generate Receipt',
              'project_id': projectId,
              'payment_id': paymentIntentId,
            },
          );
        }

        {
          await _auditService.logAuditEvent(
            userId: contracteeId,
            action: 'PAYMENT_COMPLETED',
            details: 'Payment completed for project ($contractType)',
            category: 'Payment',
            metadata: {
              'project_id': projectId,
              'amount': amount,
              'payment_reference': paymentIntentId,
              'contract_type': contractType,
              'payment_structure': paymentStructure,
              'receipt_path': receiptPath,
            },
          );
        }

        {
          await _notificationService.createNotification(
            receiverId: contractorId,
            receiverType: 'contractor',
            senderId: contracteeId,
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

        // Check and complete project after payment (pass the updated payment_status)
        // Ensure we use the correct contract type and payment status
        final finalContractType = updatedProjectdata['contract_type'] as String? ?? contractType;
        final finalPaymentStatus = updatedProjectdata['payment_status'] as String?;
        
        await _checkAndCompleteProject(
          projectId, 
          finalContractType,
          paymentStatus: finalPaymentStatus,
        );
      } else {
        throw Exception('Payment failed with status: $stripePaymentStatus');
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
          .select('status')
          .eq('project_id', projectId)
          .single();

      final projectStatus = (projectData['status'] as String?)?.toLowerCase();
      if (projectStatus == 'completed') {
        return true;
      }

      bool isPaid = false;

      final isMilestone = await isMilestoneContract(projectId);

      if (isMilestone) {
        final milestoneInfo = await getMilestonePaymentInfo(projectId);
        if (milestoneInfo != null) {
          final completedMilestones = milestoneInfo['completed_milestones'] as int? ?? 0;
          final totalMilestones = milestoneInfo['total_milestones'] as int? ?? 0;
          isPaid = totalMilestones > 0 && completedMilestones >= totalMilestones;
        }
      } else {
        final paymentsData = await _supabase
            .from('Payments')
            .select('payment_id')
            .eq('project_id', projectId)
            .eq('payment_status', 'completed')
            .limit(1);

        isPaid = (paymentsData as List).isNotEmpty;
      }

      if (isPaid && projectStatus != 'completed') {
        try {
          await _supabase
              .from('Projects')
              .update({'status': 'completed'})
              .eq('project_id', projectId);
        } catch (updateError) {
          await _errorService.logError(
            errorMessage: 'Failed to auto-complete project after payment: $updateError',
            module: 'Payment Service',
            severity: 'Low',
            extraInfo: {
              'operation': 'Auto-complete project',
              'project_id': projectId,
            },
          );
        }
      }

      return isPaid;
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
      // Always return requires_custom_amount: true so contractee can specify the amount
      // This removes dependency on bid_id
      return {
        'amount': null,
        'contract_type': 'manual',
        'payment_structure': 'manual',
        'requires_custom_amount': true,
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get payment info: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Payment Info',
          'project_id': projectId,
        },
      );
      // Still return requires_custom_amount even on error
      return {
        'amount': null,
        'contract_type': 'manual',
        'payment_structure': 'manual',
        'requires_custom_amount': true,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String projectId) async {
    try {
      final paymentsData = await _supabase
          .from('Payments')
          .select('*')
          .eq('project_id', projectId)
          .order('paid_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(paymentsData as List);
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
          .select('projectdata, bid_id, contract_id')
          .eq('project_id', projectId)
          .single();

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final contractType = (projectdata['contract_type'] as String?)?.toLowerCase() ?? '';
      
      // Get payments from Payments table
      final paymentsData = await _supabase
          .from('Payments')
          .select('amount')
          .eq('project_id', projectId)
          .eq('payment_status', 'completed');
      
      final payments = paymentsData as List;
      
      final totalPaid = payments.fold<double>(
        0.0,
        (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0),
      );
      
      // Get total contract amount
      double? totalAmount;
      
      // For custom contracts, use bid amount directly (no field_values)
      if (contractType == 'custom') {
        final bidId = projectData['bid_id'] as String?;
        if (bidId != null) {
          try {
            final bidData = await _supabase
                .from('Bids')
                .select('bid_amount')
                .eq('bid_id', bidId)
                .single();
            totalAmount = (bidData['bid_amount'] as num?)?.toDouble();
          } catch (_) {}
        }
      } else {
        // For other contract types, try to get from contract field_values first
        final contractId = projectData['contract_id'] as String?;
        if (contractId != null) {
          try {
            final contractData = await _supabase
                .from('Contracts')
                .select('field_values')
                .eq('contract_id', contractId)
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
        if (totalAmount == null) {
          final bidId = projectData['bid_id'] as String?;
          if (bidId != null) {
            try {
              final bidData = await _supabase
                  .from('Bids')
                  .select('bid_amount')
                  .eq('bid_id', bidId)
                  .single();
              totalAmount = (bidData['bid_amount'] as num?)?.toDouble();
            } catch (_) {}
          }
        }
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

      final contractId = projectData['contract_id'] as String?;
      final bidId = projectData['bid_id'] as String?;

      if (contractId == null || bidId == null) {
        return null;
      }

      final contractData = await _supabase
          .from('Contracts')
          .select('field_values, contract_type:ContractTypes(template_name)')
          .eq('contract_id', contractId)
          .single();


      final fieldValues = Map<String, dynamic>.from(contractData['field_values'] ?? {});
      final contractTypeData = contractData['contract_type'] as Map<String, dynamic>?;
      final contractType = contractTypeData?['template_name'] as String? ?? '';

      final milestonePaymentInfo = _detectMilestonePayments(contractType, fieldValues);

      if (milestonePaymentInfo != null) {
        final milestones = List<Map<String, dynamic>>.from(milestonePaymentInfo['milestones'] ?? []);
 
        final milestoneProgressData = await _supabase
            .from('MilestoneProgress')
            .select()
            .eq('contract_id', contractId);
        
        final milestoneProgressList = milestoneProgressData as List;
        
        for (var milestone in milestones) {
          final milestoneNumber = milestone['milestone_number'];
          final progressRecord = milestoneProgressList.firstWhere(
            (m) => m['milestone_number'] == milestoneNumber,
            orElse: () => <String, dynamic>{},
          );

          final progressStatus = (progressRecord['status'] as String?)?.toLowerCase();
          final hasBeenPaid = progressRecord.isNotEmpty &&
              (progressRecord['paid_at'] != null ||
                  progressStatus == 'completed' ||
                  progressStatus == 'paid');

          if (hasBeenPaid) {
            milestone['status'] = 'paid';
            milestone['paid_amount'] = (progressRecord['amount'] as num?)?.toDouble() ?? 0.0;
            milestone['payment_date'] = progressRecord['paid_at'];
          } else if (progressStatus != null) {
            milestone['status'] = progressStatus;
          }
        }

        milestones.sort((a, b) => (a['milestone_number'] as int).compareTo(b['milestone_number'] as int));

        final nextMilestone = milestones.firstWhere(
          (milestone) {
            final status = (milestone['status'] as String?)?.toLowerCase();
            return status == null || status == 'pending';
          },
          orElse: () => milestones.isNotEmpty ? milestones.last : {},
        );
        
        return {
          ...milestonePaymentInfo,
          'milestones': milestones,
          'current_milestone': nextMilestone,
          'completed_milestones': milestones
              .where((m) {
                final status = (m['status'] as String?)?.toLowerCase();
                return status == 'paid' || status == 'completed';
              })
              .length,
        };
      }

      if (contractType.toLowerCase().contains('lump sum')) {

        double? amount;
        final priceKeys = ['Project.ContractPrice', 'Payment.Total', 'Total.Amount', 'Contract.TotalAmount'];

        for (final key in priceKeys) {
          final value = fieldValues[key];

          if (value != null && value.toString().isNotEmpty) {
            try {
              amount = double.parse(value.toString());
              break;
            } catch (e) {
              //
            }
          }
        }

        if (amount == null) {
          return null;
        }

        final singleMilestone = {
          'milestone_number': 1,
          'description': 'Full Contract Payment',
          'amount': amount,
          'status': 'pending',
          'due_date': null,
        };

        return {
          'milestones': [singleMilestone],
          'current_milestone': singleMilestone,
          'total_milestones': 1,
          'completed_milestones': 0,
          'total_contract_amount': amount,
          'payment_structure': 'milestone',
          'contract_info': {
            'total_price': amount,
            'down_payment_percentage': 0.0,
            'retention_percentage': 0.0,
            'final_payment': 0.0,
          },
        };
      }

      return null;
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
      final projectData = await _supabase
          .from('Projects')
          .select('contract_id, title, contractor_id, contractee_id, projectdata')
          .eq('project_id', projectId)
          .single();

      final contractId = projectData['contract_id'] as String?;
      final projectTitle = projectData['title'] ?? 'Project';
      final contractorId = projectData['contractor_id'] as String?;
      final contracteeId = projectData['contractee_id'] as String?;
      
      if (contractId == null) {
        throw Exception('Project does not have an associated contract');
      }
      
      if (contracteeId == null || contractorId == null) {
        throw Exception('Missing contractee or contractor information');
      }

      final existingMilestone = await _supabase
          .from('MilestoneProgress')
          .select()
          .eq('contract_id', contractId)
          .eq('milestone_number', milestoneNumber)
          .maybeSingle();

      if (existingMilestone != null && existingMilestone['paid_at'] != null) {
        throw Exception('Milestone $milestoneNumber has already been paid');
      }

      final milestoneInfo = await getMilestonePaymentInfo(projectId);
      if (milestoneInfo == null) {
        throw Exception('Project does not have milestone-based payments');
      }

      final milestones = List<Map<String, dynamic>>.from(milestoneInfo['milestones']);
      final targetMilestone = milestones.firstWhere(
        (milestone) => milestone['milestone_number'] == milestoneNumber,
        orElse: () => throw Exception('Milestone $milestoneNumber not found'),
      );

      final amount = (targetMilestone['amount'] as num).toDouble();
      final description = targetMilestone['description'] as String? ?? 'Milestone $milestoneNumber';

      final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
      final projectStatus = projectData['status'] as String?;
      
      if (projectStatus == 'completed') {
        throw Exception('This project has already been completed');
      }

      final paymentIntent = await createPaymentIntent(
        amount: amount,
        projectId: projectId,
        description: 'Milestone $milestoneNumber payment for $projectTitle',
      );

      final paymentIntentId = paymentIntent['data']['id'] as String;

      final paymentMethodId = await createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
        billingEmail: billingEmail,
      );

      final result = await attachPaymentMethod(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      final stripePaymentStatus = result['data']['attributes']['status'] as String;

      if (stripePaymentStatus == 'succeeded' || stripePaymentStatus == 'awaiting_payment_method') {
        final paymentRecord = await _supabase.from('Payments').insert({
          'project_id': projectId,
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
          'amount': amount,
          'payment_type': 'milestone',
          'payment_status': 'completed',
          'milestone_number': milestoneNumber,
          'milestone_description': description,
          'payment_intent_id': paymentIntentId,
          'payment_method': 'card',
          'payment_reference': paymentIntentId,
          'description': 'Milestone $milestoneNumber: $description',
          'paid_at': DateTimeHelper.getLocalTimeISOString(),
          'created_by': contracteeId,
        }).select().single();

        final paymentId = paymentRecord['payment_id'] as String;

        if (existingMilestone == null) {
          await _supabase.from('MilestoneProgress').insert({
            'contract_id': contractId,
            'project_id': projectId,
            'milestone_number': milestoneNumber,
            'description': description,
            'amount': amount,
            'status': 'completed',
            'completion_percentage': 100.0,
            'completed_at': DateTimeHelper.getLocalTimeISOString(),
            'payment_id': paymentId,
            'paid_at': DateTimeHelper.getLocalTimeISOString(),
          });
        } else {
          await _supabase.from('MilestoneProgress').update({
            'status': 'completed',
            'completion_percentage': 100.0,
            'completed_at': DateTimeHelper.getLocalTimeISOString(),
            'payment_id': paymentId,
            'paid_at': DateTimeHelper.getLocalTimeISOString(),
          }).eq('contract_id', contractId).eq('milestone_number', milestoneNumber);
        }

        final paymentsData = await _supabase
            .from('Payments')
            .select('amount')
            .eq('project_id', projectId)
            .eq('payment_status', 'completed');
        
        final totalPaid = (paymentsData as List).fold<double>(
          0.0,
          (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0),
        );
        
        final updatedProjectdata = Map<String, dynamic>.from(projectdata);
        updatedProjectdata['total_paid'] = totalPaid;
        updatedProjectdata['last_payment_date'] = DateTimeHelper.getLocalTimeISOString();
        updatedProjectdata['last_payment_reference'] = paymentIntentId;
        updatedProjectdata['contract_type'] = 'milestone';
        updatedProjectdata['payment_structure'] = 'milestone';
        
        final allMilestonesData = await _supabase
            .from('MilestoneProgress')
            .select('status')
            .eq('contract_id', contractId);
        
        final allMilestones = allMilestonesData as List;
        final allPaid = allMilestones.isNotEmpty && 
                       allMilestones.every((m) => m['status'] == 'completed');
        
        updatedProjectdata['payment_status'] = allPaid ? 'paid' : 'partial';

        await _supabase.from('Projects').update({
          'projectdata': updatedProjectdata,
        }).eq('project_id', projectId);
        
        try {
          String contracteeName = 'Contractee';
          String contracteeEmail = '';
          String contractorName = 'Contractor';
          
          {
            try {
              final contracteeData = await _supabase
                  .from('Contractee')
                  .select('full_name')
                  .eq('contractee_id', contracteeId)
                  .maybeSingle();
              if (contracteeData != null) {
                contracteeName = contracteeData['full_name'] ?? 'Contractee';
              }
              
              final userData = await _supabase
                  .from('Users')
                  .select('email')
                  .eq('users_id', contracteeId)
                  .maybeSingle();
              if (userData != null) {
                contracteeEmail = userData['email'] ?? '';
              }
            } catch (e) {
              //
            }
          }
          
          {
            try {
              final contractorData = await _supabase
                  .from('Contractor')
                  .select('firm_name')
                  .eq('contractor_id', contractorId)
                  .maybeSingle();
              if (contractorData != null) {
                contractorName = contractorData['firm_name'] ?? 'Contractor';
              }
            } catch (e) {
              // Use defaults if fetch fails
            }
          }
          
          final paymentDate = DateTimeHelper.getLocalTimeISOString();
          
          // Generate receipt PDF
          final receiptPdf = await ReceiptService.generateReceiptPdf(
            paymentId: paymentId,
            amount: amount,
            projectTitle: projectTitle,
            contractorName: contractorName,
            contracteeName: contracteeName,
            contracteeEmail: contracteeEmail,
            paymentDate: paymentDate,
            paymentReference: paymentId,
            contractType: 'milestone',
            paymentStructure: 'milestone',
            milestoneNumber: milestoneNumber,
            milestoneDescription: targetMilestone['description'],
          );
          
          // Upload receipt to storage
          final receiptPath = await ReceiptService.uploadReceiptToStorage(
            pdfBytes: receiptPdf,
            projectId: projectId,
            contracteeId: contracteeId,
            paymentId: paymentIntentId,
          );
          
          // Update payment record with receipt path
          await _supabase.from('Payments').update({
            'receipt_path': receiptPath,
            'receipt_generated_at': DateTimeHelper.getLocalTimeISOString(),
          }).eq('payment_reference', paymentIntentId);
        } catch (receiptError) {
          // Log error but don't fail payment
          await _errorService.logError(
            errorMessage: 'Failed to generate receipt: $receiptError',
            module: 'Payment Service',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Generate Receipt (Milestone)',
              'project_id': projectId,
              'milestone_number': milestoneNumber,
            },
          );
        }
        
        // Check if all milestones are paid and auto-complete if so
        await _checkAndCompleteProject(projectId, 'milestone', paymentStatus: updatedProjectdata['payment_status'] as String?);
      } else {
        throw Exception('Payment failed with status: $stripePaymentStatus');
      }

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
      final projectData = await _supabase
          .from('Projects')
          .select('contract_id, bid_id, projectdata')
          .eq('project_id', projectId)
          .single();

      final contractId = projectData['contract_id'] as String?;
      final bidId = projectData['bid_id'] as String?;
      if (contractId == null || bidId == null) {
        return false;
      }

      final milestoneInfo = await getMilestonePaymentInfo(projectId);
      final result = milestoneInfo != null;

      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> initializeMilestones({
    required String projectId,
    required String contractId,
  }) async {
    try {
      final milestoneInfo = await getMilestonePaymentInfo(projectId);
      if (milestoneInfo == null) {
        return;
      }

      final milestones = List<Map<String, dynamic>>.from(milestoneInfo['milestones'] ?? []);

      final existingMilestones = await _supabase
          .from('MilestoneProgress')
          .select('milestone_number')
          .eq('contract_id', contractId);
      
      final existingNumbers = (existingMilestones as List)
          .map((m) => m['milestone_number'] as int)
          .toSet();

      for (final milestone in milestones) {
        final milestoneNumber = milestone['milestone_number'] as int;
        
        if (existingNumbers.contains(milestoneNumber)) {
          continue;
        }

        final amount = (milestone['amount'] as num).toDouble();
        final description = milestone['description'] as String? ?? 'Milestone $milestoneNumber';
        final dueDate = milestone['due_date'] as String?;

        await _supabase.from('MilestoneProgress').insert({
          'contract_id': contractId,
          'project_id': projectId,
          'milestone_number': milestoneNumber,
          'description': description,
          'amount': amount,
          'target_date': dueDate,
          'status': 'pending',
          'completion_percentage': 0.0,
        });

      }

      await _auditService.logAuditEvent(
        userId: _supabase.auth.currentUser?.id,
        action: 'MILESTONES_INITIALIZED',
        details: 'Initialized ${milestones.length} milestones for contract',
        category: 'Payment',
        metadata: {
          'project_id': projectId,
          'contract_id': contractId,
          'milestone_count': milestones.length,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to initialize milestones: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Initialize Milestones',
          'project_id': projectId,
          'contract_id': contractId,
        },
      );
      // Don't rethrow - this is a background operation
    }
  }

  Future<void> _checkAndCompleteProject(
    String projectId, 
    String contractType, {
    String? paymentStatus,
  }) async {
    try {
      final normalizedContractType = contractType.toLowerCase().trim();
      final isLumpSum = normalizedContractType == 'lump_sum' || 
                       (normalizedContractType.contains('lump') && normalizedContractType.contains('sum'));
      
      bool isFullyPaid = false;

      if (isLumpSum) {
        if (paymentStatus != null) {
          isFullyPaid = paymentStatus.toLowerCase() == 'paid';
        } else {
          final projectData = await _supabase
              .from('Projects')
              .select('projectdata')
              .eq('project_id', projectId)
              .single();

          final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
          final status = projectdata['payment_status'] as String?;
          isFullyPaid = (status?.toLowerCase() ?? '') == 'paid';
        }
      } else if (contractType == 'custom' || contractType == 'cost_plus' || contractType == 'time_and_materials') {
        final projectData = await _supabase
            .from('Projects')
            .select('projectdata, contract_id, bid_id')
            .eq('project_id', projectId)
            .single();

        final projectdata = projectData['projectdata'] as Map<String, dynamic>? ?? {};
        
        final paymentsData = await _supabase
            .from('Payments')
            .select('amount')
            .eq('project_id', projectId)
            .eq('payment_status', 'completed');
        
        final totalPaid = (paymentsData as List).fold<double>(
          0.0,
          (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0.0),
        );

        double? totalAmount;
        
        if (contractType == 'custom') {
          final bidId = projectData['bid_id'] as String?;
          if (bidId != null) {
            try {
              final bidData = await _supabase
                  .from('Bids')
                  .select('bid_amount')
                  .eq('bid_id', bidId)
                  .single();
              totalAmount = (bidData['bid_amount'] as num?)?.toDouble();
            } catch (_) {
            }
          }
        } else {
          final contractId = projectData['contract_id'] as String?;
          if (contractId != null) {
            try {
              final contractData = await _supabase
                  .from('Contracts')
                  .select('field_values')
                  .eq('contract_id', contractId)
                  .single();
              
              final fieldValues = contractData['field_values'] as Map<String, dynamic>? ?? {};
              
              if (fieldValues['Payment.Total'] != null) {
                totalAmount = double.tryParse(fieldValues['Payment.Total'].toString());
              } else if (fieldValues['Estimated Total'] != null) {
                totalAmount = double.tryParse(fieldValues['Estimated Total'].toString());
              }
            } catch (_) {
            }
          }
          
          if (totalAmount == null) {
            final bidId = projectData['bid_id'] as String?;
            if (bidId != null) {
              try {
                final bidData = await _supabase
                    .from('Bids')
                    .select('bid_amount')
                    .eq('bid_id', bidId)
                    .single();
                totalAmount = (bidData['bid_amount'] as num?)?.toDouble();
              } catch (_) {
              }
            }
          }
        }

        if (totalAmount != null && totalAmount > 0) {
          isFullyPaid = totalPaid >= (totalAmount - 0.01); // Allow 1 cent tolerance
          
          if (isFullyPaid) {
            final updatedProjectdata = Map<String, dynamic>.from(projectdata);
            updatedProjectdata['payment_status'] = 'paid';

            await _supabase.from('Projects').update({
              'projectdata': updatedProjectdata,
            }).eq('project_id', projectId);
          }
        }
      } else if (normalizedContractType.contains('milestone')) {
        final milestoneInfo = await getMilestonePaymentInfo(projectId);
        if (milestoneInfo != null) {
          final completedMilestones = milestoneInfo['completed_milestones'] as int? ?? 0;
          final totalMilestones = milestoneInfo['total_milestones'] as int? ?? 0;
          isFullyPaid = totalMilestones > 0 && completedMilestones >= totalMilestones;
          
          if (isFullyPaid) {
            final projectData = await _supabase
                .from('Projects')
                .select('projectdata')
                .eq('project_id', projectId)
                .single();

            final projectdata = Map<String, dynamic>.from(projectData['projectdata'] ?? {});
            projectdata['payment_status'] = 'paid';

            await _supabase.from('Projects').update({
              'projectdata': projectdata,
            }).eq('project_id', projectId);
          }
        }
      }

      if (isFullyPaid) {
        final projectData = await _supabase
            .from('Projects')
            .select('contract_id, title, contractor_id, contractee_id, status')
            .eq('project_id', projectId)
            .single();

        final contractId = projectData['contract_id'] as String?;
        final projectTitle = projectData['title'] as String? ?? 'Project';
        final contractorId = projectData['contractor_id'] as String?;
        final contracteeId = projectData['contractee_id'] as String?;
        final currentStatus = projectData['status'] as String?;

        if (currentStatus?.toLowerCase() != 'completed') {
          await _supabase.from('Projects').update({
            'status': 'completed',
            'updated_at': DateTimeHelper.getLocalTimeISOString(),
          }).eq('project_id', projectId);

          if (contractId != null) {
            await _supabase.from('Contracts').update({
              'status': 'completed',
              'updated_at': DateTimeHelper.getLocalTimeISOString(),
            }).eq('contract_id', contractId);
          }
        }

        if (contracteeId != null) {
          await _auditService.logAuditEvent(
            userId: contracteeId,
            action: 'PROJECT_COMPLETED',
            details: 'Project automatically completed after full payment',
            category: 'Project',
            metadata: {
              'project_id': projectId,
              'contract_id': contractId,
              'contract_type': contractType,
            },
          );
        }

        if (contractorId != null && contracteeId != null) {
          await _notificationService.createNotification(
            receiverId: contractorId,
            receiverType: 'contractor',
            senderId: 'system',
            senderType: 'system',
            type: 'Project Completed',
            message: 'Project "$projectTitle" has been automatically completed after full payment.',
            information: {
              'project_id': projectId,
              'contract_id': contractId,
              'completion_date': DateTimeHelper.getLocalTimeISOString(),
            },
          );

          await _notificationService.createNotification(
            receiverId: contracteeId,
            receiverType: 'contractee',
            senderId: 'system',
            senderType: 'system',
            type: 'Project Completed',
            message: 'Project "$projectTitle" has been automatically completed after full payment.',
            information: {
              'project_id': projectId,
              'contract_id': contractId,
              'completion_date': DateTimeHelper.getLocalTimeISOString(),
            },
          );
        }
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check and complete project: $e',
        module: 'Payment Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Check and Complete Project',
          'project_id': projectId,
        },
      );
      // Don't rethrow - this is a background operation that shouldn't fail payment
    }
  }

  double _parsePercent(String raw) {
    final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '');
    final v = double.tryParse(cleaned) ?? 0.0;

    if (cleaned.contains('.')) {
      return v; 
    } else {
      return v / 100.0; 
    }
  }
}

