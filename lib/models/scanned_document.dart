import 'package:scanner_app/core/enums/document_kind.dart';

/// A permanently saved document in the local library index.
class ScannedDocument {
  const ScannedDocument({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    required this.pageCount,
    required this.imagePaths,
    this.pdfPath,
    this.folderId,
  });

  final String id;
  final String title;
  final DocumentKind kind;
  final DateTime createdAt;
  final int pageCount;

  /// Absolute paths to persisted page images (may be empty for PDF-only imports).
  final List<String> imagePaths;

  /// Absolute path to the primary PDF, if any.
  final String? pdfPath;

  /// Optional folder membership; null means root / All Documents.
  final String? folderId;

  bool get hasPdf => pdfPath != null && pdfPath!.isNotEmpty;

  ScannedDocument copyWith({
    String? id,
    String? title,
    DocumentKind? kind,
    DateTime? createdAt,
    int? pageCount,
    List<String>? imagePaths,
    String? pdfPath,
    String? folderId,
    bool clearFolderId = false,
    bool clearPdfPath = false,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      imagePaths: imagePaths ?? this.imagePaths,
      pdfPath: clearPdfPath ? null : (pdfPath ?? this.pdfPath),
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'kind': kind.storageKey,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
      'imagePaths': imagePaths,
      'pdfPath': pdfPath,
      'folderId': folderId,
    };
  }

  factory ScannedDocument.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawImages =
        json['imagePaths'] as List<dynamic>? ?? const <dynamic>[];

    return ScannedDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: DocumentKindX.fromStorageKey(json['kind'] as String? ?? 'scan'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      pageCount: json['pageCount'] as int? ?? rawImages.length,
      imagePaths: rawImages.map((dynamic e) => e as String).toList(),
      pdfPath: json['pdfPath'] as String?,
      folderId: json['folderId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ScannedDocument && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
