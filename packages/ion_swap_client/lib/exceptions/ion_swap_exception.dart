class IonSwapException implements Exception {
  const IonSwapException([this.message]);

  final String? message;

  @override
  String toString() => 'IonSwapException: $message';
}
