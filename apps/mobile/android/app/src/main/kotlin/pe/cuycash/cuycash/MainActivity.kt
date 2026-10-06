package pe.cuycash.cuycash

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val secureScreenChannel = "cuycash/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureScreenChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // FLAG_SECURE mientras hay un PIN en pantalla: sin capturas y
                // sin miniatura en la vista de apps recientes.
                "setSecure" -> {
                    val secure = call.arguments as? Boolean ?: false
                    if (secure) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
