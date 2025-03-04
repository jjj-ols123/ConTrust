// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  

  final authService = AuthService();

  void signUp() async { 

    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (password != confirmPass) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return; 
    }

    try { 

      if (_validateFields(context)) { 
        await authService.signUp(email: email, password: password, data: {
            'full_name' : '${_fNameController.text} ${_lNameController.text}',
            'user_type' : 'contractee',
        });
        Navigator.pop(context);
      }
    } 
    
    on PostgrestException catch (error) { 
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } 
    
    catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unexpected error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
  
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('bgloginscreen.jpg'),
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
        style: const TextStyle(color: Colors.white)
      ), 
      const SizedBox(height: 10),
      TextField(
        controller: _lNameController,  
        decoration: const InputDecoration(labelText: 'Last Name'), 
        style: const TextStyle(color: Colors.white)
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _emailController, 
        decoration: const InputDecoration(labelText: 'Email'), 
        keyboardType: TextInputType.emailAddress,  
        style: const TextStyle(color: Colors.white)
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _passwordController, 
        decoration: const InputDecoration(labelText: 'Password'), 
        obscureText: true,  
        style: const TextStyle(color: Colors.white)
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _confirmPasswordController, 
        decoration: const InputDecoration(labelText: 'Confirm Password'), 
        obscureText: true,  
        style: const TextStyle(color: Colors.white)
      ),
      const SizedBox(height: 20),

      ElevatedButton(
        onPressed: () async{
            signUp();
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

  bool _validateFields(BuildContext context) {
    if (_fNameController.text.isEmpty ||
        _lNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }
}




