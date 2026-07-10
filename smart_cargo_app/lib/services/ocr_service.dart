import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService()
      : _recognizer = TextRecognizer(
          script: TextRecognitionScript.latin,
        );

  final TextRecognizer _recognizer;

  Future<String> readTextFromImagePath(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      throw ArgumentError('O caminho da imagem está vazio.');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);

    return result.text.trim();
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
