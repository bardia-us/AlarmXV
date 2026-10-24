package com.alarmxv.alarm_xv

import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

data class MathProblem(
    val left: Int,
    val right: Int,
    val addition: Boolean,
    val operation: String = if (addition) "add" else "subtract",
) {
    val answer: Int get() = when (operation) {
        "multiply" -> left * right
        "divide" -> left / right
        "subtract" -> left - right
        else -> left + right
    }
    val symbol: String get() = when (operation) {
        "multiply" -> "×"
        "divide" -> "÷"
        "subtract" -> "−"
        else -> "+"
    }
    val key: String get() = "$left$operation$right"
}

class MathProblemGenerator(private val random: Random = Random.Default) {
    fun next(previousKey: String? = null, settings: MissionSettings = MissionSettings()): MathProblem {
        val limit = when (settings.mathDifficulty) {
            "easy" -> 20
            "hard" -> 150
            "custom" -> settings.mathMaxOperand
            else -> 90
        }
        val operations = settings.mathOperations
        val multiplicationLimit = if (settings.mathDifficulty == "custom") limit else min(limit, 20)
        var fallback: MathProblem? = null
        val minimum = if (settings.mathDifficulty == "medium") 20 else 1
        repeat(100) {
            val operation = operations.random(random)
            val first = random.nextInt(minimum, limit + 1)
            val second = random.nextInt(minimum, limit + 1)
            val divisor = random.nextInt(1, min(limit, 12) + 1)
            val problem = MathProblem(
                left = when (operation) {
                    "subtract" -> max(first, second)
                    "multiply" -> random.nextInt(1, multiplicationLimit + 1)
                    "divide" -> divisor * random.nextInt(1, limit / divisor + 1)
                    else -> first
                },
                right = when (operation) {
                    "subtract" -> min(first, second)
                    "multiply" -> random.nextInt(1, multiplicationLimit + 1)
                    "divide" -> divisor
                    else -> second
                },
                addition = operation == "add",
                operation = operation,
            )
            fallback = problem
            if (problem.key != previousKey) return problem
        }
        return requireNotNull(fallback)
    }
}
