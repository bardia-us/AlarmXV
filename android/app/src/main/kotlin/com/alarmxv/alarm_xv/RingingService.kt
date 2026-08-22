package com.alarmxv.alarm_xv

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
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

class RingingService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var mediaPlayer: MediaPlayer? = null
    private var toneGenerator: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var fallbackToneActive = false
    private var volumeGuardEnabled = false
    private var guardedVolume = 0
    private var currentAlarm: AlarmData? = null
    private var currentSnoozeCount = 0
    private var challengeInProgress = false
    private var alarmActivityVisible = false
    private var guardOverlay: View? = null

    private val restoreAlarmScreen = Runnable {
        if (alarmActivityVisible || currentAlarm == null) return@Runnable
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
        if (intent?.action == actionPauseForChallenge) {
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
        currentAlarm = alarm
        currentSnoozeCount = snoozeCount
        challengeInProgress = false

        startForeground(notificationId, buildNotification(alarm, snoozeCount, false))
        acquireWakeLock()
        configureVolumeGuard(true)
        startSound(alarm)
        startVibration()
        handler.removeCallbacks(restoreAlarmScreen)
        if (!alarmActivityVisible) handler.postDelayed(restoreAlarmScreen, 300)
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
        stopVolumeGuard()
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        removeGuardOverlay()
        currentAlarm = null
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
        val ringIntent = AlarmRingActivity.createIntent(this, alarm, snoozeCount)
        val fullScreenIntent = PendingIntent.getActivity(
            this,
            0,
            ringIntent.apply {
                data = Uri.Builder()
                    .scheme("alarmxv")
                    .authority("ring")
                    .appendPath(alarm.id)
                    .build()
            },
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
                if (challengeInProgress) {
                    "Challenge timer is running"
                } else {
                    "Alarm ringing - tap to wake up"
                },
            )
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenIntent)
            .setFullScreenIntent(fullScreenIntent, true)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
            }
            .build()
    }

    private fun pauseRingingForChallenge() {
        stopSoundAndVibration()
        stopVolumeGuard()
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
        } else if (currentAlarm != null) {
            handler.postDelayed(restoreAlarmScreen, 300)
        }
    }

    private fun showGuardOverlay() {
        if (guardOverlay != null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            !Settings.canDrawOverlays(this)
        ) return
        val alarm = currentAlarm ?: return
        val windowManager = getSystemService(WindowManager::class.java)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(28), dp(28), dp(28))
            setBackgroundColor(Color.rgb(10, 12, 17))
            addView(TextClock(this@RingingService).apply {
                format12Hour = "h:mm"
                format24Hour = "HH:mm"
                textSize = 76f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
            })
            addView(TextView(this@RingingService).apply {
                text = alarm.label
                textSize = 24f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setTypeface(typeface, Typeface.BOLD)
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(8) })
            addView(TextView(this@RingingService).apply {
                text = if (challengeInProgress) {
                    "Challenge in progress — return before time runs out"
                } else {
                    "Alarm is ringing"
                }
                textSize = 16f
                setTextColor(Color.rgb(196, 188, 255))
                gravity = Gravity.CENTER
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(18) })
            addView(Button(this@RingingService).apply {
                text = "Return to alarm"
                isAllCaps = false
                textSize = 18f
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
                AlarmRingActivity.createIntent(this, alarm, currentSnoozeCount).apply {
                    addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                },
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
        stopVolumeGuard()
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
        guardRunningInProcess = true
        handler.post(volumeMonitor)
    }

    private fun stopVolumeGuard() {
        handler.removeCallbacks(volumeMonitor)
        if (volumeGuardEnabled) restoreStoredVolume(this)
        volumeGuardEnabled = false
        guardRunningInProcess = false
    }

    companion object {
        private const val channelId = "alarm_xv_ringing_v1"
        private const val notificationId = 1701
        private const val extraAlarmJson = "alarm_json"
        private const val extraSnoozeCount = "snooze_count"
        private const val actionPauseForChallenge =
            "com.alarmxv.alarm_xv.ACTION_PAUSE_FOR_CHALLENGE"
        private const val volumePreferencesName = "alarm_xv_volume_guard"
        private const val volumeActiveKey = "active"
        private const val volumeOriginalKey = "original"

        @Volatile
        private var guardRunningInProcess = false

        fun createIntent(context: Context, alarm: AlarmData, snoozeCount: Int): Intent =
            Intent(context, RingingService::class.java).apply {
                putExtra(extraAlarmJson, alarm.toJson().toString())
                putExtra(extraSnoozeCount, snoozeCount)
            }

        fun stop(context: Context) {
            context.stopService(Intent(context, RingingService::class.java))
        }

        fun pauseForChallenge(context: Context) {
            context.startService(Intent(context, RingingService::class.java).apply {
                action = actionPauseForChallenge
            })
        }

        fun setAlarmActivityVisible(visible: Boolean) {
            activeInstance?.onAlarmActivityVisibilityChanged(visible)
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
                "Ringing alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Full-screen notifications for active AlarmXV alarms"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(false)
            }
            context.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        fun restoreOrphanedVolume(context: Context) {
            if (!guardRunningInProcess) restoreStoredVolume(context)
        }

        private fun restoreStoredVolume(context: Context) {
            val preferences = volumePreferences(context)
            if (!preferences.getBoolean(volumeActiveKey, false)) return
            val original = preferences.getInt(volumeOriginalKey, -1)
            if (original >= 0) {
                runCatching {
                    context.getSystemService(AudioManager::class.java)
                        .setStreamVolume(AudioManager.STREAM_ALARM, original, 0)
                }
            }
            preferences.edit().clear().apply()
        }

        private fun volumePreferences(context: Context) = context.getSharedPreferences(
            volumePreferencesName,
            Context.MODE_PRIVATE,
        )

        @Volatile
        private var activeInstance: RingingService? = null
    }
}
