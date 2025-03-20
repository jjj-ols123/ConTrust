// ignore_for_file: file_names, deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously



import 'package:contractor/blocs/signupcontractor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
                color: Colors.amber.withOpacity(0.3),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Spacer(),
                          Image.asset('logo3.png', width: screenWidth * 0.50),
                          Spacer(),
                        ],
                      ),
                      Positioned(
                        bottom: 180,
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
                        _buildTextField(
                          'Firm Name',
                          controller: _firmNameController,
                        ),
                        SizedBox(height: 10),

                        // Contact Number & Email
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Contact Number',
                                isNumber: true,
                                controller: _contactNumberController,
                                maxLength: 11,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Email Address',
                                controller: _emailController,
                              ),
                            ),
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
                                controller: _passwordController,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Confirm password',
                                isPassword: true,
                                controller: _confirmPasswordController,
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
                              onPressed: () {},
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
                              onPressed: () async {
                                final signUpContractor = SignUpContractor();
                                signUpContractor.signUpUser(
                                  context, 
                                  _emailController.text,
                                  _confirmPasswordController.text,
                                  {
                                    'userType': 'Contractor',
                                    'firmName': _firmNameController.text,
                                    'contactNumber': _contactNumberController.text,
                                  },
                                  _validateFields,
                                );
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
    required TextEditingController controller,
    int? maxLength,
  }) {
    return TextField(
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLength)] : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  bool _validateFields() {
    if (_firmNameController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }
}
