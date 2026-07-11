import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool hasScanned = false;

  void onDetect(BarcodeCapture capture) {
    if (hasScanned || capture.barcodes.isEmpty) {
      return;
    }

    final code = capture.barcodes.first.rawValue;

    if (code == null || code.trim().isEmpty) {
      return;
    }

    hasScanned = true;
    Navigator.pop(context, code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear pacote'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: onDetect),
          Center(
            child: Container(
              width: 300,
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Text(
              'Aponte para o código de barras ou QR Code da etiqueta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTES
// ============================================================
