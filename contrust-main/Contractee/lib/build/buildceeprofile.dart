// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend/services/both services/be_receipt_service.dart';
import 'package:backend/services/both services/be_user_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/web/html_stub.dart' as html if (dart.library.html) 'dart:html';
import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:backend/build/ui_web_stub.dart'
    if (dart.library.html) 'dart:ui_web' as ui_web;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CeeProfileBuildMethods {
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
    Widget Function() buildPaymentHistoryContent,
  ) {
    Widget content;
    switch (selectedTab) {
      case 'Payment History':
        content = buildPaymentHistoryContent();
        break;
      case 'About':
      default:
        content = buildAboutContent();
        break;
    }

    final bool isForward = _isForwardTransition(previousTab, selectedTab);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<String>(selectedTab),
        child: content,
      ),
      transitionBuilder: (child, animation) {
        final key = child.key;
        final isCurrentChild =
            key is ValueKey<String> && key.value == selectedTab;

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
    if (previousTab == 'About' && currentTab == 'Payment History') {
      return true;
    }
    if (previousTab == 'Payment History' && currentTab == 'About') {
      return false;
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade500,
                    Colors.amber.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.grey.shade100,
                          child: ClipOval(
                            child: (profileImage != null &&
                                    profileImage.isNotEmpty)
                                ? Image.network(
                                    profileImage,
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        profileUrl,
                                        width: 108,
                                        height: 108,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image(
                                            image: const AssetImage(
                                                'assets/defaultpic.png'),
                                            width: 108,
                                            height: 108,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(Icons.person,
                                                  size: 44,
                                                  color: Colors.grey.shade400);
                                            },
                                          );
                                        },
                                      );
                                    },
                                  )
                                : Image.network(
                                    profileUrl,
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image(
                                        image: const AssetImage(
                                            'assets/defaultpic.png'),
                                        width: 108,
                                        height: 108,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.person,
                                              size: 44,
                                              color: Colors.grey.shade400);
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
                          bottom: 6,
                          child: GestureDetector(
                            onTap: isUploadingPhoto ? null : onUploadPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.amber.shade600,
                                child: isUploadingPhoto
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              const AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contractee',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatChip(
                        label: 'Ongoing',
                        value: ongoingProjectsCount,
                        background: Colors.white,
                        foreground: Colors.amber.shade700,
                      ),
                      _buildStatChip(
                        label: 'Completed',
                        value: completedProjectsCount,
                        background: Colors.white.withOpacity(0.2),
                        foreground: Colors.white,
                        borderColor: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (selectedTab != null && onTabChanged != null) ...[
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

  static Widget _buildStatChip({
    required String label,
    required int value,
    required Color background,
    required Color foreground,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.4)
            : null,
        boxShadow: [
          if (background.opacity > 0.2)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: foreground.withOpacity(0.85),
            ),
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
    required bool isUploadingPhoto,
    String? selectedTab,
    Function(String)? onTabChanged,
    required bool isEditingFullName,
    required TextEditingController fullNameController,
    required VoidCallback toggleEditFullName,
    required VoidCallback saveFullName,
  }) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade500,
                        Colors.amber.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.28),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.16),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 62,
                              backgroundColor: Colors.grey.shade100,
                              child: ClipOval(
                                child: (profileImage != null && profileImage.isNotEmpty)
                                    ? Image.network(
                                        profileImage,
                                        width: 124,
                                        height: 124,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            profileUrl,
                                            width: 124,
                                            height: 124,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.person,
                                                  size: 52, color: Colors.grey.shade400);
                                            },
                                          );
                                        },
                                      )
                                    : Image.network(
                                        profileUrl,
                                        width: 124,
                                        height: 124,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.person,
                                              size: 52, color: Colors.grey.shade400);
                                        },
                                      ),
                              ),
                            ),
                          ),
                          if (onUploadPhoto != null)
                            Positioned(
                              right: 6,
                              bottom: 10,
                              child: GestureDetector(
                                onTap: isUploadingPhoto ? null : onUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.amber.shade600,
                                    child: isUploadingPhoto
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.camera_alt_rounded,
                                            size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Contractee',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildStatChip(
                            label: 'Ongoing',
                            value: ongoingProjectsCount,
                            background: Colors.white,
                            foreground: Colors.amber.shade700,
                          ),
                          _buildStatChip(
                            label: 'Completed',
                            value: completedProjectsCount,
                            background: Colors.white.withOpacity(0.2),
                            foreground: Colors.white,
                            borderColor: Colors.white.withOpacity(0.55),
                          ),
                        ],
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
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                if (selectedTab != null && onTabChanged != null) ...[
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
    final tabs = ['About', 'Payment History'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == selectedTab;

          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            Colors.amber.shade500,
                            Colors.amber.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: isActive ? 40 : 0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
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
    final tabs = ['About', 'Payment History'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == selectedTab;

          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            Colors.amber.shade500,
                            Colors.amber.shade600,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isActive ? null : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 3,
                      width: isActive ? 48 : 0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
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

  static Widget buildPaymentHistory({
    required BuildContext context,
    required List<Map<String, dynamic>> transactions,
    required TextEditingController transactionSearchController,
    required String selectedPaymentType,
    required Function(String) onPaymentTypeChanged,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Payment History',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: transactionSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedPaymentType,
                  items: [
                    'All',
                    'Full Payment',
                    'Milestone Payment',
                    'Down Payment',
                    'Final Payment',
                    'Contract Payment'
                  ]
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onPaymentTypeChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No payment history found',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                itemCount: transactions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final amount =
                      (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                  final paymentDate = transaction['payment_date'] ?? '';
                  final projectTitle =
                      transaction['project_title'] ?? 'Unknown Project';
                  final contractorName =
                      transaction['contractor_name'] ?? 'Unknown Contractor';
                  final paymentType = transaction['payment_type'] ?? 'Payment';
                  final receiptPath = transaction['receipt_path'] as String?;
                  final reference = transaction['reference'] ?? '';

                  DateTime? parsedDate;
                  if (paymentDate is String && paymentDate.isNotEmpty) {
                    try {
                      parsedDate = DateTime.parse(paymentDate).toLocal();
                    } catch (e) {
                      parsedDate = DateTime.now();
                    }
                  } else {
                    parsedDate = DateTime.now();
                  }

                  final formattedDate =
                      '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: receiptPath != null && receiptPath.isNotEmpty
                          ? () => _showReceiptDialog(
                              context, receiptPath, reference)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              radius: 24,
                              child: Icon(Icons.check_circle,
                                  color: Colors.green.shade700, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₱${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    projectTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By: $contractorName',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      paymentType,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: receiptPath != null &&
                                        receiptPath.isNotEmpty
                                    ? () {
                                        final path = receiptPath;
                                        if (path.isNotEmpty) {
                                          _showReceiptDialog(
                                              context, path, reference);
                                        }
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (receiptPath != null &&
                                            receiptPath.isNotEmpty)
                                        ? Colors.blue.shade50
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: (receiptPath != null &&
                                              receiptPath.isNotEmpty)
                                          ? Colors.blue.shade200
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.visibility,
                                    color: (receiptPath != null &&
                                            receiptPath.isNotEmpty)
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: receiptPath != null &&
                                        receiptPath.isNotEmpty
                                    ? () {
                                        final path = receiptPath;
                                        if (path.isNotEmpty) {
                                          _downloadReceipt(
                                              context, path, reference);
                                        }
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (receiptPath != null &&
                                            receiptPath.isNotEmpty)
                                        ? Colors.green.shade50
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: (receiptPath != null &&
                                              receiptPath.isNotEmpty)
                                          ? Colors.green.shade200
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.download,
                                    color: (receiptPath != null &&
                                            receiptPath.isNotEmpty)
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showReceiptDialog(
      BuildContext context, String receiptPath, String reference) async {
    try {
      final receiptUrl = await ReceiptService.getReceiptSignedUrl(receiptPath);

      if (receiptUrl == null) {
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Failed to load receipt');
        }
        return;
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'E-Receipt',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _downloadReceipt(context, receiptPath, reference),
                        icon: const Icon(Icons.download, color: Colors.white),
                        tooltip: 'Download Receipt',
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: kIsWeb
                      ? _buildWebPdfViewer(receiptUrl)
                      : _buildMobilePdfViewer(receiptUrl),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error loading receipt: $e');
      }
    }
  }

  static Future<void> _downloadReceipt(
      BuildContext context, String receiptPath, String reference) async {
    try {
      final receiptUrl = await ReceiptService.getReceiptSignedUrl(receiptPath,
          expirationSeconds: 86400);

      if (receiptUrl == null) {
        if (context.mounted) {
          ConTrustSnackBar.error(
              context, 'Failed to get receipt download link');
        }
        return;
      }

      if (kIsWeb) {
        html.AnchorElement anchor = html.AnchorElement(href: receiptUrl)
          ..target = '_blank'
          ..download = 'receipt_$reference.pdf';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        if (context.mounted) {
          ConTrustSnackBar.success(context, 'Receipt download started');
        }
      } else {
        // For mobile, download the PDF file
        try {
          final response = await http.get(Uri.parse(receiptUrl));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final directory = await getApplicationDocumentsDirectory();
            final fileName = 'receipt_$reference.pdf';
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(bytes);

            if (context.mounted) {
              ConTrustSnackBar.success(
                  context, 'Receipt downloaded to: ${file.path}');
            }
          } else {
            if (context.mounted) {
              ConTrustSnackBar.error(context, 'Failed to download receipt');
            }
          }
        } catch (e) {
          if (context.mounted) {
            ConTrustSnackBar.error(context, 'Error downloading receipt: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error downloading receipt: $e');
      }
    }
  }

  static Widget _buildWebPdfViewer(String pdfUrl) {
    final viewType = 'pdf-viewer-${pdfUrl.hashCode.abs()}';

    try {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = pdfUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'fullscreen'
          ..onError.listen((event) {});

        return iframe;
      });
    } catch (e) {
      // Continue if registration fails
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: HtmlElementView(viewType: viewType),
    );
  }

  static Widget _buildMobilePdfViewer(String pdfUrl) {
    return FutureBuilder<Uint8List?>(
      future: _downloadPdfBytes(pdfUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade50,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the button below to open in external app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _launchPdfUrl(context, pdfUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        try {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SfPdfViewer.memory(
              snapshot.data!,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            ),
          );
        } catch (e) {
          debugPrint('Error displaying PDF with SfPdfViewer: $e');
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error displaying PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _launchPdfUrl(context, pdfUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  static Future<Uint8List?> _downloadPdfBytes(String pdfUrl) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          debugPrint('PDF download returned empty bytes');
          return null;
        }
        debugPrint('PDF downloaded successfully: ${bytes.length} bytes');
        return bytes;
      } else {
        debugPrint('PDF download failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading PDF bytes: $e');
      return null;
    }
  }

  static Future<void> _launchPdfUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ConTrustSnackBar.error(context, 'Could not open PDF URL');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error opening PDF: $e');
      }
    }
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
