package com.hendramarihot.platform_bridge

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val batteryChannel = "com.hendramarihot.platform_bridge/battery"
    private val accelerometerChannel = "com.hendramarihot.platform_bridge/accelerometer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, batteryChannel)
            .setMethodCallHandler { call, result ->
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
                            "technology" to "Li-ion",
                        )
                    )
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, accelerometerChannel)
            .setStreamHandler(AccelerometerStreamHandler(this))
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun getBatteryState(): String {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return if (batteryManager.isCharging) "charging" else "discharging"
    }
}

class AccelerometerStreamHandler(private val activity: FlutterActivity) :
    EventChannel.StreamHandler {
    private var sensorManager: SensorManager? = null
    private var sensorListener: SensorEventListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sensorManager = activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        if (accelerometer == null) {
            events?.error("NO_SENSOR", "Accelerometer not available on this device", null)
            return
        }

        sensorListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                event?.let {
                    events?.success(
                        mapOf(
                            "x" to it.values[0].toDouble(),
                            "y" to it.values[1].toDouble(),
                            "z" to it.values[2].toDouble(),
                        )
                    )
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sensorManager?.registerListener(
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
