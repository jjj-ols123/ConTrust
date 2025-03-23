import 'package:contractor/Screen/bidding.dart';
import 'package:contractor/Screen/clienthistory.dart';
import 'package:contractor/Screen/dashboard_screen.dart';
import 'package:contractor/Screen/editprofile.dart';
import 'package:contractor/Screen/logginginscreen.dart';
import 'package:contractor/Screen/loginscreen.dart';
import 'package:contractor/Screen/ongoingproject.dart';
import 'package:contractor/Screen/productpanel.dart';
import 'package:contractor/Screen/profilescreen.dart';
import 'package:contractor/Screen/registerscreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final url = 'https://bgihfdqruamnjionhkeq.supabase.co';
final key =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnaWhmZHFydWFtbmppb25oa2VxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MDg3MjI4OSwiZXhwIjoyMDU2NDQ4Mjg5fQ.0VxCNZKhvrHOMQhk37Ej3igkxUAyUGvLp_vJrE-ZFd4';

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
      home: LoginScreen(), 
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/register': (context) => RegisterScreen(),
        '/bidding': (context) => BiddingScreen(),
        '/profile': (context) => UserProfileScreen(contractorId: 
          ModalRoute.of(context)!.settings.arguments as String),
        '/productpanel': (context) => ProductPanelScreen(),
        '/ongoingproject': (context) => OngoingProgressScreen(),
        '/clienthistory': (context) => ClientHistoryScreen(),
        '/editprofile': (context) => EditProfileScreen(),
        '/login': (context) => ToLoginScreen()
      },
    );
  }
}
