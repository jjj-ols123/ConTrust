// ignore_for_file: deprecated_member_use
import 'package:backend/utils/be_pagetransition.dart';
import 'package:contractor/Screen/cor_registration.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('bgloginscreen.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(height: 40, color: Colors.amber),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'logo3.png',
                      width: screenWidth * 0.18,
                    ),
                    const SizedBox(height: 25),

                    Container(
                      width: screenWidth > 1000 ? 1000 : 400,
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 28),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900.withOpacity(0.85)
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.amber.withOpacity(0.15)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.amber.withOpacity(0.25)
                              : Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.amber.shade200
                                  : Colors.grey.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose an option to proceed',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                transitionBuilder(context, ToLoginScreen());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 8,
                                shadowColor:
                                    Colors.amber.withOpacity(0.4),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                transitionBuilder(context, RegisterScreen());
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.amber.shade700,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
