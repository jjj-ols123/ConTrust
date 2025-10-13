// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
  loading,
}

class ConTrustSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    final config = getSnackBarConfig(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              config.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: action,
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.success, duration: duration, action: action);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.error, duration: duration, action: action);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.warning, duration: duration, action: action);
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.info, duration: duration, action: action);
  }

  static void loading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    show(context, message, type: SnackBarType.loading, duration: duration);
  }


  static void dashboardRefresh(BuildContext context) {
    success(context, 'Dashboard refreshed successfully');
  }

  static void materialAdded(BuildContext context) {
    success(context, 'Material added to inventory');
  }

  static void materialUpdated(BuildContext context) {
    success(context, 'Material updated successfully');
  }

  static void materialError(BuildContext context, String errorMessage) {
    ConTrustSnackBar.error(context, 'Failed to save material: $errorMessage');
  }

  static void missingInfo(BuildContext context, String field) {
    warning(context, 'Please enter $field');
  }

  static void projectError(BuildContext context) {
    ConTrustSnackBar.error(context, 'No active / ongoing project found');
  }

  static void projectLoading(BuildContext context) {
    loading(context, 'Loading project...');
  }

  static void bidSubmitted(BuildContext context) {
    success(context, 'Bid submitted successfully');
  }

  static void bidError(BuildContext context, String errorMessage) {
    ConTrustSnackBar.error(context, 'Failed to submit bid: $errorMessage');
  }

  static void contractSent(BuildContext context) {
    success(context, 'Contract sent successfully');
  }

  static void contractSigned(BuildContext context) {
    success(context, 'Contract signed successfully');
  }

  static void contractError(BuildContext context, String errorMessage) {
    ConTrustSnackBar.error(context, 'Contract error: $errorMessage');
  }

  static void contractApproved(BuildContext context) {
    success(context, 'Contract approved! You can now sign it.');
  }

  static void contractRejected(BuildContext context) {
    warning(context, 'Contract rejected');
  }

  static void downloadSuccess(BuildContext context, String message) {
    success(context, message);
  }

  static void agreementConfirmed(BuildContext context) {
    success(context, 'Agreement confirmed!');
  }
  static void waitingForOther(BuildContext context) {
    info(context, 'Waiting for the other party to agree...');
  }
  static void messageSent(BuildContext context) {
    success(context, 'Message sent');
  }

  static void messageError(BuildContext context) {
    ConTrustSnackBar.error(context, 'Failed to send message');
  }

  static void loginSuccess(BuildContext context, String name) {
    success(context, 'Welcome back, $name!');
  }

  static void loginError(BuildContext context) {
    ConTrustSnackBar.error(context, 'Invalid credentials. Please try again.');
  }

  static void logoutSuccess(BuildContext context) {
    info(context, 'You have been logged out');
  }


  static void fileUploadSuccess(BuildContext context, String fileName) {
    success(context, '$fileName uploaded successfully');
  }

  static void fileUploadError(BuildContext context) {
    ConTrustSnackBar.error(context, 'Failed to upload file');
  }

  static void fileDownloadSuccess(BuildContext context, String fileName) {
    success(context, '$fileName downloaded');
  }

  static void profileUpdated(BuildContext context) {
    success(context, 'Profile updated successfully');
  }

  static void profileError(BuildContext context, String errorMessage) {
    ConTrustSnackBar.error(context, 'Failed to update profile: $errorMessage');
  }
}

class _SnackBarConfig {
  final Color backgroundColor;
  final IconData icon;

  const _SnackBarConfig({
    required this.backgroundColor,
    required this.icon,
  });
}

_SnackBarConfig getSnackBarConfig(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return const _SnackBarConfig(
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    case SnackBarType.error:
      return const _SnackBarConfig(
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    case SnackBarType.warning:
      return const _SnackBarConfig(
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
    case SnackBarType.info:
      return const _SnackBarConfig(
        backgroundColor: Colors.blue,
        icon: Icons.info,
      );
    case SnackBarType.loading:
      return const _SnackBarConfig(
        backgroundColor: Colors.amber,
        icon: Icons.hourglass_empty,
      );
  }
}
