
// ignore_for_file: unnecessary_null_comparison

import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:contractor/Screen/cor_authredirect.dart';
import 'package:contractor/Screen/cor_bidding.dart';
import 'package:contractor/Screen/cor_chathistory.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
import 'package:contractor/Screen/cor_profile.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractor/Screen/cor_product.dart';
import 'package:contractor/build/builddrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String? _lastPushedRoute;
bool _isRegistering = false;
bool _preventAuthNavigation = false;

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
    String target = '/';

    if (session == null) {
      _isRegistering = false;
      target = '/';
    } else {
      if (_isRegistering || _preventAuthNavigation) {
        return;
      }

      final user = session.user;
      if (user == null) {
        target = '/';
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
            target = '/';
          }
        } catch (_) {
          target = '/';
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
      initialRoute: '/',
      routes: {
        '/': (context) => const ToLoginScreen(),
        '/dashboard': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return DashboardScreen(contractorId: session.user.id);
          }
          return const ToLoginScreen();
        },
        '/auth/callback': (context) => const AuthRedirectPage(),
        '/messages': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContractorShell(
              currentPage: ContractorPage.messages,
              contractorId: session.user.id,
              child: ContractorChatHistoryPage(),
            );
          }
          return const ToLoginScreen();
        },
        '/contracts': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContractorShell(
              currentPage: ContractorPage.contracts,
              contractorId: session.user.id,
              child: ContractType(contractorId: session.user.id),
            );
          }
          return const ToLoginScreen();
        },
        '/bidding': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContractorShell(
              currentPage: ContractorPage.bidding,
              contractorId: session.user.id,
              child: BiddingScreen(contractorId: session.user.id),
            );
          }
          return const ToLoginScreen();
        },
        '/profile': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return ContractorShell(
              currentPage: ContractorPage.profile,
              contractorId: session.user.id,
              child: ContractorUserProfileScreen(contractorId: session.user.id),
            );
          }
          return const ToLoginScreen();
        },
        '/project-management': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          final projectId = ModalRoute.of(context)?.settings.arguments as String?;
          if (session != null && projectId != null) {
            return ContractorShell(
              currentPage: ContractorPage.projectManagement,
              contractorId: session.user.id,
              child: CorOngoingProjectScreen(projectId: projectId),
            );
          }
          return const ToLoginScreen();
        },
        '/materials': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final projectId = args?['projectId'] as String?;
          if (session != null && projectId != null) {
            return ContractorShell(
              currentPage: ContractorPage.materials,
              contractorId: session.user.id,
              child: ProductPanelScreen(
                contractorId: session.user.id,
                projectId: projectId,
              ),
            );
          }
          return const ToLoginScreen();
        },
      },
    );
  }
}