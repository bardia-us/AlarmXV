package com.alarmxv.alarm_xv

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import java.util.Calendar

object AlarmScheduler {
    private const val mainKind = "main"
    private const val snoozeKind = "snooze"
    private const val wakeFailureKind = "wake_failure"
    private const val challengeTimeoutKind = "challenge_timeout"

    fun saveAndSync(context: Context, encoded: String): Map<String, Any> {
        val previous = AlarmStore.load(context)
        val updated = AlarmData.listFromJson(encoded)
        val updatedById = updated.associateBy { it.id }
        previous.forEach { alarm ->
            cancelAlarmIntents(context, alarm.id)
            if (updatedById[alarm.id] != alarm) WakeCheckScheduler.cancel(context, alarm.id)
        }
        AlarmStore.save(context, encoded)
        return reschedule(context)
    }

    fun reschedule(context: Context): Map<String, Any> {
        val alarms = AlarmStore.load(context)
        alarms.forEach { cancelAlarmIntents(context, it.id) }
        var scheduledCount = 0
        if (canScheduleExact(context)) {
            alarms.filter { it.enabled && it.weekdays.isNotEmpty() }.forEach { alarm ->
                scheduleMain(context, alarm)
                scheduledCount += 1
            }
        }
        WakeCheckScheduler.rescheduleAll(context)
        return permissionStatus(context) + mapOf("scheduledCount" to scheduledCount)
    }

    fun scheduleNextAfterRing(context: Context, alarm: AlarmData) {
        if (!alarm.enabled || !canScheduleExact(context)) return
        val next = nextOccurrence(alarm, System.currentTimeMillis() + 1_000)
        setAlarmClock(context, alarm, next, mainKind, 0)
    }

    fun scheduleSnooze(context: Context, alarm: AlarmData, snoozeCount: Int): Boolean {
        if (!canScheduleExact(context) || alarm.snoozeMinutes <= 0) return false
        val triggerAt = System.currentTimeMillis() + alarm.snoozeMinutes * 60_000L
        setAlarmClock(context, alarm, triggerAt, snoozeKind, snoozeCount)
        return true
    }

    fun scheduleWakeFailure(
        context: Context,
        alarm: AlarmData,
        triggerAt: Long,
    ): Boolean {
        if (canScheduleExact(context)) {
            setAlarmClock(context, alarm, triggerAt, wakeFailureKind, 0)
        } else {
            context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                alarmPendingIntent(context, alarm.id, wakeFailureKind, alarm, 0),
            )
        }
        return true
    }

    fun cancelWakeFailure(context: Context, alarmId: String) {
        context.getSystemService(AlarmManager::class.java).cancel(
            alarmPendingIntent(context, alarmId, wakeFailureKind, null, 0),
        )
    }

    fun scheduleChallengeTimeout(
        context: Context,
        alarm: AlarmData,
        triggerAt: Long,
    ): Boolean {
        val manager = context.getSystemService(AlarmManager::class.java)
        val operation = alarmPendingIntent(
            context,
            alarm.id,
            challengeTimeoutKind,
            alarm,
            0,
        )
        return try {
            if (canScheduleExact(context)) {
                setAlarmClock(context, alarm, triggerAt, challengeTimeoutKind, 0)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, operation)
            }
            true
        } catch (_: SecurityException) {
            false
        }
    }

    fun cancelChallengeTimeout(context: Context, alarmId: String) {
        context.getSystemService(AlarmManager::class.java).cancel(
            alarmPendingIntent(context, alarmId, challengeTimeoutKind, null, 0),
        )
    }

    private fun cancelAlarmIntents(context: Context, alarmId: String) {
        val manager = context.getSystemService(AlarmManager::class.java)
        manager.cancel(alarmPendingIntent(context, alarmId, mainKind, null, 0))
        manager.cancel(alarmPendingIntent(context, alarmId, snoozeKind, null, 0))
        manager.cancel(alarmPendingIntent(context, alarmId, wakeFailureKind, null, 0))
        manager.cancel(alarmPendingIntent(context, alarmId, challengeTimeoutKind, null, 0))
    }

    fun permissionStatus(context: Context): Map<String, Any> {
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        val runtimeNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            notificationManager.areNotificationsEnabled()
        }
        val channelEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.getNotificationChannel("alarm_xv_ringing_v1")?.importance !=
                NotificationManager.IMPORTANCE_NONE
        } else {
            true
        }
        val notifications = runtimeNotifications && channelEnabled
        val fullScreen = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            notificationManager.canUseFullScreenIntent()
        } else {
            true
        }
        val overlay = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(context)
        return mapOf(
            "exactAlarm" to canScheduleExact(context),
            "notifications" to notifications,
            "fullScreen" to fullScreen,
            "overlay" to overlay,
        )
    }

    private fun scheduleMain(context: Context, alarm: AlarmData) {
        val triggerAt = nextOccurrence(alarm, System.currentTimeMillis())
        setAlarmClock(context, alarm, triggerAt, mainKind, 0)
    }

    private fun setAlarmClock(
        context: Context,
        alarm: AlarmData,
        triggerAt: Long,
        kind: String,
        snoozeCount: Int,
    ) {
        val manager = context.getSystemService(AlarmManager::class.java)
        val operation = alarmPendingIntent(context, alarm.id, kind, alarm, snoozeCount)
        val showIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                data = Uri.Builder()
                    .scheme("alarmxv")
                    .authority("show")
                    .appendPath(alarm.id)
                    .build()
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, showIntent), operation)
    }

    private fun alarmPendingIntent(
        context: Context,
        alarmId: String,
        kind: String,
        alarm: AlarmData?,
        snoozeCount: Int,
    ): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.actionFire
            data = Uri.Builder()
                .scheme("alarmxv")
                .authority("alarm")
                .appendPath(alarmId)
                .appendPath(kind)
                .build()
            putExtra(AlarmReceiver.extraAlarmId, alarmId)
            putExtra(AlarmReceiver.extraKind, kind)
            putExtra(AlarmReceiver.extraAlarmJson, alarm?.toJson()?.toString())
            putExtra(AlarmReceiver.extraSnoozeCount, snoozeCount)
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun nextOccurrence(alarm: AlarmData, afterMillis: Long): Long {
        for (offset in 0..7) {
            val candidate = Calendar.getInstance().apply {
                timeInMillis = afterMillis
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                set(Calendar.HOUR_OF_DAY, alarm.hour)
                set(Calendar.MINUTE, alarm.minute)
                add(Calendar.DAY_OF_YEAR, offset)
            }
            val flutterWeekday = when (candidate.get(Calendar.DAY_OF_WEEK)) {
                Calendar.SUNDAY -> 7
                else -> candidate.get(Calendar.DAY_OF_WEEK) - 1
            }
            if (flutterWeekday in alarm.weekdays && candidate.timeInMillis > afterMillis) {
                return candidate.timeInMillis
            }
        }
        error("An enabled alarm must contain at least one weekday")
    }

    private fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()
    }
}
