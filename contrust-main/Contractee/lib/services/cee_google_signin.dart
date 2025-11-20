  // ignore_for_file: use_build_context_synchronously
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:flutter/material.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:backend/services/superadmin services/errorlogs_service.dart';
  import 'package:backend/services/superadmin services/auditlogs_service.dart';
  import 'package:backend/utils/be_snackbar.dart';
  import 'package:backend/utils/be_datetime_helper.dart';

  const String _contracteeGoogleServerClientId = String.fromEnvironment(
    'CONTRACTEE_GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '484611097293-aem1gaurjh5sp2hbepb4dfslbtq7lqel.apps.googleusercontent.com',
  );

  class SignInGoogleContractee {
    final SuperAdminErrorService _errorService = SuperAdminErrorService();
    final SuperAdminAuditService _auditService = SuperAdminAuditService();

    Future<void> signInGoogle(BuildContext context) async {
      String? redirectUrl;

      try {
        final supabase = Supabase.instance.client;

        if (kIsWeb) {
          final origin = Uri.base.origin;
          redirectUrl = '$origin/auth/callback';
        } else {
          redirectUrl = 'io.supabase.contrust://login-callback/home';
        }

        if (kIsWeb) {
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
          final googleSignIn = GoogleSignIn(
            serverClientId: _contracteeGoogleServerClientId.isNotEmpty
                ? _contracteeGoogleServerClientId
                : null,
          );

          final account = await googleSignIn.signIn();
          final googleAuth = await account?.authentication;
          final idToken = googleAuth?.idToken;
          final email = account?.email;

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

          // Check if email is already registered as contractor
          if (email != null) {
            final supabase = Supabase.instance.client;
            final existingUser = await supabase
                .from('Users')
                .select('role')
                .eq('email', email)
                .maybeSingle();

            if (existingUser != null && existingUser['role'] == 'contractor') {
              await _auditService.logAuditEvent(
                action: 'USER_LOGIN_FAILED',
                details: 'Google login blocked - email already registered as contractor',
                metadata: {
                  'attempted_user_type': 'contractee',
                  'existing_user_type': 'contractor',
                  'email': email,
                  'login_method': 'google_oauth',
                  'failure_reason': 'cross_role_attempt',
                },
              );

              if (context.mounted) {
                ConTrustSnackBar.error(context, 'This email is already registered as a contractor account. Please use a different email or log in with the contractor app.');
              }
              // Sign out from Google
              await googleSignIn.signOut();
              await googleSignIn.disconnect();
              return;
            }
          }

          try {
            await supabase.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
            );
            final user = supabase.auth.currentUser;
            if (user != null) {
              await handleSignIn(context, user);
            }
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
              'error_details': signInError.toString(),
            },
          );

          String errorMessage = 'Google sign-in failed. Please try again.';

          // Handle specific Google Sign In errors
          final errorString = signInError.toString();
          if (errorString.contains('ApiException: 19') ||
              errorString.contains('SIGN_IN_FAILED') ||
              errorString.contains('API_NOT_CONNECTED')) {
            errorMessage = 'Google Play Services error. Please update Google Play Services or check your device settings.';
          } else if (errorString.contains('ApiException: 10') ||
                    errorString.contains('DEVELOPER_ERROR')) {
            errorMessage = 'Google Sign In configuration error. Please contact support.';
          } else if (errorString.contains('ApiException: 8') ||
                    errorString.contains('INTERNAL_ERROR')) {
            errorMessage = 'Internal Google Sign In error. Please try again later.';
          } else if (errorString.contains('ApiException: 7') ||
                    errorString.contains('NETWORK_ERROR')) {
            errorMessage = 'Network error during Google Sign In. Please check your internet connection.';
          } else if (errorString.contains('ApiException: 4') ||
                    errorString.contains('SIGN_IN_REQUIRED')) {
            errorMessage = 'Google Sign In required. Please sign in to your Google account.';
          } else if (errorString.contains('ApiException: 5') ||
                    errorString.contains('INVALID_ACCOUNT')) {
            errorMessage = 'Invalid Google account. Please try with a different account.';
          }

          if (context.mounted) {
            final debugDetails = errorString.length > 160
                ? '${errorString.substring(0, 157)}...'
                : errorString;
            ConTrustSnackBar.error(
              context,
              '$errorMessage\n[Debug: $debugDetails]',
            );
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
          ConTrustSnackBar.error(context, 'Sign-in failed: $e');
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

          if (existingEmailUser != null && existingEmailUser['users_id'] != user.id) {
            await _auditService.logAuditEvent(
              action: 'USER_LOGIN_FAILED',
              details: 'Google login blocked - email already in use by another account',
              metadata: {
                'user_type': 'contractee',
                'email': user.email,
                'login_method': 'google_oauth',
                'failure_reason': 'email_already_used',
              },
            );

            if (context.mounted) {
              ConTrustSnackBar.error(context, 'This email is already associated with another account.');
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

        if (existingContractee == null) {
          await setupContractee(context, user);
        } else if (existingUser == null) {
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

            if (shouldApplyGooglePhoto(
              (existingUser['profile_image_url'] as String?),
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
              errorMessage: 'Failed to update Users for contractee Google login: $updateError',
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

        try {
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
          rethrow;
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
