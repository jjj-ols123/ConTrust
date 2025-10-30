// ignore_for_file: file_names, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api
import 'dart:io';

import 'package:backend/utils/be_validation.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/Screen/cor_registration.dart';
import 'package:backend/services/contractor services/cor_signin.dart';
import 'package:flutter/material.dart';

class ToLoginScreen extends StatefulWidget {
  const ToLoginScreen({super.key});

  @override
  _ToLoginScreenState createState() => _ToLoginScreenState();
}

class _ToLoginScreenState extends State<ToLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAgreed = false;
  bool _isLoggingIn = false; 

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_isAgreed) {
      ConTrustSnackBar.error(
        context,
        'You must agree to the Privacy Policy and Terms of Service.',
      );
      return;
    }
    
    setState(() => _isLoggingIn = true);
    try {
      final signInContractor = SignInContractor();
      final success = await signInContractor.signInContractor(
        context,
        _emailController.text,
        _passwordController.text,
        () => validateFieldsLogin(
          context,
          _emailController.text,
          _passwordController.text,
        ),
      );
      
      if (success && mounted) {
        ConTrustSnackBar.success(context, 'Login successful!');
      }
    } on SocketException {
      ConTrustSnackBar.error(
        context,
        'No internet connection. Please check your network settings.',
      );
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 1000;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: isPhone ? screenWidth * 0.8 : 600,
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Icon(Icons.business, size: 80, color: Colors.amber.shade400),
            const SizedBox(height: 16),
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be a part of our community and start your journey with us today!',
              style: TextStyle(
                color: Colors.amber.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
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
          onPressed: _isLoggingIn ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            SignInGoogleContractor().signInGoogle(context);
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
                        color: Colors.amber.shade700,
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
        TextButton(
          onPressed: () {},
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text.rich(
            TextSpan(
              text: "Don't have an account? ",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              children: [
                TextSpan(
                  text: "Sign up",
                  style: TextStyle(
                    color: Colors.amber.shade700,
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
        "ConTrust – Privacy Policy for Contractors\n\n"
        "1. Information We Collect\n\n"
        "We collect the following data from contractors:\n\n"
        "• Personal and professional details (name, business name, license number, contact information).\n"
        "• Uploaded documents (permits, certificates, and identification).\n"
        "• Project progress reports, photos, and communication logs.\n\n"
        "2. Purpose of Data Collection\n\n"
        "Your data is used to verify your professional identity, facilitate project management and digital contract creation, display your services to potential clients, and support project tracking.\n\n"
        "3. Data Storage and Security\n\n"
        "All contractor data is stored in Firebase Cloud Database with encryption and restricted access. Only authorized personnel and the account owner can access sensitive data.\n\n"
        "4. Data Sharing and Disclosure\n\n"
        "ConTrust does not sell or trade contractor data. Data may only be shared with verified clients, legal authorities, or for internal dispute resolution.\n\n"
        "5. Data Retention\n\n"
        "Your data is retained while your account is active or as required by law. Upon account deletion, identifiable data will be permanently removed.\n\n"
        "6. User Rights\n\n"
        "Contractors may access, modify, or delete their personal data, and may withdraw consent for data processing at any time.\n\n"
        "7. Policy Updates\n\n"
        "ConTrust may update this Privacy Policy periodically. All changes will be reflected within the platform.\n",
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
        "ConTrust – Terms and Conditions for Contractors\n\n"
        "1. Acceptance of Terms\n\n"
        'By registering as a Contractor on the ConTrust platform, you agree to comply with and be bound by these Terms and Conditions. These terms constitute a legal agreement between you ("Contractor") and ConTrust, governing your access to and use of all platform services and tools.\n\n'
        "2. Eligibility and Verification\n\n"
        "Contractors must be registered businesses or licensed professionals operating within San Jose del Monte, Bulacan.\n\n"
        "Contractors are required to submit valid business permits, professional licenses, and government-issued identification for verification.\n\n"
        "ConTrust reserves the right to verify, suspend, or terminate any account found to have submitted false or misleading information.\n\n"
        "3. Use of the Platform\n\n"
        "Contractors agree to use ConTrust solely for lawful and professional purposes, including:\n\n"
        "• Promoting and showcasing their construction services.\n"
        "• Managing contracts, projects, and communication with clients (contractees).\n"
        "• Submitting project bids and progress reports through the system.\n\n"
        "Any fraudulent or abusive activity will result in immediate account suspension or termination.\n\n"
        "4. Contractor Responsibilities\n\n"
        "Contractors must:\n\n"
        "• Ensure that all information in their profile, bids, and progress reports is accurate and truthful.\n"
        "• Provide real-time project updates using the system's reporting and visualization tools.\n"
        "• Comply with agreed contract terms, including timelines, budget limits, and quality standards.\n"
        "• Maintain professional and respectful communication with clients and ConTrust administrators.\n\n"
        "5. Contracts and Transactions\n\n"
        "Contracts approved and signed through ConTrust are legally binding between the contractor and the client.\n\n"
        "ConTrust serves as a digital intermediary only and is not a party to the contract.\n\n"
        "Payment terms and project deliverables must be clearly outlined in the contract before approval.\n\n"
        "6. Bidding System\n\n"
        "Contractors may submit bids for property projects posted by contractees.\n\n"
        "Once accepted, the contractor must honor the proposal and project scope.\n\n"
        "Manipulation, fake bids, or deliberate misrepresentation will lead to account suspension.\n\n"
        "7. Real-Time Progress Updates\n\n"
        "Contractors must upload timely project updates including photos, cost breakdowns, and work progress.\n\n"
        "ConTrust is not liable for any delays or data inaccuracies provided by the contractor.\n\n"
        "8. Data Privacy and Confidentiality\n\n"
        "All project and client data are securely stored via Firebase Cloud Database.\n\n"
        "Contractors must not share or misuse confidential client data.\n\n"
        "Violations of data privacy may result in legal action and permanent removal from the platform.\n\n"
        "9. Limitation of Liability\n\n"
        "ConTrust shall not be held responsible for:\n\n"
        "• Project disputes, delays, or financial losses between contractors and clients.\n"
        "• Technical issues, data loss, or system downtime.\n"
        "• Third-party tools or materials used within the platform.\n\n"
        "10. Account Termination\n\n"
        "ConTrust reserves the right to terminate contractor accounts for fraudulent activities, contract violations, or unethical conduct.\n\n"
        "11. Updates to Terms\n\n"
        "ConTrust may revise these Terms and Conditions at any time. Continued use of the platform indicates acceptance of any changes.\n\n"
        "12. Governing Law\n\n"
        "These Terms are governed by the laws of the Republic of the Philippines, under the jurisdiction of San Jose del Monte, Bulacan.\n",
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
