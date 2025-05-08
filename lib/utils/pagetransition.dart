//contractee
import 'package:contractee/pages/about_page.dart';
import 'package:contractee/pages/buildingmaterial_page.dart';
import 'package:contractee/pages/contractor_profile.dart';
import 'package:contractee/pages/home_page.dart';
import 'package:contractee/pages/transaction_page.dart';

//contractor
import 'package:contractor/Screen/bidding.dart';
import 'package:contractor/Screen/clienthistory.dart';
import 'package:contractor/Screen/dashboardscreen.dart';
import 'package:contractor/Screen/logginginscreen.dart';
import 'package:contractor/Screen/loginscreen.dart';
import 'package:contractor/Screen/ongoingproject.dart';
import 'package:contractor/Screen/productpanel.dart';
import 'package:contractor/Screen/profilescreen.dart';
import 'package:flutter/material.dart';


Future<void> transitionBuilder(
  BuildContext context,
  Widget destination, {
  bool replace = false, 
}) async {
  final route = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );

  if (replace) {
    await Navigator.pushReplacement(context, route);
  } else {
    await Navigator.push(context, route);
  }
}

Widget getScreenFromRoute(BuildContext context, String route, {Object? arguments}) {
  switch (route) {
    case '/profile':
      if (arguments == null || arguments is! String) {
        return Scaffold(
          body: Center(child: Text("Error: Contractor ID is missing")),
        );
      }
      return ContractorUserProfileScreen(contractorId: arguments);
      
    // Contractor Pages
    case '/ongoingproject':
      return OngoingProgressScreen();
    case '/bidding':
      return BiddingScreen();
    case '/clienthistory':
      return ClientHistoryScreen();
    case '/productpanel':
      return ProductPanelScreen();
    case '/login':
      return ToLoginScreen();
    case '/first':
      return LoginScreen();
    case '/dashboard':
      return DashboardScreen();

    // Contractee Pages
    case '/homepage':
      return HomePage();
    case '/transaction':
      return TransactionPage();
    case '/about':
      return AboutPage();
    case '/buildingmaterials': 
      return Buildingmaterial();  
    case '/contractorprofile':
      if (arguments == null || arguments is! String) {
        return Scaffold(
          body: Center(child: Text("Error: Contractor not found")),
        );
      }
      return ContractorProfileScreen(contractorId: arguments);

    default:
      return DashboardScreen();
  }
}