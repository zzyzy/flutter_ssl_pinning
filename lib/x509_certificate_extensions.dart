import 'dart:io';

import 'package:flutter_ssl_pinning/spki_fingerprint.dart';

extension X509CertificateExtensions on X509Certificate {
  String getSha256Fingerprint() {
    final der = this.der;
    final sha256 = SpkiFingerprint.computeSha256(der);
    return sha256;
  }

  bool isValid([DateTime? now]) {
    now ??= DateTime.now();
    return now.isAfter(startValidity) && now.isBefore(endValidity);
  }
}
