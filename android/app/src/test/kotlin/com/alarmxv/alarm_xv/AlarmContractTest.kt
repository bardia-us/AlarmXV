package com.alarmxv.alarm_xv

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import kotlin.random.Random

class AlarmContractTest {
    @Test fun committedSaveReturnsWarningWhenFollowingSyncThrows() {
        val result = AlarmSyncPolicy.afterPersist { throw SecurityException("Exact access revoked") }
        assertEquals(true, result["saved"])
        assertEquals(0, result["scheduledCount"])
        assertEquals(false, result["exactAlarm"])
        assertEquals(false, result["notifications"])
        assertTrue((result["scheduleError"] as String).contains("Exact access revoked"))
    }

    @Test fun committedSavePreservesSuccessfulSchedulingCount() {
        val result = AlarmSyncPolicy.afterPersist { mapOf("scheduledCount" to 2, "exactAlarm" to true) }
        assertEquals(true, result["saved"])
        assertEquals(2, result["scheduledCount"])
        assertEquals(true, result["exactAlarm"])
        assertNull(result["scheduleError"])
    }

    @Test fun failedArmDoesNotPreventFollowingAlarmsAndCountIsAccurate() {
        val armed = mutableListOf<String>()
        val result = AlarmSyncPolicy.rescheduleBestEffort(
            alarms = listOf(alarm(), alarm().copy(id = "next")),
            permissions = { mapOf("exactAlarm" to true) },
            cancelMain = {},
            armMain = { if (it.id == "morning") throw SecurityException("Revoked while arming") else armed.add(it.id) },
            syncWakeChecks = {},
        )
        assertEquals(listOf("next"), armed)
        assertEquals(1, result["scheduledCount"])
        assertTrue((result["scheduleError"] as String).contains("Revoked while arming"))
    }

    @Test fun cancellationFailureStillAllowsArmingAndPermissionQueryFailureIsHonest() {
        var armed = 0
        val result = AlarmSyncPolicy.rescheduleBestEffort(
            alarms = listOf(alarm()), permissions = { mapOf("exactAlarm" to true) },
            cancelMain = { throw IllegalStateException("Cancel unavailable") },
            armMain = { armed += 1 }, syncWakeChecks = {},
        )
        assertEquals(1, armed)
        assertEquals(1, result["scheduledCount"])
        assertTrue((result["scheduleError"] as String).contains("Cancel unavailable"))
        val unavailable = AlarmSyncPolicy.rescheduleBestEffort(
            alarms = listOf(alarm()), permissions = { throw SecurityException("Query unavailable") },
            cancelMain = {}, armMain = { fail("Must not assume exact permission") }, syncWakeChecks = {},
        )
        assertEquals(false, unavailable["exactAlarm"])
        assertEquals(false, unavailable["notifications"])
        assertEquals(0, unavailable["scheduledCount"])
        assertTrue((unavailable["scheduleError"] as String).contains("Query unavailable"))
    }

    private fun alarm() = AlarmData.fromJson(JSONObject("""{
      "id":"morning","hour":7,"minute":30,"weekdays":[1,2,3],
      "challenges":["typing","shake","order","memory","math"],"groupId":"work",
      "missionSettings":{"mathDifficulty":"custom","mathOperations":["divide"],
        "mathQuestions":8,"memoryGridSize":5,"memoryTargets":9,"memoryRounds":3,
        "shakeCount":27,"shakeThreshold":3.1,"typingPhrase":"Ready for today","numberCount":9},
      "wakeCheck":{"enabled":true,"delayMinutes":4,"checkCount":2}
    }"""))

    @Test fun nativeRewritePreservesOrderedMissionsAndGroupAndSettings() {
        val rewritten = alarm().toJson()
        assertEquals("work", rewritten.getString("groupId"))
        assertEquals("[\"typing\",\"shake\",\"order\",\"memory\",\"math\"]", rewritten.getJSONArray("challenges").toString())
        assertEquals(27, rewritten.getJSONObject("missionSettings").getInt("shakeCount"))
        assertEquals(3, rewritten.getJSONObject("missionSettings").getInt("memoryRounds"))
        assertEquals("Ready for today", rewritten.getJSONObject("missionSettings").getString("typingPhrase"))
        assertEquals(alarm(), AlarmData.fromJson(rewritten))
    }

    @Test fun legacyAlarmDefaultsRemainSolvable() {
        val legacy = AlarmData.fromJson(JSONObject("""{"id":"old","hour":8,"minute":0,"challenge":"math"}"""))
        val settings = legacy.toJson().getJSONObject("missionSettings")
        assertEquals(3, settings.getInt("mathQuestions"))
        assertEquals(4, settings.getInt("memoryGridSize"))
        assertEquals(5, settings.getInt("memoryTargets"))
        assertEquals(10, settings.getInt("shakeCount"))
        assertEquals(3, MissionSettings().memoryGridSize)
        assertEquals(12, MissionSettings().shakeCount)
        assertEquals(3, MissionSettings.fromJson(JSONObject()).memoryGridSize)
    }

    @Test fun invalidMissionSettingsAreClamped() {
        val settings = MissionSettings.fromJson(JSONObject("""{"mathQuestions":0,"mathOperations":["unknown"],"memoryGridSize":3,"memoryTargets":99,"shakeThreshold":999,"typingPhrase":"  "}"""))
        assertEquals(1, settings.mathQuestions)
        assertEquals(listOf("add", "subtract"), settings.mathOperations)
        assertEquals(8, settings.memoryTargets)
        assertEquals(4.0, settings.shakeThreshold, 0.0)
        assertEquals("I am awake and ready", settings.typingPhrase)
    }

    @Test fun unrelatedEditsPreservePendingSessionButDisableCancelsIt() {
        val original = alarm()
        assertFalse(AlarmSyncPolicy.cancelSession(original, original.copy(label = "New label")))
        assertFalse(AlarmSyncPolicy.cancelSession(original, original))
        assertTrue(AlarmSyncPolicy.cancelSession(original, original.copy(enabled = false)))
        assertTrue(AlarmSyncPolicy.cancelSession(original, null))
    }

    @Test fun customDivisionAlwaysHasExactPositiveIntegerAnswer() {
        val settings = MissionSettings.fromJson(JSONObject("""{"mathDifficulty":"custom","mathOperations":["divide"],"mathMaxOperand":25}"""))
        val generator = MathProblemGenerator(Random(4))
        repeat(200) {
            val problem = generator.next(settings = settings)
            assertEquals("divide", problem.operation)
            assertTrue(problem.right > 0)
            assertTrue(problem.left <= 25)
            assertEquals(0, problem.left % problem.right)
            assertEquals(problem.left / problem.right, problem.answer)
        }
    }

    @Test fun legacyMathStillUsesTwoDigitOperandsWithoutNegativeAnswers() {
        val generator = MathProblemGenerator(Random(12))
        repeat(200) {
            val problem = generator.next()
            assertTrue(problem.left in 20..90)
            assertTrue(problem.right in 20..90)
            assertTrue(problem.operation in listOf("add", "subtract"))
            assertTrue(problem.answer >= 0)
        }
    }

    @Test fun hardDifficultyDoesNotOverrideSelectedOperation() {
        val settings = MissionSettings.fromJson(JSONObject("""{"mathDifficulty":"hard","mathOperations":["subtract"]}"""))
        val generator = MathProblemGenerator(Random(1))
        repeat(100) {
            val problem = generator.next(settings = settings)
            assertEquals("subtract", problem.operation)
            assertTrue(problem.answer >= 0)
        }
    }
}
