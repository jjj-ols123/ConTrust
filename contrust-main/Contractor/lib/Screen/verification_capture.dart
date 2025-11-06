import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VerificationCapturePage extends StatefulWidget {
  final List<Map<String, dynamic>> initialFiles;
  final String? initialPcabQrText;
  final String? initialPermitQrText;

  const VerificationCapturePage({
    super.key,
    this.initialFiles = const [],
    this.initialPcabQrText,
    this.initialPermitQrText,
  });

  @override
  State<VerificationCapturePage> createState() => _VerificationCapturePageState();
}

class _VerificationCapturePageState extends State<VerificationCapturePage> {
  late List<Map<String, dynamic>> _files;
  String? _pcabQrText;
  String? _permitQrText;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _files = List<Map<String, dynamic>>.from(widget.initialFiles);
    _pcabQrText = widget.initialPcabQrText;
    _permitQrText = widget.initialPermitQrText;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
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
        final duplicate = _files.any((f) => listEquals(f['bytes'], bytes));
        if (duplicate) {
          if (mounted) ConTrustSnackBar.warning(context, 'This file is already selected');
          return;
        }
        setState(() {
          _files.add({ 'name': file.name, 'bytes': bytes, 'isImage': isImage });
        });
      }
    }
  }

  Future<void> _useCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final duplicate = _files.any((f) => listEquals(f['bytes'], bytes));
      if (duplicate) {
        if (mounted) ConTrustSnackBar.warning(context, 'This image is already selected');
        return;
      }
      setState(() {
        _files.add({
          'name': 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'bytes': bytes,
          'isImage': true,
        });
      });
    }
  }

  Future<void> _scanQr({required bool isPcab}) async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => _QrInlineScanner(title: isPcab ? 'Scan PCAB QR' : 'Scan Permit QR'),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (isPcab) {
          _pcabQrText = result;
        } else {
          _permitQrText = result;
        }
      });
      if (mounted) ConTrustSnackBar.success(context, isPcab ? 'PCAB QR captured' : 'Permit QR captured');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Capture'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pick File'),
                ),
                if (isMobile)
                  ElevatedButton.icon(
                    onPressed: _useCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Use Camera'),
                  ),
                if (isMobile)
                  ElevatedButton.icon(
                    onPressed: () => _scanQr(isPcab: true),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan PCAB QR'),
                  ),
                if (isMobile)
                  ElevatedButton.icon(
                    onPressed: () => _scanQr(isPcab: false),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Scan Permit QR'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pcabQrText != null || _permitQrText != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_pcabQrText != null)
                    const Chip(
                      label: Text('PCAB QR ready'),
                      avatar: Icon(Icons.verified, color: Colors.green, size: 18),
                    ),
                  if (_permitQrText != null)
                    const Chip(
                      label: Text('Permit QR ready'),
                      avatar: Icon(Icons.verified, color: Colors.green, size: 18),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _files.isEmpty
                  ? Center(
                      child: Text(
                        'No files added yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _files.asMap().entries.map((e) {
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
                                          (file['name'] as String).length > 10
                                              ? '${(file['name'] as String).substring(0, 10)}...'
                                              : (file['name'] as String),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _files.removeAt(idx)),
                              child: Container(
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'files': _files,
                        'pcabQrText': _pcabQrText,
                        'permitQrText': _permitQrText,
                      });
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrInlineScanner extends StatefulWidget {
  final String title;
  const _QrInlineScanner({required this.title});

  @override
  State<_QrInlineScanner> createState() => _QrInlineScannerState();
}

class _QrInlineScannerState extends State<_QrInlineScanner> {
  bool _done = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) async {
          if (_done) return;
          final barcodes = capture.barcodes;
          final value = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
          if (value != null && value.isNotEmpty) {
            _done = true;
            if (mounted) Navigator.pop(context, value);
          }
        },
      ),
    );
  }
}


