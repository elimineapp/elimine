import 'package:flutter/services.dart';

/// Whether the app's card in the system's recent apps shows its content,
/// behind an interface so tests can replace the platform channel.
abstract interface class RecentsWindow {
  Future<void> setHidden(bool hidden);
}

/// Android 13 and later blank the card; older versions and other platforms
/// ignore the call.
class PlatformRecentsWindow implements RecentsWindow {
  const PlatformRecentsWindow();

  static const _channel = MethodChannel('elimine/window');

  @override
  Future<void> setHidden(bool hidden) async {
    try {
      await _channel.invokeMethod<void>('setRecentsHidden', hidden);
    } on MissingPluginException {
      // Not implemented on this platform.
    }
  }
}
