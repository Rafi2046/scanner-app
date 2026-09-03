/// Origin / kind of a saved library item.
enum DocumentKind {
  scan,
  idCard,
  imported,
  toolOutput,
}

extension DocumentKindX on DocumentKind {
  String get storageKey => name;

  static DocumentKind fromStorageKey(String key) {
    return DocumentKind.values.firstWhere(
      (DocumentKind value) => value.name == key,
      orElse: () => DocumentKind.scan,
    );
  }
}
