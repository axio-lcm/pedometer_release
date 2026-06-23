package com.pedometer.motion_fitness

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.time.LocalDate

class MotionFitnessPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    private val channelName = "pedometer/motion_fitness"
    private val stepChannelName = "pedometer/motion_fitness_steps"
    private val activityRecognitionRequestCode = 7401
    private val handler = Handler(Looper.getMainLooper())

    private lateinit var applicationContext: Context
    private lateinit var sensorManager: SensorManager
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var stepCounter: Sensor? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var pendingAuthorizationResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var streamListener: SensorEventListener? = null
    private var latestCounterValue: Float? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        sensorManager = applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        methodChannel = MethodChannel(binding.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, stepChannelName)
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopStepStream()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestAuthorization" -> requestAuthorization(result)
            "authorizationStatus" -> result.success(authorizationStatus())
            "isStepCountingAvailable" -> result.success(isStepCountingAvailable())
            "todaySteps" -> todaySteps(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (!isStepCountingAvailable()) {
            events?.error("unsupported", "Step counting is not available on this device.", null)
            return
        }
        if (!hasActivityRecognitionPermission()) {
            events?.error("denied", "Activity recognition permission is not granted.", null)
            return
        }

        eventSink = events
        startStepStream()
    }

    override fun onCancel(arguments: Any?) {
        stopStepStream()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != activityRecognitionRequestCode) return false

        val status = if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            "authorized"
        } else {
            "denied"
        }
        pendingAuthorizationResult?.success(status)
        pendingAuthorizationResult = null
        return true
    }

    private fun requestAuthorization(result: MethodChannel.Result) {
        val currentActivity = activity
        if (!isStepCountingAvailable()) {
            result.success("unsupported")
            return
        }
        if (hasActivityRecognitionPermission()) {
            result.success("authorized")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success("authorized")
            return
        }
        if (currentActivity == null) {
            result.success("unknown")
            return
        }
        if (pendingAuthorizationResult != null) {
            result.success("unknown")
            return
        }

        pendingAuthorizationResult = result
        ActivityCompat.requestPermissions(
            currentActivity,
            arrayOf(Manifest.permission.ACTIVITY_RECOGNITION),
            activityRecognitionRequestCode,
        )
    }

    private fun authorizationStatus(): String {
        if (!isStepCountingAvailable()) return "unsupported"
        return if (hasActivityRecognitionPermission()) "authorized" else "denied"
    }

    private fun isStepCountingAvailable(): Boolean {
        return stepCounter != null
    }

    private fun hasActivityRecognitionPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
        return ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACTIVITY_RECOGNITION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun todaySteps(result: MethodChannel.Result) {
        val sensor = stepCounter
        if (sensor == null) {
            result.error("unsupported", "Step counting is not available on this device.", null)
            return
        }
        if (!hasActivityRecognitionPermission()) {
            result.error("denied", "Activity recognition permission is not granted.", null)
            return
        }

        latestCounterValue?.let {
            result.success(stepsForCounterValue(it))
            return
        }

        var completed = false
        lateinit var listener: SensorEventListener
        listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (completed) return
                completed = true
                sensorManager.unregisterListener(listener)
                val value = event.values.firstOrNull() ?: 0f
                latestCounterValue = value
                result.success(stepsForCounterValue(value))
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }

        sensorManager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        handler.postDelayed({
            if (completed) return@postDelayed
            completed = true
            sensorManager.unregisterListener(listener)
            result.success(0)
        }, 2_000)
    }

    private fun startStepStream() {
        val sensor = stepCounter ?: return
        streamListener?.let { sensorManager.unregisterListener(it) }
        streamListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val value = event.values.firstOrNull() ?: return
                latestCounterValue = value
                eventSink?.success(mapOf("steps" to stepsForCounterValue(value)))
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }
        sensorManager.registerListener(streamListener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    private fun stopStepStream() {
        streamListener?.let { sensorManager.unregisterListener(it) }
        streamListener = null
        eventSink = null
    }

    private fun stepsForCounterValue(counterValue: Float): Int {
        val today = LocalDate.now().toString()
        val prefs = applicationContext.getSharedPreferences(
            "motion_fitness",
            Context.MODE_PRIVATE,
        )
        val baselineDate = prefs.getString("step_baseline_date", null)
        val baseline = prefs.getFloat("step_baseline_value", counterValue)
        val shouldResetBaseline = baselineDate != today || counterValue < baseline

        val effectiveBaseline = if (shouldResetBaseline) {
            prefs.edit()
                .putString("step_baseline_date", today)
                .putFloat("step_baseline_value", counterValue)
                .apply()
            counterValue
        } else {
            baseline
        }

        return (counterValue - effectiveBaseline).toInt().coerceAtLeast(0)
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
        pendingAuthorizationResult?.success("unknown")
        pendingAuthorizationResult = null
    }
}
