package com.alarmxv.alarm_xv

import android.content.Context
import org.json.JSONObject

object RingStateStore {
    private const val preferencesName = "alarm_xv_ring_state"

    fun load(context: Context, alarmId: String): JSONObject? {
        val encoded = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .getString(alarmId, null) ?: return null
        return runCatching { JSONObject(encoded) }.getOrNull()
    }

    fun save(context: Context, alarmId: String, state: JSONObject) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(alarmId, state.toString())
            .apply()
    }

    fun clear(context: Context, alarmId: String) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .remove(alarmId)
            .apply()
    }
}
