package app.metoo

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * Invisible screen that asks for the phone's own lock (PIN, pattern, password
 * or fingerprint where the phone offers it) before the siren is stopped.
 * If the phone has no screen lock at all, the siren stops straight away.
 */
class StopSirenActivity : Activity() {

    private val requestCode = 77

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (km.isDeviceSecure) {
            @Suppress("DEPRECATION")
            val intent = km.createConfirmDeviceCredentialIntent(
                "Stop the siren", "Unlock your phone to stop the siren"
            )
            if (intent != null) {
                @Suppress("DEPRECATION")
                startActivityForResult(intent, requestCode)
                return
            }
        }
        stopNow()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(code: Int, result: Int, data: Intent?) {
        super.onActivityResult(code, result, data)
        if (code == requestCode && result == RESULT_OK) stopNow() else finish()
    }

    private fun stopNow() {
        startService(Intent(this, SosService::class.java).setAction(SosService.ACTION_STOP_SIREN))
        finish()
    }
}
