// SPDX-License-Identifier: ice License 1.0

sealed class IONContentLabelerException implements Exception {
  const IONContentLabelerException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'IONContentLabelerException(code: $code, message: $message)';
}

class LoadFfiLibraryException extends IONContentLabelerException {
  const LoadFfiLibraryException(dynamic error) : super(20000, 'Failed to load library: $error');
}

class LoadFfiModelException extends IONContentLabelerException {
  const LoadFfiModelException(dynamic error) : super(20001, 'Failed to load ffi model: $error');
}

class CreateFastTextInstanceException extends IONContentLabelerException {
  const CreateFastTextInstanceException() : super(20002, 'Failed to create FastText instance');
}

class FastTextPredictionException extends IONContentLabelerException {
  const FastTextPredictionException(dynamic error)
      : super(20003, 'Fast Text prediction exception: $error');
}

class FastTextDisposeException extends IONContentLabelerException {
  const FastTextDisposeException(dynamic error)
      : super(20004, 'Fast Text dispose exception: $error');
}

class NetworkModelDownloadException extends IONContentLabelerException {
  const NetworkModelDownloadException(String url, dynamic error)
      : super(20005, 'Failed to download network model $url: $error');
}

class AssetModelCopyException extends IONContentLabelerException {
  const AssetModelCopyException(String name, dynamic error)
      : super(20006, 'Failed to copy asset model $name: $error');
}
