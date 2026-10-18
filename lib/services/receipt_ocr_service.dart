import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'receipt_parser.dart';

class ReceiptOcrService {
  static final ReceiptOcrService instance = ReceiptOcrService._internal();
  ReceiptOcrService._internal();

  /// Process the image file with Google ML Kit Text Recognition on device
  Future<ReceiptParseResult> recognizeAndParse(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Tệp ảnh không tồn tại: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      final rawText = recognizedText.text;
      return ReceiptParser.parse(rawText);
    } catch (e) {
      rethrow;
    } finally {
      await textRecognizer.close();
    }
  }
}
