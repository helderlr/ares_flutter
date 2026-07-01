package br.com.domina.aresia

import android.content.pm.PackageManager
import com.google.android.gms.maps.MapsInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "br.com.domina.aresia/google_maps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setApiKey" -> {
                    val apiKey = call.argument<String>("apiKey")
                    if (apiKey.isNullOrBlank()) {
                        result.error("INVALID_KEY", "API key is empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val appInfo = packageManager.getApplicationInfo(
                            packageName,
                            PackageManager.GET_META_DATA,
                        )
                        appInfo.metaData.putString(
                            "com.google.android.geo.API_KEY",
                            apiKey,
                        )
                        MapsInitializer.initialize(applicationContext)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error(
                            "SET_KEY_FAILED",
                            error.message,
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
