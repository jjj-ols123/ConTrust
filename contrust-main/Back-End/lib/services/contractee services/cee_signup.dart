// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignUpContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<bool> signUpContractee(
    BuildContext context,
    String email,
    String password,
    String userType,
    Map<String, dynamic>? data,
    bool Function() validateFields,
  ) async {
  
    final supabase = Supabase.instance.client;
    int project = 0;
    dynamic signUpResponse; 

    if (!validateFields()) {
      return false;
    }

    try {
      signUpResponse = await UserService().signUp(
        email: email,
        password: password,
        data: data,
      );

      if (!context.mounted) return false;

      if (signUpResponse.user == null) {
        ConTrustSnackBar.error(context, 'Error creating account');
        return false;
      }

      if (userType == 'contractee') {
        final String userId = signUpResponse.user!.id;
        final bool hasSession = signUpResponse.session != null;
        
        if (hasSession) {
          await Future.delayed(const Duration(milliseconds: 1000));
          
          bool insertSuccess = false;
          for (int attempt = 0; attempt < 5 && !insertSuccess; attempt++) {
            try {
              await supabase.from('Users').upsert({
                'users_id': userId,
                'email': email,
                'name': data?['full_name'] ?? 'User',
                'role': 'contractee',
                'status': 'active',
                'created_at': DateTimeHelper.getLocalTimeISOString(),
                'profile_image_url': data?['profilePhoto'] ?? 'assets/defaultpic.png',
                'phone_number': data?['phone_number'] ?? '',
                'verified': true,
              }, onConflict: 'users_id');
              insertSuccess = true;
            } catch (e) {
              if (attempt == 4) {
                throw Exception('Failed to create user record: $e');
              }
              await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            }
          }
        }
        
        final contracteeData = {
          'contractee_id': userId,
          'full_name': data?['full_name'],
          'address': data?['address'] ?? '',
          'created_at': DateTimeHelper.getLocalTimeISOString(),
          'project_history_count': project,
          'phone_number': data?['phone_number'] ?? '',
          'profile_photo': data?['profilePhoto'] ?? 'assets/defaultpic.png',
        };

        final insertResponse = await supabase
            .from('Contractee')
            .insert(contracteeData)
            .select(); 

        if (insertResponse.isEmpty) {
          await _auditService.logAuditEvent(
            userId: signUpResponse?.user?.id,
            action: 'USER_REGISTRATION_FAILED',
            details: 'Contractee registration failed - data insertion error',
            metadata: {
              'user_type': userType,
              'email': email,
              'full_name': data?['full_name'],
              'failure_reason': 'contractee_data_insertion_failed',
            },
          );

          await _errorService.logError(
            errorMessage: 'Failed to insert contractee data for user ID ${signUpResponse.user?.id} - insert response was empty',
            module: 'Contractee Sign-up',
            severity: 'High',
            extraInfo: {
              'operation': 'Insert Contractee Data',
              'contractee_id': signUpResponse.user?.id,
              'email': email,
              'timestamp': DateTimeHelper.getLocalTimeISOString(),
            },
          );
          throw Exception("Error saving contractee data");
        }
      }

      await _auditService.logAuditEvent(
        userId: signUpResponse?.user?.id, 
        action: 'USER_REGISTRATION',
        details: 'Contractee account created successfully',
        metadata: {
          'user_type': userType,
          'email': email,
          'full_name': data?['full_name'],
          'registration_method': 'email_password',
        },
      );

      return true;

    } on AuthException catch (e) {
      await _auditService.logAuditEvent(
        userId: signUpResponse?.user?.id,  
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractee registration failed due to authentication error',
        metadata: {
          'user_type': userType,
          'email': email,
          'error_type': 'AuthException',
          'error_message': e.message,
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee sign-up failed - AuthException: ${e.message}',
        module: 'Contractee Sign-up',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Sign Up Contractee',
          'email': email,
          'user_type': userType,
          'users_id': signUpResponse?.user?.id, 
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      if (!context.mounted) return false;
      ConTrustSnackBar.error(context, 'Error creating account: ${e.message}');
      return false;
    } catch (e) {
      await _auditService.logAuditEvent(
        userId: signUpResponse?.user?.id, 
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractee registration failed due to unexpected error',
        metadata: {
          'user_type': userType,
          'email': email,
          'error_type': 'UnexpectedError',
          'error_message': e.toString(),
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee sign-up failed - Unexpected error: $e',
        module: 'Contractee Sign-up',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign Up Contractee',
          'email': email,
          'user_type': userType,
          'users_id': signUpResponse?.user?.id, 
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      if (!context.mounted) return false;
      ConTrustSnackBar.error(context, 'Unexpected error: $e');
      return false;
    }
  }
}
