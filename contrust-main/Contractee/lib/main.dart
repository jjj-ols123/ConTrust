// ignore_for_file: unnecessary_null_comparison

import 'dart:ui';
import 'package:contractee/pages/cee_authredirect.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:contractee/pages/cee_forgot_password.dart';
import 'package:contractee/pages/cee_ongoing.dart';
import 'package:contractee/pages/cee_profile.dart';
import 'package:contractee/pages/cee_chathistory.dart';
import 'package:contractee/pages/cee_messages.dart';
import 'package:contractee/pages/cee_registration.dart';
import 'package:contractee/pages/cee_torprofile.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractee/pages/cee_ai_assistant.dart';
import 'package:contractee/pages/cee_history.dart';
import 'package:contractee/build/builddrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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

  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

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
        GoRoute(
          path: '/auth/reset-password',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const RegistrationPage(),
          ),
        ),
        
        GoRoute(
          path: '/chat/:contractorName',
          pageBuilder: (context, state) {
            final contractorName = Uri.decodeComponent(state.pathParameters['contractorName'] ?? '');
            final chatData = state.extra as Map<String, dynamic>?;
            return NoTransitionPage(
              child: Builder(
                builder: (context) {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session != null && contractorName.isNotEmpty && chatData != null) {
                    return MessagePageContractee(
                      chatRoomId: chatData['chatRoomId'] ?? '',
                      contracteeId: chatData['contracteeId'] ?? '',
                      contractorId: chatData['contractorId'] ?? '',
                      contractorName: contractorName,
                      contractorProfile: chatData['contractorProfile'],
                    );
                  }
                  return const LoginPage();
                },
              ),
            );
          },
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

                  final currentUser = Supabase.instance.client.auth.currentUser;
                  final userType = (currentUser?.userMetadata?['user_type']?.toString() ?? '').toLowerCase();
                      if (userType != 'contractee') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ConTrustSnackBar.warning(
                            context,
                            'Please log in with a contractee account.',
                          );
                          Supabase.instance.client.auth.signOut();
                          context.go('/login');
                        });
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
                        );
                      }

                      final contracteeId = session.user.id;

                      final location = state.matchedLocation;
                      ContracteePage currentPage;
                      switch (location) {
                    case '/home':
                      currentPage = ContracteePage.home;
                      break;
                    case '/profile':
                      currentPage = ContracteePage.profile;
                      break;
                    case '/messages':
                      currentPage = ContracteePage.messages;
                      break;
                    case '/chathistory':
                      currentPage = ContracteePage.chatHistory;
                      break;
                    case '/notifications':
                      currentPage = ContracteePage.notifications;
                      break;
                    case '/ai-assistant':
                      currentPage = ContracteePage.aiAssistant;
                      break;
                    case '/history':
                      currentPage = ContracteePage.history;
                      break;
                    default:
                      if (location.startsWith('/ongoing')) {
                        currentPage = ContracteePage.ongoing;
                      } else if (location.startsWith('/contractor')) {
                        currentPage = ContracteePage.home;
                      } else {
                        currentPage = ContracteePage.home;
                      }
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
              path: '/ongoing/:projectId',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final projectId = state.pathParameters['projectId'];
                      if (session != null && projectId != null && projectId.isNotEmpty) {
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
            GoRoute(
              path: '/chathistory',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return ContracteeChatHistoryPage();
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/ai-assistant',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return const AiAssistantPage();
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return CeeHistoryPage(contracteeId: session.user.id);
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/contractor/:name',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final contractorName = Uri.decodeComponent(state.pathParameters['name'] ?? '');
                      if (session != null && contractorName != null) {
                        return ContractorProfileScreen(contractorName: contractorName);
                      }
                      return const LoginPage();
                    },
                  ),
                );
              },
            ),
          ],
        ),
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
        final location = state.matchedLocation.isEmpty ? state.uri.path : state.matchedLocation;
        final session = Supabase.instance.client.auth.currentSession;

        final prefs = await SharedPreferences.getInstance();
        final isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

        if (session == null) {
          if (!isFirstOpen && location == '/welcome') {
            return '/login';
          }
          if (location != '/login' && location != '/welcome' && location != '/auth/callback' && location != '/auth/reset-password' && location != '/register') {
            return '/login';
          }
        } else {
          if (_isRegistering || _preventAuthNavigation) {
            return null;
          }

          if (location == '/login' || location == '/welcome') {
            return '/home';
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
