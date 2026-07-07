import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  String recognizedText = '';
  bool loading = false;

  Future<void> scanLabel() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo == null) return;

    setState(() {
      loading = true;
      recognizedText = '';
    });

    final text = await _ocrService.readTextFromImage(File(photo.path));

    setState(() {
      recognizedText = text;
      loading = false;
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner OCR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : scanLabel,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  loading ? 'Lendo etiqueta...' : 'Escanear etiqueta',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: recognizedText.isEmpty
                  ? const Center(
                      child: Text('Nenhuma etiqueta lida ainda.'),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        recognizedText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}