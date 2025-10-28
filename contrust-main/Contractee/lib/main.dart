import 'dart:ui';
import 'package:contractee/pages/cee_authredirect.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractee/pages/cee_login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  final supabase = Supabase.instance.client;
  final hasSession = supabase.auth.currentSession != null;
  
  bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  
  if (hasSession && isFirstOpen) {
    await prefs.setBool('isFirstOpen', false);
    isFirstOpen = false;
  }

  runApp(MyApp(isFirstOpen: isFirstOpen));
}

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
      setState(() {
        _session = session;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    String initialRoute;
    if (_session != null) {
      initialRoute = '/home';
    } else if (widget.isFirstOpen) {
      initialRoute = '/welcome';
    } else {
      initialRoute = '/login';
    }

    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/auth/callback': (context) => const AuthRedirectPage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => _session != null 
            ? const HomePage() 
            : (widget.isFirstOpen ? const WelcomePage() : const LoginPage()),
      ),
    );
  }
}
