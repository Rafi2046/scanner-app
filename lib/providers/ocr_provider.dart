import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/models/ocr_result.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'ocr_provider.g.dart';

@riverpod
class OcrNotifier extends _$OcrNotifier {
  @override
  FutureOr<String?> build() => null;

  Future<void> extractTextFromImage(String imagePath) async {
    state = const AsyncLoading();
    try {
      final OcrResult result =
          await ref.read(ocrServiceProvider).extractTextFromImage(imagePath);
      state = AsyncData<String?>(
        result.text.isEmpty ? 'No text found.' : result.text,
      );
    } catch (error, stackTrace) {
      state = AsyncError<String?>(error, stackTrace);
    }
  }

  Future<void> pickImageAndExtract() async {
    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final String? path = picked?.files.single.path;
      if (path == null || path.isEmpty) {
        return;
      }
      await extractTextFromImage(path);
    } on AppException catch (error, stackTrace) {
      state = AsyncError<String?>(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError<String?>(
        OcrException('Failed to pick an image.', cause: error),
        stackTrace,
      );
    }
  }
}
