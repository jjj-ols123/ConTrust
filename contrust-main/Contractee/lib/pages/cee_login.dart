// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_validation.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/pages/cee_registration.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/contractee services/cee_signin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAgreed = false;
  bool _isLoggingIn = false;

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
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildLoginForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.amber.shade400),
            const SizedBox(height: 12),
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Login to your account',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _isLoggingIn ? null : () async {
            if (!_isAgreed) {
              ConTrustSnackBar.error(
                context,
                'You must agree to the Privacy Policy and Terms of Service.',
              );
              return;
            }

            setState(() => _isLoggingIn = true);
            try {
              final signInContractee = SignInContractee();
              signInContractee.signInContractee(
                context,
                _emailController.text,
                _passwordController.text,
                () => validateFieldsLogin(
                  context,
                  _emailController.text,
                  _passwordController.text,
                ),
              );
            } finally {
              if (mounted) setState(() => _isLoggingIn = false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade400,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isLoggingIn
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Or Continue With',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            SignInGoogleContractee().signInGoogle(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.g_mobiledata, size: 28, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: _isAgreed,
              onChanged: (val) {
                setState(() {
                  _isAgreed = val ?? false;
                });
              },
            ),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    "I agree to the ",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  InkWell(
                    onTap: () => _showPolicyTabs(context),
                    child: Text(
                      "Privacy Policy and Terms of Service",
                      style: TextStyle(
                        color: Colors.teal.shade600,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage()));
          },
          child: Text.rich(
            TextSpan(
              text: "Don't have an account? ",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              children: [
                TextSpan(
                  text: "Sign up",
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
  void _showPolicyTabs(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final dialogWidth = isSmallScreen
        ? screenSize.width * 0.9
        : (isTablet ? screenSize.width * 0.75 : 700.0);
    final dialogHeight = isSmallScreen
        ? screenSize.height * 0.8
        : (isTablet ? screenSize.height * 0.75 : 650.0);

    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.policy_rounded,
                        color: Color(0xFFFFA726),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Privacy Policy & Terms",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1a1a1a),
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.black54,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                TabBar(
                  labelColor: const Color(0xFFFFA726),
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: const Color(0xFFFFA726),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: isSmallScreen ? 15 : 17,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: "Privacy Policy"),
                    Tab(text: "Terms of Service"),
                  ],
                ),
                const Divider(height: 1, thickness: 1),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPolicyContent(isSmallScreen),
                        _buildTermsContent(isSmallScreen),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA726),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      );
  }

  Widget _buildPolicyContent(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Text(
        "ConTrust – Privacy Policy for Contractees (Clients)\n\n"
        "1. Information We Collect\n\n"
        "We collect personal and project-related data including name, contact details, uploaded IDs, project posts, chat messages, and payment information.\n\n"
        "2. Purpose of Data Collection\n\n"
        "We use this data to verify identity, manage projects, enable communication with contractors, and ensure secure contract transactions.\n\n"
        "3. Data Storage and Protection\n\n"
        "All data is securely stored in Firebase Cloud Database using encryption and access control to prevent unauthorized use.\n\n"
        "4. Data Sharing and Use\n\n"
        "ConTrust does not sell or trade user data. Information is shared only with verified contractors or when legally required.\n\n"
        "5. User Rights\n\n"
        "Contractees may access, modify, or delete their personal information and request account removal at any time.\n\n"
        "6. Cookies and Analytics\n\n"
        "ConTrust uses cookies for improving platform functionality but does not collect sensitive data through them.\n\n"
        "7. Data Retention\n\n"
        "Your data is stored as long as needed for project management or as required by law. Once deleted, identifiers are permanently removed.\n\n"
        "8. Privacy Policy Updates\n\n"
        "This policy may be updated from time to time. Updates will be posted on the ConTrust platform.\n\n",
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 15,
          height: 1.7,
          color: Colors.black.withOpacity(0.8),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildTermsContent(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Text(
        "ConTrust – Terms and Conditions for Contractees (Clients)\n\n"
        "1. Acceptance of Terms\n\n"
        "By registering and using the ConTrust platform as a Contractee (Client), you agree to comply with and be bound by these Terms and Conditions.\n\n"
        "2. User Eligibility and Verification\n\n"
        "Contractees must be 18 years old and above and legally capable of entering into contracts.\n\n"
        "3. Use of the Platform\n\n"
        "Contractees may use ConTrust for searching, hiring verified contractors, managing contracts, and tracking project progress.\n\n"
        "4. Responsibilities of Contractees\n\n"
        "Provide accurate project details, respect payment schedules, and maintain professional communication.\n\n"
        "5. Contracts and Transactions\n\n"
        "Contracts are binding between parties. ConTrust acts only as a digital intermediary.\n\n"
        "6. Dispute Resolution\n\n"
        "Disputes must first be resolved via chat; ConTrust may mediate but is not liable for outcomes.\n\n"
        "7. Limitation of Liability\n\n"
        "ConTrust is not liable for project delays, data loss, or misuse beyond its control.\n\n"
        "8. Governing Law\n\n"
        "Governed by the laws of the Republic of the Philippines under San Jose del Monte, Bulacan.\n",
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 15,
          height: 1.7,
          color: Colors.black.withOpacity(0.8),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
