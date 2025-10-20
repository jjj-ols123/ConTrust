import 'package:contractee/main.dart';
import 'package:contractee/pages/cee_authredirect.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:contractee/pages/cee_welcome.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MyApp extends StatefulWidget {
  final bool isFirstOpen;
  const MyApp({super.key, required this.isFirstOpen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Session? _session;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;

    _session = supabase.auth.currentSession;

    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() => _session = session);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget initialPage;

    if (widget.isFirstOpen) {
      initialPage = const WelcomePage();
    } else if (_session != null) {
      initialPage = const HomePage();
    } else {
      initialPage = const LoginPage();
    }

    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      home: initialPage,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/auth/callback': (context) => const AuthRedirectPage(),
      },
    );
  }
}
