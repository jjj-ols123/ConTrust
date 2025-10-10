// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInContractee {
  void signInContractee(BuildContext modalContext, String email,
      String password, bool Function() validateFields) async {
    if (!validateFields()) {
      return;
    }

    try {
      final signInResponse = await UserService().signIn(
        email: email,
        password: password,
      );

      if (signInResponse.user == null) {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];

      if (userType?.toLowerCase() != 'contractee') {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Not a contractee...'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        modalContext,
        '/home',
        (route) => false,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        ConTrustSnackBar.success(modalContext, 'Successfully logged in');
      });
    } catch (e) {
      ConTrustSnackBar.error(modalContext, 'Error logging in');
    }
    }
  }


class SignInGoogleContractee {
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
          ConTrustSnackBar.success(context, 'Signed in cancelled');
        }
      });
      
    } catch (e) {
       rethrow;
    }
  }


  Future<void> handleSignIn(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;
      
      final existingContractee = await supabase
          .from('Contractee') 
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingContractee == null) {
        await setupContractee(context, user);
      } else {
        final userType = user.userMetadata?['user_type'];
        if (userType?.toLowerCase() != 'contractee') {
          ConTrustSnackBar.error(context, 'Not a contractee...');
          await supabase.auth.signOut();
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setupContractee(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'user_type': 'contractee',
            'full_name': user.userMetadata?['full_name'] ?? 'User',
            'email': user.email,
            'profile_photo': user.userMetadata?['avatar_url'],
          },
        ),
      );

      await supabase.from('Contractee').insert({
        'user_id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'profile_photo': user.userMetadata?['avatar_url'],
        'created_at': DateTime.now().toIso8601String(),
      });

      ConTrustSnackBar.success(context, 'Welcome! Your contractee account has been created.');

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );

    } catch (e) {
      rethrow;
    }
  }
}
