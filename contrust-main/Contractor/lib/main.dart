
// ignore_for_file: unnecessary_null_comparison

import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_profile.dart';
import 'package:contractor/Screen/cor_registration.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:contractor/Screen/cor_authredirect.dart';
import 'package:contractor/Screen/cor_forgot_password.dart';
import 'package:contractor/Screen/cor_bidding.dart';
import 'package:contractor/Screen/cor_chathistory.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
import 'package:contractor/Screen/cor_createcontract.dart';
import 'package:contractor/Screen/cor_messages.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractor/Screen/cor_notification.dart';
import 'package:contractor/Screen/cor_history.dart';
import 'package:contractor/Screen/cor_viewcontract.dart';
import 'package:contractor/Screen/cor_product.dart';
import 'package:contractor/Screen/cor_editcontract.dart';
import 'package:contractor/build/builddrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/utils/be_snackbar.dart';

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
      initialLocation: '/logincontractor',
      routes: [
        GoRoute(
          path: '/logincontractor',
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
        GoRoute(
          path: '/auth/reset-password',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const RegisterScreen(),
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

                  final currentUser = Supabase.instance.client.auth.currentUser;
                  final userType = (currentUser?.userMetadata?['user_type']?.toString() ?? '').toLowerCase();
                      if (userType != 'contractor') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ConTrustSnackBar.warning(
                            context,
                            'Please log in with a contractor account.',
                          );
                          Supabase.instance.client.auth.signOut();
                          context.go('/logincontractor');
                        });
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
                        );
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
                    case '/notifications':
                      currentPage = ContractorPage.notifications;
                      break;
                    case '/contracttypes':
                      currentPage = ContractorPage.contractTypes;
                      break;
                    default:
                      if (location.startsWith('/createcontract')) {
                        currentPage = ContractorPage.createContract;
                      } else if (location.startsWith('/chathistory')) {
                        currentPage = ContractorPage.chatHistory;
                      } else if (location.startsWith('/bidding')) {
                        currentPage = ContractorPage.bidding;
                      } else if (location.startsWith('/profile')) {
                        currentPage = ContractorPage.profile;
                      } else if (location.startsWith('/project-management')) {
                        if (location.contains('/materials')) {
                          currentPage = ContractorPage.materials;
                        } else {
                        currentPage = ContractorPage.projectManagement;
                        }
                      } else if (location.startsWith('/materials')) {
                        currentPage = ContractorPage.materials;
                      } else if (location.startsWith('/history')) {
                        currentPage = ContractorPage.history;
                      } else if (location.startsWith('/viewcontract')) {
                        currentPage = ContractorPage.createContract;
                      } else if (location.startsWith('/editcontract')) {
                        currentPage = ContractorPage.createContract;
                      } else {
                        currentPage = ContractorPage.dashboard;
                      }
                      }

                      return ContractorShell(
                        key: ValueKey(currentPage),
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
              path: '/notifications',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return const ContractorNotificationPage();
                      }
                      return const ToLoginScreen();
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
                        return CorHistoryPage(contractorId: session.user.id);
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/contracttypes',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        final showNoProjectsMessage = state.uri.queryParameters['showNoProjectsMessage'] == 'true';
                        return ContractType(
                          contractorId: session.user.id,
                          showNoProjectsMessage: showNoProjectsMessage,
                        );
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/createcontract',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        final mode = state.uri.queryParameters['mode'];
                        final identifier = state.uri.queryParameters['identifier'];
                        final extraData = state.extra as Map<String, dynamic>?;
                        final contractorId = extraData?['contractorId'] ?? session.user.id;
                        final contractType = extraData?['contractType'];

                        Map<String, dynamic>? template;
                        Map<String, dynamic>? existingContract;

                        if (mode == 'template' && (identifier ?? '').isNotEmpty) {
                          final decodedName = Uri.decodeComponent(identifier!);
                          template = extraData?['template'];
                          template ??= {'template_name': decodedName};
                        } else if (mode == 'contract' && (identifier ?? '').isNotEmpty) {
                          existingContract = extraData?['existingContract'];
                          existingContract ??= {'contract_id': identifier};
                        }

                        // If template deep link, verify contractor before allowing creation
                        if (mode == 'template' && existingContract == null) {
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: FetchService().fetchContractorData(contractorId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                                  ),
                                );
                              }
                              final contractorData = snapshot.data;
                              final isVerified = contractorData?['verified'] == true;
                              if (!isVerified) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  context.go('/contracttypes');
                                  ConTrustSnackBar.warning(
                                    context,
                                    'Your account needs to be verified before you can create contracts. Please complete your verification.',
                                  );
                                });
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                                  ),
                                );
                              }

                              return CreateContractPage(
                                contractorId: contractorId,
                                contractType: contractType,
                                template: template,
                                existingContract: existingContract,
                              );
                            },
                          );
                        }

                        return CreateContractPage(
                          contractorId: contractorId,
                          contractType: contractType,
                          template: template,
                          existingContract: existingContract,
                        );
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/editcontract',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session == null) return const ToLoginScreen();
                      final id = state.uri.queryParameters['contractId'];
                      final extra = state.extra as Map<String, dynamic>?;
                      if (id == null || id.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/contracttypes'));
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
                        );
                      }
                      return CorEditContractScreen(
                        contractId: id,
                        initialContract: extra?['existingContract'] as Map<String, dynamic>?,
                        initialTemplate: extra?['template'] as Map<String, dynamic>?,
                        initialContractTypeName: extra?['contractType'] as String?,
                      );
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/editcontract/:contractId',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session == null) return const ToLoginScreen();
                      final id = state.pathParameters['contractId'];
                      final extra = state.extra as Map<String, dynamic>?;
                      if (id == null || id.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/contracttypes'));
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
                        );
                      }
                      return CorEditContractScreen(
                        contractId: id,
                        initialContract: extra?['existingContract'] as Map<String, dynamic>?,
                        initialTemplate: extra?['template'] as Map<String, dynamic>?,
                        initialContractTypeName: extra?['contractType'] as String?,
                      );
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/createcontract/:mode/:identifier',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        final mode = state.pathParameters['mode'];
                        final identifier = state.pathParameters['identifier'];
                        final extraData = state.extra as Map<String, dynamic>?;
                        final contractorId = extraData?['contractorId'] ?? session.user.id;
                        final contractType = extraData?['contractType'];

                        Map<String, dynamic>? template;
                        Map<String, dynamic>? existingContract;

                        if (mode == 'template' && identifier != null) {
                          final decodedName = Uri.decodeComponent(identifier);
                          template = extraData?['template'];
                          template ??= {'template_name': decodedName};
                        } else if (mode == 'contract' && identifier != null) {
                          existingContract = extraData?['existingContract'];
                          existingContract ??= {'contract_id': identifier};
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.go('/contracttypes');
                          });
                          return const Scaffold(
                            body: Center(
                              child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                            ),
                          );
                        }
                        
                        // Check if contractor is verified (only for new templates, not editing existing contracts)
                        if (mode == 'template' && existingContract == null) {
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: FetchService().fetchContractorData(contractorId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                                  ),
                                );
                              }
                              final contractorData = snapshot.data;
                              final isVerified = contractorData?['verified'] == true;
                              
                              if (!isVerified) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  context.go('/contracttypes');
                                  ConTrustSnackBar.warning(
                                    context,
                                    'Your account needs to be verified before you can create contracts. Please complete your verification.',
                                  );
                                });
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                                  ),
                                );
                              }
                              
                              return CreateContractPage(
                                contractorId: contractorId,
                                contractType: contractType,
                                template: template,
                                existingContract: existingContract,
                              );
                            },
                          );
                        }
                        
                        return CreateContractPage(
                          contractorId: contractorId,
                          contractType: contractType,
                          template: template,
                          existingContract: existingContract,
                        );
                      }
                      return const ToLoginScreen();
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
                        return ContractorChatHistoryPage();
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
              path: '/project-management/:projectId',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final projectId = state.pathParameters['projectId'];
                      if (session != null && projectId != null && projectId.isNotEmpty) {
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FetchService().fetchProjectDetails(projectId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Scaffold(
                                body: Center(child: CircularProgressIndicator(color: Colors.amber)),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return Scaffold(
                                body: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                      const SizedBox(height: 16),
                                      Text(
                                        snapshot.hasError ? 'Error loading project' : 'Project not found',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final project = snapshot.data!;
                            final contractorId = project['contractor_id']?.toString();
                            if (contractorId != session.user.id) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                context.go('/dashboard');
                              });
                              return const Scaffold(
                                body: Center(child: CircularProgressIndicator(color: Colors.amber)),
                              );
                            }
                            final status = project['status']?.toString().toLowerCase();
                            final allowedStatuses = ['active', 'completed'];
                            if (!allowedStatuses.contains(status)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Only active projects can be viewed. Current status: ${ProjectStatus().getStatusLabel(status)}',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                context.go('/dashboard');
                              });
                              return const Scaffold(
                                body: Center(child: CircularProgressIndicator(color: Colors.amber)),
                              );
                            }
                            return CorOngoingProjectScreen(projectId: projectId);
                          },
                        );
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: 'materials',
                  pageBuilder: (context, state) {
                    return NoTransitionPage(
                      child: Builder(
                        builder: (context) {
                          final session = Supabase.instance.client.auth.currentSession;
                          final projectId = state.pathParameters['projectId'];
                          if (session != null && projectId != null && projectId.isNotEmpty) {
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
            GoRoute(
              path: '/materials',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final args = state.extra as Map<String, dynamic>?;
                      final projectId = args?['projectId'] as String?;
                      if (session != null) {
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
            GoRoute(
              path: '/viewcontract',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final args = state.extra as Map<String, dynamic>?;
                      final contractId =
                          state.uri.queryParameters['contractId'] ?? args?['contractId'] as String?;
                      final contractorId =
                          state.uri.queryParameters['contractorId'] ?? (args?['contractorId'] as String?) ?? session?.user.id;
                      if (session != null && contractId != null && contractorId != null) {
                        return ContractorViewContractPage(
                          contractId: contractId,
                          contractorId: contractorId,
                        );
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            GoRoute(
              path: '/viewcontract/:contractId',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final contractId = state.pathParameters['contractId'];
                      final contractorId = state.uri.queryParameters['contractorId'] ?? session?.user.id;
                      if (session != null && contractId != null && contractId.isNotEmpty && contractorId != null) {
                        return ContractorViewContractPage(
                          contractId: contractId,
                          contractorId: contractorId,
                        );
                      }
                      return const ToLoginScreen();
                    },
                  ),
                );
              },
            ),
            // Support path-parameter deep links with contractor: /viewcontract/:contractId/:contractorId
            GoRoute(
              path: '/viewcontract/:contractId/:contractorId',
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: Builder(
                    builder: (context) {
                      final session = Supabase.instance.client.auth.currentSession;
                      final contractId = state.pathParameters['contractId'];
                      final contractorId = state.pathParameters['contractorId'] ?? session?.user.id;
                      if (session != null && contractId != null && contractId.isNotEmpty && contractorId != null) {
                        return ContractorViewContractPage(
                          contractId: contractId,
                          contractorId: contractorId,
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
        GoRoute(
          path: '/chat/:contracteeName',
          pageBuilder: (context, state) {
            final contracteeName = Uri.decodeComponent(state.pathParameters['contracteeName'] ?? '');
            final chatData = state.extra as Map<String, dynamic>?;
            return NoTransitionPage(
              child: Builder(
                builder: (context) {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session != null && contracteeName.isNotEmpty && chatData != null) {
                    return MessagePageContractor(
                      chatRoomId: chatData['chatRoomId'] ?? '',
                      contractorId: chatData['contractorId'] ?? '',
                      contracteeId: chatData['contracteeId'] ?? '',
                      contracteeName: contracteeName,
                      contracteeProfile: chatData['contracteeProfile'],
                    );
                  }
                  return const ToLoginScreen();
                },
              ),
            );
          },
        ),
        GoRoute(
          path: '/:path(.*)',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Builder(
              builder: (context) {
                final path = state.path ?? '';
                if (path.startsWith('/createcontract/')) {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session != null) {
                    final segments = Uri.parse(path).pathSegments;
                    if (segments.length >= 3) {
                      final mode = segments[1];
                      final identifier = segments[2];

                      Map<String, dynamic>? template;
                      Map<String, dynamic>? existingContract;

                      if (mode == 'template') {
                        final decodedName = Uri.decodeComponent(identifier);
                        template = {'template_name': decodedName};
                      } else if (mode == 'contract') {
                        existingContract = {'contract_id': identifier};
                      }

                      // Check if contractor is verified (only for new templates, not editing existing contracts)
                      if (mode == 'template' && existingContract == null) {
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FetchService().fetchContractorData(session.user.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Scaffold(
                                body: Center(
                                  child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                                ),
                              );
                            }
                            final contractorData = snapshot.data;
                            final isVerified = contractorData?['verified'] == true;
                            
                            if (!isVerified) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                context.go('/contracttypes');
                                ConTrustSnackBar.warning(
                                  context,
                                  'Your account needs to be verified before you can create contracts. Please complete your verification.',
                                );
                              });
                              return const Scaffold(
                                body: Center(
                                  child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                                ),
                              );
                            }
                            
                            return CreateContractPage(
                              contractorId: session.user.id,
                              contractType: null,
                              template: template,
                              existingContract: existingContract,
                            );
                          },
                        );
                      }

                      return CreateContractPage(
                        contractorId: session.user.id,
                        contractType: null,
                        template: template,
                        existingContract: existingContract,
                      );
                    }
                  }
                }

                return Scaffold(
                appBar: AppBar(
                  title: const Text('Page Not Found'),
                  backgroundColor: const Color(0xFFFFB300),
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
                          backgroundColor: const Color(0xFFFFB300),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Go to Dashboard'),
                      ),
                    ],
                  ),
                ),
              );
              },
            ),
          ),
        ),
      ],
      redirect: (context, state) {
        final uriPath = state.uri.path;
        
        Session? session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          if (uriPath == '/logincontractor' || 
              uriPath == '/auth/callback' || 
              uriPath == '/auth/reset-password' || 
              uriPath == '/register' ||
              uriPath == '/register/verification') {
            return null; 
          }
          return '/logincontractor';
        }

        if (_isRegistering || _preventAuthNavigation) {
          return null;
        }

        if (uriPath == '/auth/callback') {
          return null;
        }

        if (uriPath == '/logincontractor') {
          return '/dashboard';
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