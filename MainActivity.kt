package app.metoo

import android.telephony.SmsManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
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
    }
}
