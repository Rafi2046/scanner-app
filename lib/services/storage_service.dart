import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/models/folder_item.dart';
import 'package:scanner_app/models/library_index.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/services/pdf_service.dart';
import 'package:uuid/uuid.dart';

/// Permanent local storage: directories, file persistence, and JSON library index.
class StorageService {
  StorageService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Directory? _rootDir;
  File? _indexFile;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Creates root + feature directories and loads (or creates) the JSON index.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final Directory appDocs = await getApplicationDocumentsDirectory();
      _rootDir = Directory(p.join(appDocs.path, 'scanner_app'));
      await _rootDir!.create(recursive: true);

      await Future.wait(<Future<Directory>>[
        _subdir(AppConstants.scansDirName).create(recursive: true),
        _subdir(AppConstants.idCardsDirName).create(recursive: true),
        _subdir(AppConstants.importsDirName).create(recursive: true),
        _subdir(AppConstants.toolsDirName).create(recursive: true),
        _subdir(AppConstants.foldersDirName).create(recursive: true),
      ]);

      _indexFile = File(p.join(_rootDir!.path, AppConstants.indexFileName));
      if (!await _indexFile!.exists()) {
        await _writeIndex(_emptyIndex());
      }

      _initialized = true;
    } catch (error) {
      throw StorageException(
        'Failed to initialize local storage.',
        cause: error,
      );
    }
  }

  Directory get scansDirectory => _requireSubdir(AppConstants.scansDirName);

  Directory get idCardsDirectory =>
      _requireSubdir(AppConstants.idCardsDirName);

  Directory get importsDirectory =>
      _requireSubdir(AppConstants.importsDirName);

  Directory get toolsDirectory => _requireSubdir(AppConstants.toolsDirName);

  /// Copies temporary files into a permanent document folder and indexes them.
  Future<ScannedDocument> persistScan({
    required DocumentKind kind,
    required String title,
    List<String> tempImagePaths = const <String>[],
    String? tempPdfPath,
    String? folderId,
  }) async {
    await _ensureReady();

    if (tempImagePaths.isEmpty &&
        (tempPdfPath == null || tempPdfPath.isEmpty)) {
      throw const StorageException('Nothing to persist: no images or PDF.');
    }

    final String id = _uuid.v4();
    final Directory targetDir = await _documentDirectoryFor(kind, id);

    try {
      final List<String> savedImages = await _copyImages(
        tempImagePaths,
        targetDir,
      );

      String? savedPdfPath;
      if (tempPdfPath != null && tempPdfPath.isNotEmpty) {
        savedPdfPath = p.join(targetDir.path, 'document.pdf');
        await _copyFile(tempPdfPath, savedPdfPath);
      }

      final ScannedDocument document = ScannedDocument(
        id: id,
        title: title,
        kind: kind,
        createdAt: DateTime.now(),
        pageCount: savedImages.isNotEmpty ? savedImages.length : 1,
        imagePaths: savedImages,
        pdfPath: savedPdfPath,
        folderId: folderId,
      );

      await _upsertDocument(document);
      return document;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Failed to persist scan "$title".',
        cause: error,
      );
    }
  }

  /// Saves an already-written PDF (e.g. ID-card A4) under permanent storage.
  Future<ScannedDocument> persistGeneratedPdf({
    required DocumentKind kind,
    required String title,
    required String sourcePdfPath,
    List<String> sourceImagePaths = const <String>[],
    String? folderId,
  }) async {
    await _ensureReady();

    final String id = _uuid.v4();
    final Directory targetDir = await _documentDirectoryFor(kind, id);

    try {
      final List<String> savedImages = await _copyImages(
        sourceImagePaths,
        targetDir,
      );

      final String savedPdfPath = p.join(targetDir.path, 'document.pdf');
      await _copyFile(sourcePdfPath, savedPdfPath);

      final ScannedDocument document = ScannedDocument(
        id: id,
        title: title,
        kind: kind,
        createdAt: DateTime.now(),
        pageCount: savedImages.isNotEmpty ? savedImages.length : 1,
        imagePaths: savedImages,
        pdfPath: savedPdfPath,
        folderId: folderId,
      );

      await _upsertDocument(document);
      return document;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Failed to persist generated PDF "$title".',
        cause: error,
      );
    }
  }

  Future<List<ScannedDocument>> listDocuments({String? folderId}) async {
    await _ensureReady();
    final LibraryIndex index = await _readIndex();
    final List<ScannedDocument> docs = List<ScannedDocument>.from(
      index.documents,
    );

    if (folderId != null) {
      docs.retainWhere((ScannedDocument d) => d.folderId == folderId);
    }

    docs.sort(
      (ScannedDocument a, ScannedDocument b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    return docs;
  }

  Future<List<ScannedDocument>> listRecents({int limit = 20}) async {
    final List<ScannedDocument> all = await listDocuments();
    if (all.length <= limit) {
      return all;
    }
    return all.sublist(0, limit);
  }

  Future<ScannedDocument?> getDocument(String id) async {
    await _ensureReady();
    final LibraryIndex index = await _readIndex();
    for (final ScannedDocument doc in index.documents) {
      if (doc.id == id) {
        return doc;
      }
    }
    return null;
  }

  Future<ScannedDocument> updateDocument(ScannedDocument document) async {
    await _ensureReady();
    await _upsertDocument(document);
    return document;
  }

  Future<ScannedDocument> renameDocument(String id, String newTitle) async {
    await _ensureReady();
    final String trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      throw const StorageException('Document title cannot be empty.');
    }
    final ScannedDocument? existing = await getDocument(id);
    if (existing == null) {
      throw StorageException('Document $id was not found.');
    }
    final ScannedDocument updated = existing.copyWith(title: trimmed);
    await _upsertDocument(updated);
    return updated;
  }

  Future<ScannedDocument> addPagesToDocument({
    required String id,
    required List<String> newTempImages,
    required PdfService pdfService,
  }) async {
    await _ensureReady();
    final ScannedDocument? existing = await getDocument(id);
    if (existing == null) {
      throw StorageException('Document $id was not found.');
    }
    if (newTempImages.isEmpty) {
      return existing;
    }

    final Directory docDir = await _documentDirectoryFor(existing.kind, id);
    final List<String> currentImages = List<String>.from(existing.imagePaths);
    int nextIndex = currentImages.length + 1;

    for (final String tempPath in newTempImages) {
      final String ext =
          p.extension(tempPath).isEmpty ? '.jpg' : p.extension(tempPath);
      final String destPath = p.join(
        docDir.path,
        FileNameUtils.withExtension('page_${DateTime.now().millisecondsSinceEpoch}_$nextIndex', ext),
      );
      await _copyFile(tempPath, destPath);
      currentImages.add(destPath);
      nextIndex++;
    }

    final String? pdfPath = existing.pdfPath;
    if (pdfPath != null && pdfPath.isNotEmpty) {
      await pdfService.createDocumentPdfFromImages(
        imagePaths: currentImages,
        outputPath: pdfPath,
      );
    }

    final ScannedDocument updated = existing.copyWith(
      pageCount: currentImages.length,
      imagePaths: currentImages,
    );
    await _upsertDocument(updated);
    return updated;
  }

  Future<ScannedDocument> deletePageFromDocument({
    required String id,
    required int pageIndex,
    required PdfService pdfService,
  }) async {
    await _ensureReady();
    final ScannedDocument? existing = await getDocument(id);
    if (existing == null) {
      throw StorageException('Document $id was not found.');
    }
    if (pageIndex < 0 || pageIndex >= existing.imagePaths.length) {
      throw const StorageException('Invalid page index.');
    }
    if (existing.imagePaths.length <= 1) {
      throw const StorageException('Cannot delete the only page in a document.');
    }

    final List<String> currentImages = List<String>.from(existing.imagePaths);
    final String removedPath = currentImages.removeAt(pageIndex);
    final File removedFile = File(removedPath);
    if (await removedFile.exists()) {
      await removedFile.delete();
    }

    final String? pdfPath = existing.pdfPath;
    if (pdfPath != null && pdfPath.isNotEmpty) {
      await pdfService.createDocumentPdfFromImages(
        imagePaths: currentImages,
        outputPath: pdfPath,
      );
    }

    final ScannedDocument updated = existing.copyWith(
      pageCount: currentImages.length,
      imagePaths: currentImages,
    );
    await _upsertDocument(updated);
    return updated;
  }

  Future<void> deleteDocument(String id) async {
    await _ensureReady();

    try {
      final LibraryIndex index = await _readIndex();
      ScannedDocument? existing;
      for (final ScannedDocument doc in index.documents) {
        if (doc.id == id) {
          existing = doc;
          break;
        }
      }

      if (existing == null) {
        return;
      }

      await _deleteDocumentFiles(existing);

      final LibraryIndex updated = index.copyWith(
        documents: index.documents
            .where((ScannedDocument d) => d.id != id)
            .toList(),
      );
      await _writeIndex(updated);
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Failed to delete document $id.',
        cause: error,
      );
    }
  }

  Future<List<FolderItem>> listFolders() async {
    await _ensureReady();
    final LibraryIndex index = await _readIndex();
    final List<FolderItem> folders = List<FolderItem>.from(index.folders);
    folders.sort(
      (FolderItem a, FolderItem b) => a.name.compareTo(b.name),
    );
    return folders;
  }

  Future<FolderItem> createFolder(String name) async {
    await _ensureReady();
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const StorageException('Folder name cannot be empty.');
    }

    final FolderItem folder = FolderItem(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: DateTime.now(),
    );

    final LibraryIndex index = await _readIndex();
    await _writeIndex(
      index.copyWith(folders: <FolderItem>[...index.folders, folder]),
    );
    return folder;
  }

  Future<FolderItem> renameFolder(String id, String newName) async {
    await _ensureReady();
    final String trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const StorageException('Folder name cannot be empty.');
    }

    final LibraryIndex index = await _readIndex();
    FolderItem? renamed;
    final List<FolderItem> folders = index.folders.map((FolderItem f) {
      if (f.id == id) {
        renamed = f.copyWith(name: trimmed);
        return renamed!;
      }
      return f;
    }).toList();

    if (renamed == null) {
      throw StorageException('Folder $id was not found.');
    }

    await _writeIndex(index.copyWith(folders: folders));
    return renamed!;
  }

  Future<void> deleteFolder(String id, {bool deleteDocuments = false}) async {
    await _ensureReady();
    final LibraryIndex index = await _readIndex();

    List<ScannedDocument> documents = index.documents;
    if (deleteDocuments) {
      final List<String> idsToDelete = documents
          .where((ScannedDocument d) => d.folderId == id)
          .map((ScannedDocument d) => d.id)
          .toList();
      for (final String docId in idsToDelete) {
        await deleteDocument(docId);
      }
      documents = (await _readIndex()).documents;
    } else {
      documents = documents
          .map(
            (ScannedDocument d) =>
                d.folderId == id ? d.copyWith(clearFolderId: true) : d,
          )
          .toList();
    }

    await _writeIndex(
      LibraryIndex(
        documents: documents,
        folders: index.folders.where((FolderItem f) => f.id != id).toList(),
      ),
    );
  }

  Future<ScannedDocument> moveDocumentToFolder({
    required String documentId,
    String? folderId,
  }) async {
    await _ensureReady();
    final ScannedDocument? existing = await getDocument(documentId);
    if (existing == null) {
      throw StorageException('Document $documentId was not found.');
    }

    final ScannedDocument updated = folderId == null
        ? existing.copyWith(clearFolderId: true)
        : existing.copyWith(folderId: folderId);

    await _upsertDocument(updated);
    return updated;
  }

  // --- Internals -----------------------------------------------------------

  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Directory _subdir(String name) {
    return Directory(p.join(_rootDir!.path, name));
  }

  Directory _requireSubdir(String name) {
    if (_rootDir == null) {
      throw const StorageException(
        'StorageService is not initialized. Call initialize() first.',
      );
    }
    return _subdir(name);
  }

  Future<Directory> _documentDirectoryFor(
    DocumentKind kind,
    String id,
  ) async {
    final String parent = switch (kind) {
      DocumentKind.scan => AppConstants.scansDirName,
      DocumentKind.idCard => AppConstants.idCardsDirName,
      DocumentKind.imported => AppConstants.importsDirName,
      DocumentKind.toolOutput => AppConstants.toolsDirName,
    };

    final Directory dir = Directory(p.join(_subdir(parent).path, id));
    await dir.create(recursive: true);
    return dir;
  }

  Future<List<String>> _copyImages(
    List<String> sources,
    Directory targetDir,
  ) async {
    final List<String> saved = <String>[];
    for (int i = 0; i < sources.length; i++) {
      final String source = sources[i];
      final String ext =
          p.extension(source).isEmpty ? '.jpg' : p.extension(source);
      final String destPath = p.join(
        targetDir.path,
        FileNameUtils.withExtension('page_${i + 1}', ext),
      );
      await _copyFile(source, destPath);
      saved.add(destPath);
    }
    return saved;
  }

  Future<void> _copyFile(String sourcePath, String destPath) async {
    try {
      final File source = File(sourcePath);
      if (!await source.exists()) {
        throw StorageException('Source file does not exist: $sourcePath');
      }
      await source.copy(destPath);
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Failed to copy file to $destPath.',
        cause: error,
      );
    }
  }

  Future<void> _deleteDocumentFiles(ScannedDocument document) async {
    final String? anchorPath = document.pdfPath ??
        (document.imagePaths.isNotEmpty ? document.imagePaths.first : null);
    if (anchorPath == null || anchorPath.isEmpty) {
      return;
    }

    final Directory docDir = Directory(p.dirname(anchorPath));
    if (await docDir.exists()) {
      await docDir.delete(recursive: true);
    }
  }

  Future<void> _upsertDocument(ScannedDocument document) async {
    final LibraryIndex index = await _readIndex();
    final List<ScannedDocument> docs = index.documents
        .where((ScannedDocument d) => d.id != document.id)
        .toList();
    docs.add(document);
    await _writeIndex(index.copyWith(documents: docs));
  }

  Future<LibraryIndex> _readIndex() async {
    try {
      final String raw = await _indexFile!.readAsString();
      if (raw.trim().isEmpty) {
        return _emptyIndex();
      }
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      return LibraryIndex.fromJson(json);
    } catch (error) {
      throw StorageException(
        'Failed to read library index.',
        cause: error,
      );
    }
  }

  Future<void> _writeIndex(LibraryIndex index) async {
    try {
      final String encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(index.toJson());
      await _indexFile!.writeAsString(encoded, flush: true);
    } catch (error) {
      throw StorageException(
        'Failed to write library index.',
        cause: error,
      );
    }
  }

  LibraryIndex _emptyIndex() => const LibraryIndex(
        documents: <ScannedDocument>[],
        folders: <FolderItem>[],
      );
}
