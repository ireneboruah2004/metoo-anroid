package app.metoo

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private var pendingPermResult: MethodChannel.Result? = null

    private val callPermissions = arrayOf(
        Manifest.permission.READ_PHONE_STATE,
        Manifest.permission.CALL_PHONE,
        Manifest.permission.READ_CALL_LOG
    )

    private fun granted(p: String): Boolean =
        checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "metoo/sms")
            .setMethodCallHandler { call, result ->
                if (call.method != "send") { result.notImplemented(); return@setMethodCallHandler }
                try {
                    val numbers = call.argument<List<String>>("numbers") ?: emptyList()
                    val body = call.argument<String>("body") ?: ""
                    val sms = if (Build.VERSION.SDK_INT >= 31)
                        getSystemService(SmsManager::class.java)
                    else @Suppress("DEPRECATION") SmsManager.getDefault()
                    val parts = sms.divideMessage(body)
                    for (n in numbers) sms.sendMultipartTextMessage(n, null, parts, null, null)
                    result.success(numbers.isNotEmpty())
                } catch (e: Exception) {
                    result.success(false)
                }
            }

        // Home-screen widget: settings sync and the call-related permissions.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "metoo/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sync" -> {
                        try {
                            val numbers = call.argument<List<String>>("numbers") ?: emptyList()
                            val siren = call.argument<Boolean>("siren") ?: false
                            val countdown = call.argument<Int>("countdown") ?: 5
                            getSharedPreferences(SosService.PREFS, MODE_PRIVATE).edit()
                                .putString("numbers", numbers.joinToString(","))
                                .putBoolean("siren", siren)
                                .putInt("countdown", countdown)
                                .apply()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "callPerms" -> {
                        result.success(
                            mapOf(
                                "phone" to (granted(Manifest.permission.READ_PHONE_STATE) &&
                                    granted(Manifest.permission.CALL_PHONE)),
                                "calllog" to granted(Manifest.permission.READ_CALL_LOG)
                            )
                        )
                    }
                    "requestCallPerms" -> {
                        val missing = callPermissions.filter { !granted(it) }
                        if (missing.isEmpty()) {
                            result.success(true)
                        } else if (pendingPermResult != null) {
                            result.success(false)
                        } else {
                            pendingPermResult = result
                            requestPermissions(missing.toTypedArray(), 91)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 91) {
            val ok = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermResult?.success(ok)
            pendingPermResult = null
        }
    }
}
