// ignore_for_file: file_names, deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously

import 'package:contractor/blocs/signupcontractor_bloc.dart';
import 'package:contractor/blocs/validatefields.dart';
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

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

              // Back Button
              Positioned(
                top: 50,
                left: 30,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Image.asset(
                      'logo3.png',
                      width: isMobile ? constraints.maxWidth * 0.25 : constraints.maxWidth * 0.2,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Simplify your contracts. Secure results!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Times New Roman',
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Container(
                    width: isMobile ? double.infinity : constraints.maxWidth * 0.5,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Register as a Contractor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField('Firm Name', controller: _firmNameController),
                        const SizedBox(height: 10),

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
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField('Email Address', controller: _emailController),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Password',
                                isPassword: true,
                                controller: _passwordController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Confirm Password',
                                isPassword: true,
                                controller: _confirmPasswordController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                'Verify(ID)',
                                Colors.amber,
                                Colors.black,
                                () {}, 
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildButton(
                                'Sign Up',
                                Colors.green,
                                Colors.white,
                                () async {
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
                                    () => validateFieldsContractor(context, _emailController.text, _contactNumberController.text,
                                    _emailController.text, _passwordController.text, _confirmPasswordController.text
                                    )
                                  );
                                },
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
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    {bool isPassword = false,
    bool isNumber = false,
    TextEditingController? controller,
    int? maxLength,}
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ]
          : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Center(child: Text(text, style: TextStyle(color: textColor))),
    );
  }
}
