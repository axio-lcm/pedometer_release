package com.example.pedometer_health

import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PedometerHealthPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "pedometer_health")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                val source = call.argument<String>("source")
                result.success(source == "healthConnect" && Build.VERSION.SDK_INT >= 34)
            }
            "requestAuthorization" -> result.success(false)
            "fetchDailySummaries" -> result.success(emptyList<Map<String, Any>>())
            else -> result.notImplemented()
        }
    }
}
