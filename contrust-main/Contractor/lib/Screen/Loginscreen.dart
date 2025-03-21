// ignore_for_file: deprecated_member_use

import 'package:backend/pagetransition.dart';
import 'package:contractor/Screen/Registerscreen.dart';
import 'package:contractor/Screen/logginginscreen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
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
              Container(
                height: 5,
                color: Colors.white,
              ),
              Container(
                height: 5,
                color: Colors.amber,
              ),
            ],
          ),

          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Image.asset(
                  'logo3.png', 
                  width: screenWidth * 0.2,
                ),
                SizedBox(height: 20),

                // Login Box
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

                      // Login Button
                      ElevatedButton(
                        onPressed: () {
                          transitionBuilder(context, ToLoginScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: Size(double.infinity, 40),
                        ),
                        child: Text('Login', style: TextStyle(color: Colors.white)),
                      ),

                      SizedBox(height: 10),

                      // Sign Up Button
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