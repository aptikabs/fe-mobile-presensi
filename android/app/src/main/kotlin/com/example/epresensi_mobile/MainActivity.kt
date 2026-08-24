package com.diskominfo_prov_bengkulu.e_presensimobileprovinsibengkulu

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.InetSocketAddress
import java.net.Socket

class MainActivity : FlutterActivity() {
    private val CHANNEL = "epresensi/native_security"

    companion object {
        init {
            try {
                System.loadLibrary("native_security")
            } catch (_: Throwable) {}
        }
    }

    private external fun checkEmulatorNativeC(): Boolean
    private external fun checkFridaNativeC(): Boolean

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isEmulator" -> result.success(isEmulatorNative())
                "isFridaDetected" -> result.success(isFridaDetectedNative())
                "isRootedNative" -> result.success(isRootedNative())
                else -> result.notImplemented()
            }
        }
    }

    private fun isEmulatorNative(): Boolean {
        var nativeCResult = false
        try {
            nativeCResult = checkEmulatorNativeC()
        } catch (_: Throwable) {}

        return nativeCResult || checkBuildProperties() || checkQemuFiles() || checkSensorHeuristics()
    }

    private fun isFridaDetectedNative(): Boolean {
        var nativeCResult = false
        try {
            nativeCResult = checkFridaNativeC()
        } catch (_: Throwable) {}

        return nativeCResult || checkFridaMaps() || checkTracerPid() || checkFridaFiles() || checkFridaPort()
    }

    private fun isRootedNative(): Boolean {
        return checkSuPaths() || checkMagiskFiles() || checkBuildTags()
    }

    private fun checkSensorHeuristics(): Boolean {
        try {
            val sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return true
            val sensors = sensorManager.getSensorList(Sensor.TYPE_ALL) ?: return true

            // Most real physical Android smartphones have 10-30+ sensors.
            // Emulators typically have < 5 sensors or zero physical sensors.
            if (sensors.size < 5) return true

            val hasAccelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null
            val hasGyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null
            val hasMagnetic = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null
            val hasProximity = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY) != null

            // If a device lacks both magnetic field and proximity sensor simultaneously, it's virtually an emulator
            if (!hasMagnetic && !hasProximity && !hasGyroscope) return true
        } catch (_: Exception) {}
        return false
    }

    private fun checkBuildProperties(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val product = Build.PRODUCT.lowercase()
        val brand = Build.BRAND.lowercase()
        val board = Build.BOARD.lowercase()
        val device = Build.DEVICE.lowercase()

        if (fingerprint.startsWith("generic") || fingerprint.startsWith("unknown")) return true
        if (model.contains("google_sdk") || model.contains("emulator") || model.contains("android sdk built for x86") || model.contains("sdk_gphone")) return true
        if (hardware.contains("goldfish") || hardware.contains("ranchu") || hardware.contains("vbox86") || hardware.contains("nox")) return true
        if (manufacturer.contains("genymotion") || manufacturer.contains("andy") || manufacturer.contains("nox") || manufacturer.contains("bluestacks") || manufacturer.contains("tencent")) return true
        if (brand.startsWith("generic") && device.startsWith("generic")) return true
        if (product.contains("sdk") || product.contains("google_sdk") || product.contains("vbox86p") || product.contains("nox") || product.contains("genymotion") || product.contains("sdk_gphone")) return true
        if (board.contains("nox")) return true

        return false
    }

    private fun checkQemuFiles(): Boolean {
        val knownPipes = arrayOf(
            "/dev/socket/qemud",
            "/dev/qemu_pipe",
            "/sys/qemu_trace",
            "/system/lib/libc_malloc_debug_qemu.so",
            "/system/bin/nox-prop",
            "/system/bin/ttVM-prop",
            "/drivers/vboxguest",
            "/sys/module/vboxguest",
            "/sys/module/qemu_trace",
            "/system/lib/libhoudini.so",
            "/system/lib64/libhoudini.so",
            "/system/lib/libndk_translation.so",
            "/system/lib64/libndk_translation.so"
        )
        for (pipe in knownPipes) {
            if (File(pipe).exists()) {
                return true
            }
        }
        return false
    }

    private fun checkFridaMaps(): Boolean {
        try {
            val reader = BufferedReader(FileReader("/proc/self/maps"))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                val lowerLine = line!!.lowercase()
                if (lowerLine.contains("frida") ||
                    lowerLine.contains("gadget") ||
                    lowerLine.contains("linjector") ||
                    lowerLine.contains("xposed") ||
                    lowerLine.contains("substrate")
                ) {
                    reader.close()
                    return true
                }
            }
            reader.close()
        } catch (_: Exception) {}
        return false
    }

    private fun checkTracerPid(): Boolean {
        if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) return true

        try {
            val reader = BufferedReader(FileReader("/proc/self/status"))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                if (line!!.startsWith("TracerPid:")) {
                    val pidString = line!!.split("\t").getOrNull(1)?.trim()
                    val pid = pidString?.toIntOrNull() ?: 0
                    if (pid > 0) {
                        reader.close()
                        return true
                    }
                }
            }
            reader.close()
        } catch (_: Exception) {}
        return false
    }

    private fun checkFridaFiles(): Boolean {
        val fridaPaths = arrayOf(
            "/data/local/tmp/frida-server",
            "/data/local/tmp/re.frida.server",
            "/data/local/tmp/frida-agent.so",
            "/data/local/tmp/frida-gadget.so"
        )
        for (path in fridaPaths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkFridaPort(): Boolean {
        val ports = intArrayOf(27042, 27043)
        for (port in ports) {
            try {
                val socket = Socket()
                socket.connect(InetSocketAddress("127.0.0.1", port), 200)
                socket.close()
                return true
            } catch (_: Exception) {}
        }
        return false
    }

    private fun checkSuPaths(): Boolean {
        val suPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )
        for (path in suPaths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkMagiskFiles(): Boolean {
        val magiskPaths = arrayOf(
            "/dev/com.topjohnwu.magisk",
            "/sbin/.magisk",
            "/cache/magisk.log",
            "/data/adb/magisk"
        )
        for (path in magiskPaths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }
}
