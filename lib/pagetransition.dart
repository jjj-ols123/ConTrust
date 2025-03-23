import 'package:contractor/Screen/bidding.dart';
import 'package:contractor/Screen/clienthistory.dart';
import 'package:contractor/Screen/dashboard_screen.dart';
import 'package:contractor/Screen/ongoingproject.dart';
import 'package:contractor/Screen/productpanel.dart';
import 'package:contractor/Screen/profilescreen.dart';
import 'package:flutter/material.dart';

void transitionBuilder(BuildContext context, Widget destination) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    ),
  );
}

// ignore: unused_element
Widget getScreenFromRoute(BuildContext context, String route) {
  switch (route) {
    case '/profile':
      final contractorId = ModalRoute.of(context)!.settings.arguments as String;
      return UserProfileScreen(contractorId: contractorId);
    case '/ongoingproject':
      return OngoingProgressScreen();
    case '/bidding':
      return BiddingScreen();
    case '/clienthistory':
      return ClientHistoryScreen();
    case '/productpanel':
      return ProductPanelScreen();
    default:
      return DashboardScreen();
  }
}