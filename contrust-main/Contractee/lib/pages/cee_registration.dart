// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_validation.dart';
import 'package:contractee/services/cee_signup.dart';
import 'package:contractor/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'logo.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ..._buildRegistrationFields(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRegistrationFields(BuildContext context) {
    InputDecoration _inputStyle(String label, IconData icon, {Widget? suffix}) {
      return InputDecoration(
        prefixIcon: Icon(icon, color: Colors.yellowAccent),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.yellowAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07), 
      );
    }

    return [
      TextField(
        controller: _fNameController,
        decoration: _inputStyle('First Name', Icons.person),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: _lNameController,
        decoration: _inputStyle('Last Name', Icons.person_outline),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputStyle('Email', Icons.email_outlined),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: _inputStyle(
          'Password',
          Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.yellowAccent,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmPasswordVisible,
        decoration: _inputStyle(
          'Confirm Password',
          Icons.lock_reset,
          suffix: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.yellowAccent,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 25),
      ElevatedButton(
        onPressed: () async {
          final signUpContractee = SignUpContractee();
          signUpContractee.signUpContractee(
            context,
            _emailController.text,
            _confirmPasswordController.text,
            'contractee',
            {
              'user_type': 'contractee',
              'address': 'address',
              'full_name':
                  '${_fNameController.text} ${_lNameController.text}',
            },
            () => validateFieldsContractee(
              context,
              _fNameController.text,
              _lNameController.text,
              _emailController.text,
              _passwordController.text,
              _confirmPasswordController.text,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 6,
        ),
        child: const Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }
}
