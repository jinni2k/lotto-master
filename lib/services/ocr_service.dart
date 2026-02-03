import 'dart:collection';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScanResult {
  const OcrScanResult({required this.rawText, required this.numbers});

  final String rawText;
  final List<int> numbers;
}

class OcrService {
  OcrService._();

  static final OcrService instance = OcrService._();

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<OcrScanResult> recognizeLottoNumbers(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);
    final rawText = recognized.text;
    final numbers = _extractNumbers(rawText);
    return OcrScanResult(rawText: rawText, numbers: numbers);
  }

  List<int> _extractNumbers(String text) {
    final matches = RegExp(r'\d{1,2}').allMatches(text);
    final seen = LinkedHashSet<int>();
    for (final match in matches) {
      final value = int.tryParse(match.group(0) ?? '');
      if (value == null || value < 1 || value > 45) {
        continue;
      }
      seen.add(value);
      if (seen.length == 6) {
        break;
      }
    }
    return seen.toList(growable: false);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
