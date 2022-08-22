class InvalidSslCertificateException implements Exception {
  InvalidSslCertificateException([this.message]);

  final String? message;

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}
