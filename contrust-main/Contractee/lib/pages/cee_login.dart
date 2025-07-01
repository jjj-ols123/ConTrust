import 'package:backend/utils/be_pagetransition.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:contractee/services/cee_signin.dart';
import 'package:contractee/pages/cee_registration.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final BuildContext modalContext;
  const LoginPage({super.key, required this.modalContext});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildLoginForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Login',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 25),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: () async {
            final signInContractee = SignInContractee();
            signInContractee.signInContractee(
              context, 
              _emailController.text,
              _passwordController.text, 
              () => validateFieldsLogin(context, _emailController.text, _passwordController.text)
              );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: const Text('Login'),
        ),
        const SizedBox(height: 15),
        const Text(
          'Or Continue With',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            //Googlesign-in
          },
          child: Center(
            child: Image.asset(
              'assets/googleicon.png',
              height: 50,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            transitionBuilder(context, RegistrationPage());
          },
          child: const Text(
            "Doesn't have an account? Sign up",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.teal,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

}
