import 'dart:io';

class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    SecurityContext sc = SecurityContext();
    // sc.setTrustedCertificatesBytes(AppConfig.trustedRootBytes);
    final httpClient = super.createHttpClient(sc);
    httpClient.badCertificateCallback = badCertificateCallback;
    return httpClient;
  }

  bool badCertificateCallback(X509Certificate cert, String host, int port) {
    return false;
  }
}
