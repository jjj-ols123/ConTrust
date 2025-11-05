// ignore_for_file: file_names, deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously
import 'package:backend/utils/be_validation.dart';
import 'package:backend/services/contractor services/cor_signup.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/services/both%20services/be_otp_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contractor/main.dart' as app;
import 'cor_otp_verification.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController firmNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final List<Map<String, dynamic>> _verificationFiles = [];
  final String _profilePhoto = 'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  final bool _isUploadingVerification = false;
  bool _isSigningUp = false;

  final List<String> _selectedSpecializations = [];
  bool _showSpecializationDropdown = false;
  

  final List<String> _availableSpecializations = [
    'General Construction',
    'Residential Construction',
    'Commercial Construction',
    'Interior Design',
    'Exterior Design',
    'Architecture',
    'Electrical Work',
    'Plumbing',
    'HVAC (Heating, Ventilation, Air Conditioning)',
    'Roofing',
    'Flooring',
    'Painting',
    'Landscaping',
    'Kitchen Renovation',
    'Bathroom Renovation',
    'Structural Engineering',
    'Civil Engineering',
    'Project Management',
    'Home Improvement',
    'Maintenance & Repair',
    'Concrete Work',
    'Masonry',
    'Carpentry',
    'Welding',
    'Flooring Installation',
    'Wall Finishing',
    'Window Installation',
    'Door Installation',
    'Tile Work',
    'Drywall',
    'Insulation',
    'Solar Installation',
    'Smart Home Integration',
  ];

  bool get canSignUp =>
      _verificationFiles.isNotEmpty && !_isUploadingVerification;

  bool _pwHasMin = false;
  bool _pwHasMax = false;
  bool _pwHasUpper = false;
  bool _pwHasNumber = false;
  bool _pwHasSpecial = false;
  bool _isEmailGmail = false;
  bool _passwordVisible = false;

  bool _confirmPasswordVisible = false;
  bool _isAgreed = false;
  bool _isCheckingFirmName = false;
  String? _firmNameError;
  bool _emailVerified = false;
  final OtpService _otpService = OtpService();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;
  bool _isEmailFocused = false;

  Future<void> _checkFirmNameAvailability(String firmName) async {
    if (firmName.trim().isEmpty) {
      setState(() {
        _firmNameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingFirmName = true;
      _firmNameError = null;
    });

    try {
      final existingContractor = await Supabase.instance.client
          .from('Contractor')
          .select('contractor_id, firm_name')
          .ilike('firm_name', firmName.trim())
          .limit(1)
          .maybeSingle();

      setState(() {
        _isCheckingFirmName = false;
        _firmNameError = existingContractor != null
            ? 'This firm name is already taken. Please choose a different name.'
            : null;
      });
    } catch (e) {
      setState(() {
        _isCheckingFirmName = false;
        _firmNameError = null; 
      });
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).clearSnackBars();
    
    if (!isValidEmail(emailController.text)) {
      ConTrustSnackBar.error(
        context,
        'Please enter a valid Gmail address (example@gmail.com).',
      );
      return;
    }
    
    if (passwordController.text.length < 6) {
      ConTrustSnackBar.error(
        context,
        'Password must be at least 6 characters long.',
      );
      return;
    }
    
    if (passwordController.text.length > 15) {
      ConTrustSnackBar.error(
        context,
        'Password must be no more than 15 characters long.',
      );
      return;
    }
    
    final hasUppercase = passwordController.text.contains(RegExp(r'[A-Z]'));
    final hasNumber = passwordController.text.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasNumber || !hasSpecialChar) {
      ConTrustSnackBar.error(
        context,
        'Password must include uppercase, number and special character.',
      );
      return;
    }
    
    if (passwordController.text != confirmPasswordController.text) {
      ConTrustSnackBar.error(
        context,
        'Passwords do not match.',
      );
      return;
    }

    if (!_isAgreed) {
      ConTrustSnackBar.error(
        context,
        'You must agree to the Privacy Policy and Terms of Service.',
      );
      return;
    }

    if (_selectedSpecializations.isEmpty) {
      ConTrustSnackBar.error(
        context,
        'Please select at least one specialization.',
      );
      return;
    }

    if (!_emailVerified) {
      setState(() => _isSigningUp = true);
      
      try {
        await _otpService.sendOtp(
          email: emailController.text,
          userType: 'contractor',
        );

        if (!mounted) return;

        setState(() => _isSigningUp = false);

        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: emailController.text,
              userType: 'contractor',
              registrationData: {
                'user_type': "contractor",
                'firmName': firmNameController.text,
                'contactNumber': _formatPhone(contactNumberController.text),
                'address': addressController.text,
                'specialization': _selectedSpecializations,
                'verificationFiles': _verificationFiles,
                'profilePhoto': _profilePhoto,
              },
            ),
          ),
        );

        if (!mounted) return;

        if (verified == true) {
          setState(() => _emailVerified = true);
          await _completeSignUp();
        } else {
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSigningUp = false);
        ConTrustSnackBar.error(
          context,
          'Failed to send OTP: ${e.toString()}',
        );
        return;
      }
    } else {
      await _completeSignUp();
    }
  }

  Future<void> _completeSignUp() async {
    setState(() => _isSigningUp = true);
    app.setRegistrationState(true);

    try {
      final signUpContractor = SignUpContractor();
      final success = await signUpContractor.signUpContractor(
        context,
        emailController.text,
        passwordController.text,
        "contractor",
        {
          'user_type': "contractor",
          'firmName': firmNameController.text,
          'contactNumber': _formatPhone(contactNumberController.text),
          'address': addressController.text,
          'specialization': _selectedSpecializations, 
          'verificationFiles': _verificationFiles,
          'profilePhoto': _profilePhoto,
        },
        () => validateFieldsContractor(
          context,
          firmNameController.text,
          _formatPhone(contactNumberController.text),
          emailController.text,
          passwordController.text,
          confirmPasswordController.text,
          firmNameError: _firmNameError,
        ),
      );

      setState(() => _isSigningUp = false);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();

        app.setPreventAuthNavigation(true);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            Future.delayed(const Duration(seconds: 2), () {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            });
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              elevation: 12,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              title: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                        ),
                    padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                      size: 40,
                        ),
                      ),
                  const SizedBox(height: 10),
                      const Text(
                        'Success',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                      fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
              content: const Text(
                    'Account created! Please wait for verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                  fontSize: 15,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
            );
          },
        );

        Future.delayed(const Duration(seconds: 2), () async {
          if (!mounted) return;
          try {
            await Supabase.instance.client.auth.signOut();
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            //
          }

          app.setRegistrationState(false);
          app.setPreventAuthNavigation(false);

          if (!mounted) return;

          context.go('/logincontractor');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningUp = false);
      }
    }
  }

  void _validatePassword() {
    final s = passwordController.text;
    setState(() {
      _pwHasMin = s.length >= 6;
      _pwHasMax = s.length <= 20;
      _pwHasUpper = s.contains(RegExp(r'[A-Z]'));
      _pwHasNumber = s.contains(RegExp(r'[0-9]'));
      _pwHasSpecial = s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void _validateEmail() {
    final e = emailController.text.trim();
    setState(() {
      _isEmailGmail = RegExp(r'^[^@]+@gmail\.com$').hasMatch(e);
      if (_emailVerified) {
        _emailVerified = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    contactNumberController.text = '+63';
    contactNumberController.selection = TextSelection.fromPosition(
      TextPosition(offset: contactNumberController.text.length),
    );
    passwordController.addListener(_validatePassword);
    emailController.addListener(_validateEmail);
    
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
    
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  String _formatPhone(String phone) {
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }

    if (!digitsOnly.startsWith('63')) {
      digitsOnly = '63$digitsOnly';
    }

    return '+$digitsOnly';
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@gmail\.com$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 600;
    final isSmallScreen = screenWidth < 600;
    

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: const AssetImage('assets/images/bgloginscreen.jpg'),
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
                  child: Stack(
                    children: [
                      Row(
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
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                context.go('/logincontractor');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              width: isPhone ? screenWidth * 0.9 : 700,
                              padding: const EdgeInsets.all(20),
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
                              child: _buildRegistrationForm(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationUploadDialog(
    BuildContext context,
    VoidCallback onUpdate,
  ) async {

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.upload_file,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Upload Verification Documents',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: StatefulBuilder(
                        builder:
                            (context, setState) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Please upload clear photos of your ID, business license, or other documents.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'jpg',
                                            'jpeg',
                                            'png',
                                            'pdf',
                                            'doc',
                                            'docx',
                                          ],
                                          allowMultiple: false,
                                        );
                                    if (result != null &&
                                        result.files.isNotEmpty) {
                                      final file = result.files.first;
                                      final bytes = file.bytes;
                                      if (bytes != null) {
                                        final isImage = [
                                          'jpg',
                                          'jpeg',
                                          'png',
                                        ].contains(
                                          file.extension?.toLowerCase(),
                                        );
                                        final duplicate = _verificationFiles
                                            .any(
                                              (f) =>
                                                  listEquals(f['bytes'], bytes),
                                            );
                                        if (duplicate) {
                                          ConTrustSnackBar.warning(
                                            context,
                                            'This file is already selected',
                                          );
                                          return;
                                        }
                                        setState(
                                          () => _verificationFiles.add({
                                            'name': file.name,
                                            'bytes': bytes,
                                            'isImage': isImage,
                                          }),
                                        );
                                        onUpdate();
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Pick File'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade100,
                                    foregroundColor: Colors.amber.shade900,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_verificationFiles.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _verificationFiles.asMap().entries.map((
                                          e,
                                        ) {
                                          final idx = e.key;
                                          final file = e.value;
                                          final isImage =
                                              file['isImage'] as bool;
                                          return Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child:
                                                    isImage
                                                        ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.memory(
                                                            file['bytes'],
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                        : Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .insert_drive_file,
                                                              size: 24,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            Text(
                                                              file['name'].length >
                                                                      10
                                                                  ? '${file['name'].substring(0, 10)}...'
                                                                  : file['name'],
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                              ),
                                              GestureDetector(
                                                onTap:
                                                    () => setState(
                                                      () => _verificationFiles
                                                          .removeAt(idx),
                                                    ),
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.black54,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 600;

    final hasMinLength = _pwHasMin;
    final hasMaxLength = _pwHasMax;
    final hasUppercase = _pwHasUpper;
    final hasNumber = _pwHasNumber;
    final hasSpecialChar = _pwHasSpecial;

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
        Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Join ConTrust',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Register as a Contractor',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              'Be a part of our community and start your journey with us today!',
              style: TextStyle(
                color: Colors.amber.shade600,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: firmNameController,
          decoration: InputDecoration(
            labelText: 'Firm / Business Name',
            prefixIcon: const Icon(Icons.business),
            suffixIcon: _isCheckingFirmName
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _firmNameError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorText: _firmNameError,
          ),
          onChanged: (value) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && firmNameController.text == value) {
                _checkFirmNameAvailability(value);
              }
            });
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            prefixIcon: const Icon(Icons.location_on),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSpecializationDropdown = !_showSpecializationDropdown;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedSpecializations.isEmpty
                            ? 'Select Specializations (Tap to choose)'
                            : '${_selectedSpecializations.length} specialization(s) selected',
                        style: TextStyle(
                          color: _selectedSpecializations.isEmpty
                              ? Colors.grey.shade600
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      _showSpecializationDropdown
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedSpecializations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedSpecializations.map((spec) {
                  return Chip(
                    label: Text(spec),
                    backgroundColor: Colors.amber.shade100,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedSpecializations.remove(spec);
                      });
                    },
                    labelStyle: const TextStyle(fontSize: 13),
                  );
                }).toList(),
              ),
            ],
            if (_showSpecializationDropdown) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableSpecializations.length,
                  itemBuilder: (context, index) {
                    final spec = _availableSpecializations[index];
                    final isSelected = _selectedSpecializations.contains(spec);
                    
                    return ListTile(
                      dense: true,
                      title: Text(
                        spec,
                        style: TextStyle(
                          color: isSelected ? Colors.amber.shade700 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.amber.shade700, size: 20)
                          : const Icon(Icons.circle_outlined, size: 20),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSpecializations.remove(spec);
                          } else {
                            _selectedSpecializations.add(spec);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        isPhone
            ? Column(
              children: [
                TextFormField(
                  controller: contactNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(13),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  onChanged: (value) {
                    if (!value.startsWith('+63')) {
                      contactNumberController.text = '+63';
                      contactNumberController
                          .selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: contactNumberController.text.length,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Gmail only)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: _isEmailFocused
                        ? (_isEmailGmail
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : const Icon(Icons.cancel, color: Colors.red))
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            )
            : Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: contactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: const Icon(Icons.phone),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(13),
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                    onChanged: (value) {
                      if (!value.startsWith('+63')) {
                        contactNumberController.text = '+63';
                        contactNumberController
                            .selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: contactNumberController.text.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address (Gmail only)',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: _isEmailFocused
                          ? (_isEmailGmail
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : const Icon(Icons.cancel, color: Colors.red))
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        const SizedBox(height: 12),

        TextFormField(
          controller: passwordController,
          focusNode: _passwordFocusNode,
          obscureText: !_passwordVisible,
          maxLength: 15,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed:
                  () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_isPasswordFocused) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
        ),
              child: isPhone
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            checkRow('Minimum 6 characters', hasMinLength),
                        const SizedBox(height: 6),
            checkRow('Maximum 15 characters', hasMaxLength),
                        const SizedBox(height: 6),
                        checkRow('At least one uppercase', hasUppercase),
                        const SizedBox(height: 6),
            checkRow('At least one number', hasNumber),
                        const SizedBox(height: 6),
            checkRow('At least one special character', hasSpecialChar),
          ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            checkRow('Minimum 6 characters', hasMinLength),
                            const SizedBox(width: 16),
                            checkRow('Maximum 15 characters', hasMaxLength),
                            const SizedBox(width: 16),
                            checkRow('At least one uppercase', hasUppercase),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            checkRow('At least one number', hasNumber),
                            const SizedBox(width: 16),
                            checkRow('At least one special character', hasSpecialChar),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed:
                  () => setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible,
                  ),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),
        isPhone
            ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isUploadingVerification
                            ? null
                            : () => _showVerificationUploadDialog(
                              context,
                              () => setState(() {}),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _isUploadingVerification ? 'Uploading...' : 'Verify ID',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        canSignUp && !_isSigningUp
                            ? () => _handleSignUp()
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child:
                        _isSigningUp
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            )
            : Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isUploadingVerification
                            ? null
                            : () => _showVerificationUploadDialog(
                              context,
                              () => setState(() {}),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _isUploadingVerification ? 'Uploading...' : 'Verify ID',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        canSignUp && !_isSigningUp
                            ? () => _handleSignUp()
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child:
                        _isSigningUp
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
        const SizedBox(height: 12),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  InkWell(
                    onTap: () => _showPolicyTabs(context),
                    child: Text(
                      "Privacy Policy and Terms of Service",
                      style: TextStyle(
                        color: Colors.amber.shade600,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/logincontractor');
            }
          },
          child: Text.rich(
            TextSpan(
              text: "Already have an account? ",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              children: [
                TextSpan(
                  text: "Login here",
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

  @override
  void dispose() {
    passwordController.removeListener(_validatePassword);
    emailController.removeListener(_validateEmail);
    
    _emailFocusNode.removeListener(() {});
    _passwordFocusNode.removeListener(() {});
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    firmNameController.dispose();
    contactNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    super.dispose();
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
