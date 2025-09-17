// ignore_for_file: use_build_context_synchronously
import 'package:backend/services/be_user_service.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userType = signInResponse.user?.userMetadata?['user_type'];

      if (userType?.toLowerCase() != 'contractor') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not a contractee...'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged in'),
          backgroundColor: Colors.green,
        ),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in'),
          backgroundColor: Colors.red,
        ),
      );
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
      
      final existingContractor = await supabase
          .from('Contractor')
          .select()
          .eq('contractor_id', user.id)
          .maybeSingle();

      if (existingContractor == null) {
        await _setupContractor(context, user);
      } else {
        final userType = user.userMetadata?['user_type'];
        if (userType?.toLowerCase() != 'contractor') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Google account is not registered as a contractor'),
              backgroundColor: Colors.red,
            ),
          );
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during sign in: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setupContractor(BuildContext context, User user) async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome! Your account has been created.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(contractorId: user.id),
        ),
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
