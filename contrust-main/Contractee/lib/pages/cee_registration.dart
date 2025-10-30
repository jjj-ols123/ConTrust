// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_validation.dart';
import 'package:backend/services/contractee services/cee_signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _phoneController = TextEditingController(text: '+63');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSigningUp = false;

  @override
  void initState() {
    super.initState();
    _phoneController.selection = TextSelection.collapsed(offset: 3);
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+63')) {
      return phone;
    }
    
    String digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }
    return '+63$digitsOnly';
  }

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
    InputDecoration inputStyle(String label, IconData icon, {Widget? suffix}) {
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
          decoration: inputStyle('First Name', Icons.person),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _lNameController,
          decoration: inputStyle('Last Name', Icons.person_outline),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: inputStyle('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _addressController,
          decoration: inputStyle('Address', Icons.home_outlined),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            LengthLimitingTextInputFormatter(13),
          ],
          onChanged: (value) {
            if (!value.startsWith('+63')) {
              _phoneController.value = TextEditingValue(
                text: '+63',
                selection: TextSelection.collapsed(offset: 3),
              );
            }
          },
          decoration: inputStyle('Phone Number', Icons.phone_android_outlined).copyWith(
            helperText: 'Enter mobile number',
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: inputStyle(
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
          decoration: inputStyle(
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
            if (_isSigningUp) return; 
            setState(() => _isSigningUp = true); 
            try {
              final signUpContractee = SignUpContractee();
              signUpContractee.signUpContractee(
                context,
                _emailController.text,
                _confirmPasswordController.text,
                'contractee',
                {
                  'user_type': 'contractee',
                  'address': _addressController.text,
                  'phone_number': _formatPhone(_phoneController.text),
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
            } finally {
              if (mounted) setState(() => _isSigningUp = false); 
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSigningUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amber,
                  ),
                )
              : const Text(
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

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
