package com.alarmxv.alarm_xv

import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

data class MathProblem(
    val left: Int,
    val right: Int,
    val addition: Boolean,
) {
    val answer: Int get() = if (addition) left + right else left - right
    val key: String get() = "$left${if (addition) "+" else "-"}$right"
}

class MathProblemGenerator(private val random: Random = Random.Default) {
    fun next(previousKey: String? = null): MathProblem {
        repeat(20) {
            val first = random.nextInt(20, 91)
            val second = random.nextInt(20, 91)
            val addition = random.nextBoolean()
            val problem = MathProblem(
                left = if (addition) first else max(first, second),
                right = if (addition) second else min(first, second),
                addition = addition,
            )
            if (problem.key != previousKey) return problem
        }
        return if (previousKey == "47+38") {
            MathProblem(83, 29, false)
        } else {
            MathProblem(47, 38, true)
        }
    }
}
