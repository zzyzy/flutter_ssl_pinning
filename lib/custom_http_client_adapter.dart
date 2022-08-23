import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ssl_pinning/app_config.dart';
import 'package:flutter_ssl_pinning/custom_http_client.dart';
import 'package:flutter_ssl_pinning/x509_certificate_extensions.dart';

class CustomHttpClientAdapter extends DefaultHttpClientAdapter {
  CustomHttpClientAdapter() {
    super.onHttpClientCreate = _onHttpClientCreate;
  }

  HttpClient? _onHttpClientCreate(HttpClient _) {
    final client = CustomHttpClient();

    client.serverCertificateCustomValidationCallback = (chain, host, port) {
      for (var cert in chain) {
        if (kDebugMode) {
          debugPrint(cert.getSha256Fingerprint());
        }

        final sha256 = cert.getSha256Fingerprint();
        if (AppConfig.certificatePins.contains(sha256) && cert.isValid()) {
          return true;
        }
      }

      return false;
    };

    return client;
  }
}
