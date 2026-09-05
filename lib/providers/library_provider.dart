import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'library_provider.g.dart';

@Riverpod(keepAlive: true)
class LibraryNotifier extends _$LibraryNotifier {
  @override
  Future<List<ScannedDocument>> build() {
    return _fetch();
  }

  Future<void> loadLibrary() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> deleteDocument(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(storageServiceProvider).deleteDocument(id);
      return _fetch();
    });
  }

  Future<ScannedDocument?> renameDocument(String id, String newTitle) async {
    ScannedDocument? result;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      result = await ref
          .read(storageServiceProvider)
          .renameDocument(id, newTitle);
      return _fetch();
    });
    return result;
  }

  Future<ScannedDocument?> addPagesToDocument(
    String id,
    List<String> tempImages,
  ) async {
    ScannedDocument? result;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final pdfService = ref.read(pdfServiceProvider);
      result = await ref.read(storageServiceProvider).addPagesToDocument(
            id: id,
            newTempImages: tempImages,
            pdfService: pdfService,
          );
      return _fetch();
    });
    return result;
  }

  Future<ScannedDocument?> deletePage(String id, int pageIndex) async {
    ScannedDocument? result;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final pdfService = ref.read(pdfServiceProvider);
      result = await ref.read(storageServiceProvider).deletePageFromDocument(
            id: id,
            pageIndex: pageIndex,
            pdfService: pdfService,
          );
      return _fetch();
    });
    return result;
  }

  Future<List<ScannedDocument>> _fetch() {
    return ref.read(storageServiceProvider).listDocuments();
  }
}
