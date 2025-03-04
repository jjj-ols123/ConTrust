// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Register', style: TextStyle(color: Colors.black)),
      ),
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

          // Left Side 
          Row(
            children: [
              Container(
                width: screenWidth * 0.3, 
                color: Colors.amber.withOpacity(
                  0.3,
                ), 
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Spacer(),
                          Image.asset(
                            'logo3.png', 
                            width: screenWidth * 0.50, 
                          ),
                          Spacer(),
                        ],
                      ),
                      Positioned(
                        bottom:
                            180, 
                        left: 80,
                        right: 60,
                        child: Text(
                          'Simplify your contracts. Secure results!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Times New Roman',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Side (Form)
              Expanded(
                child: Center(
                  child: Container(
                    width: screenWidth * 0.5,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Firm Name
                        _buildTextField('Firm Name'),
                        SizedBox(height: 10),

                        // Contact Number & Email
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Contact Number',
                                isNumber: true,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(child: _buildTextField('Email Address')),
                          ],
                        ),
                        SizedBox(height: 10),

                        // Password & Confirm Password
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Password',
                                isPassword: true,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Confirm password',
                                isPassword: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Verification 
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                'Verify(ID)',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Registration 
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // create a text field
  Widget _buildTextField(
    String label, {
    bool isPassword = false,
    bool isNumber = false,
  }) {
    return TextField(
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }
}
