import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/package_data.dart';
import '../services/ocr_service.dart';
import '../services/parser_service.dart';

class OcrCapturePage extends StatefulWidget {
  const OcrCapturePage({super.key});

  @override
  State<OcrCapturePage> createState() => _OcrCapturePageState();
}

class _OcrCapturePageState extends State<OcrCapturePage> {
  final OcrService _ocrService = OcrService();
  final ParserService _parserService = const ParserService();

  CameraController? _cameraController;
  PackageData? _result;

  bool _loadingCamera = true;
  bool _processing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw StateError('Nenhuma câmera encontrada.');
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _loadingCamera = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingCamera = false;
        _errorMessage = 'Não foi possível abrir a câmera: $error';
      });
    }
  }

  Future<void> _captureAndRead() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized || _processing) {
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final photo = await controller.takePicture();
      final rawText = await _ocrService.readTextFromImagePath(photo.path);

      debugPrint('================ OCR BRUTO ================');
      debugPrint(rawText);
      debugPrint('===========================================');

      final parsed = _parserService.parse(rawText);

      if (!mounted) return;

      setState(() {
        _result = parsed;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Falha ao ler a etiqueta: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _confirmResult() {
    final result = _result;

    if (result == null || !result.hasValidAddress) {
      return;
    }

    Navigator.pop(context, result);
  }

  void _clearResult() {
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Ler endereço da etiqueta')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _loadingCamera
                    ? const Center(child: CircularProgressIndicator())
                    : controller == null || !controller.value.isInitialized
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _errorMessage ?? 'Câmera indisponível.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(controller),
                          Center(
                            child: Container(
                              width: 320,
                              height: 430,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 20,
                            right: 20,
                            bottom: 18,
                            child: Text(
                              'Enquadre toda a etiqueta dentro da moldura',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 8, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(_errorMessage!),
                        ),
                      ),
                    if (result != null) _OcrResultCard(data: result),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _processing ? null : _captureAndRead,
                        icon: _processing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.document_scanner),
                        label: Text(
                          _processing
                              ? 'Lendo etiqueta...'
                              : result == null
                              ? 'Fotografar e ler'
                              : 'Ler novamente',
                        ),
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: result.hasValidAddress
                              ? _confirmResult
                              : null,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Usar este endereço'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _clearResult,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Descartar leitura'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrResultCard extends StatelessWidget {
  final PackageData data;

  const _OcrResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final confidence = (data.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.hasValidAddress
                  ? 'Endereço reconhecido'
                  : 'Leitura incompleta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _ResultLine(label: 'Transportadora', value: data.carrier),
            _ResultLine(
              label: 'Rua',
              value: data.street.isEmpty ? 'Não encontrada' : data.street,
            ),
            _ResultLine(
              label: 'Número',
              value: data.houseNumber.isEmpty
                  ? 'Não encontrado'
                  : data.houseNumber,
            ),
            _ResultLine(
              label: 'CEP',
              value: data.postalCode.isEmpty
                  ? 'Não encontrado'
                  : data.postalCode,
            ),
            _ResultLine(label: 'Confiança', value: '$confidence%'),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Ver texto completo do OCR'),
              children: [
                SelectableText(
                  data.rawText.isEmpty
                      ? 'Nenhum texto reconhecido.'
                      : data.rawText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String label;
  final String value;

  const _ResultLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
