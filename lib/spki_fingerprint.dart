import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_ssl_pinning/hash_helpers.dart';
import 'package:pointycastle/pointycastle.dart';

class SpkiFingerprint {
  static String computeSha256(List<int> certificate) {
    // Certificate  ::=  SEQUENCE  {
    //  tbsCertificate       TBSCertificate,
    //  signatureAlgorithm   AlgorithmIdentifier,
    //  signature            BIT STRING  }
    final cert = ASN1Sequence.fromBytes(Uint8List.fromList(certificate));

    // TBSCertificate  ::=  SEQUENCE  {
    //  version         [0]  Version DEFAULT v1,
    //  serialNumber         CertificateSerialNumber,
    //  signature            AlgorithmIdentifier,
    //  issuer               Name,
    //  validity             Validity,
    //  subject              Name,
    //  subjectPublicKeyInfo SubjectPublicKeyInfo,
    //  issuerUniqueID  [1]  IMPLICIT UniqueIdentifier OPTIONAL,
    //                       -- If present, version MUST be v2 or v3
    //  subjectUniqueID [2]  IMPLICIT UniqueIdentifier OPTIONAL,
    //                       -- If present, version MUST be v2 or v3
    //  extensions      [3]  Extensions OPTIONAL
    //                       -- If present, version MUST be v3 --  }
    final tbs = cert.elements![0] as ASN1Sequence;

    // SubjectPublicKeyInfo  ::=  SEQUENCE  {
    //  algorithm            AlgorithmIdentifier,
    //  subjectPublicKey     BIT STRING  }
    final spki = tbs.elements![6] as ASN1Sequence;

    // Get DER encoded bytes
    final bytes = Uint8List.fromList(
        spki.encodedBytes!.take(spki.totalEncodedByteLength).toList());
    final hash = base64.encode(sha256(bytes));
    return 'sha256/$hash';
  }
}
