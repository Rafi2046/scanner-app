import 'package:scanner_app/models/folder_item.dart';
import 'package:scanner_app/models/scanned_document.dart';

/// On-disk JSON index of documents and folders.
class LibraryIndex {
  const LibraryIndex({
    required this.documents,
    required this.folders,
  });

  final List<ScannedDocument> documents;
  final List<FolderItem> folders;

  LibraryIndex copyWith({
    List<ScannedDocument>? documents,
    List<FolderItem>? folders,
  }) {
    return LibraryIndex(
      documents: documents ?? this.documents,
      folders: folders ?? this.folders,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'documents': documents.map((ScannedDocument d) => d.toJson()).toList(),
      'folders': folders.map((FolderItem f) => f.toJson()).toList(),
    };
  }

  factory LibraryIndex.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawDocs =
        json['documents'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawFolders =
        json['folders'] as List<dynamic>? ?? const <dynamic>[];

    return LibraryIndex(
      documents: rawDocs
          .map(
            (dynamic e) =>
                ScannedDocument.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      folders: rawFolders
          .map(
            (dynamic e) => FolderItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
