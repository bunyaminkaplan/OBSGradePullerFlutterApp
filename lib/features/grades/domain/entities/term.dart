/// Term Entity - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

/// Akademik dönem domain entity
/// Immutable ve pure Dart
class Term {
  final String id;
  final String name;

  const Term({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Term && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Term($id: $name)';
}
