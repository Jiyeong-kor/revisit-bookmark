import 'failures.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Ok<T>;
  bool get isFailure => this is Err<T>;

  T? get dataOrNull => switch (this) {
        Ok(:final data) => data,
        Err() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Ok() => null,
        Err(:final failure) => failure,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Ok(:final data) => success(data),
        Err(:final failure) => onFailure(failure),
      };
}
