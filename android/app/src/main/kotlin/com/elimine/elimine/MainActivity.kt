package com.elimine.elimine

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity, because local_auth shows the biometric prompt as a
// fragment.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "elimine/window")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Blanks the app's card in recent apps without blocking
                    // screenshots, which FLAG_SECURE would. Android 13+ only.
                    "setRecentsHidden" -> {
                        val hidden = call.arguments as Boolean
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            setRecentsScreenshotEnabled(!hidden)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
