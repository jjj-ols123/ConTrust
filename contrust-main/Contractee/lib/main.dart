// ignore_for_file: unnecessary_null_comparison

import 'dart:ui';
import 'package:contractee/pages/cee_authredirect.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractee/pages/cee_profile.dart';
import 'package:contractee/pages/cee_chathistory.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractee/build/builddrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String? _lastPushedRoute;
bool _isRegistering = false;
bool _preventAuthNavigation = false;

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad
      };
}

Future<void> main() async {
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

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

  setupAuthListener(isFirstOpen);

  runApp(MyApp(isFirstOpen: isFirstOpen));
}

void setupAuthListener(bool isFirstOpen) {
  final supabase = Supabase.instance.client;

  Future<void> handleSession(Session? session) async {
    String target = '/login';

    if (session == null) {
      _isRegistering = false;
      target = '/login';
    } else {
      if (_isRegistering || _preventAuthNavigation) {
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

          if (verified && role == 'contractee') {
            target = '/home';
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

void setPreventAuthNavigation(bool prevent) {
  _preventAuthNavigation = prevent;
}

class MyApp extends StatelessWidget {
  final bool isFirstOpen;
  const MyApp({super.key, required this.isFirstOpen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      initialRoute: isFirstOpen ? '/welcome' : '/login',
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/auth/callback': (context) => const AuthRedirectPage(),
        '/ongoing': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          final projectId = ModalRoute.of(context)?.settings.arguments as String?;
          if (session != null && projectId != null) {
            return ContracteeShell(
              currentPage: ContracteePage.ongoing,
              contracteeId: session.user.id,
              child: CeeOngoingProjectScreen(projectId: projectId),
            );
          }
          return const LoginPage();
        },
        '/profile': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContracteeShell(
              currentPage: ContracteePage.profile,
              contracteeId: session.user.id,
              child: CeeProfilePage(contracteeId: session.user.id),
            );
          }
          return const LoginPage();
        },
        '/messages': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContracteeShell(
              currentPage: ContracteePage.messages,
              contracteeId: session.user.id,
              child: const ContracteeChatHistoryPage(),
            );
          }
          return const LoginPage();
        },
        '/notifications': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContracteeShell(
              currentPage: ContracteePage.notifications,
              contracteeId: session.user.id,
              child: const ContracteeNotificationPage(),
            );
          }
          return const LoginPage();
        },
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => isFirstOpen ? const WelcomePage() : const LoginPage(),
      ),
    );
  }
}
