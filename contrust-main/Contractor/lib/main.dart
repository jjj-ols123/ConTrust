
// ignore_for_file: unnecessary_null_comparison

import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:contractor/Screen/cor_authredirect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String? _lastPushedRoute;
bool _isRegistering = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://bgihfdqruamnjionhkeq.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnaWhmZHFydWFtbmppb25oa2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NzIyODksImV4cCI6MjA1NjQ0ODI4OX0.-GRaolUVu1hW6NUaEAwJuYJo8C2X5_1wZ-qB4a-9Txs',
    ),
  );

  setupAuthListener();

  runApp(const MyApp());
}

void setupAuthListener() {
  final supabase = Supabase.instance.client;

  Future<void> handleSession(Session? session) async {
    String target = '/login';

    if (session == null) {
      _isRegistering = false;
      target = '/login';
    } else {
      if (_isRegistering) {
        return;
      }

      final user = session.user;
      if (user == null) {
        target = '/login';
      } else {
        try {
          final resp = await supabase
              .from('Users')
              .select('verified, role')
              .eq('users_id', user.id)
              .maybeSingle();

          final verified = resp != null && (resp['verified'] == true);
          final role = resp != null ? resp['role'] : null;

          if (verified && role == 'contractor') {
            target = '/dashboard';
          } else {
            target = '/login';
          }
        } catch (_) {
          target = '/login';
        }
      }
    }

    if (_lastPushedRoute == target) return;
    _lastPushedRoute = target;

    if (appNavigatorKey.currentState == null) return;
    try {
      appNavigatorKey.currentState!.pushNamedAndRemoveUntil(target, (r) => false);
    } catch (_) {}
  }

  Future.microtask(() => handleSession(supabase.auth.currentSession));

  supabase.auth.onAuthStateChange.listen((event) {
    handleSession(event.session);
  });
}

void setRegistrationState(bool isRegistering) {
  _isRegistering = isRegistering;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const ToLoginScreen(),
        '/dashboard': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return DashboardScreen(contractorId: session.user.id);
          }
          return const ToLoginScreen();
        },
        '/auth/callback': (context) => const AuthRedirectPage(),
      },
    );
  }
}