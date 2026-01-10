/// Result Type - Either/Result Pattern
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../errors/failure.dart';

/// Fonksiyonel hata yönetimi için Result tipi
/// UseCase'ler bu tipi döndürerek başarı/hata durumunu açıkça belirtir
sealed class Result<T> {
  const Result();

  /// Başarılı sonuç mu?
  bool get isSuccess => this is Success<T>;

  /// Başarısız sonuç mu?
  bool get isError => this is Error<T>;

  /// Başarılı ise veriyi döndür, değilse null
  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Error<T>() => null,
  };

  /// Hata varsa failure'ı döndür, yoksa null
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Error<T>(:final failure) => failure,
  };

  /// Pattern matching helper
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Error<T>(:final failure) => error(failure),
    };
  }

  /// Sadece başarı durumunda işlem yap
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success<T>(:final data) => Success(mapper(data)),
      Error<T>(:final failure) => Error(failure),
    };
  }

  /// Sadece başarı durumunda async işlem yap
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    return switch (this) {
      Success<T>(:final data) => Success(await mapper(data)),
      Error<T>(:final failure) => Error(failure),
    };
  }

  /// FlatMap - zincirleme Result işlemleri için
  Result<R> flatMap<R>(Result<R> Function(T data) mapper) {
    return switch (this) {
      Success<T>(:final data) => mapper(data),
      Error<T>(:final failure) => Error(failure),
    };
  }
}

/// Başarılı sonuç
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Hatalı sonuç
class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  String toString() => 'Error(failure: $failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}

/// Extension: Try-catch'i Result'a çevir
extension ResultExtension<T> on Future<T> {
  /// Future'ı Result'a çevir
  Future<Result<T>> toResult({Failure Function(Object error)? onError}) async {
    try {
      return Success(await this);
    } catch (e) {
      if (onError != null) {
        return Error(onError(e));
      }
      return Error(UnknownFailure(message: e.toString(), originalError: e));
    }
  }
}
