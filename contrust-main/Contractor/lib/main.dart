import 'package:contractor/Screen/bidding.dart';
import 'package:contractor/Screen/clienthistory.dart';
import 'package:contractor/Screen/dashboard_screen.dart';
import 'package:contractor/Screen/loginscreen.dart';
import 'package:contractor/Screen/ongoingproject.dart';
import 'package:contractor/Screen/productpanel.dart';
import 'package:contractor/Screen/profilescreen.dart';
import 'package:contractor/Screen/registerscreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final url = 'https://bgihfdqruamnjionhkeq.supabase.co';
final key =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnaWhmZHFydWFtbmppb25oa2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NzIyODksImV4cCI6MjA1NjQ0ODI4OX0.-GRaolUVu1hW6NUaEAwJuYJo8C2X5_1wZ-qB4a-9Txs';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: url, anonKey: key);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contrust',
      home: LoginScreen(), // Start with the login screen
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/register': (context) => RegisterScreen(),
        '/bidding': (context) => BiddingScreen(),
        '/profile': (context) => UserProfileScreen(),
        '/productpanel': (context) => ProductPanelScreen(),
        '/ongoingproject': (context) => OngoingProgressScreen(),
        '/clienthistory': (context) => ClientHistoryScreen(),
      },
    );
  }
}
