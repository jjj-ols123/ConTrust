import 'package:flutter/material.dart';
import 'Screen/dashboard_screen.dart';
import 'Screen/loginscreen.dart';
import 'Screen/registerscreen.dart';
import 'Screen/bidding.dart';
import 'Screen/profilescreen.dart';
import 'Screen/productpanel.dart';
import 'Screen/ongoingproject.dart';
import 'Screen/clienthistory.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
