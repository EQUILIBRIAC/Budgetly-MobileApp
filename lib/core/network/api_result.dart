import 'network_exception.dart';

/// Resultado de operaciones contra el API para flujos que no usan excepciones.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  void fold({
    required void Function(T value) success,
    required void Function(NetworkException error) failure,
  }) {
    final self = this;
    if (self is ApiSuccess<T>) {
      success(self.value);
      return;
    }
    if (self is ApiFailure<T>) {
      failure(self.exception);
    }
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T value;

  const ApiSuccess(this.value);
}

final class ApiFailure<T> extends ApiResult<T> {
  final NetworkException exception;

  const ApiFailure(this.exception);
}
