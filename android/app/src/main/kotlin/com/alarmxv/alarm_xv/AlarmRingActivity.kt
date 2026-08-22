package com.alarmxv.alarm_xv

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextClock
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.min
import kotlin.math.sqrt
import kotlin.random.Random

class AlarmRingActivity : Activity(), SensorEventListener {
    private val handler = Handler(Looper.getMainLooper())
    private val mathGenerator = MathProblemGenerator()

    private lateinit var alarm: AlarmData
    private var snoozeCount = 0
    private var challengeOrder = listOf<String>()
    private var challengeIndex = 0
    private var currentChallenge = ""
    private var ringPhase = phaseRinging
    private var challengeDeadlineMillis = 0L
    private var endingAlarm = false

    private lateinit var challengeBadge: TextView
    private lateinit var challengeProgressText: TextView
    private lateinit var overallProgress: ProgressBar
    private lateinit var challengeContainer: LinearLayout
    private lateinit var snoozeButton: Button
    private lateinit var snoozeCard: LinearLayout

    private val challengeCountdown = object : Runnable {
        override fun run() {
            if (ringPhase != phaseChallenge || challengeDeadlineMillis <= 0L) return
            val remaining = challengeDeadlineMillis - System.currentTimeMillis()
            if (remaining <= 0L) {
                challengeTimedOut()
                return
            }
            updateChallengeProgress(remaining)
            handler.postDelayed(this, 250L.coerceAtLeast(remaining % 1_000L))
        }
    }

    private var mathSolved = 0
    private var mathProblem: MathProblem? = null
    private var mathInput = ""

    private var memoryPhase = ""
    private val memoryTargets = mutableSetOf<Int>()
    private val memorySelected = mutableSetOf<Int>()
    private var memoryToken = 0

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var shakeCount = 0
    private var lastShakeAt = 0L
    private var shakeCountText: TextView? = null
    private var shakeRemainingText: TextView? = null
    private var shakeProgress: ProgressBar? = null
    private var shakeFeedback: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureLockScreen()
        alarm = AlarmData.fromJson(
            JSONObject(intent.getStringExtra(extraAlarmJson) ?: error("Missing alarm")),
        )
        snoozeCount = intent.getIntExtra(extraSnoozeCount, 0)
        challengeOrder = listOf("math", "memory", "shake").filter { it in alarm.challenges }
        if (challengeOrder.isEmpty()) challengeOrder = listOf("math")

        sensorManager = getSystemService(SensorManager::class.java)
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        restoreState(savedInstanceState)
        setContentView(buildScreen())
        hideSystemBars()
        if (ringPhase == phaseChallenge && challengeDeadlineMillis > System.currentTimeMillis()) {
            RingingService.pauseForChallenge(this)
            showCurrentChallenge(resumeDeadline = true)
        } else {
            showRingingPhase(resumeSound = ringPhase == phaseChallenge)
        }
    }

    override fun onResume() {
        super.onResume()
        RingingService.setAlarmActivityVisible(true)
        hideSystemBars()
        if (ringPhase == phaseChallenge && challengeDeadlineMillis <= System.currentTimeMillis()) {
            challengeTimedOut()
            return
        }
        if (currentChallenge == "shake") registerAccelerometer()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            RingingService.setAlarmActivityVisible(true)
            hideSystemBars()
        } else if (!endingAlarm) {
            RingingService.setAlarmActivityVisible(false)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val nextAlarmId = runCatching {
            JSONObject(intent.getStringExtra(extraAlarmJson) ?: "{}").optString("id")
        }.getOrDefault("")
        setIntent(intent)
        if (::alarm.isInitialized && nextAlarmId.isNotEmpty() && nextAlarmId != alarm.id) {
            recreate()
        } else if (::alarm.isInitialized && nextAlarmId == alarm.id &&
            RingStateStore.load(this, alarm.id) == null
        ) {
            resetChallengeProgress()
            showRingingPhase(resumeSound = false)
        }
    }

    override fun onPause() {
        sensorManager.unregisterListener(this)
        if (!endingAlarm) RingingService.setAlarmActivityVisible(false)
        persistState()
        super.onPause()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        val state = createStateJson()
        outState.putString(savedStateKey, state.toString())
        if (!isFinishing) RingStateStore.save(this, alarm.id, state)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        memoryToken += 1
        handler.removeCallbacksAndMessages(null)
        sensorManager.unregisterListener(this)
        super.onDestroy()
    }

    @Deprecated("Alarm challenges must not be bypassed with Back")
    override fun onBackPressed() = Unit

    private fun configureLockScreen() {
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            getSystemService(KeyguardManager::class.java).requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun hideSystemBars() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.apply {
                hide(WindowInsets.Type.systemBars())
                systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        }
    }

    private fun buildScreen(): View {
        val screenWidth = resources.displayMetrics.widthPixels
        val contentWidth = min(screenWidth - dp(28), dp(600))
        val compact = resources.configuration.screenHeightDp < 650

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(18), if (compact) dp(20) else dp(36), dp(18), dp(24))
        }

        val clock = TextClock(this).apply {
            format12Hour = "h:mm"
            format24Hour = "HH:mm"
            textSize = if (compact) 68f else 82f
            setTextColor(colorText)
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
            includeFontPadding = false
        }
        content.addView(clock, linearParams())
        content.addView(textView(alarm.label, 24f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            maxLines = 2
        }, linearParams(top = 2))

        challengeBadge = textView("", 13f, colorPrimarySoft, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(7), dp(14), dp(7))
            background = roundedBackground(colorCardRaised, 20)
        }
        content.addView(challengeBadge, linearParams(top = if (compact) 18 else 26))

        challengeProgressText = textView("", 14f, colorMuted, Typeface.NORMAL).apply {
            gravity = Gravity.CENTER
        }
        content.addView(challengeProgressText, linearParams(top = 10))
        overallProgress = ProgressBar(
            this,
            null,
            android.R.attr.progressBarStyleHorizontal,
        ).apply {
            max = challengeOrder.size
            progressTintList = ColorStateList.valueOf(colorPrimary)
            progressBackgroundTintList = ColorStateList.valueOf(colorTrack)
        }
        content.addView(overallProgress, linearParams(height = dp(5), top = 7))

        challengeContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(20), dp(22), dp(20), dp(22))
            background = roundedBackground(colorCard, 26)
        }
        content.addView(challengeContainer, linearParams(top = 16))

        snoozeCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(16), dp(14), dp(16), dp(16))
            background = roundedBackground(colorCardRaised, 20)
        }
        snoozeCard.addView(textView("SNOOZE", 12f, colorMuted, Typeface.BOLD).apply {
            letterSpacing = 0.16f
            gravity = Gravity.CENTER
        }, linearParams())
        snoozeButton = secondaryButton().apply {
            text = "Snooze ${alarm.snoozeMinutes} minutes"
            visibility = if (
                alarm.snoozeMinutes > 0 && snoozeCount < alarm.maxSnoozes
            ) View.VISIBLE else View.GONE
            setOnClickListener { snooze() }
        }
        snoozeCard.addView(snoozeButton, linearParams(height = dp(54), top = 10))
        snoozeCard.visibility = snoozeButton.visibility
        content.addView(snoozeCard, linearParams(top = 18))

        val frame = FrameLayout(this).apply {
            setBackgroundColor(colorBackground)
            addView(
                content,
                FrameLayout.LayoutParams(
                    contentWidth,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER_HORIZONTAL,
                ),
            )
        }
        return ScrollView(this).apply {
            isFillViewport = true
            overScrollMode = View.OVER_SCROLL_NEVER
            setBackgroundColor(colorBackground)
            addView(
                frame,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
        }
    }

    private fun showRingingPhase(resumeSound: Boolean) {
        ringPhase = phaseRinging
        currentChallenge = ""
        challengeDeadlineMillis = 0L
        memoryToken += 1
        sensorManager.unregisterListener(this)
        handler.removeCallbacks(challengeCountdown)
        AlarmScheduler.cancelChallengeTimeout(this, alarm.id)
        if (resumeSound) RingingService.resumeRinging(this, alarm, snoozeCount)

        challengeBadge.visibility = View.GONE
        challengeProgressText.visibility = View.GONE
        overallProgress.visibility = View.GONE
        snoozeCard.visibility = if (
            alarm.snoozeMinutes > 0 && snoozeCount < alarm.maxSnoozes
        ) View.VISIBLE else View.GONE
        challengeContainer.removeAllViews()
        challengeContainer.addView(primaryButton().apply {
            text = "Start"
            textSize = 20f
            setOnClickListener { beginChallenges() }
        }, linearParams(height = dp(64)))
        persistState()
    }

    private fun beginChallenges() {
        resetChallengeProgress()
        ringPhase = phaseChallenge
        snoozeCard.visibility = View.GONE
        RingingService.pauseForChallenge(this)
        showCurrentChallenge(resumeDeadline = false)
    }

    private fun showCurrentChallenge(resumeDeadline: Boolean = false) {
        memoryToken += 1
        sensorManager.unregisterListener(this)
        handler.removeCallbacks(challengeCountdown)
        challengeContainer.removeAllViews()
        if (challengeIndex >= challengeOrder.size) {
            completeAlarm()
            return
        }
        ringPhase = phaseChallenge
        currentChallenge = challengeOrder[challengeIndex]
        challengeBadge.visibility = View.VISIBLE
        challengeProgressText.visibility = View.VISIBLE
        overallProgress.visibility = View.VISIBLE
        snoozeCard.visibility = View.GONE
        challengeBadge.text = currentChallenge.uppercase()
        overallProgress.progress = challengeIndex + 1
        if (!resumeDeadline || challengeDeadlineMillis <= System.currentTimeMillis()) {
            challengeDeadlineMillis = System.currentTimeMillis() + challengeDurationMillis()
        }
        if (!AlarmScheduler.scheduleChallengeTimeout(this, alarm, challengeDeadlineMillis)) {
            Toast.makeText(
                this,
                "Could not arm the challenge timeout. Exact alarm access is required.",
                Toast.LENGTH_LONG,
            ).show()
        }
        updateChallengeProgress(challengeDeadlineMillis - System.currentTimeMillis())
        when (currentChallenge) {
            "math" -> showMathChallenge()
            "memory" -> showMemoryChallenge()
            "shake" -> showShakeChallenge()
        }
        persistState()
        handler.post(challengeCountdown)
    }

    private fun nextChallenge() {
        challengeIndex += 1
        memoryPhase = ""
        memoryTargets.clear()
        memorySelected.clear()
        challengeDeadlineMillis = 0L
        showCurrentChallenge(resumeDeadline = false)
    }

    private fun challengeDurationMillis(): Long = when (currentChallenge) {
        "math" -> 90_000L
        "memory" -> 75_000L
        "shake" -> 60_000L
        else -> 60_000L
    }

    private fun updateChallengeProgress(remainingMillis: Long) {
        val seconds = ((remainingMillis.coerceAtLeast(0L) + 999L) / 1_000L).toInt()
        challengeProgressText.text =
            "${challengeIndex + 1} / ${challengeOrder.size}  ·  %d:%02d".format(
                seconds / 60,
                seconds % 60,
            )
    }

    private fun challengeTimedOut() {
        if (ringPhase != phaseChallenge) return
        resetChallengeProgress()
        RingStateStore.clear(this, alarm.id)
        showRingingPhase(resumeSound = true)
        Toast.makeText(this, "Time is up — the alarm is ringing again.", Toast.LENGTH_LONG).show()
    }

    private fun resetChallengeProgress() {
        challengeIndex = 0
        currentChallenge = ""
        challengeDeadlineMillis = 0L
        mathSolved = 0
        mathProblem = null
        mathInput = ""
        memoryPhase = ""
        memoryTargets.clear()
        memorySelected.clear()
        memoryToken += 1
        shakeCount = 0
        lastShakeAt = 0L
    }

    private fun showMathChallenge() {
        if (mathProblem == null) mathProblem = mathGenerator.next()
        val question = textView("", 46f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            includeFontPadding = false
        }
        val remaining = textView("", 14f, colorMuted, Typeface.NORMAL).apply {
            gravity = Gravity.CENTER
        }
        val answer = textView("", 34f, colorText, Typeface.NORMAL).apply {
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(12), dp(14), dp(12))
            background = roundedBackground(colorInput, 16)
            minHeight = dp(64)
        }
        val feedback = textView("", 14f, colorDanger, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            minHeight = dp(24)
        }

        fun render() {
            val problem = mathProblem ?: return
            question.text = "${problem.left} ${if (problem.addition) "+" else "−"} ${problem.right}"
            answer.text = mathInput.ifEmpty { "—" }
            remaining.text = "${3 - mathSolved} correct answer${if (3 - mathSolved == 1) "" else "s"} remaining"
        }

        val keypad = GridLayout(this).apply {
            columnCount = 3
            rowCount = 4
        }
        val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓")
        keys.forEachIndexed { index, key ->
            val button = keypadButton(key, key == "✓").apply {
                setOnClickListener {
                    when (key) {
                        "⌫" -> if (mathInput.isNotEmpty()) mathInput = mathInput.dropLast(1)
                        "✓" -> {
                            val correct = mathInput.toIntOrNull() == mathProblem?.answer
                            if (correct) {
                                mathSolved += 1
                                mathInput = ""
                                if (mathSolved >= 3) {
                                    nextChallenge()
                                    return@setOnClickListener
                                }
                                val previous = mathProblem?.key
                                mathProblem = mathGenerator.next(previous)
                                feedback.text = "Correct"
                                feedback.setTextColor(colorSuccess)
                            } else {
                                feedback.text = "Try again"
                                feedback.setTextColor(colorDanger)
                                mathInput = ""
                                answer.animate().translationX(dp(10).toFloat()).setDuration(70)
                                    .withEndAction {
                                        answer.animate().translationX(-dp(10).toFloat()).setDuration(70)
                                            .withEndAction {
                                                answer.animate().translationX(0f).setDuration(70).start()
                                            }.start()
                                    }.start()
                            }
                        }
                        else -> if (mathInput.length < 4) mathInput += key
                    }
                    render()
                    persistState()
                }
            }
            keypad.addView(button, gridParams(index, columns = 3, size = 68))
        }
        challengeContainer.addView(question, linearParams())
        challengeContainer.addView(remaining, linearParams(top = 6))
        challengeContainer.addView(answer, linearParams(top = 16))
        challengeContainer.addView(feedback, linearParams(top = 6))
        challengeContainer.addView(keypad, linearParams(top = 10))
        render()
    }

    private fun showMemoryChallenge() {
        val instruction = textView("", 17f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }
        val countdown = textView("", 54f, colorPrimarySoft, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            minHeight = dp(70)
        }
        val grid = GridLayout(this).apply {
            columnCount = 4
            rowCount = 4
        }
        val cells = mutableListOf<TextView>()
        val confirm = primaryButton().apply {
            text = "Confirm pattern"
            isEnabled = false
        }

        fun cellColor(index: Int, revealing: Boolean): Int = when {
            revealing && index in memoryTargets -> colorPrimary
            index in memorySelected -> colorPrimaryDark
            else -> colorTile
        }

        fun updateCells(revealing: Boolean, enabled: Boolean) {
            cells.forEachIndexed { index, cell ->
                cell.background = roundedBackground(cellColor(index, revealing), 14)
                cell.isEnabled = enabled
                cell.text = if (!revealing && index in memorySelected) "✓" else ""
                cell.alpha = if (revealing && index !in memoryTargets) 0.62f else 1f
            }
            confirm.isEnabled = enabled
        }

        repeat(16) { index ->
            val cell = TextView(this).apply {
                gravity = Gravity.CENTER
                textSize = 20f
                setTextColor(colorText)
                setOnClickListener {
                    if (memoryPhase != "selecting") return@setOnClickListener
                    if (index in memorySelected) {
                        memorySelected.remove(index)
                    } else if (memorySelected.size < 5) {
                        memorySelected.add(index)
                    }
                    updateCells(revealing = false, enabled = true)
                    instruction.text = "${memorySelected.size} / 5 selected"
                    persistState()
                }
            }
            cells.add(cell)
            grid.addView(cell, gridParams(index, columns = 4, size = 62))
        }

        fun enterSelection() {
            memoryPhase = "selecting"
            countdown.text = ""
            instruction.text = "Select the 5 highlighted tiles"
            updateCells(revealing = false, enabled = true)
            persistState()
        }

        fun reveal(token: Int) {
            if (token != memoryToken) return
            memoryPhase = "revealing"
            countdown.text = ""
            instruction.text = "Remember this pattern"
            updateCells(revealing = true, enabled = false)
            cells.filterIndexed { index, _ -> index in memoryTargets }.forEach { cell ->
                cell.scaleX = 0.86f
                cell.scaleY = 0.86f
                cell.animate().scaleX(1f).scaleY(1f).setDuration(220).start()
            }
            persistState()
            handler.postDelayed({ enterSelection() }, 1_450)
        }

        fun runCountdown(token: Int, value: Int) {
            if (token != memoryToken) return
            if (value == 0) {
                reveal(token)
                return
            }
            memoryPhase = "countdown"
            instruction.text = "Get ready"
            countdown.text = value.toString()
            countdown.alpha = 0f
            countdown.scaleX = 1.35f
            countdown.scaleY = 1.35f
            countdown.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(260).start()
            handler.postDelayed({ runCountdown(token, value - 1) }, 720)
        }

        fun startNewRound(message: String? = null) {
            memoryToken += 1
            val token = memoryToken
            memoryTargets.clear()
            memorySelected.clear()
            while (memoryTargets.size < 5) memoryTargets.add(Random.nextInt(0, 16))
            updateCells(revealing = false, enabled = false)
            instruction.text = message ?: "Get ready"
            persistState()
            handler.postDelayed({ runCountdown(token, 3) }, if (message == null) 250 else 700)
        }

        confirm.setOnClickListener {
            if (memorySelected == memoryTargets) {
                nextChallenge()
            } else {
                startNewRound("New pattern — try again")
            }
        }

        challengeContainer.addView(instruction, linearParams())
        challengeContainer.addView(countdown, linearParams(top = 4))
        challengeContainer.addView(grid, linearParams(top = 8))
        challengeContainer.addView(confirm, linearParams(height = dp(54), top = 16))

        if (memoryPhase == "selecting" && memoryTargets.size == 5) {
            enterSelection()
        } else {
            startNewRound()
        }
    }

    private fun showShakeChallenge() {
        val icon = textView("↔", 62f, colorPrimarySoft, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            includeFontPadding = false
        }
        challengeContainer.addView(textView("Shake the phone", 24f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }, linearParams())
        challengeContainer.addView(icon, linearParams(top = 10))
        shakeCountText = textView("$shakeCount / 10", 36f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }
        challengeContainer.addView(shakeCountText, linearParams(top = 2))
        shakeProgress = ProgressBar(
            this,
            null,
            android.R.attr.progressBarStyleHorizontal,
        ).apply {
            max = 10
            progress = shakeCount
            progressTintList = ColorStateList.valueOf(colorPrimary)
            progressBackgroundTintList = ColorStateList.valueOf(colorTrack)
        }
        challengeContainer.addView(shakeProgress, linearParams(height = dp(8), top = 14))
        shakeRemainingText = textView(
            "${10 - shakeCount} remaining",
            15f,
            colorMuted,
            Typeface.NORMAL,
        ).apply { gravity = Gravity.CENTER }
        challengeContainer.addView(shakeRemainingText, linearParams(top = 10))
        shakeFeedback = icon
        if (accelerometer == null) {
            challengeContainer.addView(textView(
                "Accelerometer unavailable — use emergency stop below.",
                13f,
                colorDanger,
                Typeface.NORMAL,
            ).apply { gravity = Gravity.CENTER }, linearParams(top = 10))
        } else {
            challengeContainer.addView(textView(
                "Use deliberate shakes. Small movements are ignored.",
                13f,
                colorMuted,
                Typeface.NORMAL,
            ).apply { gravity = Gravity.CENTER }, linearParams(top = 10))
        }
        registerAccelerometer()
    }

    private fun registerAccelerometer() {
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (currentChallenge != "shake") return
        val force = sqrt(
            event.values[0] * event.values[0] +
                event.values[1] * event.values[1] +
                event.values[2] * event.values[2],
        ) / SensorManager.GRAVITY_EARTH
        val now = System.currentTimeMillis()
        if (force >= 2.4f && now - lastShakeAt >= 500) {
            lastShakeAt = now
            shakeCount += 1
            shakeCountText?.text = "$shakeCount / 10"
            shakeRemainingText?.text = "${10 - shakeCount} remaining"
            shakeProgress?.progress = shakeCount
            shakeFeedback?.animate()?.scaleX(1.3f)?.scaleY(1.3f)?.setDuration(100)
                ?.withEndAction {
                    shakeFeedback?.animate()?.scaleX(1f)?.scaleY(1f)?.setDuration(140)?.start()
                }?.start()
            persistState()
            if (shakeCount >= 10) nextChallenge()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun snooze() {
        if (!AlarmScheduler.scheduleSnooze(this, alarm, snoozeCount + 1)) {
            Toast.makeText(this, "Exact alarm access is required for snooze.", Toast.LENGTH_LONG)
                .show()
            return
        }
        AlarmScheduler.cancelChallengeTimeout(this, alarm.id)
        RingStateStore.clear(this, alarm.id)
        WakeCheckScheduler.cancel(this, alarm.id)
        endingAlarm = true
        RingingService.stop(this)
        finishAndRemoveTask()
    }

    private fun completeAlarm() {
        AlarmScheduler.cancelChallengeTimeout(this, alarm.id)
        RingStateStore.clear(this, alarm.id)
        WakeCheckScheduler.startCycle(this, alarm)
        endingAlarm = true
        RingingService.stop(this)
        finishAndRemoveTask()
    }

    private fun restoreState(savedInstanceState: Bundle?) {
        val savedState = savedInstanceState?.getString(savedStateKey)?.let {
            runCatching { JSONObject(it) }.getOrNull()
        }
        val state = savedState?.takeIf { it.optString("alarmId") == alarm.id }
            ?: RingStateStore.load(this, alarm.id)
            ?: return
        ringPhase = state.optString("phase", phaseRinging)
            .takeIf { it == phaseRinging || it == phaseChallenge }
            ?: phaseRinging
        challengeDeadlineMillis = state.optLong("challengeDeadlineMillis", 0L)
        challengeIndex = state.optInt("challengeIndex", 0).coerceIn(0, challengeOrder.size)
        mathSolved = state.optInt("mathSolved", 0).coerceIn(0, 3)
        mathInput = state.optString("mathInput", "")
        state.optJSONObject("mathProblem")?.let {
            mathProblem = MathProblem(
                left = it.getInt("left"),
                right = it.getInt("right"),
                addition = it.getBoolean("addition"),
            )
        }
        memoryPhase = state.optString("memoryPhase", "")
        restoreIntSet(state.optJSONArray("memoryTargets"), memoryTargets)
        restoreIntSet(state.optJSONArray("memorySelected"), memorySelected)
        shakeCount = state.optInt("shakeCount", 0).coerceIn(0, 10)
    }

    private fun persistState() {
        if (!::alarm.isInitialized || isFinishing) return
        RingStateStore.save(this, alarm.id, createStateJson())
    }

    private fun createStateJson() = JSONObject().apply {
        put("alarmId", alarm.id)
        put("phase", ringPhase)
        put("challengeDeadlineMillis", challengeDeadlineMillis)
        put("challengeIndex", challengeIndex)
        put("mathSolved", mathSolved)
        put("mathInput", mathInput)
        mathProblem?.let { problem ->
            put("mathProblem", JSONObject().apply {
                put("left", problem.left)
                put("right", problem.right)
                put("addition", problem.addition)
            })
        }
        put("memoryPhase", memoryPhase)
        put("memoryTargets", JSONArray(memoryTargets.toList()))
        put("memorySelected", JSONArray(memorySelected.toList()))
        put("shakeCount", shakeCount)
    }

    private fun restoreIntSet(array: JSONArray?, target: MutableSet<Int>) {
        target.clear()
        if (array == null) return
        for (index in 0 until array.length()) target.add(array.getInt(index))
    }

    private fun primaryButton(): Button = styledButton(colorPrimary, colorText)

    private fun secondaryButton(): Button = styledButton(colorPrimaryDark, colorText)

    private fun keypadButton(label: String, primary: Boolean): Button =
        styledButton(if (primary) colorPrimary else colorInput, colorText).apply {
            text = label
            textSize = if (label == "✓") 22f else 20f
        }

    private fun styledButton(backgroundColor: Int, textColor: Int): Button = Button(this).apply {
        isAllCaps = false
        textSize = 16f
        setTextColor(textColor)
        background = roundedBackground(backgroundColor, 18)
        stateListAnimator = null
        setPadding(dp(12), 0, dp(12), 0)
    }

    private fun textView(textValue: String, size: Float, color: Int, style: Int) =
        TextView(this).apply {
            text = textValue
            textSize = size
            setTextColor(color)
            setTypeface(typeface, style)
        }

    private fun roundedBackground(color: Int, radius: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radius).toFloat()
    }

    private fun roundedStrokeBackground(color: Int, stroke: Int, radius: Int) =
        GradientDrawable().apply {
            setColor(color)
            setStroke(dp(1), stroke)
            cornerRadius = dp(radius).toFloat()
        }

    private fun linearParams(
        width: Int = LinearLayout.LayoutParams.MATCH_PARENT,
        height: Int = LinearLayout.LayoutParams.WRAP_CONTENT,
        top: Int = 0,
    ) = LinearLayout.LayoutParams(width, height).apply { topMargin = dp(top) }

    private fun fixedWidth(width: Int, height: Int, top: Int = 0) =
        LinearLayout.LayoutParams(width, height).apply { topMargin = dp(top) }

    private fun gridParams(index: Int, columns: Int, size: Int) = GridLayout.LayoutParams().apply {
        width = dp(size)
        height = dp(size)
        rowSpec = GridLayout.spec(index / columns)
        columnSpec = GridLayout.spec(index % columns)
        setMargins(dp(4), dp(4), dp(4), dp(4))
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val extraAlarmJson = "alarm_json"
        private const val extraSnoozeCount = "snooze_count"
        private const val savedStateKey = "ring_state_json"
        private const val phaseRinging = "ringing"
        private const val phaseChallenge = "challenge"

        private val colorBackground = Color.rgb(10, 12, 17)
        private val colorCard = Color.rgb(25, 28, 36)
        private val colorCardRaised = Color.rgb(34, 37, 47)
        private val colorInput = Color.rgb(43, 46, 57)
        private val colorTile = Color.rgb(52, 55, 66)
        private val colorTrack = Color.rgb(55, 58, 69)
        private val colorPrimary = Color.rgb(139, 128, 249)
        private val colorPrimaryDark = Color.rgb(82, 68, 150)
        private val colorPrimarySoft = Color.rgb(196, 188, 255)
        private val colorText = Color.rgb(246, 243, 252)
        private val colorMuted = Color.rgb(179, 178, 190)
        private val colorDanger = Color.rgb(255, 180, 171)
        private val colorDangerDim = Color.rgb(108, 63, 62)
        private val colorSuccess = Color.rgb(128, 219, 168)

        fun createIntent(context: Context, alarm: AlarmData, snoozeCount: Int): Intent =
            Intent(context, AlarmRingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(extraAlarmJson, alarm.toJson().toString())
                putExtra(extraSnoozeCount, snoozeCount)
            }
    }
}
