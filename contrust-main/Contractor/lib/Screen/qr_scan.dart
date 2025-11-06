import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  final String title;
  const QrScanPage({super.key, required this.title});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
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
        actions: [
          IconButton(
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {});
            },
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
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


