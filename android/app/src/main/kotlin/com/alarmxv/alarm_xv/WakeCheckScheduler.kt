package com.alarmxv.alarm_xv

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.json.JSONObject

data class WakeCheckState(
    val alarmId: String,
    val checkNumber: Int,
    val phase: String,
    val dueAtMillis: Long,
) {
    fun toJson() = JSONObject().apply {
        put("alarmId", alarmId)
        put("checkNumber", checkNumber)
        put("phase", phase)
        put("dueAtMillis", dueAtMillis)
    }

    companion object {
        fun fromJson(json: JSONObject) = WakeCheckState(
            alarmId = json.getString("alarmId"),
            checkNumber = json.getInt("checkNumber"),
            phase = json.getString("phase"),
            dueAtMillis = json.getLong("dueAtMillis"),
        )
    }
}

object WakeCheckScheduler {
    private const val channelId = "alarm_xv_wake_check_silent_v3"
    private val legacyChannelIds = listOf(
        "alarm_xv_wake_check_v1",
        "alarm_xv_wake_check_silent_v2",
    )
    private const val phaseWaiting = "waiting"
    private const val phaseAwaiting = "awaiting"
    private const val actionCheck = "com.alarmxv.alarm_xv.ACTION_WAKE_CHECK"
    private const val actionConfirm = "com.alarmxv.alarm_xv.ACTION_WAKE_CONFIRM"
    private const val extraAlarmId = "alarm_id"
    private const val extraCheckNumber = "check_number"
    private const val confirmationWindowMillis = 60_000L

    fun startCycle(context: Context, alarm: AlarmData) {
        cancel(context, alarm.id)
        WakeFailureStore.clear(context, alarm.id)
        if (alarm.isNormal || !alarm.wakeCheckEnabled || !alarm.enabled) return
        scheduleCheck(
            context,
            alarm,
            checkNumber = 1,
            dueAt = System.currentTimeMillis() + alarm.wakeCheckDelayMinutes * 60_000L,
        )
    }

    fun onCheckDue(context: Context, alarmId: String, checkNumber: Int) {
        val pendingState = WakeCheckStore.get(context, alarmId)
        if (pendingState?.phase != phaseWaiting || pendingState.checkNumber != checkNumber) return
        val alarm = AlarmStore.find(context, alarmId)
        if (alarm == null || alarm.isNormal || !alarm.enabled || !alarm.wakeCheckEnabled) {
            cancel(context, alarmId)
            return
        }
        if (!canShowWakeCheckNotification(context)) {
            cancel(context, alarmId)
            return
        }
        val deadline = System.currentTimeMillis() + confirmationWindowMillis
        WakeCheckStore.put(
            context,
            WakeCheckState(alarmId, checkNumber, phaseAwaiting, deadline),
        )
        if (!showNotification(context, alarm, checkNumber, deadline)) {
            cancel(context, alarmId)
            return
        }
        AlarmScheduler.scheduleWakeFailure(context, alarm, deadline)
        showWakeCheckScreen(context, alarm, checkNumber, deadline)
    }

    fun confirm(context: Context, alarmId: String, checkNumber: Int) {
        val state = WakeCheckStore.get(context, alarmId) ?: return
        if (state.phase != phaseAwaiting || state.checkNumber != checkNumber) return
        if (System.currentTimeMillis() >= state.dueAtMillis) return
        AlarmScheduler.cancelWakeFailure(context, alarmId)
        notificationManager(context).cancel(notificationId(alarmId))
        val alarm = AlarmStore.find(context, alarmId)
        if (alarm == null || alarm.isNormal || !alarm.enabled || !alarm.wakeCheckEnabled ||
            checkNumber >= alarm.wakeCheckCount
        ) {
            WakeCheckStore.remove(context, alarmId)
            return
        }
        scheduleCheck(
            context,
            alarm,
            checkNumber = checkNumber + 1,
            dueAt = System.currentTimeMillis() + alarm.wakeCheckDelayMinutes * 60_000L,
        )
    }

    fun onFailureFired(context: Context, alarmId: String) {
        cancelCheckIntent(context, alarmId)
        notificationManager(context).cancel(notificationId(alarmId))
        WakeCheckStore.remove(context, alarmId)
        WakeFailureStore.mark(context, alarmId)
    }

    fun cancel(context: Context, alarmId: String) {
        cancelCheckIntent(context, alarmId)
        AlarmScheduler.cancelWakeFailure(context, alarmId)
        notificationManager(context).cancel(notificationId(alarmId))
        WakeCheckStore.remove(context, alarmId)
    }

    fun rescheduleAll(context: Context) {
        ensureNotificationChannel(context)
        val now = System.currentTimeMillis()
        WakeCheckStore.all(context).forEach { state ->
            val alarm = AlarmStore.find(context, state.alarmId)
            if (alarm == null || alarm.isNormal || !alarm.enabled || !alarm.wakeCheckEnabled) {
                cancel(context, state.alarmId)
                return@forEach
            }
            cancelCheckIntent(context, state.alarmId)
            AlarmScheduler.cancelWakeFailure(context, state.alarmId)
            when (state.phase) {
                phaseWaiting -> scheduleCheck(
                    context,
                    alarm,
                    state.checkNumber,
                    maxOf(now + 1_000, state.dueAtMillis),
                )
                phaseAwaiting -> {
                    if (!canShowWakeCheckNotification(context)) {
                        cancel(context, state.alarmId)
                        return@forEach
                    }
                    val deadline = if (state.dueAtMillis > now) {
                        state.dueAtMillis
                    } else {
                        now + confirmationWindowMillis
                    }
                    WakeCheckStore.put(context, state.copy(dueAtMillis = deadline))
                    if (!showNotification(context, alarm, state.checkNumber, deadline)) {
                        cancel(context, state.alarmId)
                        return@forEach
                    }
                    AlarmScheduler.scheduleWakeFailure(
                        context,
                        alarm,
                        deadline,
                    )
                    showWakeCheckScreen(
                        context,
                        alarm,
                        state.checkNumber,
                        deadline,
                    )
                }
            }
        }
    }

    fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            channelId,
            NativeStrings.text(context, "Silent wake-up checks"),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = NativeStrings.text(context, "Silent confirmations; missed checks restart the real alarm")
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        notificationManager(context).apply {
            createNotificationChannel(channel)
            legacyChannelIds.forEach(::deleteNotificationChannel)
        }
    }

    private fun scheduleCheck(
        context: Context,
        alarm: AlarmData,
        checkNumber: Int,
        dueAt: Long,
    ) {
        WakeCheckStore.put(
            context,
            WakeCheckState(alarm.id, checkNumber, phaseWaiting, dueAt),
        )
        val manager = context.getSystemService(AlarmManager::class.java)
        try {
            manager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                dueAt,
                checkPendingIntent(context, alarm.id, checkNumber),
            )
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                dueAt,
                checkPendingIntent(context, alarm.id, checkNumber),
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun showNotification(
        context: Context,
        alarm: AlarmData,
        checkNumber: Int,
        deadline: Long,
    ): Boolean {
        ensureNotificationChannel(context)
        val confirmIntent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, WakeCheckReceiver::class.java).apply {
                action = actionConfirm
                data = wakeUri(alarm.id, "confirm")
                putExtra(extraAlarmId, alarm.id)
                putExtra(extraCheckNumber, checkNumber)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            WakeCheckActivity.createIntent(context, alarm, checkNumber, deadline),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setContentTitle(NativeStrings.text(context, "Still awake?"))
            .setContentText(NativeStrings.text(context, "Confirm you are awake before the countdown ends"))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setPriority(Notification.PRIORITY_DEFAULT)
            .setDefaults(0)
            .setSound(null)
            .setVibrate(null)
            .setContentIntent(contentIntent)
            .setWhen(deadline)
            .setUsesChronometer(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(
                Notification.Action.Builder(
                    null,
                    NativeStrings.text(context, "I’m awake"),
                    confirmIntent,
                ).build(),
            )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setTimeoutAfter(maxOf(1_000, deadline - System.currentTimeMillis()))
        }
        val notification = builder.build()
        return runCatching {
            notificationManager(context).notify(notificationId(alarm.id), notification)
            true
        }.getOrDefault(false)
    }

    private fun canShowWakeCheckNotification(context: Context): Boolean {
        val manager = notificationManager(context)
        val runtimeGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            manager.areNotificationsEnabled()
        }
        val channelEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ensureNotificationChannel(context)
            manager.getNotificationChannel(channelId)?.importance !=
                NotificationManager.IMPORTANCE_NONE
        } else {
            true
        }
        return runtimeGranted && manager.areNotificationsEnabled() && channelEnabled
    }

    private fun showWakeCheckScreen(
        context: Context,
        alarm: AlarmData,
        checkNumber: Int,
        deadline: Long,
    ) {
        val canLaunch = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(context)
        if (!canLaunch) return
        runCatching {
            context.startActivity(
                WakeCheckActivity.createIntent(context, alarm, checkNumber, deadline),
            )
        }
    }

    private fun checkPendingIntent(
        context: Context,
        alarmId: String,
        checkNumber: Int,
    ): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, WakeCheckReceiver::class.java).apply {
            action = actionCheck
            data = wakeUri(alarmId, "check")
            putExtra(extraAlarmId, alarmId)
            putExtra(extraCheckNumber, checkNumber)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun cancelCheckIntent(context: Context, alarmId: String) {
        context.getSystemService(AlarmManager::class.java).cancel(
            checkPendingIntent(context, alarmId, 0),
        )
    }

    private fun wakeUri(alarmId: String, kind: String): Uri = Uri.Builder()
        .scheme("alarmxv")
        .authority("wake-check")
        .appendPath(alarmId)
        .appendPath(kind)
        .build()

    private fun notificationId(alarmId: String): Int =
        20_000 + (alarmId.hashCode() and 0x3FFF)

    private fun notificationManager(context: Context): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    fun isCheckAction(action: String?): Boolean = action == actionCheck
    fun isConfirmAction(action: String?): Boolean = action == actionConfirm
    fun alarmId(intent: Intent): String? = intent.getStringExtra(extraAlarmId)
    fun checkNumber(intent: Intent): Int = intent.getIntExtra(extraCheckNumber, 1)
}

object WakeCheckStore {
    private const val preferencesName = "alarm_xv_wake_check_state"
    private const val statesKey = "states"

    fun get(context: Context, alarmId: String): WakeCheckState? =
        loadObject(context).optJSONObject(alarmId)?.let(WakeCheckState::fromJson)

    fun all(context: Context): List<WakeCheckState> {
        val objectValue = loadObject(context)
        return objectValue.keys().asSequence().mapNotNull { key ->
            runCatching { WakeCheckState.fromJson(objectValue.getJSONObject(key)) }.getOrNull()
        }.toList()
    }

    fun put(context: Context, state: WakeCheckState) {
        val objectValue = loadObject(context)
        objectValue.put(state.alarmId, state.toJson())
        saveObject(context, objectValue)
    }

    fun remove(context: Context, alarmId: String) {
        val objectValue = loadObject(context)
        objectValue.remove(alarmId)
        saveObject(context, objectValue)
    }

    private fun loadObject(context: Context): JSONObject = try {
        JSONObject(
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .getString(statesKey, "{}") ?: "{}",
        )
    } catch (_: Exception) {
        JSONObject()
    }

    private fun saveObject(context: Context, value: JSONObject) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(statesKey, value.toString())
            .apply()
    }
}

object WakeFailureStore {
    private const val preferencesName = "alarm_xv_wake_failure_session"

    fun mark(context: Context, alarmId: String) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(alarmId, true)
            .apply()
    }

    fun consume(context: Context, alarmId: String): Boolean {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val marked = preferences.getBoolean(alarmId, false)
        if (marked) preferences.edit().remove(alarmId).apply()
        return marked
    }

    fun clear(context: Context, alarmId: String) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .remove(alarmId)
            .apply()
    }
}

class WakeCheckReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = WakeCheckScheduler.alarmId(intent) ?: return
        val checkNumber = WakeCheckScheduler.checkNumber(intent)
        when {
            WakeCheckScheduler.isCheckAction(intent.action) ->
                WakeCheckScheduler.onCheckDue(context, alarmId, checkNumber)
            WakeCheckScheduler.isConfirmAction(intent.action) ->
                WakeCheckScheduler.confirm(context, alarmId, checkNumber)
        }
    }
}
