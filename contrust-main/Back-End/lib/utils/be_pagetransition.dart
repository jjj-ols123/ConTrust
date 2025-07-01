//contractee


//contractor
import 'package:contractee/pages/cee_about.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:contractee/pages/cee_materials.dart';
import 'package:contractee/pages/cee_torprofile.dart';
import 'package:contractee/pages/cee_transaction.dart';
import 'package:contractor/Screen/cor_bidding.dart';
import 'package:contractor/Screen/cor_dashboard.dart';
import 'package:contractor/Screen/cor_ongoing.dart';
import 'package:contractor/Screen/cor_product.dart';
import 'package:contractor/Screen/cor_profile.dart';
import 'package:contractor/Screen/cor_clienthistory.dart';
import 'package:contractor/Screen/cor_login.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:flutter/material.dart';


Future<void> transitionBuilder(
  BuildContext context,
  Widget destination, {
  bool replace = false, 
}) async {
  final route = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 150), 
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

        return DashboardScreen();
      }
      return ContractorUserProfileScreen(contractorId: arguments);

    // Contractor Pages
    case '/ongoingproject':
      return OngoingProjectScreen();
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
        return DashboardScreen();
      }
      return ContractorProfileScreen(contractorId: arguments);

    default:
      return DashboardScreen();
  }
}