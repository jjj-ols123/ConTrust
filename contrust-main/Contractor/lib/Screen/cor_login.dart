// ignore_for_file: deprecated_member_use
import 'package:backend/utils/be_pagetransition.dart';
import 'package:contractor/Screen/cor_registration.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
                'bgloginscreen.jpg', 
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Container(
                height: 40,
                color: Colors.amber,
              ),
            ],
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'logo3.png', 
                  width: screenWidth * 0.2,
                ),
                SizedBox(height: 20),
                Container(
                  width: screenWidth * 0.8,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Simplify your contracts.Secure results!',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          transitionBuilder(context, ToLoginScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          minimumSize: Size(double.infinity, 40),
                        ),
                        child: Text('Login', style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                           transitionBuilder(context, RegisterScreen());
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.black),
                          minimumSize: Size(double.infinity, 40),
                        ),
                        child: Text('Sign up'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}