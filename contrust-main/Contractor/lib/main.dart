
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
          pageBuilder: (context, state) => NoTransitionPage(
            child: const ToLoginScreen(),
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
                    return const ToLoginScreen();
                  }

                  final contractorId = session.user.id;

                  final location = state.matchedLocation;
                  ContractorPage currentPage;
                  switch (location) {
                    case '/dashboard':
                      currentPage = ContractorPage.dashboard;
                      break;
                    case '/messages':
                      currentPage = ContractorPage.messages;
                      break;
                    case '/contracts':
                      currentPage = ContractorPage.contracts;
                      break;
                    case '/bidding':
                      currentPage = ContractorPage.bidding;
                      break;
                    case '/profile':
                      currentPage = ContractorPage.profile;
                      break;
                    case '/project-management':
                      currentPage = ContractorPage.projectManagement;
                      break;
                    case '/materials':
                      currentPage = ContractorPage.materials;
                      break;
                    default:
                      currentPage = ContractorPage.dashboard;
                  }

                  return ContractorShell(
                    currentPage: currentPage,
                    contractorId: contractorId,
                    child: child,
                  );
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return DashboardScreen(contractorId: session.user.id);
                      }
                      return const ToLoginScreen();
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
                        return ContractorChatHistoryPage();
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/contracts',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return ContractType(contractorId: session.user.id);
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/bidding',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return BiddingScreen(contractorId: session.user.id);
                      }
                      return const ToLoginScreen();
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
                        return ContractorUserProfileScreen(contractorId: session.user.id);
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/project-management',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final projectId = state.extra as String?;
                      if (session != null && projectId != null) {
                        return CorOngoingProjectScreen(projectId: projectId);
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/materials',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final args = state.extra as Map<String, dynamic>?;
                      final projectId = args?['projectId'] as String?;
                      if (session != null && projectId != null) {
                        return ProductPanelScreen(
                          contractorId: session.user.id,
                          projectId: projectId,
                        );
                      }
                      return const ToLoginScreen();
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
            child: Builder(
              builder: (context) => Scaffold(
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
                        onPressed: () => context.go('/dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: const Text('Go to Dashboard'),
                      ),
                    ],
                  ),
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