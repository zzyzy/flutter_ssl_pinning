import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

Uint8List sha256(Uint8List input) {
  final sha256 = SHA256Digest();
  final hash = sha256.process(input);
  return hash;
}
