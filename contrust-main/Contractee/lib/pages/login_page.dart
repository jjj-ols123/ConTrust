// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:contractee/blocs/signin_bloc.dart';
import 'package:contractee/pages/registration_page.dart';
import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.yellow[700],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: isWideScreen
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: _buildLoginForm(context),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 450,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        child: Image.asset(
                                          'side_image.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
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
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
              signInContractee.signInUser(
                context,
                _emailController.text,
                _passwordController.text,
                _validateFields
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationPage(),
              ),
            );
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

  bool _validateFields() { 
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) { 
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