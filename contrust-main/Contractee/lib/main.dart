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
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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

  runApp(MyApp(isFirstOpen: isFirstOpen));
}

void setRegistrationState(bool isRegistering) {
  _isRegistering = isRegistering;
}

void setPreventAuthNavigation(bool prevent) {
  _preventAuthNavigation = prevent;
}

class MyApp extends StatefulWidget {
  final bool isFirstOpen;
  const MyApp({super.key, required this.isFirstOpen});

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
      initialLocation: widget.isFirstOpen ? '/welcome' : '/login',
      routes: [
        GoRoute(
          path: '/welcome',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const WelcomePage(),
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: '/auth/callback',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const AuthRedirectPage(),
          ),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: Builder(
                builder: (context) {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session == null) {
                    return const LoginPage();
                  }

                  final contracteeId = session.user.id;

                  final location = state.matchedLocation;
                  ContracteePage currentPage;
                  switch (location) {
                    case '/home':
                      currentPage = ContracteePage.home;
                      break;
                    case '/ongoing':
                      currentPage = ContracteePage.ongoing;
                      break;
                    case '/profile':
                      currentPage = ContracteePage.profile;
                      break;
                    case '/messages':
                      currentPage = ContracteePage.messages;
                      break;
                    case '/notifications':
                      currentPage = ContracteePage.notifications;
                      break;
                    default:
                      currentPage = ContracteePage.home;
                  }

                  return ContracteeShell(
                    currentPage: currentPage,
                    contracteeId: contracteeId,
                    child: child,
                  );
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return HomePage();
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/ongoing',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final projectId = state.extra as String?;
                      if (session != null && projectId != null) {
                        return CeeOngoingProjectScreen(projectId: projectId);
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return CeeProfilePage(contracteeId: session.user.id);
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/messages',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return const ContracteeChatHistoryPage();
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/notifications',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return const ContracteeNotificationPage();
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
          ],
        ),
        // Catch-all route for 404 errors
        GoRoute(
          path: '/:path(.*)',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Page Not Found'),
                backgroundColor: Colors.amber,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '404 - Page Not Found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The page "${state.path}" does not exist.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      redirect: (context, state) async {
        final session = Supabase.instance.client.auth.currentSession;
        final location = state.matchedLocation;

        if (session == null) {
          if (location != '/login' && location != '/welcome' && location != '/auth/callback') {
            return '/login';
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

              if (verified && role == 'contractee') {
                if (location == '/login' || location == '/welcome' || location == '/auth/callback') {
                  return '/home';
                }
              } else {
                if (location != '/login' && location != '/welcome' && location != '/auth/callback') {
                  return '/login';
                }
              }
            } catch (_) {
              if (location != '/login' && location != '/welcome' && location != '/auth/callback') {
                return '/login';
              }
            }
          }
        }

        return null;
      },
    );

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        _router.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
    );
  }
}
