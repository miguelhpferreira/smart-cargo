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
  return const Scaffold(
    body: Center(
      child: Text(
        'TESTE 999',
        style: TextStyle(fontSize: 40),
      ),
    ),
  );
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
