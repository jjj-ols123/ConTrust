// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class CeeProfileBuildMethods {
  static const List<String> _profileTabs = ['About'];

  static Widget buildHeader(BuildContext context, String title) {
    return const SizedBox.shrink();
  }

  static Widget buildStickyHeader(String title) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  static Widget buildMainContent(
    String selectedTab,
    String previousTab,
    Widget Function() buildAboutContent,
  ) {
    final String normalizedTab =
        _profileTabs.contains(selectedTab) ? selectedTab : _profileTabs.first;
    final String normalizedPrevious =
        _profileTabs.contains(previousTab) ? previousTab : _profileTabs.first;

    Widget content;
    switch (normalizedTab) {
      case 'About':
      default:
        content = buildAboutContent();
        break;
    }

    final bool isForward =
        _isForwardTransition(normalizedPrevious, normalizedTab);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<String>(normalizedTab),
        child: content,
      ),
      transitionBuilder: (child, animation) {
        final key = child.key;
        final isCurrentChild =
            key is ValueKey<String> && key.value == normalizedTab;

        final Offset incomingOffset =
            isForward ? const Offset(0.08, 0) : const Offset(-0.08, 0);
        final Offset outgoingOffset =
            isForward ? const Offset(-0.08, 0) : const Offset(0.08, 0);

        final offsetTween = Tween<Offset>(
          begin: isCurrentChild ? incomingOffset : Offset.zero,
          end: isCurrentChild ? Offset.zero : outgoingOffset,
        );

        final Animation<Offset> slideAnimation = isCurrentChild
            ? animation.drive(offsetTween)
            : ReverseAnimation(animation).drive(offsetTween);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  static bool _isForwardTransition(String previousTab, String currentTab) {
    if (previousTab == currentTab) return true;
    return true;
  }

  static Widget buildMobileLayout({
    required String fullName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required Widget mainContent,
    required VoidCallback? onUploadPhoto,
    required bool isUploadingPhoto,
    String? selectedTab,
    Function(String)? onTabChanged,
    required bool isEditingFullName,
    required TextEditingController fullNameController,
    required VoidCallback toggleEditFullName,
    required VoidCallback saveFullName,
  }) {
    final bool showNavigation =
        selectedTab != null && onTabChanged != null && _profileTabs.length > 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileAvatar(
                  imageUrl: profileImage,
                  fallbackUrl: profileUrl,
                  onUploadPhoto: onUploadPhoto,
                  isUploading: isUploadingPhoto,
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (showNavigation) ...[
            const SizedBox(height: 16),
            buildMobileNavigation(selectedTab, onTabChanged),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: mainContent,
          ),
        ],
      ),
    );
  }

  static Widget _buildProfileAvatar({
    required String fallbackUrl,
    String? imageUrl,
    double size = 108,
    VoidCallback? onUploadPhoto,
    bool isUploading = false,
  }) {
    final double badgeSize = size * 0.32;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: ClipOval(
            child: _buildAvatarImage(imageUrl, fallbackUrl, size),
          ),
        ),
        if (onUploadPhoto != null)
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              onTap: isUploading ? null : onUploadPhoto,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade600),
                ),
                child: Center(
                  child: isUploading
                      ? SizedBox(
                          width: badgeSize * 0.5,
                          height: badgeSize * 0.5,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber.shade600,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          size: badgeSize * 0.5,
                          color: Colors.amber.shade600,
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildAvatarImage(
      String? imageUrl, String fallbackUrl, double size) {
    final String url =
        (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : fallbackUrl;

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image(
          image: const AssetImage('assets/defaultpic.png'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, assetError, assetStackTrace) => Icon(
            Icons.person,
            size: size * 0.45,
            color: Colors.grey.shade500,
          ),
        );
      },
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
    required bool isUploadingPhoto,
    String? selectedTab,
    Function(String)? onTabChanged,
    required bool isEditingFullName,
    required TextEditingController fullNameController,
    required VoidCallback toggleEditFullName,
    required VoidCallback saveFullName,
  }) {
    final bool showNavigation =
        selectedTab != null && onTabChanged != null && _profileTabs.length > 1;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildProfileAvatar(
                        imageUrl: profileImage,
                        fallbackUrl: profileUrl,
                        onUploadPhoto: onUploadPhoto,
                        isUploading: isUploadingPhoto,
                        size: 120,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.stars_rounded,
                                size: 20, color: Colors.amber.shade700),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Complete your profile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Review your personal information on the right to keep contractors informed.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showNavigation) ...[
                  buildDesktopNavigation(selectedTab, onTabChanged),
                  const SizedBox(height: 20),
                ],
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: mainContent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildMobileNavigation(
      String selectedTab, Function(String) onTabChanged) {
    if (_profileTabs.length <= 1) {
      return const SizedBox.shrink();
    }

    final tabs = _profileTabs;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == selectedTab;

          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive ? Colors.amber.shade500 : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget buildDesktopNavigation(
      String selectedTab, Function(String) onTabChanged) {
    if (_profileTabs.length <= 1) {
      return const SizedBox.shrink();
    }

    final tabs = _profileTabs;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == selectedTab;

          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive ? Colors.amber.shade500 : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final EdgeInsets padding = EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 32,
          vertical: isCompact ? 24 : 32,
        );
        final double headerSpacing = isCompact ? 16 : 24;
        final double fieldSpacing = isCompact ? 12 : 16;
        final double maxFormWidth = isCompact ? double.infinity : 720;

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
            padding: padding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.amber.shade700, size: 24),
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: headerSpacing),
                    _buildReadOnlyField(
                      'Email',
                      email.isEmpty ? 'No email provided' : email,
                      Icons.email_outlined,
                    ),
                    SizedBox(height: fieldSpacing),
                    _buildPasswordField(),
                    SizedBox(height: fieldSpacing),
                    _buildInfoField(
                      'Full Name',
                      fullName,
                      Icons.person_outline,
                      isEditingFullName,
                      fullNameController,
                      toggleEditFullName,
                      saveFullName,
                    ),
                    SizedBox(height: fieldSpacing),
                    _buildInfoField(
                      'Contact Number',
                      contactNumber,
                      Icons.phone_outlined,
                      isEditingContact,
                      contactController,
                      toggleEditContact,
                      saveContact,
                    ),
                    SizedBox(height: fieldSpacing),
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
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 420;

        Widget actionArea;
        if (isEditing) {
          actionArea = Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              InkWell(
                onTap: onEdit,
                child: Text('Cancel',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ),
              InkWell(
                onTap: onSave,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        } else {
          actionArea = InkWell(
            onTap: onEdit,
            child: Icon(Icons.edit, size: 18, color: Colors.amber.shade700),
          );
        }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (!isCompact)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: actionArea,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (isCompact) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: actionArea,
                ),
              ],
              const SizedBox(height: 8),
              isEditing
                  ? TextField(
                      controller: controller,
                      minLines: label == 'Address' ? 2 : 1,
                      maxLines: label == 'Address' ? null : 1,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    )
                  : Text(
                      value.isEmpty ? 'Not provided' : value,
                      style: TextStyle(
                        fontSize: 14,
                        color: value.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black87,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == 'No email provided'
                        ? Colors.grey.shade400
                        : Colors.black87,
                  ),
                  softWrap: true,
                  maxLines: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPasswordField() {
    return const _PasswordFieldWidget();
  }
}

class _PasswordFieldWidget extends StatefulWidget {
  const _PasswordFieldWidget();

  @override
  State<_PasswordFieldWidget> createState() => _PasswordFieldWidgetState();
}

class _PasswordFieldWidgetState extends State<_PasswordFieldWidget> {
  bool _isEditingPassword = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isChangingPassword = false;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
      ConTrustSnackBar.error(
          context, 'New password must be at least 6 characters long');
      return;
    }

    if (newPassword.length > 15) {
      ConTrustSnackBar.error(
          context, 'New password must be no more than 15 characters long');
      return;
    }

    final hasUppercase = newPassword.contains(RegExp(r'[A-Z]'));
    final hasNumber = newPassword.contains(RegExp(r'[0-9]'));
    final hasSpecialChar =
        newPassword.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

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

      if (!mounted) return;

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
        ConTrustSnackBar.error(
            context, 'Failed to change password. Please try again.');
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
    final borderColor = Colors.grey.shade200;
    final labelColor = Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: labelColor),
              const SizedBox(width: 8),
              Text(
                'Password',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: labelColor),
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
            const Text(
              '••••••••',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
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
                  onPressed: () => setState(
                    () => _currentPasswordVisible = !_currentPasswordVisible,
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
                  onPressed: () => setState(
                    () => _newPasswordVisible = !_newPasswordVisible,
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
                  onPressed: () => setState(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChangingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
