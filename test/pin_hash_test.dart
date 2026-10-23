import 'dart:convert';

import 'package:elimine/features/lock/pin_hash.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  const hasher = PinHasher(iterations: 10, inIsolate: false);

  test('PBKDF2-HMAC-SHA256 matches the published test vectors', () {
    final password = utf8.encode('password');
    final salt = utf8.encode('salt');
    expect(
      hex(pbkdf2(password, salt, 1)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    expect(
      hex(pbkdf2(password, salt, 2)),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
    expect(
      hex(pbkdf2(password, salt, 4096)),
      'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
    );
  });

  test('the right PIN verifies and a wrong one does not', () async {
    final encoded = await hasher.hash('2468');
    expect(encoded, startsWith(r'pbkdf2-sha256$10$'));
    expect(await hasher.verify('2468', encoded), isTrue);
    expect(await hasher.verify('2469', encoded), isFalse);
    expect(await hasher.verify('24680', encoded), isFalse);
  });

  test('the same PIN gets a different salt every time', () async {
    final a = await hasher.hash('2468');
    final b = await hasher.hash('2468');
    expect(a, isNot(b));
    expect(await hasher.verify('2468', b), isTrue);
  });

  test(
    'a hash with fewer iterations still verifies and needs a rehash',
    () async {
      final old = await const PinHasher(
        iterations: 3,
        inIsolate: false,
      ).hash('1357');
      expect(await hasher.verify('1357', old), isTrue);
      expect(hasher.needsRehash(old), isTrue);
      expect(hasher.needsRehash(await hasher.hash('1357')), isFalse);
    },
  );

  test('malformed encodings never verify', () async {
    for (final bad in [
      '',
      'plain',
      r'md5$1$AA==$AA==',
      r'pbkdf2-sha256$x$AA==$AA==',
      r'pbkdf2-sha256$1$!!$AA==',
    ]) {
      expect(await hasher.verify('2468', bad), isFalse, reason: bad);
    }
  });

  test('hashing runs in an isolate by default', () async {
    const isolated = PinHasher(iterations: 10);
    final encoded = await isolated.hash('2468');
    expect(await isolated.verify('2468', encoded), isTrue);
  });
}
