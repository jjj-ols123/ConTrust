import 'package:backend/pagetransition.dart';
import 'package:contractee/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LaunchPageState createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      transitionBuilder(context, WelcomePage());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'CONTRUST',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
