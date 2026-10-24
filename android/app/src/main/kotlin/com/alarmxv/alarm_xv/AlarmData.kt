package com.alarmxv.alarm_xv

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class AlarmData(
    val id: String,
    val label: String,
    val hour: Int,
    val minute: Int,
    val weekdays: Set<Int>,
    val enabled: Boolean,
    val challenges: Set<String>,
    val snoozeMinutes: Int,
    val maxSnoozes: Int,
    val preventVolumeReduction: Boolean,
    val alarmSoundUri: String?,
    val alarmSoundName: String,
    val wakeCheckEnabled: Boolean,
    val wakeCheckDelayMinutes: Int,
    val wakeCheckTimeoutSeconds: Int,
    val wakeCheckCount: Int,
    val groupId: String? = null,
    val missionSettings: MissionSettings = MissionSettings(),
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("label", label)
        put("hour", hour)
        put("minute", minute)
        put("weekdays", JSONArray(weekdays.sorted()))
        put("isEnabled", enabled)
        put("challenges", JSONArray(challenges.toList()))
        put("snoozeMinutes", snoozeMinutes)
        put("maxSnoozes", maxSnoozes)
        put("preventVolumeReduction", preventVolumeReduction)
        put("alarmSoundUri", alarmSoundUri ?: "")
        put("alarmSoundName", alarmSoundName)
        put("groupId", groupId ?: JSONObject.NULL)
        put("missionSettings", missionSettings.toJson())
        put("wakeCheck", JSONObject().apply {
            put("enabled", wakeCheckEnabled)
            put("delayMinutes", wakeCheckDelayMinutes)
            put("timeoutSeconds", wakeCheckTimeoutSeconds)
            put("checkCount", wakeCheckCount)
        })
    }

    companion object {
        fun fromJson(json: JSONObject): AlarmData {
            val days = json.optJSONArray("weekdays") ?: JSONArray()
            val challengesJson = json.optJSONArray("challenges")
            val challenges = mutableSetOf<String>()
            if (challengesJson != null) {
                for (index in 0 until challengesJson.length()) {
                    challenges.add(challengesJson.optString(index))
                }
            } else {
                challenges.add(json.optString("challenge", "math"))
            }
            challenges.retainAll(setOf("math", "memory", "shake", "typing", "order"))
            if (challenges.isEmpty()) challenges.add("math")
            val wakeCheck = json.optJSONObject("wakeCheck") ?: JSONObject()

            return AlarmData(
                id = json.getString("id"),
                label = json.optString("label", "Alarm").ifBlank { "Alarm" },
                hour = json.getInt("hour"),
                minute = json.getInt("minute"),
                weekdays = buildSet {
                    for (index in 0 until days.length()) add(days.getInt(index))
                },
                enabled = json.optBoolean("isEnabled", true),
                challenges = challenges,
                snoozeMinutes = json.optInt("snoozeMinutes", 5).coerceAtLeast(0),
                maxSnoozes = json.optInt("maxSnoozes", 3).coerceAtLeast(0),
                preventVolumeReduction = json.optBoolean("preventVolumeReduction", false),
                alarmSoundUri = json.optString("alarmSoundUri", "")
                    .takeIf { it.isNotBlank() },
                alarmSoundName = json.optString(
                    "alarmSoundName",
                    "Default alarm sound",
                ).ifBlank { "Default alarm sound" },
                wakeCheckEnabled = wakeCheck.optBoolean("enabled", false),
                wakeCheckDelayMinutes = wakeCheck.optInt("delayMinutes", 3)
                    .coerceIn(2, 10),
                wakeCheckTimeoutSeconds = 60,
                wakeCheckCount = wakeCheck.optInt("checkCount", 1).coerceIn(1, 5),
                groupId = json.optString("groupId", "").takeIf { it.isNotBlank() && it != "null" },
                missionSettings = MissionSettings.fromJson(json.optJSONObject("missionSettings")),
            )
        }

        fun listFromJson(encoded: String): List<AlarmData> {
            val array = JSONArray(encoded)
            return buildList {
                for (index in 0 until array.length()) {
                    add(fromJson(array.getJSONObject(index)))
                }
            }
        }
    }
}

object AlarmStore {
    private const val preferencesName = "alarm_xv_preferences"
    private const val alarmsKey = "alarms_json"

    fun loadJson(context: Context): String = context
        .getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        .getString(alarmsKey, "[]") ?: "[]"

    fun load(context: Context): List<AlarmData> = try {
        AlarmData.listFromJson(loadJson(context))
    } catch (_: Exception) {
        emptyList()
    }

    fun save(context: Context, encoded: String) {
        check(context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(alarmsKey, encoded)
            .commit()) { "Could not save alarms" }
    }

    fun find(context: Context, id: String): AlarmData? =
        load(context).firstOrNull { it.id == id }
}
