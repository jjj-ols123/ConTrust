// ignore_for_file: use_build_context_synchronously_user_service.dart';, use_build_context_synchronously, use_build_context_synchronously
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'dart:typed_data';

class SignUpContractor {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<void> signUpContractor(
    BuildContext context,
    String email,
    String password,
    String userType,
    Map<String, dynamic>? data,
    bool Function() validateFields,
  ) async {
    final supabase = Supabase.instance.client;

    if (!validateFields()) {
      return;
    }

    final List<Map<String, dynamic>> verificationFiles = (data?['verificationFiles'] as List<Map<String, dynamic>>? ?? []);

    if (verificationFiles.isEmpty) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Please upload verification documents before signing up.');
      }
      return;
    }

    dynamic signUpResponse;
    try {

      Map<String, dynamic> signUpData = Map.from(data ?? {});
      signUpData.remove('verificationFiles');

      signUpResponse = await UserService().signUp(
        email: email,
        password: password,
        data: signUpData,
      );

      if (!context.mounted) return;

      final String? userId = signUpResponse.user?.id ?? signUpResponse.session?.user.id;

      if (userId == null) {
        await _auditService.logAuditEvent(
          action: 'USER_REGISTRATION_FAILED',
          details: 'Contractor registration failed - no user ID returned',
          metadata: {
            'user_type': userType,
            'email': email,
            'failure_reason': 'no_user_id',
          },
        );

        await _errorService.logError(
          errorMessage: 'Contractor sign-up failed - no user ID returned from sign-up response',
          module: 'Contractor Sign-up',
          severity: 'High',
          extraInfo: {
            'operation': 'Sign Up Contractor',
            'email': email,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (!context.mounted) return;
        ConTrustSnackBar.error(context, 'Failed to create account. Please try again.');
        return;
      }

      if (userType == 'contractor') {
        await supabase.from('Users').upsert({
          'users_id': userId,
          'email': email,
          'name': data?['firmName'] ?? 'Contractor Firm',
          'role': 'contractor',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'last_login': DateTime.now().toIso8601String(),
          'profile_image_url': data?['profilePhoto'],
          'phone_number': data?['contactNumber'] ?? '',
          'verified': false,
        }, onConflict: 'users_id');

        final contractorData = {
          'contractor_id': userId,
          'firm_name': data?['firmName'] ?? '',
          'contact_number': data?['contactNumber'],
          'address': data?['address'] ?? '', 
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

        final insertResponse = await supabase
            .from('Contractor')
            .insert(contractorData)
            .select();

        if ((insertResponse as List).isEmpty) {
          await _auditService.logAuditEvent(
            userId: userId,
            action: 'USER_REGISTRATION_FAILED',
            details: 'Contractor registration failed - data insertion error',
            metadata: {
              'user_type': userType,
              'email': email,
              'firm_name': data?['firmName'],
              'failure_reason': 'contractor_data_insertion_failed',
            },
          );

          await _errorService.logError(
            errorMessage: 'Failed to insert contractor data for user ID $userId - insert response was empty',
            module: 'Contractor Sign-up',
            severity: 'High',
            extraInfo: {
              'operation': 'Insert Contractor Data',
              'users_id': userId,
              'email': email,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          throw Exception("Error saving contractor data");
        }

        for (int i = 0; i < verificationFiles.length; i++) {
          final fileData = verificationFiles[i];
          final fileBytes = fileData['bytes'] as Uint8List;
          final fileName = fileData['name'] as String;
          final isImage = fileData['isImage'] as bool;

          final url = await UserService().uploadImage(
            fileBytes,
            'verification',
            folderPath: 'contractor/$userId',
            fileName: fileName,
          );

          await supabase.from('Verification').insert({
            'contractor_id': userId,
            'doc_url': url,
            'uploaded_at': DateTime.now().toIso8601String(),
            'file_type': isImage ? 'image' : 'document', 
          });
        }
      }

      await _auditService.logAuditEvent(
        userId: userId,
        action: 'USER_REGISTRATION',
        details: 'Contractor account created successfully',
        metadata: {
          'user_type': userType,
          'email': email,
          'firm_name': data?['firmName'],
          'registration_method': 'email_password',
        },
      );

      if (!context.mounted) return;
      ConTrustSnackBar.success(context, 'Account successfully created');

      await Future.delayed(const Duration(seconds: 2));  
      Navigator.pop(context);
      
    } on AuthException catch (e) {
      await _auditService.logAuditEvent(
        userId: signUpResponse?.user?.id, 
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractor registration failed due to authentication error',
        metadata: {
          'user_type': userType,
          'email': email,
          'error_type': 'AuthException',
          'error_message': e.message,
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractor sign-up failed - AuthException: ${e.message}',
        module: 'Contractor Sign-up',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Sign Up Contractor',
          'email': email,
          'user_type': userType,
          'users_id': signUpResponse?.user?.id, 
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Error creating account: ${e.message}');
      return;
    } catch (e) {
      await _auditService.logAuditEvent(
        userId: signUpResponse?.user?.id,  
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractor registration failed due to unexpected error',
        metadata: {
          'user_type': userType,
          'email': email,
          'error_type': 'UnexpectedError',
          'error_message': e.toString(),
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractor sign-up failed - Unexpected error: $e',
        module: 'Contractor Sign-up',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign Up Contractor',
          'email': email,
          'user_type': userType,
          'users_id': signUpResponse?.user?.id,  
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Unexpected error: $e');
    }
  }
}
