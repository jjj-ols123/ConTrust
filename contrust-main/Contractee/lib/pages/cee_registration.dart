// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_validation.dart';
import 'package:contractee/services/cee_signup.dart';
import 'package:contractor/main.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(bgScreen),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
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
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
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
    return [
      TextField(
          controller: _fNameController,
          decoration: const InputDecoration(labelText: 'First Name'),
          style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 10),
      TextField(
          controller: _lNameController,
          decoration: const InputDecoration(labelText: 'Last Name'),
          style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 10),
      TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 10),
      TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 20),
      TextField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(labelText: 'Confirm Password'),
          obscureText: true,
          style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 20),
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
                'full_name': '${_fNameController.text} ${_lNameController.text}',
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
          backgroundColor: Colors.yellow,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    ];
  }

}
