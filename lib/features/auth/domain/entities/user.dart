/// User Entity - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

/// Kullanıcı kimlik bilgilerini temsil eden domain entity
/// Immutable ve pure Dart
class User {
  final String studentNumber;
  final String password;
  final String? alias;

  const User({required this.studentNumber, required this.password, this.alias});

  /// Alias veya öğrenci numarasını döndür
  String get displayName => alias ?? studentNumber;

  /// Kimlik bilgilerinin dolu olup olmadığını kontrol et
  bool get hasCredentials => studentNumber.isNotEmpty && password.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          studentNumber == other.studentNumber;

  @override
  int get hashCode => studentNumber.hashCode;

  @override
  String toString() => 'User(studentNumber: $studentNumber, alias: $alias)';

  /// Yeni değerlerle kopyala
  User copyWith({String? studentNumber, String? password, String? alias}) {
    return User(
      studentNumber: studentNumber ?? this.studentNumber,
      password: password ?? this.password,
      alias: alias ?? this.alias,
    );
  }
}
