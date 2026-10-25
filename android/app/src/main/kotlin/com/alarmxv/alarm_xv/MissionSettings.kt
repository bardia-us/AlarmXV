package com.alarmxv.alarm_xv

import org.json.JSONArray
import org.json.JSONObject

data class MissionSettings(
    val mathDifficulty: String = "medium",
    val mathQuestions: Int = 3,
    val mathOperations: List<String> = listOf("add", "subtract"),
    val mathMaxOperand: Int = 90,
    val memoryGridSize: Int = 3,
    val memoryTargets: Int = 3,
    val memoryRounds: Int = 1,
    val shakeCount: Int = 12,
    val shakeThreshold: Double = 2.4,
    val typingPhrase: String = "I am awake and ready",
    val numberCount: Int = 6,
) {
    fun toJson() = JSONObject().apply {
        put("mathDifficulty", mathDifficulty)
        put("mathQuestions", mathQuestions)
        put("mathOperations", JSONArray(mathOperations))
        put("mathMaxOperand", mathMaxOperand)
        put("memoryGridSize", memoryGridSize)
        put("memoryTargets", memoryTargets)
        put("memoryRounds", memoryRounds)
        put("shakeCount", shakeCount)
        put("shakeThreshold", shakeThreshold)
        put("typingPhrase", typingPhrase)
        put("numberCount", numberCount)
    }

    companion object {
        fun fromJson(json: JSONObject?): MissionSettings {
            // Missing configuration belongs to v1.2; keep its actual mission rules.
            // A present empty object and newly created settings use the new defaults.
            if (json == null) return MissionSettings(memoryGridSize = 4, memoryTargets = 5, shakeCount = 10)
            val gridSize = json.optInt("memoryGridSize", 3).coerceIn(3, 5)
            val operationsJson = json.optJSONArray("mathOperations") ?: JSONArray()
            val operations = (0 until operationsJson.length()).map { operationsJson.optString(it) }
                .filter { it in setOf("add", "subtract", "multiply", "divide") }.distinct()
            return MissionSettings(
                mathDifficulty = json.optString("mathDifficulty", "medium")
                    .takeIf { it in setOf("easy", "medium", "hard", "custom") } ?: "medium",
                mathQuestions = json.optInt("mathQuestions", 3).coerceIn(1, 20),
                mathOperations = operations.ifEmpty { listOf("add", "subtract") },
                mathMaxOperand = json.optInt("mathMaxOperand", 90).coerceIn(5, 999),
                memoryGridSize = gridSize,
                memoryTargets = json.optInt("memoryTargets", 3).coerceIn(1, gridSize * gridSize - 1),
                memoryRounds = json.optInt("memoryRounds", 1).coerceIn(1, 10),
                shakeCount = json.optInt("shakeCount", 12).coerceIn(3, 100),
                shakeThreshold = json.optDouble("shakeThreshold", 2.4).let {
                    if (it.isFinite()) it.coerceIn(1.5, 4.0) else 2.4
                },
                typingPhrase = json.optString("typingPhrase", "I am awake and ready").trim()
                    .ifBlank { "I am awake and ready" }.take(120),
                numberCount = json.optInt("numberCount", 6).coerceIn(4, 12),
            )
        }
    }
}

/** Editing schedules must not cancel an in-flight snooze or silent mission timer. */
object AlarmSyncPolicy {
    fun cancelSession(previous: AlarmData, updated: AlarmData?): Boolean =
        previous.enabled && (updated == null || !updated.enabled || previous.mode != updated.mode)

    private val unavailablePermissions = mapOf<String, Any>(
        "exactAlarm" to false, "notifications" to false, "fullScreen" to false, "overlay" to false,
    )

    /** Once storage committed, a scheduling error cannot truthfully report a failed save. */
    fun afterPersist(sync: () -> Map<String, Any>): Map<String, Any> = try {
        sync() + mapOf("saved" to true)
    } catch (error: Exception) {
        unavailablePermissions + mapOf(
            "saved" to true, "scheduledCount" to 0,
            "scheduleError" to failureMessage(error),
        )
    }

    fun rescheduleBestEffort(
        alarms: List<AlarmData>,
        permissions: () -> Map<String, Any>,
        cancelMain: (AlarmData) -> Unit,
        armMain: (AlarmData) -> Unit,
        syncWakeChecks: () -> Unit,
    ): Map<String, Any> {
        val failures = mutableListOf<String>()
        val status = try {
            unavailablePermissions + permissions()
        } catch (error: Exception) {
            failures.add("Permission query: ${failureMessage(error)}")
            unavailablePermissions
        }
        fun attempt(stage: String, action: () -> Unit): Boolean = try {
            action()
            true
        } catch (error: Exception) {
            failures.add("$stage: ${failureMessage(error)}")
            false
        }
        alarms.forEach { alarm -> attempt("Cancel previous schedule") { cancelMain(alarm) } }
        var count = 0
        if (status["exactAlarm"] == true) alarms.filter { it.enabled && it.weekdays.isNotEmpty() }.forEach {
            if (attempt("Schedule alarm") { armMain(it) }) count += 1
        } else if (alarms.any { it.enabled && it.weekdays.isNotEmpty() }) {
            failures.add("Exact alarm access is required to schedule enabled alarms")
        }
        attempt("Restore wake checks", syncWakeChecks)
        return status + mapOf("scheduledCount" to count) +
            if (failures.isEmpty()) emptyMap() else mapOf("scheduleError" to failures.joinToString("; "))
    }

    private fun failureMessage(error: Exception): String =
        error.message?.takeIf { it.isNotBlank() }?.take(300) ?: error.javaClass.simpleName
}
