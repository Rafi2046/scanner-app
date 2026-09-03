import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/models/ocr_result.dart';

/// On-device OCR via ML Kit Text Recognition.
class OcrService {
  const OcrService();

  Future<OcrResult> extractTextFromImage(String imagePath) async {
    if (imagePath.isEmpty) {
      throw const OcrException('No image path was provided.');
    }

    final TextRecognizer recognizer = TextRecognizer();
    try {
      final InputImage input = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized = await recognizer.processImage(input);
      return OcrResult(
        text: recognized.text.trim(),
        sourcePath: imagePath,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw OcrException('Failed to extract text from image.', cause: error);
    } finally {
      await recognizer.close();
    }
  }
}
