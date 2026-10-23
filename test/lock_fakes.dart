import 'package:elimine/features/lock/biometrics.dart';
import 'package:elimine/features/lock/pin_hash.dart';
import 'package:elimine/features/lock/recents_window.dart';

/// One iteration and no isolate, so widget tests need no real async.
const fastPinHasher = PinHasher(iterations: 1, inIsolate: false);

class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.available = true, this.succeed = true});

  bool available;
  bool succeed;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(BiometricPromptText text) async {
    prompts++;
    return available && succeed;
  }
}

class FakeRecentsWindow implements RecentsWindow {
  final calls = <bool>[];

  @override
  Future<void> setHidden(bool hidden) async => calls.add(hidden);
}
