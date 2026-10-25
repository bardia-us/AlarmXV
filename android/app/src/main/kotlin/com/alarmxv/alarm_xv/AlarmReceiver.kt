package com.alarmxv.alarm_xv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != actionFire) return
        val alarmId = intent.getStringExtra(extraAlarmId) ?: return
        val alarm = AlarmStore.find(context, alarmId) ?: return
        if (!alarm.enabled) return
        val kind = intent.getStringExtra(extraKind) ?: "main"
        if (alarm.isNormal && kind in setOf("wake_failure", "challenge_timeout")) {
            AlarmScheduler.cancelChallengeTimeout(context, alarm.id)
            WakeCheckScheduler.cancel(context, alarm.id)
            RingStateStore.clear(context, alarm.id)
            return
        }
        RingingService.restoreOrphanedVolume(context)
        RingStateStore.clear(context, alarm.id)

        if (kind == "main") {
            WakeFailureStore.clear(context, alarm.id)
            AlarmScheduler.cancelChallengeTimeout(context, alarm.id)
            WakeCheckScheduler.cancel(context, alarm.id)
            AlarmScheduler.scheduleNextAfterRing(context, alarm)
        } else if (kind == "wake_failure") {
            WakeCheckScheduler.onFailureFired(context, alarm.id)
        }

        val serviceIntent = RingingService.createIntent(
            context = context,
            alarm = alarm,
            snoozeCount = intent.getIntExtra(extraSnoozeCount, 0),
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    companion object {
        const val actionFire = "com.alarmxv.alarm_xv.ACTION_FIRE_ALARM"
        const val extraAlarmId = "alarm_id"
        const val extraAlarmJson = "alarm_json"
        const val extraKind = "alarm_kind"
        const val extraSnoozeCount = "snooze_count"
    }
}
