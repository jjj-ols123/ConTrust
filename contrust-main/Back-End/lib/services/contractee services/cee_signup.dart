import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

class SignUpContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  void signUpContractee(
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
      return;
    }

    try {
      signUpResponse = await UserService().signUp(
        email: email,
        password: password,
        data: data,
      );

      if (!context.mounted) return;

      if (signUpResponse.user == null) {
        ConTrustSnackBar.error(context, 'Error creating account');
        return;
      }

      if (userType == 'contractee') {
        await supabase.from('Users').upsert({
          'users_id': signUpResponse.user?.id,
          'email': email,
          'name': data?['full_name'] ?? 'User',
          'role': 'contractee',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'profile_image_url': data?['profilePhoto'],
          'phone_number': data?['phone_number'] ?? '',
          'verified': false,
        }, onConflict: 'users_id');
        
        final contracteeData = {
          'contractee_id': signUpResponse.user?.id,
          'full_name': data?['full_name'],
          'address': data?['address'] ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'project_history_count': project,
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
            errorMessage: 'Failed to insert contractee data for user ID ${signUpResponse.user!.id} - insert response was empty',
            module: 'Contractee Sign-up',
            severity: 'High',
            extraInfo: {
              'operation': 'Insert Contractee Data',
              'contractee_id': signUpResponse.user?.id,
              'email': email,
              'timestamp': DateTime.now().toIso8601String(),
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

      if (!context.mounted) return;
      ConTrustSnackBar.success(context, 'Account successfully created');
      Navigator.pop(context);
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
          'users_id': signUpResponse.user?.id, 
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
          'users_id': signUpResponse.user?.id, 
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!context.mounted) return;
      ConTrustSnackBar.error(context, 'Unexpected error: $e');
    }
  }
}
