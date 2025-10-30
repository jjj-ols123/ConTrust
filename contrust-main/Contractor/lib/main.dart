
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
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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

  // Disable browser back button for web
  if (kIsWeb && html.window != null) {
    html.window.onPopState.listen((event) {
      event.preventDefault();
      html.window.history.pushState(null, '', html.window.location.href);
    });
  }

  runApp(const MyApp());
}

void setRegistrationState(bool isRegistering) {
  _isRegistering = isRegistering;
}

void setPreventAuthNavigation(bool prevent) {
  _preventAuthNavigation = prevent;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      navigatorKey: appNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ToLoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              return DashboardScreen(contractorId: session.user.id);
            }
            return const ToLoginScreen();
          },
        ),
        GoRoute(
          path: '/auth/callback',
          builder: (context, state) => const AuthRedirectPage(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) {
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
        ),
        GoRoute(
          path: '/contracts',
          builder: (context, state) {
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
        ),
        GoRoute(
          path: '/bidding',
          builder: (context, state) {
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
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
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
        ),
        GoRoute(
          path: '/project-management',
          builder: (context, state) {
            final session = Supabase.instance.client.auth.currentSession;
            final projectId = state.extra as String?;
            if (session != null && projectId != null) {
              return ContractorShell(
                currentPage: ContractorPage.projectManagement,
                contractorId: session.user.id,
                child: CorOngoingProjectScreen(projectId: projectId),
              );
            }
            return const ToLoginScreen();
          },
        ),
        GoRoute(
          path: '/materials',
          builder: (context, state) {
            final session = Supabase.instance.client.auth.currentSession;
            final args = state.extra as Map<String, dynamic>?;
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
        ),
      ],
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        final location = state.matchedLocation;

        if (session == null) {
          if (location != '/' && location != '/auth/callback') {
            return '/';
          }
        } else {
          if (_isRegistering || _preventAuthNavigation) {
            return null;
          }

          final user = session.user;
          if (user != null) {
            try {
              final resp = await Supabase.instance.client
                  .from('Users')
                  .select('verified, role')
                  .eq('users_id', user.id)
                  .maybeSingle();

              final verified = resp != null && (resp['verified'] == true);
              final role = resp != null ? resp['role'] : null;

              if (verified && role == 'contractor') {
                if (location == '/' || location == '/auth/callback') {
                  return '/dashboard';
                }
              } else {
                if (location != '/' && location != '/auth/callback') {
                  return '/';
                }
              }
            } catch (_) {
              if (location != '/' && location != '/auth/callback') {
                return '/';
              }
            }
          }
        }

        return null;
      },
    );

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _router.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
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
    );
  }
}