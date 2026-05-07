sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
