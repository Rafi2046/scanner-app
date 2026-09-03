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

  Future<List<ScannedDocument>> _fetch() {
    return ref.read(storageServiceProvider).listDocuments();
  }
}
