// ignore_for_file: file_names, deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously
import 'package:backend/utils/be_validation.dart';
import 'package:backend/services/contractor services/cor_signup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

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
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController addressController = TextEditingController(); // added

  // Change to store file data (name, bytes, type)
  final List<Map<String, dynamic>> _verificationFiles = [];  // [{ 'name': String, 'bytes': Uint8List, 'isImage': bool }]

  final bool _isUploadingVerification = false;
  bool _isSigningUp = false;  // Add this

  bool get canSignUp => _verificationFiles.isNotEmpty && !_isUploadingVerification;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 1000;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgloginscreen.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: isPhone ? screenWidth * 0.9 : 700,
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
                    child: _buildRegistrationForm(context),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 30,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
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
          ],
        ),
      ),
    );
  }

  void _showVerificationUploadDialog(BuildContext context, VoidCallback onUpdate) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Verification Documents'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please upload clear photos of your ID, business license, or other documents.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],  
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    final bytes = file.bytes;
                    if (bytes != null) {
                      final isImage = ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());
                      final duplicate = _verificationFiles.any((f) => listEquals(f['bytes'], bytes));
                      if (duplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This file is already selected')),
                        );
                        return;
                      }
                      setState(() => _verificationFiles.add({
                        'name': file.name,
                        'bytes': bytes,
                        'isImage': isImage,
                      }));
                      onUpdate();  // trigger parent rebuild to enable sign up button
                    }
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Pick File'),
              ),
              const SizedBox(height: 16),
              if (_verificationFiles.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _verificationFiles.asMap().entries.map((e) {
                    final idx = e.key;
                    final file = e.value;
                    final isImage = file['isImage'] as bool;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(file['bytes'], fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.insert_drive_file, size: 24, color: Colors.grey),
                                    Text(
                                      file['name'].length > 10 ? '${file['name'].substring(0, 10)}...' : file['name'],
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _verificationFiles.removeAt(idx)),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Image.asset('assets/images/logo3.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text(
              'Join ConTrust',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Register as a Contractor',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 4),
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
          controller: firmNameController,
          decoration: InputDecoration(
            labelText: 'Firm Name',
            prefixIcon: const Icon(Icons.business),
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
        const SizedBox(height: 18),
        isPhone
            ? Column(
                children: [
                  TextFormField(
                    controller: contactNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
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
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: emailController,
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
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: contactNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: emailController,
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
                  ),
                ],
              ),
        const SizedBox(height: 18),
        isPhone
            ? Column(
                children: [
                  TextFormField(
                    controller: passwordController,
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
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                      controller: passwordController,
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
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
        const SizedBox(height: 25),
        isPhone
            ? Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploadingVerification
                          ? null
                          : () => _showVerificationUploadDialog(context, () => setState(() {})),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _isUploadingVerification
                            ? 'Uploading...'
                            : 'Verify ID',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSignUp && !_isSigningUp  
                          ? () async {
                              setState(() => _isSigningUp = true);  
                              try {
                                final signUpContractor = SignUpContractor();
                                await signUpContractor.signUpContractor(
                                  context,
                                  emailController.text,
                                  passwordController.text,
                                  "contractor",
                                  {
                                    'user_type': "contractor",
                                    'firmName': firmNameController.text,
                                    'contactNumber': contactNumberController.text,
                                    'address': addressController.text, 
                                    'verificationFiles': _verificationFiles,  
                                  },
                                  () => validateFieldsContractor(
                                    context,
                                    firmNameController.text,
                                    contactNumberController.text,
                                    emailController.text,
                                    passwordController.text,
                                    confirmPasswordController.text,
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isSigningUp = false);  
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isSigningUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
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
                      onPressed: _isUploadingVerification
                          ? null
                          : () => _showVerificationUploadDialog(context, () => setState(() {})),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _isUploadingVerification
                            ? 'Uploading...'
                            : 'Verify ID',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canSignUp && !_isSigningUp  // Disable during sign-up
                          ? () async {
                              setState(() => _isSigningUp = true);  // Start loading
                              try {
                                final signUpContractor = SignUpContractor();
                                await signUpContractor.signUpContractor(
                                  context,
                                  emailController.text,
                                  passwordController.text,
                                  "contractor",
                                  {
                                    'user_type': "contractor",
                                    'firmName': firmNameController.text,
                                    'contactNumber': contactNumberController.text,
                                    'address': addressController.text, // added
                                    'verificationFiles': _verificationFiles,
                                  },
                                  () => validateFieldsContractor(
                                    context,
                                    firmNameController.text,
                                    contactNumberController.text,
                                    emailController.text,
                                    passwordController.text,
                                    confirmPasswordController.text,
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isSigningUp = false);  // Stop loading
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isSigningUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            Navigator.pop(context);
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
    firmNameController.dispose();
    contactNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose(); 
    super.dispose();
  }
}
