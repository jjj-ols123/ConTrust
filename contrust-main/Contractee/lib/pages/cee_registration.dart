// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:backend/services/contractee services/cee_signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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

  final String _profilePhoto = '';

  String get _fullName => '${_fNameController.text.trim()} ${_lNameController.text.trim()}';

  bool _isSigningUp = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _pwHasMin = false;
  bool _pwHasMax = false;
  bool _pwHasUpper = false;
  bool _pwHasNumber = false;
  bool _pwHasSpecial = false;
  bool _isEmailGmail = false;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _phoneController.selection = TextSelection.collapsed(offset: 3);
    _passwordController.addListener(_validatePassword);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _emailController.removeListener(_validateEmail);
    _fNameController.dispose();
    _lNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@gmail\.com$').hasMatch(email);
  }

  void _validatePassword() {
    final s = _passwordController.text;
    setState(() {
      _pwHasMin = s.length >= 6;
      _pwHasMax = s.length <= 15;
      _pwHasUpper = s.contains(RegExp(r'[A-Z]'));
      _pwHasNumber = s.contains(RegExp(r'[0-9]'));
      _pwHasSpecial = s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void _validateEmail() {
    final e = _emailController.text.trim();
    setState(() {
      _isEmailGmail = RegExp(r'^[^@]+@gmail\.com$').hasMatch(e);
    });
  }

  Future<void> _handleSignUp() async {
    if (!isValidEmail(_emailController.text)) {
      ConTrustSnackBar.error(context, 'Please enter a valid Gmail address (example@gmail.com).');
      return;
    }
    if (_passwordController.text.length < 6) {
      ConTrustSnackBar.error(context, 'Password must be at least 6 characters long.');
      return;
    }

    if (_passwordController.text.length > 15) {
      ConTrustSnackBar.error(context, 'Password must be no more than 15 characters long.');
      return;
    }
    
    final hasUppercase = _passwordController.text.contains(RegExp(r'[A-Z]'));
    final hasNumber = _passwordController.text.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasNumber || !hasSpecialChar) {
      ConTrustSnackBar.error(context, 'Password must include uppercase, number and special character.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ConTrustSnackBar.error(context, 'Passwords do not match.');
      return;
    }
    if (!_isAgreed) {
      ConTrustSnackBar.error(
        context,
        'You must agree to the Privacy Policy and Terms of Service.',
      );
      return;
    }

    setState(() => _isSigningUp = true);
    try {
      final signUpContractee = SignUpContractee();
      final success = await signUpContractee.signUpContractee(
        context,
        _emailController.text,
        _passwordController.text,
        "contractee",
        {
          'user_type': "contractee",
          'full_name': _fullName,
          'phone_number': _formatPhone(_phoneController.text),
          'address': _addressController.text,
          'profilePhoto': _profilePhoto,
        },
        () => validateFieldsContractee(
          context,
          _fullName,
          _phoneController.text,
          _emailController.text,
          _passwordController.text,
          _confirmPasswordController.text,
        ),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Success',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Account created! Please check your email for verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1, vertical: 20),
            elevation: 8,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: const AssetImage('assets/bgloginscreen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: isSmallScreen ? 4 : 6,
                        height: isSmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Text(
                        'ConTrust',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1a1a1a),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
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
              ])
          ]
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

    final hasMinLength = _pwHasMin;
    final hasMaxLength = _pwHasMax;
    final hasUppercase = _pwHasUpper;
    final hasNumber = _pwHasNumber;
    final hasSpecialChar = _pwHasSpecial;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final bool isMobile = screenWidth < 600;

    Widget checkRow(String label, bool ok) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ok ? Colors.green : Colors.red,
            ),
          ),
        ],
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
          decoration: inputStyle(
            'Email (Gmail only)', 
            Icons.email_outlined,
            suffix: _isEmailGmail
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.cancel, color: Colors.red),
          ),
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
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          maxLength: 15,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password must contain:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                checkRow('Minimum 6 characters', hasMinLength),
                checkRow('Maximum 15 characters', hasMaxLength),
                checkRow('At least one uppercase letter', hasUppercase),
                checkRow('At least one number', hasNumber),
                checkRow('At least one special character', hasSpecialChar),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
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
                        color: Colors.amber.shade600,
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
        ElevatedButton(
          onPressed: _isSigningUp ? null : _handleSignUp,
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
            context.go('/login');
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
                _buildFooter(context, isDesktop, isTablet, isMobile),
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

  Widget _buildFooter(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = 10;
    final double logoFontSize = isMobile ? 20 : 24;
    final double logoHeight = isMobile ? 20 : 24;
    final double logoWidth = isMobile ? 3 : 4;
    
    return Container(
    width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: logoWidth,
                height: logoHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'ConTrust',
                style: TextStyle(
                  fontSize: logoFontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
            child: Text(
              'Building trust in construction, one contract at a time.',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
