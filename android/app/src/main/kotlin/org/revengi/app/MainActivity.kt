package org.revengi.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter.native/helper"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceInfo") {
                val deviceInfo: HashMap<String, String> = getDeviceInfo()
                if (deviceInfo.isNotEmpty()) {
                    result.success(deviceInfo)
                } else {
                    result.error("UNAVAILABLE", "Device info not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getDeviceInfo(): HashMap<String, String> {
        val deviceInfo = HashMap<String, String>()
        deviceInfo["version"] = System.getProperty("os.version").toString()
        deviceInfo["device"] = Build.DEVICE
        deviceInfo["model"] = Build.MODEL
        deviceInfo["product"] = Build.PRODUCT
        deviceInfo["manufacturer"] = Build.MANUFACTURER
        deviceInfo["sdkVersion"] = Build.VERSION.SDK_INT.toString()
        deviceInfo["id"] = Build.ID
        return deviceInfo
    }
}
