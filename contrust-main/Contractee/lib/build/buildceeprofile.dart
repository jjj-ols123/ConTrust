// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class CeeProfileBuildMethods {
  static Widget buildHeader(BuildContext context, String title) {
    return const SizedBox.shrink();
  }

  static Widget buildStickyHeader(String title) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  static Widget buildMainContent(String selectedTab, Function buildAboutContent) {
    switch (selectedTab) {
      case 'About':
        return buildAboutContent();
      default:
    return buildAboutContent();
    }
  }

  static Widget buildMobileLayout({
    required String fullName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required Widget mainContent,
    required VoidCallback? onUploadPhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade700, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey.shade100,
                        child: ClipOval(
                          child: (profileImage != null && profileImage.isNotEmpty)
                              ? Image.network(
                                  profileImage,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      profileUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image(
                                          image: const AssetImage('assets/defaultpic.png'),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.person, size: 40, color: Colors.grey.shade400);
                                          },
                                        );
                                      },
                                    );
                                  },
                                )
                              : Image.network(
                                  profileUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image(
                                      image: const AssetImage('assets/defaultpic.png'),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person, size: 40, color: Colors.grey.shade400);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    if (onUploadPhoto != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: onUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
              child: mainContent,
          ),
        ],
      ),
    );
  }

  static Widget buildDesktopLayout({
    required String fullName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required Widget mainContent,
    required VoidCallback? onUploadPhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Container(
                  width: 280, 
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber.shade700, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey.shade100,
                              child: ClipOval(
                                child: (profileImage != null && profileImage.isNotEmpty)
                                    ? Image.network(
                                        profileImage,
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            profileUrl,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.person, size: 45, color: Colors.grey.shade400);
                                            },
                                          );
                                        },
                                      )
                                    : Image.network(
                                        profileUrl,
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.person, size: 45, color: Colors.grey.shade400);
                                        },
                                      ),
                              ),
                            ),
                          ),
                          if (onUploadPhoto != null)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: onUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6)
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              child: mainContent,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAbout({
    required BuildContext context,
    required String fullName,
    required String contactNumber,
    required String address,
    required String email,
    required bool isEditingFullName,
    required bool isEditingContact,
    required bool isEditingAddress,
    required TextEditingController fullNameController,
    required TextEditingController contactController,
    required TextEditingController addressController,
    required VoidCallback toggleEditFullName,
    required VoidCallback toggleEditContact,
    required VoidCallback toggleEditAddress,
    required VoidCallback saveFullName,
    required VoidCallback saveContact,
    required VoidCallback saveAddress,
    required String contracteeId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildReadOnlyField(
            'Email',
            email.isEmpty ? 'No email provided' : email,
            Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildInfoField(
            'Full Name',
            fullName,
            Icons.person_outline,
            isEditingFullName,
            fullNameController,
            toggleEditFullName,
            saveFullName,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Contact Number',
            contactNumber,
            Icons.phone_outlined,
            isEditingContact,
            contactController,
            toggleEditContact,
            saveContact,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Address',
            address,
            Icons.location_on_outlined,
            isEditingAddress,
            addressController,
            toggleEditAddress,
            saveAddress,
          ),
        ],
      ),
      ),
    );
  }

  static Widget _buildInfoField(
    String label,
    String value,
    IconData icon,
    bool isEditing,
    TextEditingController controller,
    VoidCallback onEdit,
    VoidCallback onSave,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (isEditing)
                Row(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      child: Text('Cancel', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onSave,
                      child: Text('Save', style: TextStyle(fontSize: 13, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEditing)
            TextField(
              controller: controller,
              keyboardType: label == 'Contact Number' ? TextInputType.phone : TextInputType.text,
              inputFormatters: label == 'Contact Number' 
                ? [
                    LengthLimitingTextInputFormatter(13),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ]
                : null,
              onChanged: label == 'Contact Number' 
                ? (value) {
                    if (!value.startsWith('+63')) {
                      controller.value = TextEditingValue(
                        text: '+63',
                        selection: TextSelection.collapsed(offset: 3),
                      );
                    }
                  }
                : null,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                ),
                helperText: label == 'Contact Number' ? 'Enter mobile number' : null,
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            )
          else
            Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: 14,
                color: value.isNotEmpty ? const Color(0xFF1F2937) : Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  static Widget _buildPasswordField() {
    return _CeePasswordFieldWidget();
  }


















}

class _CeePasswordFieldWidget extends StatefulWidget {
  @override
  State<_CeePasswordFieldWidget> createState() => _CeePasswordFieldWidgetState();
}

class _CeePasswordFieldWidgetState extends State<_CeePasswordFieldWidget> {
  bool _isEditingPassword = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isChangingPassword = false;
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    FocusScope.of(context).unfocus();

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      ConTrustSnackBar.error(context, 'Please enter your current password');
      return;
    }

    if (newPassword.isEmpty) {
      ConTrustSnackBar.error(context, 'Please enter a new password');
      return;
    }

    if (newPassword.length < 6) {
      ConTrustSnackBar.error(context, 'New password must be at least 6 characters long');
      return;
    }

    if (newPassword.length > 15) {
      ConTrustSnackBar.error(context, 'New password must be no more than 15 characters long');
      return;
    }

    final hasUppercase = newPassword.contains(RegExp(r'[A-Z]'));
    final hasNumber = newPassword.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = newPassword.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasNumber || !hasSpecialChar) {
      ConTrustSnackBar.error(
        context,
        'New password must include uppercase, number and special character',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ConTrustSnackBar.error(context, 'New passwords do not match');
      return;
    }

    if (currentPassword == newPassword) {
      ConTrustSnackBar.error(
        context,
        'New password must be different from current password',
      );
      return;
    }

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email == null) {
        ConTrustSnackBar.error(context, 'User not authenticated');
        return;
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: currentUser!.email!,
        password: currentPassword,
      );

      setState(() => _isChangingPassword = true);

      final success = await _userService.changePassword(
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (success) {
        ConTrustSnackBar.success(
          context,
          'Password changed successfully!',
        );

        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        setState(() {
          _isEditingPassword = false;
          _isChangingPassword = false;
        });
      } else {
        ConTrustSnackBar.error(context, 'Failed to change password. Please try again.');
        setState(() => _isChangingPassword = false);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('password')) {
        ConTrustSnackBar.error(context, 'Current password is incorrect');
      } else {
        ConTrustSnackBar.error(context, 'Error: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      ConTrustSnackBar.error(
        context,
        'Failed to change password: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Password',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                  setState(() {
                    _isEditingPassword = !_isEditingPassword;
                    if (!_isEditingPassword) {
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    }
                  });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      _isEditingPassword ? Icons.close : Icons.edit_outlined,
                      size: 18,
                      color: Colors.amber.shade700,
                    ),
                        const SizedBox(width: 4),
                        Text(
                      _isEditingPassword ? 'Cancel' : 'Change',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          if (!_isEditingPassword) ...[
              const SizedBox(height: 12),
              Text(
                '••••••••',
                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
          ],
          if (_isEditingPassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              obscureText: !_currentPasswordVisible,
              enabled: !_isChangingPassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _currentPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: !_newPasswordVisible,
              enabled: !_isChangingPassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _newPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              enabled: !_isChangingPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isChangingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
