import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// The texts of the system biometric prompt, in the interface language.
typedef BiometricPromptText = ({String title, String reason, String cancel});

/// The system biometric prompt, behind an interface so tests can replace it.
abstract interface class Biometrics {
  /// Whether a strong biometric, such as a fingerprint, is enrolled.
  Future<bool> isAvailable();

  /// Shows the prompt; false when the user cancels or the check fails.
  Future<bool> authenticate(BiometricPromptText text);
}

class LocalAuthBiometrics implements Biometrics {
  LocalAuthBiometrics();

  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      // Weak face unlock is not good enough to open the app.
      return types.contains(BiometricType.strong) ||
          types.contains(BiometricType.fingerprint);
    } on Exception {
      // No plugin on this platform, or no biometric hardware.
      return false;
    }
  }

  @override
  Future<bool> authenticate(BiometricPromptText text) async {
    try {
      return await _auth.authenticate(
        localizedReason: text.reason,
        authMessages: [
          // No subtitle: the reason already shows as the description, and
          // without one Android adds its own, in English only.
          AndroidAuthMessages(
            signInTitle: text.title,
            signInHint: '',
            cancelButton: text.cancel,
          ),
        ],
        biometricOnly: true,
      );
    } on LocalAuthException {
      // Cancelled, locked out after too many tries, or no longer enrolled:
      // the PIN keypad stays available either way.
      return false;
    }
  }
}
