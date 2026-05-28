package com.hendramarihot.platform_bridge

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val batteryChannelName = "com.hendramarihot.platform_bridge/battery"
    private val accelerometerChannelName = "com.hendramarihot.platform_bridge/accelerometer"

    private var batteryChannel: MethodChannel? = null
    private var accelerometerChannel: EventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        batteryChannel = MethodChannel(messenger, batteryChannelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryLevel" -> {
                        val level = getBatteryLevel()
                        if (level != -1) result.success(level)
                        else result.error("UNAVAILABLE", "Battery level not available", null)
                    }
                    "getBatteryState" -> result.success(getBatteryState())
                    "getBatteryInfo" -> result.success(
                        mapOf(
                            "level" to getBatteryLevel(),
                            "state" to getBatteryState(),
                            "technology" to getBatteryTechnology(),
                        )
                    )
                    else -> result.notImplemented()
                }
            }
        }

        accelerometerChannel = EventChannel(messenger, accelerometerChannelName).apply {
            // Sensors are process-global; an application context avoids leaking the Activity.
            setStreamHandler(AccelerometerStreamHandler(applicationContext))
        }
    }

    // Detach handlers so a cached/retained FlutterEngine does not keep this Activity reachable.
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        batteryChannel?.setMethodCallHandler(null)
        accelerometerChannel?.setStreamHandler(null)
        batteryChannel = null
        accelerometerChannel = null
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        // getIntProperty returns Integer.MIN_VALUE on devices/emulators without the property.
        return if (level in 0..100) level else -1
    }

    private fun getBatteryState(): String {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return if (batteryManager.isCharging) "charging" else "discharging"
    }

    private fun getBatteryTechnology(): String {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return intent?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "unknown"
    }
}

class AccelerometerStreamHandler(private val context: Context) :
    EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sensorManager: SensorManager? = null
    private var sensorListener: SensorEventListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        if (accelerometer == null) {
            events?.error("NO_SENSOR", "Accelerometer not available on this device", null)
            return
        }

        sensorManager = manager
        sensorListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                val values = event?.values ?: return
                val data = mapOf(
                    "x" to values[0].toDouble(),
                    "y" to values[1].toDouble(),
                    "z" to values[2].toDouble(),
                )
                // EventSink methods are @UiThread; ensure we post to the main thread
                // regardless of which thread SensorManager delivers callbacks on.
                mainHandler.post { events?.success(data) }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        manager.registerListener(
            sensorListener,
            accelerometer,
            SensorManager.SENSOR_DELAY_UI,
        )
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(sensorListener)
        sensorListener = null
        sensorManager = null
    }
}
