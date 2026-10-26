package com.alarmxv.alarm_xv

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextClock
import android.widget.TextView
import java.util.UUID
import kotlin.math.roundToInt

class RingingService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var mediaPlayer: MediaPlayer? = null
    private var toneGenerator: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var fallbackToneActive = false
    private var volumeGuardEnabled = false
    private var volumeOverrideActive = false
    private var guardedVolume = 0
    private var currentAlarm: AlarmData? = null
    private var currentSnoozeCount = 0
    private var challengeInProgress = false
    private var alarmActivityVisible = false
    private var guardOverlay: View? = null
    private var sessionToken = ""

    private val restoreAlarmScreen = Runnable {
        if (alarmActivityVisible || currentAlarm == null || currentAlarm?.isNormal == true) return@Runnable
        showGuardOverlay()
        if (guardOverlay != null) launchAlarmActivity()
    }

    private val volumeMonitor = object : Runnable {
        override fun run() {
            if (!volumeGuardEnabled) return
            val audioManager = getSystemService(AudioManager::class.java)
            if (audioManager.getStreamVolume(AudioManager.STREAM_ALARM) < guardedVolume) {
                runCatching {
                    audioManager.setStreamVolume(AudioManager.STREAM_ALARM, guardedVolume, 0)
                }
            }
            handler.postDelayed(this, 1_000)
        }
    }
    private val fallbackTone = object : Runnable {
        override fun run() {
            if (!fallbackToneActive) return
            toneGenerator?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 900)
            handler.postDelayed(this, 1_200)
        }
    }

    override fun onCreate() {
        super.onCreate()
        activeInstance = this
        ensureNotificationChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == actionDismissNormal) {
            dismissNormalSession(intent.getStringExtra(extraAlarmId).orEmpty(),
                intent.getStringExtra(extraSessionToken).orEmpty())
            if (currentAlarm == null) stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action == actionPauseForChallenge) {
            if (currentAlarm == null) {
                stopSelf()
                return START_NOT_STICKY
            }
            if (currentAlarm?.isNormal == true) return START_NOT_STICKY
            challengeInProgress = true
            pauseRingingForChallenge()
            return START_NOT_STICKY
        }
        val encoded = intent?.getStringExtra(extraAlarmJson) ?: return START_NOT_STICKY
        val alarm = try {
            AlarmData.fromJson(org.json.JSONObject(encoded))
        } catch (_: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }
        val snoozeCount = intent.getIntExtra(extraSnoozeCount, 0)
        if (currentAlarm?.id == alarm.id && currentSnoozeCount == snoozeCount &&
            !challengeInProgress && currentAlarm == alarm
        ) return START_NOT_STICKY
        // A new session owns the one player and its volume override; release the previous one first.
        stopSoundAndVibration()
        stopVolumeOverride()
        removeGuardOverlay()
        currentAlarm = alarm
        currentSnoozeCount = snoozeCount
        sessionToken = UUID.randomUUID().toString()
        challengeInProgress = false

        startForeground(notificationId, buildNotification(alarm, snoozeCount, false))
        acquireWakeLock()
        if (alarm.isNormal) configureNormalVolume(alarm) else configureVolumeGuard(true)
        startSound(alarm)
        startVibration()
        handler.removeCallbacks(restoreAlarmScreen)
        if (alarmActivityVisible) launchAlarmActivity()
        else if (!alarm.isNormal) handler.postDelayed(restoreAlarmScreen, 300)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        fallbackToneActive = false
        mediaPlayer?.runCatching { stop() }
        mediaPlayer?.release()
        mediaPlayer = null
        toneGenerator?.release()
        toneGenerator = null
        vibrator?.cancel()
        vibrator = null
        stopVolumeOverride()
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        removeGuardOverlay()
        val endedAlarm = currentAlarm
        currentAlarm = null
        if (endedAlarm != null) {
            sendBroadcast(Intent(actionSessionEnded).setPackage(packageName)
                .putExtra(extraAlarmId, endedAlarm.id).putExtra(extraSessionToken, sessionToken))
        }
        if (activeInstance === this) activeInstance = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(
        alarm: AlarmData,
        snoozeCount: Int,
        challengeInProgress: Boolean,
    ): Notification {
        val ringIntent = AlarmRingActivity.createIntent(this, alarm, snoozeCount, sessionToken)
        val fullScreenIntent = PendingIntent.getActivity(
            this,
            0,
            ringIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setContentTitle(alarm.label)
            .setContentText(
                if (alarm.isNormal) {
                    NativeStrings.text(this@RingingService, "Normal alarm · dismiss directly from the notification")
                } else if (challengeInProgress) {
                    NativeStrings.text(this@RingingService, "Challenge timer is running")
                } else {
                    NativeStrings.text(this@RingingService, "Alarm ringing - tap to wake up")
                },
            )
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenIntent)
            .setFullScreenIntent(fullScreenIntent, true)
            .apply {
                if (alarm.isNormal) {
                    val dismiss = PendingIntent.getService(
                        this@RingingService, 0,
                        Intent(this@RingingService, RingingService::class.java).apply {
                            action = actionDismissNormal
                            data = Uri.Builder().scheme("alarmxv").authority("dismiss")
                                .appendPath(alarm.id).appendPath(sessionToken).build()
                            putExtra(extraAlarmId, alarm.id)
                            putExtra(extraSessionToken, sessionToken)
                        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    addAction(Notification.Action.Builder(null, NativeStrings.text(this@RingingService, "Dismiss alarm"), dismiss).build())
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
            }
            .build()
    }

    private fun pauseRingingForChallenge() {
        stopSoundAndVibration()
        stopVolumeOverride()
        currentAlarm?.let { alarm ->
            getSystemService(NotificationManager::class.java).notify(
                notificationId,
                buildNotification(alarm, currentSnoozeCount, true),
            )
        }
    }

    private fun onAlarmActivityVisibilityChanged(visible: Boolean) {
        alarmActivityVisible = visible
        handler.removeCallbacks(restoreAlarmScreen)
        if (visible) {
            removeGuardOverlay()
        } else if (currentAlarm != null && currentAlarm?.isNormal != true) {
            handler.postDelayed(restoreAlarmScreen, 300)
        }
    }

    private fun showGuardOverlay() {
        if (guardOverlay != null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            !Settings.canDrawOverlays(this)
        ) return
        val alarm = currentAlarm ?: return
        if (alarm.isNormal) return
        val windowManager = getSystemService(WindowManager::class.java)
        val appearance = NativeAppearance(this)
        val content = LinearLayout(this).apply {
            layoutDirection = if (NativeStrings.language(this@RingingService) == "fa") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(28), dp(28), dp(28))
            setBackgroundColor(appearance.background)
            addView(TextClock(this@RingingService).apply {
                textDirection = View.TEXT_DIRECTION_LTR
                format12Hour = "h:mm"
                format24Hour = "HH:mm"
                textSize = 76f
                setTextColor(appearance.text)
                gravity = Gravity.CENTER
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            })
            addView(TextView(this@RingingService).apply {
                text = alarm.label
                textSize = 24f
                setTextColor(appearance.text)
                gravity = Gravity.CENTER
                setTypeface(typeface, Typeface.BOLD)
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(8) })
            addView(TextView(this@RingingService).apply {
                text = if (challengeInProgress) {
                    NativeStrings.text(this@RingingService, "Challenge in progress — return before time runs out")
                } else {
                    NativeStrings.text(this@RingingService, "Alarm is ringing")
                }
                textSize = 16f
                setTextColor(appearance.accent)
                gravity = Gravity.CENTER
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(18) })
            addView(Button(this@RingingService).apply {
                text = NativeStrings.text(this@RingingService, "Return to alarm")
                isAllCaps = false
                textSize = 18f
                setTextColor(appearance.onAccent)
                background = appearance.ripple(this@RingingService, appearance.accent)
                appearance.elevate(this)
                setOnClickListener { launchAlarmActivity() }
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(64),
            ).apply { topMargin = dp(28) })
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            PixelFormat.OPAQUE,
        ).apply { gravity = Gravity.TOP or Gravity.START }
        runCatching {
            windowManager.addView(content, params)
            guardOverlay = content
        }
    }

    private fun launchAlarmActivity() {
        val alarm = currentAlarm ?: return
        runCatching {
            startActivity(
                AlarmRingActivity.createIntent(this, alarm, currentSnoozeCount, sessionToken),
            )
        }
    }

    private fun removeGuardOverlay() {
        val overlay = guardOverlay ?: return
        guardOverlay = null
        runCatching { getSystemService(WindowManager::class.java).removeView(overlay) }
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private fun stopSoundAndVibration() {
        fallbackToneActive = false
        handler.removeCallbacks(fallbackTone)
        mediaPlayer?.runCatching { stop() }
        mediaPlayer?.release()
        mediaPlayer = null
        toneGenerator?.release()
        toneGenerator = null
        vibrator?.cancel()
        vibrator = null
    }

    private fun startSound(alarm: AlarmData) {
        // Some devices clamp STREAM_ALARM above zero; an explicit silent alarm stays silent.
        if (alarm.isNormal && alarm.volumeMode == "custom" && alarm.volumePercent == 0) return
        if (mediaPlayer?.isPlaying == true || fallbackToneActive) return
        val alarmUri = alarm.alarmSoundUri?.let(Uri::parse)
            ?: Settings.System.DEFAULT_ALARM_ALERT_URI
            ?: Settings.System.DEFAULT_RINGTONE_URI
            ?: Settings.System.DEFAULT_NOTIFICATION_URI
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@RingingService, alarmUri)
                isLooping = true
                setOnErrorListener { _, _, _ ->
                    startFallbackTone()
                    true
                }
                prepare()
                start()
            }
        } catch (_: Exception) {
            startFallbackTone()
        }
    }

    private fun startFallbackTone() {
        mediaPlayer?.release()
        mediaPlayer = null
        if (currentAlarm?.let { it.isNormal && it.volumeMode == "custom" && it.volumePercent == 0 } == true) return
        if (fallbackToneActive) return
        toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        fallbackToneActive = true
        handler.post(fallbackTone)
    }

    private fun startVibration() {
        vibrator?.cancel()
        vibrator = getSystemService(Vibrator::class.java)
        val pattern = longArrayOf(0, 600, 450)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun acquireWakeLock() {
        wakeLock?.takeIf { it.isHeld }?.release()
        val powerManager = getSystemService(PowerManager::class.java)
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AlarmXV:RingingWakeLock",
        ).apply { acquire() }
    }

    private fun configureVolumeGuard(enabled: Boolean) {
        stopVolumeOverride()
        if (!enabled) return
        val audioManager = getSystemService(AudioManager::class.java)
        val initial = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
        guardedVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        volumePreferences(this).edit()
            .putBoolean(volumeActiveKey, true)
            .putInt(volumeOriginalKey, initial)
            .apply()
        runCatching {
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, guardedVolume, 0)
        }
        volumeGuardEnabled = true
        volumeOverrideActive = true
        volumeSessionRunningInProcess = true
        handler.post(volumeMonitor)
    }

    private fun configureNormalVolume(alarm: AlarmData) {
        if (alarm.volumeMode != "custom") return
        val audioManager = getSystemService(AudioManager::class.java)
        val original = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
        val maximum = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val requested = if (alarm.volumePercent == 0) 0 else
            (maximum * alarm.volumePercent / 100f).roundToInt().coerceAtLeast(1).coerceAtMost(maximum)
        volumePreferences(this).edit().putBoolean(volumeActiveKey, true)
            .putInt(volumeOriginalKey, original).apply()
        volumeOverrideActive = true
        volumeSessionRunningInProcess = true
        runCatching { audioManager.setStreamVolume(AudioManager.STREAM_ALARM, requested, 0) }
        // No monitor in normal mode: hardware volume controls remain under the user's control.
    }

    private fun stopVolumeOverride() {
        handler.removeCallbacks(volumeMonitor)
        if (volumeOverrideActive) restoreStoredVolume(this)
        volumeGuardEnabled = false
        volumeOverrideActive = false
        volumeSessionRunningInProcess = false
    }

    private fun dismissNormalSession(alarmId: String, expectedToken: String): Boolean {
        val alarm = currentAlarm ?: return false
        if (!alarm.isNormal || alarm.id != alarmId || expectedToken.isEmpty() || sessionToken != expectedToken) {
            return false
        }
        runCatching { AlarmScheduler.cancelChallengeTimeout(this, alarm.id) }
        runCatching { WakeCheckScheduler.cancel(this, alarm.id) }
        RingStateStore.clear(this, alarm.id)
        stopSelf()
        return true
    }

    companion object {
        private const val channelId = "alarm_xv_ringing_v1"
        private const val notificationId = 1701
        private const val extraAlarmJson = "alarm_json"
        private const val extraSnoozeCount = "snooze_count"
        const val extraAlarmId = "alarm_id"
        const val extraSessionToken = "ring_session_token"
        const val actionSessionEnded = "com.alarmxv.alarm_xv.ACTION_RING_SESSION_ENDED"
        private const val actionDismissNormal = "com.alarmxv.alarm_xv.ACTION_DISMISS_NORMAL_ALARM"
        private const val actionPauseForChallenge =
            "com.alarmxv.alarm_xv.ACTION_PAUSE_FOR_CHALLENGE"
        private const val volumePreferencesName = "alarm_xv_volume_guard"
        private const val volumeActiveKey = "active"
        private const val volumeOriginalKey = "original"

        @Volatile
        private var volumeSessionRunningInProcess = false

        fun createIntent(context: Context, alarm: AlarmData, snoozeCount: Int): Intent =
            Intent(context, RingingService::class.java).apply {
                putExtra(extraAlarmJson, alarm.toJson().toString())
                putExtra(extraSnoozeCount, snoozeCount)
            }

        fun stop(context: Context) {
            context.stopService(Intent(context, RingingService::class.java))
        }

        fun isNormalSessionActive(alarmId: String, expectedToken: String): Boolean =
            activeInstance?.let { it.currentAlarm?.isNormal == true && it.currentAlarm?.id == alarmId &&
                expectedToken.isNotEmpty() && it.sessionToken == expectedToken } == true

        /** Reopen the existing strict session; never restart audio or mint a token. */
        fun activeScreenIntent(context: Context): Intent? {
            val service = activeInstance ?: return null
            val alarm = service.currentAlarm ?: return null
            if (alarm.isNormal) return null
            return AlarmRingActivity.createIntent(context, alarm, service.currentSnoozeCount, service.sessionToken)
        }

        fun dismissNormal(alarmId: String, expectedToken: String): Boolean =
            activeInstance?.dismissNormalSession(alarmId, expectedToken) == true

        fun pauseForChallenge(context: Context) {
            context.startService(Intent(context, RingingService::class.java).apply {
                action = actionPauseForChallenge
            })
        }

        fun setAlarmActivityVisible(visible: Boolean, alarmId: String, expectedToken: String) {
            activeInstance?.let { service ->
                if (service.currentAlarm?.id == alarmId && service.sessionToken == expectedToken) {
                    service.onAlarmActivityVisibilityChanged(visible)
                }
            }
        }

        fun resumeRinging(context: Context, alarm: AlarmData, snoozeCount: Int) {
            val intent = createIntent(context, alarm, snoozeCount)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun ensureNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val channel = NotificationChannel(
                channelId,
                NativeStrings.text(context, "Ringing alarms"),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = NativeStrings.text(context, "Full-screen notifications for active AlarmXV alarms")
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(false)
            }
            context.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        fun restoreOrphanedVolume(context: Context) {
            if (!volumeSessionRunningInProcess) restoreStoredVolume(context)
        }

        private fun restoreStoredVolume(context: Context) {
            val preferences = volumePreferences(context)
            if (!preferences.getBoolean(volumeActiveKey, false)) return
            val original = preferences.getInt(volumeOriginalKey, -1)
            val restored = original < 0 || runCatching {
                    context.getSystemService(AudioManager::class.java)
                        .setStreamVolume(AudioManager.STREAM_ALARM, original, 0)
                    true
                }.getOrDefault(false)
            if (restored) preferences.edit().clear().apply()
        }

        private fun volumePreferences(context: Context) = context.getSharedPreferences(
            volumePreferencesName,
            Context.MODE_PRIVATE,
        )

        @Volatile
        private var activeInstance: RingingService? = null
    }
}
