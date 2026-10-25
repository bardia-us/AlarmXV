package com.alarmxv.alarm_xv

import android.app.Activity
import android.animation.ValueAnimator
import android.app.KeyguardManager
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.content.res.ColorStateList
import android.graphics.Typeface
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextClock
import android.widget.TextView
import android.widget.Toast
import android.text.Editable
import android.text.TextWatcher
import android.text.InputType
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.min
import kotlin.math.sqrt
import kotlin.random.Random

class AlarmRingActivity : Activity(), SensorEventListener {
    private val handler = Handler(Looper.getMainLooper())
    private val mathGenerator = MathProblemGenerator()
    private val motionEnabled get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        ValueAnimator.areAnimatorsEnabled()
    } else android.provider.Settings.Global.getFloat(contentResolver,
        android.provider.Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f
    private lateinit var appearance: NativeAppearance
    private val colorBackground get() = appearance.background
    private val colorCard get() = appearance.surface
    private val colorCardRaised get() = appearance.raised
    private val colorInput get() = appearance.raised
    private val colorTile get() = appearance.tile
    private val colorTrack get() = appearance.tile
    private val colorPrimary get() = appearance.accent
    private val colorPrimaryDark get() = appearance.accentSurface
    private val colorPrimarySoft get() = appearance.accent
    private val colorText get() = appearance.text
    private val colorMuted get() = appearance.muted
    private val colorDanger get() = appearance.danger
    private val colorDangerDim get() = appearance.accentSurface
    private val colorSuccess get() = appearance.success

    private lateinit var alarm: AlarmData
    private var snoozeCount = 0
    private var challengeOrder = listOf<String>()
    private var challengeIndex = 0
    private var currentChallenge = ""
    private var ringPhase = phaseRinging
    private var challengeDeadlineMillis = 0L
    private var endingAlarm = false
    private var sessionToken = ""
    private var sessionReceiverRegistered = false
    private val sessionEndedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (::alarm.isInitialized && alarm.isNormal &&
                intent.getStringExtra(RingingService.extraAlarmId) == alarm.id &&
                intent.getStringExtra(RingingService.extraSessionToken) == sessionToken
            ) {
                endingAlarm = true
                finish()
            }
        }
    }

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
    private var memoryRoundsSolved = 0
    private var typingInput = ""
    private var orderNumbers = listOf<Int>()
    private var orderSelected = 0
    private var shakeFallback = false
    private var sensorReceived = false

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
        appearance = NativeAppearance(this)
        volumeControlStream = AudioManager.STREAM_ALARM
        sensorManager = getSystemService(SensorManager::class.java)
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val sessionFilter = IntentFilter(RingingService.actionSessionEnded)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(sessionEndedReceiver, sessionFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(sessionEndedReceiver, sessionFilter)
        }
        sessionReceiverRegistered = true
        showAlarmIntent(intent, savedInstanceState)
    }

    private fun showAlarmIntent(intent: Intent, savedInstanceState: Bundle?) {
        handler.removeCallbacksAndMessages(null)
        memoryToken += 1
        sensorManager.unregisterListener(this)
        resetChallengeProgress()
        ringPhase = phaseRinging
        endingAlarm = false
        alarm = AlarmData.fromJson(
            JSONObject(intent.getStringExtra(extraAlarmJson) ?: error("Missing alarm")),
        )
        sessionToken = intent.getStringExtra(RingingService.extraSessionToken).orEmpty()
        snoozeCount = intent.getIntExtra(extraSnoozeCount, 0)
        configureLockScreen()
        challengeOrder = alarm.challenges.toList()
        if (challengeOrder.isEmpty() && !alarm.isNormal) challengeOrder = listOf("math")
        if (!alarm.isNormal) restoreState(savedInstanceState)
        setContentView(buildScreen())
        applySystemBars()
        if (!alarm.isNormal && ringPhase == phaseChallenge && challengeDeadlineMillis > System.currentTimeMillis()) {
            RingingService.pauseForChallenge(this)
            showCurrentChallenge(resumeDeadline = true)
        } else {
            showRingingPhase(resumeSound = ringPhase == phaseChallenge)
        }
    }

    override fun onResume() {
        super.onResume()
        if (alarm.isNormal && !RingingService.isNormalSessionActive(alarm.id, sessionToken)) {
            endingAlarm = true
            finish()
            return
        }
        updateServiceVisibility(true)
        applySystemBars()
        if (ringPhase == phaseChallenge && challengeDeadlineMillis <= System.currentTimeMillis()) {
            challengeTimedOut()
            return
        }
        if (currentChallenge == "shake") registerAccelerometer()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            updateServiceVisibility(true)
            applySystemBars()
        } else if (!endingAlarm) {
            updateServiceVisibility(false)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val nextAlarmId = runCatching {
            JSONObject(intent.getStringExtra(extraAlarmJson) ?: "{}").optString("id")
        }.getOrDefault("")
        val nextSession = intent.getStringExtra(RingingService.extraSessionToken).orEmpty()
        setIntent(intent)
        if (::alarm.isInitialized && nextAlarmId.isNotEmpty() &&
            (nextAlarmId != alarm.id || nextSession != sessionToken)
        ) {
            if (nextAlarmId != alarm.id) persistState() else RingStateStore.clear(this, alarm.id)
            showAlarmIntent(intent, null)
        } else if (::alarm.isInitialized && nextAlarmId == alarm.id &&
            RingStateStore.load(this, alarm.id) == null
        ) {
            resetChallengeProgress()
            showRingingPhase(resumeSound = false)
        }
    }

    override fun onPause() {
        sensorManager.unregisterListener(this)
        if (!endingAlarm) updateServiceVisibility(false)
        persistState()
        super.onPause()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        if (!alarm.isNormal) {
            val state = createStateJson()
            outState.putString(savedStateKey, state.toString())
            if (!isFinishing) RingStateStore.save(this, alarm.id, state)
        }
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        memoryToken += 1
        handler.removeCallbacksAndMessages(null)
        sensorManager.unregisterListener(this)
        if (sessionReceiverRegistered) unregisterReceiver(sessionEndedReceiver)
        updateServiceVisibility(false)
        super.onDestroy()
    }

    private fun updateServiceVisibility(visible: Boolean) {
        if (::alarm.isInitialized) RingingService.setAlarmActivityVisible(visible, alarm.id, sessionToken)
    }

    @Deprecated("Alarm challenges must not be bypassed with Back")
    override fun onBackPressed() {
        if (::alarm.isInitialized && alarm.isNormal) super.onBackPressed()
    }

    private fun configureLockScreen() {
        if (alarm.isNormal) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_FULLSCREEN)
        } else {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            if (!alarm.isNormal) getSystemService(KeyguardManager::class.java).requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    (if (alarm.isNormal) 0 else WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD),
            )
        }
    }

    private fun applySystemBars() = appearance.applySystemBars(this)

    private fun buildScreen(): View {
        val screenWidth = resources.displayMetrics.widthPixels
        val contentWidth = min(screenWidth - dp(28), dp(600))
        val compact = resources.configuration.screenHeightDp < 650

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(18), if (compact) dp(22) else dp(34), dp(18), dp(28))
        }

        val clock = TextClock(this).apply {
            format12Hour = "h:mm"
            format24Hour = "HH:mm"
            textSize = if (compact) 68f else 82f
            setTextColor(colorText)
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            includeFontPadding = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                setAutoSizeTextTypeUniformWithConfiguration(48, if (compact) 76 else 88, 2,
                    android.util.TypedValue.COMPLEX_UNIT_SP)
            }
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
            appearance.elevate(this, 5f)
        }
        content.addView(challengeContainer, linearParams(top = 16))

        snoozeCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(16), dp(14), dp(16), dp(16))
            background = roundedBackground(colorCardRaised, 20)
        }
        snoozeCard.addView(textView("چرت کوتاه", 12f, colorMuted, Typeface.BOLD).apply {
            letterSpacing = 0.16f
            gravity = Gravity.CENTER
        }, linearParams())
        snoozeButton = secondaryButton().apply {
            text = "چرت ${alarm.snoozeMinutes} دقیقه‌ای"
            visibility = if (
                alarm.snoozeMinutes > 0 && snoozeCount < alarm.maxSnoozes
            ) View.VISIBLE else View.GONE
            setOnClickListener { snooze() }
        }
        snoozeCard.addView(snoozeButton, linearParams(top = 10))
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setOnApplyWindowInsetsListener { view, insets ->
                    val safe = insets.getInsetsIgnoringVisibility(
                        WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                    val keyboard = insets.getInsets(WindowInsets.Type.ime())
                    view.setPadding(safe.left, safe.top, safe.right, maxOf(safe.bottom, keyboard.bottom))
                    insets
                }
            } else {
                fitsSystemWindows = true
                setPadding(0, dp(24), 0, dp(24))
            }
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
        if (alarm.isNormal) {
            challengeContainer.addView(textView("آلارم معمولی", 20f, colorText, Typeface.BOLD).apply {
                gravity = Gravity.CENTER
            }, linearParams())
            challengeContainer.addView(textView("می‌تونی صدا رو کم کنی یا از این صفحه بیرون بری.",
                15f, colorMuted, Typeface.NORMAL).apply { gravity = Gravity.CENTER }, linearParams(top = 12))
            challengeContainer.addView(primaryButton().apply {
                text = "قطع آلارم"
                textSize = 20f
                setOnClickListener { dismissNormalAlarm() }
            }, linearParams(top = 20))
            return
        }
        challengeContainer.addView(primaryButton().apply {
            text = "شروع مأموریت"
            textSize = 20f
            setOnClickListener { beginChallenges() }
        }, linearParams())
        persistState()
    }

    private fun beginChallenges() {
        if (alarm.isNormal) return
        resetChallengeProgress()
        ringPhase = phaseChallenge
        snoozeCard.visibility = View.GONE
        RingingService.pauseForChallenge(this)
        showCurrentChallenge(resumeDeadline = false)
    }

    private fun showCurrentChallenge(resumeDeadline: Boolean = false) {
        if (alarm.isNormal) return
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
        if (currentChallenge == "shake" && (shakeFallback || accelerometer == null)) {
            shakeFallback = true
            currentChallenge = "math"
        }
        challengeBadge.visibility = View.VISIBLE
        challengeProgressText.visibility = View.VISIBLE
        overallProgress.visibility = View.VISIBLE
        snoozeCard.visibility = View.GONE
        challengeBadge.text = when (currentChallenge) {
            "math" -> "ریاضی"
            "memory" -> "حافظه"
            "shake" -> "تکان دادن"
            "typing" -> "تایپ عبارت"
            "order" -> "ترتیب اعداد"
            else -> currentChallenge
        }
        overallProgress.progress = challengeIndex
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
            "typing" -> showTypingChallenge()
            "order" -> showOrderChallenge()
        }
        persistState()
        handler.post(challengeCountdown)
    }

    private fun nextChallenge() {
        challengeIndex += 1
        memoryPhase = ""
        memoryTargets.clear()
        memorySelected.clear()
        memoryRoundsSolved = 0
        mathSolved = 0
        mathProblem = null
        mathInput = ""
        shakeCount = 0
        shakeFallback = false
        typingInput = ""
        orderNumbers = emptyList()
        orderSelected = 0
        challengeDeadlineMillis = 0L
        showCurrentChallenge(resumeDeadline = false)
    }

    private fun challengeDurationMillis(): Long = when (currentChallenge) {
        "math" -> maxOf(90_000L, alarm.missionSettings.mathQuestions * 30_000L)
        "memory" -> maxOf(75_000L, alarm.missionSettings.memoryRounds * 35_000L)
        "shake" -> maxOf(60_000L, alarm.missionSettings.shakeCount * 2_000L)
        "typing" -> 120_000L
        "order" -> 90_000L
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
        memoryRoundsSolved = 0
        typingInput = ""
        orderNumbers = emptyList()
        orderSelected = 0
        shakeFallback = false
    }

    private fun showMathChallenge() {
        if (mathProblem == null) mathProblem = mathGenerator.next(settings = alarm.missionSettings)
        if (shakeFallback) challengeContainer.addView(textView(
            "Motion sensor unavailable · solve math instead", 14f, colorMuted, Typeface.NORMAL
        ).apply { gravity = Gravity.CENTER }, linearParams(top = 8))
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
            question.text = "${problem.left} ${problem.symbol} ${problem.right}"
            answer.text = mathInput.ifEmpty { "—" }
            val count = alarm.missionSettings.mathQuestions - mathSolved
            remaining.text = "$count correct answer${if (count == 1) "" else "s"} remaining"
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
                                if (mathSolved >= alarm.missionSettings.mathQuestions) {
                                    nextChallenge()
                                    return@setOnClickListener
                                }
                                val previous = mathProblem?.key
                                mathProblem = mathGenerator.next(previous, alarm.missionSettings)
                                feedback.text = "Correct"
                                feedback.setTextColor(colorSuccess)
                            } else {
                                feedback.text = "Try again"
                                feedback.setTextColor(colorDanger)
                                mathInput = ""
                                if (motionEnabled) answer.animate().translationX(dp(10).toFloat()).setDuration(70)
                                    .withEndAction {
                                        answer.animate().translationX(-dp(10).toFloat()).setDuration(70)
                                            .withEndAction {
                                                answer.animate().translationX(0f).setDuration(70).start()
                                            }.start()
                                    }.start()
                            }
                        }
                        else -> if (mathInput.length < 7) mathInput += key
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
        val settings = alarm.missionSettings
        val gridSize = settings.memoryGridSize
        val targetCount = settings.memoryTargets
        val instruction = textView("", 17f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }
        val countdown = textView("", 54f, colorPrimarySoft, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            minHeight = dp(70)
        }
        val grid = GridLayout(this).apply {
            columnCount = gridSize
            rowCount = gridSize
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
                cell.background = appearance.ripple(this, cellColor(index, revealing), 14)
                cell.isEnabled = enabled
                cell.text = if (!revealing && index in memorySelected) "✓" else ""
                cell.alpha = if (revealing && index !in memoryTargets) 0.62f else 1f
            }
            confirm.isEnabled = enabled
        }

        repeat(gridSize * gridSize) { index ->
            val cell = TextView(this).apply {
                gravity = Gravity.CENTER
                textSize = 20f
                setTextColor(colorText)
                setOnClickListener {
                    if (memoryPhase != "selecting") return@setOnClickListener
                    if (index in memorySelected) {
                        memorySelected.remove(index)
                    } else if (memorySelected.size < targetCount) {
                        memorySelected.add(index)
                    }
                    updateCells(revealing = false, enabled = true)
                    instruction.text = "${memorySelected.size} / $targetCount selected"
                    persistState()
                }
            }
            cells.add(cell)
            val available = resources.configuration.screenWidthDp - 108
            grid.addView(cell, gridParams(index, columns = gridSize,
                size = min(62, available / gridSize - 8).coerceAtLeast(28)))
        }

        fun enterSelection() {
            memoryPhase = "selecting"
            countdown.text = ""
            instruction.text = "Select the $targetCount highlighted tiles\nRound ${memoryRoundsSolved + 1} / ${settings.memoryRounds}"
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
                if (motionEnabled) {
                    cell.scaleX = 0.86f
                    cell.scaleY = 0.86f
                    cell.animate().scaleX(1f).scaleY(1f).setDuration(220).start()
                }
            }
            persistState()
            handler.postDelayed({ if (token == memoryToken) enterSelection() }, 1_800)
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
            if (motionEnabled) {
                countdown.alpha = 0f
                countdown.scaleX = 1.35f
                countdown.scaleY = 1.35f
                countdown.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(260).start()
            }
            handler.postDelayed({ runCountdown(token, value - 1) }, 720)
        }

        fun startNewRound(message: String? = null) {
            memoryToken += 1
            val token = memoryToken
            memoryPhase = "countdown"
            memoryTargets.clear()
            memorySelected.clear()
            while (memoryTargets.size < targetCount) memoryTargets.add(Random.nextInt(gridSize * gridSize))
            updateCells(revealing = false, enabled = false)
            instruction.text = message ?: "Get ready"
            persistState()
            handler.postDelayed({ runCountdown(token, 3) }, if (message == null) 250 else 700)
        }

        confirm.setOnClickListener {
            if (memorySelected == memoryTargets) {
                memoryRoundsSolved += 1
                if (memoryRoundsSolved >= settings.memoryRounds) nextChallenge()
                else startNewRound("Correct · next round")
            } else {
                startNewRound("New pattern — try again")
            }
        }

        challengeContainer.addView(instruction, linearParams())
        challengeContainer.addView(countdown, linearParams(top = 4))
        challengeContainer.addView(grid, linearParams(top = 8))
        challengeContainer.addView(confirm, linearParams(top = 16))

        if (memoryPhase == "selecting" && memoryTargets.size == targetCount) {
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
        shakeCountText = textView("$shakeCount / ${alarm.missionSettings.shakeCount}", 36f, colorText, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }
        challengeContainer.addView(shakeCountText, linearParams(top = 2))
        shakeProgress = ProgressBar(
            this,
            null,
            android.R.attr.progressBarStyleHorizontal,
        ).apply {
            max = alarm.missionSettings.shakeCount
            progress = shakeCount
            progressTintList = ColorStateList.valueOf(colorPrimary)
            progressBackgroundTintList = ColorStateList.valueOf(colorTrack)
        }
        challengeContainer.addView(shakeProgress, linearParams(height = dp(8), top = 14))
        shakeRemainingText = textView(
            "${alarm.missionSettings.shakeCount - shakeCount} remaining",
            15f,
            colorMuted,
            Typeface.NORMAL,
        ).apply { gravity = Gravity.CENTER }
        challengeContainer.addView(shakeRemainingText, linearParams(top = 10))
        shakeFeedback = icon
        challengeContainer.addView(textView(
            "Use deliberate shakes. Small movements are ignored.",
            13f, colorMuted, Typeface.NORMAL,
        ).apply { gravity = Gravity.CENTER }, linearParams(top = 10))
        challengeContainer.addView(secondaryButton().apply {
            text = "Use math instead"
            setOnClickListener { fallbackFromShake() }
        }, linearParams(top = 16))
        registerAccelerometer()
    }

    private fun registerAccelerometer() {
        if (currentChallenge != "shake") return
        sensorReceived = false
        val registered = accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        } ?: false
        if (!registered) {
            handler.post { if (currentChallenge == "shake") fallbackFromShake() }
            return
        }
        handler.postDelayed({
            if (currentChallenge == "shake" && !sensorReceived) fallbackFromShake()
        }, 3_000)
    }

    private fun fallbackFromShake() {
        sensorManager.unregisterListener(this)
        shakeFallback = true
        mathSolved = 0
        mathProblem = null
        mathInput = ""
        // Keep this mission's existing deadline; fallback cannot extend it indefinitely.
        showCurrentChallenge(resumeDeadline = true)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (currentChallenge != "shake") return
        sensorReceived = true
        val force = sqrt(
            event.values[0] * event.values[0] +
                event.values[1] * event.values[1] +
                event.values[2] * event.values[2],
        ) / SensorManager.GRAVITY_EARTH
        val now = System.currentTimeMillis()
        if (force >= alarm.missionSettings.shakeThreshold && now - lastShakeAt >= 500) {
            lastShakeAt = now
            shakeCount += 1
            shakeCountText?.text = "$shakeCount / ${alarm.missionSettings.shakeCount}"
            shakeRemainingText?.text = "${alarm.missionSettings.shakeCount - shakeCount} remaining"
            shakeProgress?.progress = shakeCount
            if (motionEnabled) shakeFeedback?.animate()?.scaleX(1.3f)?.scaleY(1.3f)?.setDuration(100)
                ?.withEndAction {
                    shakeFeedback?.animate()?.scaleX(1f)?.scaleY(1f)?.setDuration(140)?.start()
                }?.start()
            persistState()
            if (shakeCount >= alarm.missionSettings.shakeCount) nextChallenge()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun showTypingChallenge() {
        val phrase = alarm.missionSettings.typingPhrase
        challengeContainer.addView(textView("Type this phrase", 21f, colorText, Typeface.BOLD)
            .apply { gravity = Gravity.CENTER }, linearParams())
        challengeContainer.addView(textView(phrase, 23f, colorPrimary, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(16), dp(12), dp(16))
            background = roundedBackground(colorPrimaryDark, 18)
        }, linearParams(top = 18))
        val field = EditText(this).apply {
            setText(typingInput)
            textSize = 20f
            setTextColor(colorText)
            setHintTextColor(colorMuted)
            hint = "Type here"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or
                InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO
            }
            setPadding(dp(16), dp(14), dp(16), dp(14))
            background = roundedBackground(colorInput, 18)
            // No pasted/autofilled answer; the mission requires entering the phrase.
            isLongClickable = false
            setTextIsSelectable(false)
            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                    typingInput = s?.toString().orEmpty()
                    persistState()
                }
                override fun afterTextChanged(s: Editable?) = Unit
            })
        }
        challengeContainer.addView(field, linearParams(top = 14))
        val feedback = textView("", 14f, colorDanger, Typeface.NORMAL).apply { gravity = Gravity.CENTER }
        challengeContainer.addView(feedback, linearParams(top = 10))
        challengeContainer.addView(primaryButton().apply {
            text = "Confirm phrase"
            setOnClickListener {
                if (typingInput.trim() == phrase) {
                    (getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager)
                        .hideSoftInputFromWindow(field.windowToken, 0)
                    nextChallenge()
                } else feedback.text = "Match the phrase exactly, including capitals"
            }
        }, linearParams(top = 12))
    }

    private fun showOrderChallenge() {
        val count = alarm.missionSettings.numberCount
        if (orderNumbers.size != count) orderNumbers = (1..count).shuffled()
        val instruction = textView("Tap numbers in ascending order", 22f, colorText, Typeface.BOLD)
            .apply { gravity = Gravity.CENTER }
        challengeContainer.addView(instruction, linearParams())
        val progress = textView("$orderSelected / $count complete", 15f, colorMuted, Typeface.NORMAL)
            .apply { gravity = Gravity.CENTER }
        challengeContainer.addView(progress, linearParams(top = 10))
        val grid = GridLayout(this).apply { columnCount = 3 }
        orderNumbers.forEachIndexed { index, value ->
            val tile = keypadButton(value.toString(), false).apply {
                isEnabled = value > orderSelected
                alpha = if (isEnabled) 1f else .35f
                contentDescription = "Number $value"
                setOnClickListener {
                    if (value == orderSelected + 1) {
                        orderSelected += 1
                        isEnabled = false
                        alpha = .35f
                        progress.text = "$orderSelected / $count complete"
                        persistState()
                        if (orderSelected == count) nextChallenge()
                    } else {
                        progress.text = "Next number: ${orderSelected + 1}"
                    }
                }
            }
            grid.addView(tile, gridParams(index, 3, 68))
        }
        challengeContainer.addView(grid, linearParams(top = 20))
    }

    private fun snooze() {
        if (alarm.isNormal && !RingingService.isNormalSessionActive(alarm.id, sessionToken)) {
            endingAlarm = true
            finish()
            return
        }
        if (!AlarmScheduler.scheduleSnooze(this, alarm, snoozeCount + 1)) {
            Toast.makeText(this, "Exact alarm access is required for snooze.", Toast.LENGTH_LONG)
                .show()
            return
        }
        AlarmScheduler.cancelChallengeTimeout(this, alarm.id)
        RingStateStore.clear(this, alarm.id)
        WakeCheckScheduler.cancel(this, alarm.id)
        endingAlarm = true
        if (alarm.isNormal) RingingService.dismissNormal(alarm.id, sessionToken) else RingingService.stop(this)
        finish()
    }

    private fun dismissNormalAlarm() {
        if (!alarm.isNormal) return
        endingAlarm = true
        RingingService.dismissNormal(alarm.id, sessionToken)
        finish()
    }

    private fun completeAlarm() {
        if (alarm.isNormal) {
            dismissNormalAlarm()
            return
        }
        AlarmScheduler.cancelChallengeTimeout(this, alarm.id)
        RingStateStore.clear(this, alarm.id)
        if (WakeFailureStore.consume(this, alarm.id)) {
            WakeCheckScheduler.cancel(this, alarm.id)
        } else {
            WakeCheckScheduler.startCycle(this, alarm)
        }
        endingAlarm = true
        RingingService.stop(this)
        finish()
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
        mathSolved = state.optInt("mathSolved", 0).coerceIn(0, alarm.missionSettings.mathQuestions)
        mathInput = state.optString("mathInput", "")
        state.optJSONObject("mathProblem")?.let {
            mathProblem = MathProblem(
                left = it.getInt("left"),
                right = it.getInt("right"),
                addition = it.getBoolean("addition"),
                operation = it.optString("operation",
                    if (it.optBoolean("addition", true)) "add" else "subtract"),
            )
        }
        memoryPhase = state.optString("memoryPhase", "")
        restoreIntSet(state.optJSONArray("memoryTargets"), memoryTargets)
        restoreIntSet(state.optJSONArray("memorySelected"), memorySelected)
        shakeCount = state.optInt("shakeCount", 0).coerceIn(0, alarm.missionSettings.shakeCount)
        shakeFallback = state.optBoolean("shakeFallback", false)
        memoryRoundsSolved = state.optInt("memoryRoundsSolved", 0)
            .coerceIn(0, alarm.missionSettings.memoryRounds)
        typingInput = state.optString("typingInput", "")
        val numbers = state.optJSONArray("orderNumbers")
        val restored = if (numbers == null) emptyList() else (0 until numbers.length()).map { numbers.optInt(it) }
        orderNumbers = restored.takeIf { it.sorted() == (1..alarm.missionSettings.numberCount).toList() }
            ?: emptyList()
        orderSelected = state.optInt("orderSelected", 0).coerceIn(0, alarm.missionSettings.numberCount)
    }

    private fun persistState() {
        if (!::alarm.isInitialized || alarm.isNormal || isFinishing) return
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
                put("operation", problem.operation)
            })
        }
        put("memoryPhase", memoryPhase)
        put("memoryTargets", JSONArray(memoryTargets.toList()))
        put("memorySelected", JSONArray(memorySelected.toList()))
        put("shakeCount", shakeCount)
        put("shakeFallback", shakeFallback)
        put("memoryRoundsSolved", memoryRoundsSolved)
        put("typingInput", typingInput)
        put("orderNumbers", JSONArray(orderNumbers))
        put("orderSelected", orderSelected)
    }

    private fun restoreIntSet(array: JSONArray?, target: MutableSet<Int>) {
        target.clear()
        if (array == null) return
        for (index in 0 until array.length()) target.add(array.getInt(index))
    }

    private fun primaryButton(): Button = styledButton(colorPrimary, appearance.onAccent)

    private fun secondaryButton(): Button = styledButton(colorPrimaryDark, colorText)

    private fun keypadButton(label: String, primary: Boolean): Button =
        styledButton(if (primary) colorPrimary else colorInput,
            if (primary) appearance.onAccent else colorText).apply {
            text = label
            textSize = if (label == "✓") 22f else 20f
            setPadding(0, 0, 0, 0)
            minWidth = 0
            minHeight = 0
        }

    private fun styledButton(backgroundColor: Int, textColor: Int): Button = Button(this).apply {
        isAllCaps = false
        textSize = 16f
        setTextColor(textColor)
        background = appearance.ripple(this@AlarmRingActivity, backgroundColor, 20)
        appearance.elevate(this, 3f)
        stateListAnimator = null
        minHeight = dp(56)
        setPadding(dp(12), dp(12), dp(12), dp(12))
    }

    private fun textView(textValue: String, size: Float, color: Int, style: Int) =
        TextView(this).apply {
            text = textValue
            textSize = size
            setTextColor(color)
            setTypeface(typeface, style)
        }

    private fun roundedBackground(color: Int, radius: Int) = appearance.shape(this, color, radius)

    private fun linearParams(
        width: Int = LinearLayout.LayoutParams.MATCH_PARENT,
        height: Int = LinearLayout.LayoutParams.WRAP_CONTENT,
        top: Int = 0,
    ) = LinearLayout.LayoutParams(width, height).apply { topMargin = dp(top) }

    private fun gridParams(index: Int, columns: Int, size: Int) = GridLayout.LayoutParams().apply {
        val fitted = min(size, (resources.configuration.screenWidthDp - 108) / columns - 8)
            .coerceAtLeast(28)
        width = dp(fitted)
        height = dp(fitted)
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

        fun createIntent(context: Context, alarm: AlarmData, snoozeCount: Int, sessionToken: String = ""): Intent =
            Intent(context, AlarmRingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                data = Uri.Builder().scheme("alarmxv").authority("ring").appendPath(alarm.id).build()
                putExtra(extraAlarmJson, alarm.toJson().toString())
                putExtra(extraSnoozeCount, snoozeCount)
                putExtra(RingingService.extraSessionToken, sessionToken)
            }
    }
}
