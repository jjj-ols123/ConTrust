// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ToLoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  ToLoginScreen({super.key});

  void _login(BuildContext context) {
    Navigator.pushNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Login', style: TextStyle(color: Colors.black)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600; // Mobile threshold

          return Stack(
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

              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo + Text BELOW the AppBar, Smaller Size
                      Container(
                        width: double.infinity,
                        color: Colors.amber.withOpacity(0.3),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'logo3.png',
                              width: isMobile ? constraints.maxWidth * 0.25 : constraints.maxWidth * 0.2,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Simplify your contracts. Secure results!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 14 : 16,
                                fontFamily: 'Times New Roman',
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20), // Space before login form

                      // Login Form
                      Container(
                        width: isMobile ? double.infinity : constraints.maxWidth * 0.5,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 20),

                            _buildTextField('Email Address', controller: emailController),
                            SizedBox(height: 10),

                            _buildTextField('Password', isPassword: true, controller: passwordController),
                            SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                              children: [
                                if (!isMobile)
                                  _buildButton('Forgot Password', Colors.amber, Colors.black, () {}),
                                  _buildButton('Login', Colors.green, Colors.white, () => _login(context)),
                              ],
                            ),

                            if (isMobile) ...[
                              SizedBox(height: 10),
                              _buildButton('Forgot Password', Colors.amber, Colors.black, () {}),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, {bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildButton(String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        minimumSize: Size(150, 50),
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }
}
