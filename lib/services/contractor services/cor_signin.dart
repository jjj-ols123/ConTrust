// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInContractor {
  void signInContractor(
    BuildContext context,
    String email,
    String password,
    bool Function() validateFields,
  ) async {
    if (!validateFields()) {
      return;
    }

    try {
      final signInResponse = await UserService().signIn(
        email: email,
        password: password,
      );

      if (signInResponse.user == null) {
        ConTrustSnackBar.error(context, 'Invalid email or password');
        return;
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];

      if (userType?.toLowerCase() != 'contractor') {
        ConTrustSnackBar.error(context, 'Not a contractor...');
        return;
      }

      ConTrustSnackBar.success(context, 'Successfully logged in');

      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DashboardScreen(contractorId: signInResponse.user!.id),
          ),
          (route) => false,
        );
      });
    } catch (e) {
      rethrow;
    }
  }
}

class SignInGoogleContractor {
  void signInGoogle(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );

      supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final user = data.session?.user;

        if (event == AuthChangeEvent.signedIn && user != null) {
          handleSignIn(context, user);
        } else if (event == AuthChangeEvent.signedOut) {
          ConTrustSnackBar.warning(context, 'Signed in cancelled');
        }
      });
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> handleSignIn(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;
      
      final existingContractor = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', user.id)
          .maybeSingle();

      if (existingContractor == null) {
        await setupContractor(context, user);
      } else {
        final userType = user.userMetadata?['user_type'];
        if (userType?.toLowerCase() != 'contractor') {
          ConTrustSnackBar.error(context, 'This Google account is not registered as a contractor');
        }
          await supabase.auth.signOut();
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(contractorId: user.id),
          ),
          (route) => false,
        );
      }
    catch (e) {
      rethrow;
    }
  }

  Future<void> setupContractor(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'user_type': 'contractor',
            'firm_name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
            'email': user.email,
            'profile_photo': user.userMetadata?['avatar_url'],
          },
        ),
      );

      await supabase.from('Contractor').insert({
        'contractor_id': user.id,
        'firm_name': user.userMetadata?['full_name'] ?? 'Contractor Firm',
        'profile_photo': user.userMetadata?['avatar_url'],
        'contact_number': '',
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      ConTrustSnackBar.success(context, 'Welcome! Your contractor account has been created.'
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(contractorId: user.id),
        ),
        (route) => false,
      );

    } catch (e) {
      rethrow;
    }
  }
}
