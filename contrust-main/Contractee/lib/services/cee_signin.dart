// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/be_user_service.dart';
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
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged in'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(
          content: Text('Error logging in'),
          backgroundColor: Colors.red,
        ),
      );
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
          _handleSignIn(context, user);
        } else if (event == AuthChangeEvent.signedOut) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in with Google: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _handleSignIn(BuildContext context, User user) async {
    try {
      final supabase = Supabase.instance.client;
      
      final existingContractee = await supabase
          .from('Contractee') 
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingContractee == null) {
        await _setupContractee(context, user);
      } else {
        final userType = user.userMetadata?['user_type'];
        if (userType?.toLowerCase() != 'contractee') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Google account is not registered as a contractee'),
              backgroundColor: Colors.red,
            ),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during sign in: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setupContractee(BuildContext context, User user) async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome! Your contractee account has been created.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
