// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
  loading,
}

class ConTrustSnackBar {
  static OverlayEntry? _activeToastEntry;
  static Timer? _activeToastTimer;

  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    final config = getSnackBarConfig(type);

    showDialog(
      context: context,
      barrierDismissible: type != SnackBarType.loading,
      builder: (dialogContext) {
        // Auto-close after duration (except for loading type)
        if (type != SnackBarType.loading) {
          Future.delayed(duration, () {
            if (Navigator.canPop(dialogContext)) {
              Navigator.pop(dialogContext);
            }
          });
        }
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
                  color: config.backgroundColor.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  config.icon,
                  color: config.backgroundColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _getDialogTitle(type),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: config.backgroundColor,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (action != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: config.backgroundColor,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  action.onPressed.call();
                },
                child: Text(action.label),
              ),
          ],
        );
      },
    );
  }

  static void infoToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
  }) {
    final config = getSnackBarConfig(SnackBarType.info);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(duration, () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
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
                  color: config.backgroundColor.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  config.icon,
                  color: config.backgroundColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        );
      },
    );
  }

  static String _getDialogTitle(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return 'Success';
      case SnackBarType.error:
        return 'Error';
      case SnackBarType.warning:
        return 'Warning';
      case SnackBarType.info:
        return 'Information';
      case SnackBarType.loading:
        return 'Loading';
    }
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.success, duration: duration, action: action);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.error, duration: duration, action: action);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.warning, duration: duration, action: action);
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    show(context, message, type: SnackBarType.info, duration: duration, action: action);
  }

  static void loading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
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
    error(context, 'Failed to save material: ');
  }

  static void missingInfo(BuildContext context, String field) {
    warning(context, 'Please enter $field');
  }

  static void projectError(BuildContext context) {
    error(context, 'No active / ongoing project found');
  }

  static void projectLoading(BuildContext context) {
    loading(context, 'Loading project...');
  }

  static void bidSubmitted(BuildContext context) {
    success(context, 'Bid submitted successfully');
  }

  static void bidError(BuildContext context, String errorMessage) {
    error(context, 'Failed to submit bid: ');
  }

  static void contractSent(BuildContext context) {
    success(context, 'Contract sent successfully');
  }

  static void contractSigned(BuildContext context) {
    success(context, 'Contract signed successfully');
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
    error(context, 'Failed to send message');
  }

  static void loginSuccess(BuildContext context, String name) {
    success(context, 'Welcome back, $name!');
  }

  static void loginError(BuildContext context) {
    error(context, 'Invalid credentials. Please try again.');
  }

  static void logoutSuccess(BuildContext context) {
    info(context, 'You have been logged out');
  }

  static void fileUploadSuccess(BuildContext context, String fileName) {
    success(context, '$fileName uploaded successfully');
  }

  static void fileUploadError(BuildContext context) {
    error(context, 'Failed to upload file');
  }

  static void fileDownloadSuccess(BuildContext context, String fileName) {
    success(context, '$fileName downloaded');
  }

  static void profileUpdated(BuildContext context) {
    success(context, 'Profile updated successfully');
  }

  static void profileError(BuildContext context, String errorMessage) {
    error(context, 'Failed to update profile: ');
  }

  static void notificationToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool belowAppBarOnMobile = false,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      info(context, message, duration: duration);
      return;
    }

    // Clear any existing toast before showing a new one
    _activeToastTimer?.cancel();
    _activeToastTimer = null;
    if (_activeToastEntry != null && _activeToastEntry!.mounted) {
      _activeToastEntry!.remove();
    }
    _activeToastEntry = null;

    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;

    double topOffset = mediaQuery.padding.top + 16;
    if (belowAppBarOnMobile && isMobile) {
      topOffset = mediaQuery.padding.top + kToolbarHeight + 8;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: topOffset,
          left: isMobile ? 16 : null,
          right: isMobile ? 16 : 16,
          child: Material
          (
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                if (entry.mounted) {
                  entry.remove();
                }
                if (_activeToastEntry == entry) {
                  _activeToastEntry = null;
                }
                _activeToastTimer?.cancel();
                _activeToastTimer = null;
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeToastEntry = entry;
    overlay.insert(entry);

    _activeToastTimer = Timer(duration, () {
      if (_activeToastEntry == entry && entry.mounted) {
        entry.remove();
        _activeToastEntry = null;
      }
    });
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
