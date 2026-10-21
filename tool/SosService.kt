package app.metoo

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.database.ContentObserver
import android.graphics.drawable.Icon
import android.location.Location
import android.location.LocationManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.telecom.TelecomManager
import android.telephony.SmsManager
import android.widget.Toast
import java.util.Calendar
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Runs when the home-screen widget is tapped. Counts the taps, then:
 *   1 tap  -> countdown (default 5 s, with a Cancel button), then call + SMS
 *   2 taps -> call + SMS immediately
 *   3 taps -> siren + SMS (only if the siren is switched on in the app setup)
 */
class SosService : Service() {

    companion object {
        const val ACTION_TAP = "app.metoo.action.TAP"
        const val ACTION_CANCEL = "app.metoo.action.CANCEL"
        const val ACTION_STOP_SIREN = "app.metoo.action.STOP_SIREN"
        const val PREFS = "metoo_widget"
        private const val CHANNEL = "metoo_sos"
        private const val NOTIF_ID = 4242
        private const val TAP_WINDOW_MS = 600L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var foregroundStarted = false
    private var taps = 0
    private var countingDown = false
    private var secondsLeft = 0
    private var sirenOn = false
    private var busy = false
    private var player: MediaPlayer? = null
    private var volumeBefore = -1
    private var volumeObserver: ContentObserver? = null

    private val decide = Runnable { onTapsSettled() }

    private val tick = object : Runnable {
        override fun run() {
            if (!countingDown) return
            secondsLeft--
            if (secondsLeft <= 0) {
                fireNow()
            } else {
                showCountdown()
                handler.postDelayed(this, 1000)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "MeToo SOS", NotificationManager.IMPORTANCE_HIGH)
            )
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureForeground()
        when (intent?.action) {
            ACTION_TAP -> {
                taps++
                handler.removeCallbacks(decide)
                handler.postDelayed(decide, TAP_WINDOW_MS)
            }
            ACTION_CANCEL -> cancelCountdown()
            ACTION_STOP_SIREN -> stopSiren()
            else -> finishIfIdle()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        releaseSiren()
        super.onDestroy()
    }

    // ------------------------------------------------------------- settings

    private fun prefs() = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun contacts(): List<String> =
        (prefs().getString("numbers", "") ?: "").split(",").map { it.trim() }.filter { it.isNotEmpty() }

    // ---------------------------------------------------------- tap handling

    private fun onTapsSettled() {
        val n = taps
        taps = 0
        when {
            n >= 3 -> {
                if (prefs().getBoolean("siren", false)) {
                    startSiren()
                } else {
                    toast("Siren is switched off in MeToo settings")
                    finishIfIdle()
                }
            }
            n == 2 || (n == 1 && countingDown) -> fireNow()
            n == 1 -> startCountdown()
            else -> finishIfIdle()
        }
    }

    private fun startCountdown() {
        if (contacts().isEmpty()) {
            toast("Add a trusted contact in MeToo first")
            finishIfIdle()
            return
        }
        secondsLeft = prefs().getInt("countdown", 5).coerceIn(0, 10)
        if (secondsLeft == 0) {
            fireNow()
            return
        }
        countingDown = true
        vibrate(150)
        showCountdown()
        handler.postDelayed(tick, 1000)
    }

    private fun cancelCountdown() {
        handler.removeCallbacks(tick)
        if (countingDown) toast("Cancelled")
        countingDown = false
        finishIfIdle()
    }

    private fun fireNow() {
        handler.removeCallbacks(tick)
        countingDown = false
        val numbers = contacts()
        if (numbers.isEmpty()) {
            toast("Add a trusted contact in MeToo first")
            finishIfIdle()
            return
        }
        vibrate(400)
        notify(buildNotification("MeToo: alert sent", "Calling ${numbers[0]} and sending your location"))
        busy = true
        placeCall(numbers[0])
        Thread {
            sendAlertSms(numbers)
            handler.post {
                busy = false
                finishIfIdle()
            }
        }.start()
    }

    private fun finishIfIdle() {
        if (!countingDown && !sirenOn && !busy && taps == 0) {
            handler.removeCallbacks(decide)
            stopForeground(Service.STOP_FOREGROUND_REMOVE)
            foregroundStarted = false
            stopSelf()
        }
    }

    // ------------------------------------------------------------------ call

    private fun placeCall(number: String) {
        if (checkSelfPermission(Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            toast("Phone permission missing. Open MeToo and allow Phone.")
            return
        }
        try {
            val tm = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            tm.placeCall(Uri.fromParts("tel", number, null), Bundle())
        } catch (e: Exception) {
            try {
                startActivity(
                    Intent(Intent.ACTION_CALL, Uri.parse("tel:" + Uri.encode(number)))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            } catch (e2: Exception) {
                toast("Could not place the call")
            }
        }
    }

    // ------------------------------------------------------------------- SMS

    private fun buildMessage(): String {
        val cal = Calendar.getInstance()
        val hh = cal.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')
        val mm = cal.get(Calendar.MINUTE).toString().padStart(2, '0')
        val loc = bestLocation()
        if (loc == null) {
            return "EMERGENCY: I need help. I could not get my location. " +
                "Please call me now. (MeToo, $hh:$mm)"
        }
        val link = "https://maps.google.com/?q=" +
            String.format(java.util.Locale.US, "%.6f,%.6f", loc.latitude, loc.longitude)
        return "EMERGENCY: I need help. My location: $link " +
            "(accuracy about ${Math.round(loc.accuracy)} m). Sent via MeToo at $hh:$mm."
    }

    @Suppress("DEPRECATION")
    private fun sendAlertSms(numbers: List<String>) {
        if (checkSelfPermission(Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
            handler.post { toast("SMS permission missing. Open MeToo and allow SMS.") }
            return
        }
        try {
            val sms = if (Build.VERSION.SDK_INT >= 31)
                getSystemService(SmsManager::class.java)
            else SmsManager.getDefault()
            val parts = sms.divideMessage(buildMessage())
            for (n in numbers) sms.sendMultipartTextMessage(n, null, parts, null, null)
        } catch (e: Exception) {
            handler.post { toast("Could not send the SMS") }
        }
    }

    /** Fresh fix if possible (Android 11+), otherwise the newest known position. */
    private fun bestLocation(): Location? {
        val fine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!fine && !coarse) return null
        try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            if (Build.VERSION.SDK_INT >= 30) {
                val provider = when {
                    fine && lm.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
                    lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
                    else -> null
                }
                if (provider != null) {
                    val latch = CountDownLatch(1)
                    var fresh: Location? = null
                    val signal = CancellationSignal()
                    lm.getCurrentLocation(provider, signal, mainExecutor) { l ->
                        fresh = l
                        latch.countDown()
                    }
                    if (!latch.await(7, TimeUnit.SECONDS)) signal.cancel()
                    if (fresh != null) return fresh
                }
            }
            var best: Location? = null
            for (p in lm.getProviders(true)) {
                val l: Location? = try { lm.getLastKnownLocation(p) } catch (e: Exception) { null }
                if (l == null) continue
                val current = best
                if (current == null || l.time > current.time) best = l
            }
            return best
        } catch (e: Exception) {
            return null
        }
    }

    // ----------------------------------------------------------------- siren

    private fun startSiren() {
        if (sirenOn) return
        handler.removeCallbacks(tick)
        countingDown = false
        try {
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            volumeBefore = am.getStreamVolume(AudioManager.STREAM_ALARM)
            val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            am.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)

            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            val afd = resources.openRawResourceFd(R.raw.siren)
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mp.isLooping = true
            mp.prepare()
            mp.start()
            player = mp

            // Put the alarm volume back to maximum if someone turns it down.
            val obs = object : ContentObserver(handler) {
                override fun onChange(selfChange: Boolean) {
                    if (sirenOn) am.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)
                }
            }
            contentResolver.registerContentObserver(Settings.System.CONTENT_URI, true, obs)
            volumeObserver = obs
            sirenOn = true
        } catch (e: Exception) {
            releaseSiren()
            toast("Could not start the siren")
            finishIfIdle()
            return
        }

        val stopPi = PendingIntent.getActivity(
            this, 2, Intent(this, StopSirenActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        notify(
            buildNotification(
                "MeToo: SIREN ON", "Tap Stop, then unlock your phone to silence it",
                listOf(action("Stop siren", stopPi)), stopPi
            )
        )
        vibrate(400)

        val numbers = contacts()
        if (numbers.isNotEmpty()) {
            busy = true
            Thread {
                sendAlertSms(numbers)
                handler.post { busy = false }
            }.start()
        }
    }

    /** Called only after the unlock check in StopSirenActivity succeeded. */
    private fun stopSiren() {
        releaseSiren()
        finishIfIdle()
    }

    private fun releaseSiren() {
        try { player?.stop() } catch (e: Exception) {}
        try { player?.release() } catch (e: Exception) {}
        player = null
        volumeObserver?.let { try { contentResolver.unregisterContentObserver(it) } catch (e: Exception) {} }
        volumeObserver = null
        if (volumeBefore >= 0) {
            try {
                val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                am.setStreamVolume(AudioManager.STREAM_ALARM, volumeBefore, 0)
            } catch (e: Exception) {}
            volumeBefore = -1
        }
        sirenOn = false
    }

    // --------------------------------------------------------- notifications

    private fun ensureForeground() {
        if (foregroundStarted) return
        val n = buildNotification("MeToo SOS", "Working on your tap")
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, n)
        }
        foregroundStarted = true
    }

    private fun showCountdown() {
        val cancelPi = PendingIntent.getService(
            this, 1, Intent(this, SosService::class.java).setAction(ACTION_CANCEL),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        notify(
            buildNotification(
                "MeToo: calling in $secondsLeft s",
                "Tap Cancel if this was a mistake. Tap the widget again to call now.",
                listOf(action("Cancel", cancelPi)), cancelPi
            )
        )
    }

    private fun notify(n: Notification) {
        try {
            getSystemService(NotificationManager::class.java).notify(NOTIF_ID, n)
        } catch (e: Exception) {}
    }

    private fun action(title: String, pi: PendingIntent): Notification.Action {
        val icon = Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel)
        return Notification.Action.Builder(icon, title, pi).build()
    }

    @Suppress("DEPRECATION")
    private fun buildNotification(
        title: String,
        text: String,
        actions: List<Notification.Action> = emptyList(),
        content: PendingIntent? = null
    ): Notification {
        val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL)
        else Notification.Builder(this)
        b.setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_ALARM)
        if (Build.VERSION.SDK_INT < 26) b.setPriority(Notification.PRIORITY_HIGH)
        for (a in actions) b.addAction(a)
        if (content != null) b.setContentIntent(content)
        return b.build()
    }

    @Suppress("DEPRECATION")
    private fun vibrate(ms: Long) {
        try {
            val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
            if (Build.VERSION.SDK_INT >= 26) {
                v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                v.vibrate(ms)
            }
        } catch (e: Exception) {}
    }

    private fun toast(msg: String) {
        handler.post { Toast.makeText(applicationContext, msg, Toast.LENGTH_LONG).show() }
    }
}
