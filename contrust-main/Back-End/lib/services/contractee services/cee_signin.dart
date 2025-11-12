// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'
    if (dart.library.html) 'package:backend/stubs/google_sign_in_stub.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';

const String _contracteeGoogleServerClientId = String.fromEnvironment(
  'CONTRACTEE_GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '706082803745-fc3t6v7h1iea088p8obbu3a3ig2369k7.apps.googleusercontent.com',
);

class SignInContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<bool> signInContractee(
    BuildContext context,
    String email,
    String password,
    bool Function() validateFields,
  ) async {
    if (!validateFields()) {
      return false;
    }

    dynamic signInResponse;
    try {
      signInResponse = await UserService().signIn(
        email: email,
        password: password,
      );

      if (signInResponse == null ||
          signInResponse.user == null ||
          signInResponse.user!.id == null) {
        await _auditService.logAuditEvent(
          action: 'USER_LOGIN_FAILED',
          details: 'Contractee login failed - no user ID returned',
          metadata: {
            'user_type': 'contractee',
            'email': email,
            'failure_reason': 'no_user_id',
          },
        );
        ConTrustSnackBar.error(context, 'Authentication failed');
        return false;
      }

      final user = signInResponse.user!;
      final userType = user.userMetadata != null
          ? user.userMetadata!['user_type']
          : null;

      if (userType == null || userType.toLowerCase() != 'contractee') {
        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN_FAILED',
          details: 'Login attempt with wrong user type',
          metadata: {
            'user_type': userType,
            'expected_type': 'contractee',
            'email': email,
            'failure_reason': 'wrong_user_type',
          },
        );
        ConTrustSnackBar.error(context, 'Not a contractee account');
        return false;
      }

      final supabase = Supabase.instance.client;

      try {
        await supabase
            .from('Users')
            .update({'last_login': DateTimeHelper.getLocalTimeISOString()})
            .eq('users_id', user.id);
      } catch (e) {
        await _errorService.logError(
          errorMessage: 'Failed to update last_login for contractee: $e',
          module: 'Contractee Sign-in',
          severity: 'Low',
          extraInfo: {
            'operation': 'Update Last Login',
            'users_id': user.id,
            'timestamp': DateTimeHelper.getLocalTimeISOString(),
          },
        );
      }

      await _auditService.logAuditEvent(
        userId: signInResponse.user!.id,
        action: 'USER_LOGIN',
        details: 'Contractee logged in successfully',
        metadata: {
          'user_type': 'contractee',
          'email': email,
          'login_method': 'email_password',
        },
      );

      return true;
    } catch (e) {
      await _auditService.logAuditEvent(
        userId: signInResponse != null && signInResponse.user != null
            ? signInResponse.user!.id
            : null,
        action: 'USER_LOGIN_FAILED',
        details: 'Contractee login failed due to error: $e',
        metadata: {
          'user_type': 'contractee',
          'email': email,
          'error_message': e.toString(),
          'failure_reason': 'system_error',
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee sign-in failed: $e',
        module: 'Contractee Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign In Contractee',
          'email': email,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );

      if (context.mounted) {
        String message = 'Login failed. Please try again.';
        final errorText = e.toString().toLowerCase();
        if (e is AuthException) {
          final m = e.message.toLowerCase();
          if (m.contains('invalid login') ||
              m.contains('invalid') ||
              m.contains('credentials')) {
            message = 'Invalid email or password.';
          } else if (m.contains('email not confirmed') ||
              m.contains('not confirmed') ||
              m.contains('verify')) {
            message =
                'Your account is not yet verified. Please try again later.';
          } else if (m.contains('rate') && m.contains('limit')) {
            message = 'Too many attempts. Please try again later.';
          } else {
            message = 'Authentication error. Please try again.';
          }
        } else if (errorText.contains('network') ||
            errorText.contains('socket')) {
          message = 'Network error. Please check your connection.';
        }
        ConTrustSnackBar.error(context, message);
      }
      return false;
    }
  }
}

class SignInGoogleContractee {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();

  Future<void> signInGoogle(BuildContext context) async {
    String? redirectUrl;

    try {
      final supabase = Supabase.instance.client;
      
      String? redirectUrl;
      
      if (kIsWeb) {
        final origin = Uri.base.origin;
        redirectUrl = '$origin/auth/callback';
      } else {
        redirectUrl = 'io.supabase.contrust://login-callback/home';
      }

        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
          authScreenLaunchMode: LaunchMode.platformDefault,
          queryParams: {
            'prompt': 'select_account',
          },
        );
        return;
      }

      try {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize(
          serverClientId: _contracteeGoogleServerClientId.isNotEmpty
              ? _contracteeGoogleServerClientId
              : null,
        );

        final account = await googleSignIn.authenticate();
        final googleAuth = account.authentication;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          await _errorService.logError(
            errorMessage: 'Google sign-in returned null ID token for contractee.',
            module: 'Contractee Google Sign-in',
            severity: 'High',
            extraInfo: {
              'operation': 'Google Sign In Contractee',
              'timestamp': DateTimeHelper.getLocalTimeISOString(),
            },
          );
          if (context.mounted) {
            ConTrustSnackBar.error(context, 'Unable to authenticate with Google. Please try again.');
          }
          return;
        }

        try {
          await supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
          );
        } catch (idTokenError) {
          await _errorService.logError(
            errorMessage: 'Supabase signInWithIdToken failed: $idTokenError',
            module: 'Contractee Google Sign-in',
            severity: 'High',
            extraInfo: {
              'operation': 'Google Sign In Contractee',
              'timestamp': DateTimeHelper.getLocalTimeISOString(),
            },
          );
          if (context.mounted) {
            ConTrustSnackBar.error(context, 'Authentication failed. Please try again.');
          }
          return;
        }

        // Ensure Google session is cleared to avoid stale sessions on next login attempt.
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (signInError) {
        await _errorService.logError(
          errorMessage: 'Google sign-in failed for contractee: $signInError',
          module: 'Contractee Google Sign-in',
          severity: 'High',
          extraInfo: {
            'operation': 'Google Sign In Contractee',
            'timestamp': DateTimeHelper.getLocalTimeISOString(),
          },
        );
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Google sign-in failed: $signInError');
        }
        return;
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google OAuth sign-in failed: $e',
        module: 'Contractee Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Google OAuth Sign In',
          'platform': kIsWeb ? 'web' : 'mobile',
          'redirect_url': redirectUrl,
          'error_type': e.runtimeType.toString(),
          'error_details': e.toString(),
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, errorMessage);
      }
    }
  }

  Future<void> handleSignIn(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;

      if (user.email != null) {
        final existingEmailUser = await supabase
            .from('Users')
            .select('users_id')
            .eq('email', user.email!)
            .maybeSingle();

        if (existingEmailUser != null) {
          await _auditService.logAuditEvent(
            action: 'USER_LOGIN_FAILED',
            details: 'Google login blocked - email already in use',
            metadata: {
              'user_type': 'contractee',
              'email': user.email,
              'login_method': 'google_oauth',
              'failure_reason': 'email_already_used',
            },
          );

          if (context.mounted) {
            ConTrustSnackBar.error(context, 'This email is already associated with an account.');
          }
          await supabase.auth.signOut();
          return;
        }
      }

      final existingContractee = await supabase
          .from('Contractee')
          .select()
          .eq('contractee_id', user.id)
          .maybeSingle();

      final existingUser = await supabase
          .from('Users')
          .select('users_id, profile_image_url')
          .eq('users_id', user.id)
          .maybeSingle();

      debugPrint('[Google Contractee] existingContractee: ${existingContractee != null}, existingUser: ${existingUser != null}');

      if (existingContractee == null) {
        debugPrint('[Google Contractee] creating new Contractee + Users rows');
        await setupContractee(context, user);
      } else if (existingUser == null) {
        debugPrint('[Google Contractee] Users missing; upserting from Contractee data');
        final contracteeData = await supabase
            .from('Contractee')
            .select('full_name, phone_number, profile_photo')
            .eq('contractee_id', user.id)
            .single();
        
        await supabase.from('Users').upsert({
          'users_id': user.id,
          'email': user.email ?? '',
          'name': contracteeData['full_name'] ?? 'User',
          'role': 'contractee',
          'status': 'active',
          'created_at': DateTimeHelper.getLocalTimeISOString(),
          'last_login': DateTimeHelper.getLocalTimeISOString(),
          'profile_image_url': contracteeData['profile_photo'] ?? 'assets/defaultpic.png',
          'phone_number': contracteeData['phone_number'] ?? '',
          'verified': true,
        }, onConflict: 'users_id');
      } else {
        debugPrint('[Google Contractee] Both rows exist; updating verified/last_login');
        final userType = user.userMetadata != null ? user.userMetadata!['user_type'] : null;
        if (userType == null || userType.toLowerCase() != 'contractee') {
          await _auditService.logAuditEvent(
            userId: user.id,
            action: 'USER_LOGIN_FAILED',
            details: 'Google login attempt with wrong user type',
            metadata: {
              'user_type': userType,
              'expected_type': 'contractee',
              'email': user.email,
              'login_method': 'google_oauth',
              'failure_reason': 'wrong_user_type',
            },
          );

          ConTrustSnackBar.error(
              context, 'This Google account is not registered as a contractee');
          await supabase.auth.signOut();
          return;
        }
      } else if (existingContractee != null && existingUser != null) {
        debugPrint('[Google Contractee] Both Contractee and User records exist, proceeding with login');
        debugPrint('[Google Contractee] Full user metadata: ${user.userMetadata}');
        debugPrint('[Google Contractee] Platform: ${kIsWeb ? 'web' : 'mobile'}');

        debugPrint('[Google Contractee] Valid contractee records found, proceeding with login');

        await _auditService.logAuditEvent(
          userId: user.id,
          action: 'USER_LOGIN',
          details: 'Contractee logged in via Google successfully',
          metadata: {
            'user_type': 'contractee',
            'email': user.email,
            'login_method': 'google_oauth',
            'platform': kIsWeb ? 'web' : 'mobile',
          },
        );

        try {
          String? googlePhoto =
              user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];

          bool shouldApplyGooglePhoto(String? currentPhoto, String? newPhoto) {
            if (newPhoto == null || newPhoto.isEmpty) return false;
            if (currentPhoto == null || currentPhoto.isEmpty) return true;
            final normalized = currentPhoto.toLowerCase();
            if (normalized.contains('defaultpic')) return true;
            return currentPhoto == newPhoto;
          }

          if (shouldApplyGooglePhoto(
            existingContractee['profile_photo'] as String?,
            googlePhoto,
          )) {
            await supabase
                .from('Contractee')
                .update({'profile_photo': googlePhoto})
                .eq('contractee_id', user.id);
          }

          final Map<String, dynamic> userUpdates = {
            'verified': true,
            'last_login': DateTimeHelper.getLocalTimeISOString(),
          };

          if (_shouldApplyGooglePhoto(
            (existingUser?['profile_image_url'] as String?),
            googlePhoto,
          )) {
            userUpdates['profile_image_url'] = googlePhoto;
          }

          await supabase
              .from('Users')
              .update(userUpdates)
              .eq('users_id', user.id);

        } catch (updateError) {
          await _errorService.logError(
            errorMessage: 'Failed to update Users for contractee Google login: $e',
            module: 'Contractee Google Sign-in',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Update Users during login',
              'users_id': user.id,
              'update_data': {
                'verified': true,
                'last_login': DateTimeHelper.getLocalTimeISOString(),
                'profile_image_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
              },
            },
          );
          // Don't rethrow for login updates - allow login to succeed even if update fails
        }

        if (context.mounted) {
        }
      }

    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Google sign-in handling failed for contractee: $e',
        module: 'Contractee Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Handle Google Sign In Contractee',
          'users_id': user.id,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Sign-in failed: $e');
      }
    }
  }

  Future<void> setupContractee(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;

      // Check if user already exists in our custom tables
      final existingUserInCustomTables = await supabase
          .from('Users')
          .select('users_id')
          .eq('users_id', user.id)
          .maybeSingle();

      if (existingUserInCustomTables != null) {

        // Show debug info for physical device
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User already exists in database'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      String? profilePhoto = user.userMetadata?['avatar_url'] ?? 
                            user.userMetadata?['picture'];
      
      debugPrint('[Google Contractee] Profile photo sources - avatar_url: ${user.userMetadata?['avatar_url']}, picture: ${user.userMetadata?['picture']}, final: $profilePhoto');

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'user_type': 'contractee',
            'full_name': user.userMetadata?['full_name'] ?? 'User',
            'email': user.email,
            'profile_photo': profilePhoto,
          },
        ),
      );

      } catch (authError) {
        await _errorService.logError(
          errorMessage: 'Auth updateUser failed: $authError',
          module: 'Contractee Google Sign-in',
          severity: 'High',
          extraInfo: {
            'operation': 'Update Auth User Metadata',
            'users_id': user.id,
            'metadata': {
              'user_type': 'contractee',
              'full_name': user.userMetadata?['full_name'] ?? 'User',
              'email': user.email,
              'profile_photo': profilePhoto,
            },
          },
        );
        rethrow; // Re-throw to fail the entire setup
      }

      try {
        await supabase.from('Users').upsert({
          'users_id': user.id,
          'email': user.email,
          'name': user.userMetadata?['full_name'] ?? 'User',
          'role': 'contractee',
          'status': 'active',
          'created_at': DateTimeHelper.getLocalTimeISOString(),
          'last_login': DateTimeHelper.getLocalTimeISOString(),
          'profile_image_url': profilePhoto ?? 'assets/defaultpic.png',
          'phone_number': '',
          'verified': true,
        }, onConflict: 'users_id');

      } catch (usersError) {
        await _errorService.logError(
          errorMessage: 'Users table insert failed: $usersError',
          module: 'Contractee Google Sign-in',
          severity: 'High',
          extraInfo: {
            'operation': 'Insert Users',
            'users_id': user.id,
            'user_data': {
              'users_id': user.id,
              'email': user.email,
              'name': user.userMetadata?['full_name'] ?? 'User',
              'role': 'contractee',
              'profile_image_url': profilePhoto ?? 'assets/defaultpic.png',
            },
          },
        );
        rethrow; // Re-throw to fail the entire setup
      }

      try {
        await supabase.from('Contractee').insert({
          'contractee_id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
          'profile_photo': profilePhoto ?? 'assets/defaultpic.png',
          'created_at': DateTimeHelper.getLocalTimeISOString(),
        });

      } catch (contracteeError) {
        await _errorService.logError(
          errorMessage: 'Contractee table insert failed: $contracteeError',
          module: 'Contractee Google Sign-in',
          severity: 'High',
          extraInfo: {
            'operation': 'Insert Contractee',
            'users_id': user.id,
            'contractee_data': {
              'contractee_id': user.id,
              'full_name': user.userMetadata?['full_name'] ?? 'User',
              'profile_photo': profilePhoto ?? 'assets/defaultpic.png',
            },
          },
        );
        rethrow; // Re-throw to fail the entire setup
      }

      await _auditService.logAuditEvent(
        userId: user.id,
        action: 'USER_REGISTRATION',
        details: 'Contractee account created via Google OAuth',
        metadata: {
          'user_type': 'contractee',
          'email': user.email,
          'full_name': user.userMetadata?['full_name'],
          'registration_method': 'google_oauth',
        },
      );

      ConTrustSnackBar.success(
          context, 'Welcome! Your contractee account has been created.');

    } catch (e) {
      await _auditService.logAuditEvent(
        action: 'USER_REGISTRATION_FAILED',
        details: 'Contractee Google registration failed',
        metadata: {
          'user_type': 'contractee',
          'email': user.email,
          'error_message': e.toString(),
          'registration_method': 'google_oauth',
        },
      );

      await _errorService.logError(
        errorMessage: 'Contractee setup failed during Google sign-in: $e',
        module: 'Contractee Google Sign-in',
        severity: 'High',
        extraInfo: {
          'operation': 'Setup Contractee Google',
          'users_id': user.id,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      ConTrustSnackBar.error(context, 'Account setup failed: $e');
    }
  }
}
