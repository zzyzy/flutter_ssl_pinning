import 'dart:io';

// import 'package:flutter_ssl_pinning/app_config.dart';

class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // SecurityContext sc = SecurityContext();
    // sc.setTrustedCertificatesBytes(AppConfig.trustedRootBytes);
    // final httpClient = super.createHttpClient(sc);
    // httpClient.badCertificateCallback = badCertificateCallback;
    final httpClient = super.createHttpClient(context);
    return httpClient;
  }

  bool badCertificateCallback(X509Certificate cert, String host, int port) {
    return false;
  }
}
