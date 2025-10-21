// ignore_for_file: deprecated_member_use, no_leading_underscores_for_local_identifiers

import 'package:backend/utils/be_validation.dart';
import 'package:backend/services/contractee services/cee_signup.dart';
import 'package:flutter/material.dart';
import 'package:contractee/pages/cee_login.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade100,
            Colors.white,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 800;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: isDesktop ? 850 : double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.amber.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 60, horizontal: 30),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 30),
                                  Text(
                                    "Join ConTrust",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Connect with reliable contractors and manage your projects securely and efficiently.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            flex: 2,
                            child: _buildRegistrationForm(context),
                          ),
                        ],
                      )
                    : _buildRegistrationForm(context),
              );
            },
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRegistrationForm(BuildContext context) {
    InputDecoration _inputStyle(String label, IconData icon, {Widget? suffix}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.person_add, size: 60, color: Colors.amber),
        const SizedBox(height: 15),
        const Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fill the details below to register',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _fNameController,
          decoration: _inputStyle('First Name', Icons.person),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _lNameController,
          decoration: _inputStyle('Last Name', Icons.person_outline),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputStyle('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _addressController,
          decoration: _inputStyle('Address', Icons.home_outlined),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputStyle('Phone Number', Icons.phone_android_outlined),
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
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
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
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() => _isConfirmPasswordVisible =
                    !_isConfirmPasswordVisible);
              },
            ),
          ),
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
                'address': _addressController.text,
                'phone_number': _phoneController.text,
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
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
          child: Text.rich(
            TextSpan(
              text: "Already have an account? ",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              children: [
                TextSpan(
                  text: "Login",
                  style: TextStyle(
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
