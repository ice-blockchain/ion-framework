// SPDX-License-Identifier: ice License 1.0

typedef JsonObject = Map<String, dynamic>;

typedef OnPasswordFlow<T> = Future<T> Function({required String password});
typedef OnPasskeyFlow<T> = Future<T> Function();
typedef OnBiometricsFlow<T> = Future<T> Function({
  required String localisedReason,
  required String localisedCancel,
});

typedef OnVerifyIdentity<T> = Future<T> Function({
  required OnBiometricsFlow<T> onBiometricsFlow,
  required OnPasswordFlow<T> onPasswordFlow,
  required OnPasskeyFlow<T> onPasskeyFlow,
});

typedef WithVerifyIdentity<T> = void Function(OnVerifyIdentity<T> onVerifyIdentity);

typedef GetRequestId = Future<String> Function(String username);
