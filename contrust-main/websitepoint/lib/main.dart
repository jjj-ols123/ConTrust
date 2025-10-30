import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:websitepoint/app_websitestart.dart';
import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_authredirect.dart' as cee;
import 'package:contractor/Screen/cor_startup.dart';
import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:superadmin/pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();
  
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WebsiteStartPage(),
        '/contractee': (context) => const WelcomePage(),
        '/contractee/home': (context) => const HomePage(),
        '/contractor': (context) => const ToLoginScreen(),
        '/contractor/dashboard': (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return DashboardScreen(contractorId: session.user.id);
          }
          return const ToLoginScreen();
        },
        '/superadmin': (context) => const SuperAdminLoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/auth/callback') {
          return MaterialPageRoute(
            builder: (context) => const cee.AuthRedirectPage(),
          );
        }
        
        return MaterialPageRoute(
          builder: (context) => const WebsiteStartPage(),
        );
      },
    );
  }
}
