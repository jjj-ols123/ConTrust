// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:backend/utils/be_snackbar.dart';

class PermissionUtils {
  /// Request camera permission from the user
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // Check current permission status
      final status = await Permission.camera.status;

      switch (status) {
        case PermissionStatus.granted:
          // Permission already granted
          return true;

        case PermissionStatus.denied:
          // Request permission
          final result = await Permission.camera.request();
          if (result.isGranted) {
            return true;
          } else if (result.isPermanentlyDenied) {
            // Show dialog to open app settings
            await _showPermissionDialog(
              context,
              'Camera Permission Required',
              'Camera access is needed to take photos. Please enable camera permission in app settings.',
              'Open Settings',
            );
            return false;
          } else {
            // Permission denied but not permanently
            ConTrustSnackBar.error(context, 'Camera permission is required to take photos.');
            return false;
          }

        case PermissionStatus.permanentlyDenied:
          // Show dialog to open app settings
          await _showPermissionDialog(
            context,
            'Camera Permission Required',
            'Camera access is needed to take photos. Please enable camera permission in app settings.',
            'Open Settings',
          );
          return false;

        case PermissionStatus.restricted:
        case PermissionStatus.limited:
          ConTrustSnackBar.error(context, 'Camera access is restricted on this device.');
          return false;

        default:
          return false;
      }
    } catch (e) {
      ConTrustSnackBar.error(context, 'Failed to request camera permission: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for manual permission management
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Show permission dialog with option to open settings
  static Future<void> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    String actionText,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  /// Request multiple permissions at once (can be extended for other permissions)
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      return await permissions.request();
    } catch (e) {
      return {};
    }
  }
}
