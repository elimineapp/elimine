import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Hashes and checks the app lock PIN with PBKDF2-HMAC-SHA256 and a random
/// salt. An encoded hash reads `pbkdf2-sha256$<iterations>$<salt>$<hash>`,
/// salt and hash in base64, so the iteration count can grow without a
/// migration: [needsRehash] tells when a stored hash is weaker than new ones.
///
/// The PIN space is small, so the cost only slows down guessing from a copy
/// of the database; the lock screen's throttling is what limits guessing in
/// the app.
class PinHasher {
  const PinHasher({this.iterations = defaultIterations, this.inIsolate = true});

  /// Measured in a release build on the arm64 emulator on an Apple M5:
  /// 100,000 iterations took 180 ms and 200,000 took 324 ms, about 1.6 µs
  /// each. 60,000 is then about 100 ms there and a few times that on slower
  /// phones, short enough not to delay unlocking.
  static const defaultIterations = 60000;

  static const _scheme = 'pbkdf2-sha256';

  final int iterations;

  /// Off in tests, where an isolate needs real async.
  final bool inIsolate;

  Future<String> hash(String pin) async {
    final random = Random.secure();
    final salt = Uint8List.fromList([
      for (var i = 0; i < 16; i++) random.nextInt(256),
    ]);
    final key = await _derive(pin, salt, iterations);
    return [
      _scheme,
      iterations,
      base64.encode(salt),
      base64.encode(key),
    ].join(r'$');
  }

  /// Whether [pin] matches [encoded]; false for anything malformed.
  Future<bool> verify(String pin, String encoded) async {
    final parts = _parse(encoded);
    if (parts == null) return false;
    final key = await _derive(pin, parts.salt, parts.iterations);
    return _equal(key, parts.key);
  }

  bool needsRehash(String encoded) =>
      (_parse(encoded)?.iterations ?? 0) < iterations;

  Future<Uint8List> _derive(String pin, Uint8List salt, int iterations) {
    final password = utf8.encode(pin);
    return inIsolate
        ? Isolate.run(() => pbkdf2(password, salt, iterations))
        : Future.value(pbkdf2(password, salt, iterations));
  }

  static ({int iterations, Uint8List salt, Uint8List key})? _parse(
    String encoded,
  ) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return null;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) return null;
    try {
      return (
        iterations: iterations,
        salt: base64.decode(parts[2]),
        key: base64.decode(parts[3]),
      );
    } on FormatException {
      return null;
    }
  }

  /// Compares in time that depends only on the lengths.
  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2-HMAC-SHA256 (RFC 8018) with a 32-byte output, one SHA-256 block.
@visibleForTesting
Uint8List pbkdf2(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final result = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }
  return result;
}
