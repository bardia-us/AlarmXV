package com.alarmxv.alarm_xv

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Typeface
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
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextClock
import android.widget.TextView
import android.widget.ScrollView

class WakeCheckActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var alarmId: String
    private var checkNumber = 1
    private var deadline = 0L
    private lateinit var countdown: TextView
    private lateinit var appearance: NativeAppearance

    private val ticker = object : Runnable {
        override fun run() {
            val state = WakeCheckStore.get(this@WakeCheckActivity, alarmId)
            if (state == null || state.checkNumber != checkNumber) {
                finish()
                return
            }
            val remaining = deadline - System.currentTimeMillis()
            if (remaining <= 0L) {
                finish()
                return
            }
            val seconds = ((remaining + 999L) / 1_000L).toInt()
            countdown.text = "%02d:%02d".format(seconds / 60, seconds % 60)
            handler.postDelayed(this, 250L)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appearance = NativeAppearance(this)
        configureWindow()
        showCheckIntent(intent)
    }

    private fun showCheckIntent(intent: Intent) {
        handler.removeCallbacks(ticker)
        alarmId = intent.getStringExtra(extraAlarmId) ?: run {
            finish()
            return
        }
        if (AlarmStore.find(this, alarmId)?.isNormal == true) {
            finish()
            return
        }
        checkNumber = intent.getIntExtra(extraCheckNumber, 1)
        deadline = intent.getLongExtra(extraDeadline, 0L)
        setContentView(buildScreen(intent.getStringExtra(extraAlarmLabel).orEmpty()))
        handler.post(ticker)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showCheckIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        applySystemBars()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) applySystemBars()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun confirmAwake() {
        WakeCheckScheduler.confirm(this, alarmId, checkNumber)
        finish()
    }

    private fun configureWindow() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
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

    private fun applySystemBars() = appearance.applySystemBars(this)

    private fun buildScreen(label: String): View {
        val content = LinearLayout(this).apply {
            layoutDirection = if (NativeStrings.language(this@WakeCheckActivity) == "fa") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(28), dp(24), dp(28))
            background = appearance.shape(this@WakeCheckActivity, appearance.surface, 30)
            appearance.elevate(this, 6f)
        }
        content.addView(TextClock(this).apply {
            format12Hour = "h:mm"
            format24Hour = "HH:mm"
            textSize = 72f
            gravity = Gravity.CENTER
            setTextColor(appearance.text)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                setAutoSizeTextTypeUniformWithConfiguration(40, 72, 2,
                    android.util.TypedValue.COMPLEX_UNIT_SP)
            }
        }, linearParams())
        content.addView(TextView(this).apply {
            text = NativeStrings.text(this@WakeCheckActivity, "Still awake?")
            textSize = 28f
            gravity = Gravity.CENTER
            setTextColor(appearance.text)
            setTypeface(typeface, Typeface.BOLD)
        }, linearParams(top = 14))
        if (label.isNotBlank()) {
            content.addView(TextView(this).apply {
                text = label
                textSize = 15f
                gravity = Gravity.CENTER
                setTextColor(appearance.muted)
            }, linearParams(top = 8))
        }
        content.addView(TextView(this).apply {
            text = NativeStrings.text(this@WakeCheckActivity, "Confirm you are awake to prevent the alarm from ringing again.")
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(appearance.accent)
        }, linearParams(top = 18))
        countdown = TextView(this).apply {
            text = "01:00"
            textSize = 38f
            gravity = Gravity.CENTER
            setTextColor(appearance.text)
            setTypeface(typeface, Typeface.BOLD)
        }
        content.addView(countdown, linearParams(top = 18))
        content.addView(Button(this).apply {
            text = NativeStrings.text(this@WakeCheckActivity, "I’m awake")
            isAllCaps = false
            textSize = 18f
            setTextColor(appearance.onAccent)
            background = appearance.ripple(this@WakeCheckActivity, appearance.accent, 20)
            appearance.elevate(this, 3f)
            minHeight = dp(60)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            setOnClickListener { confirmAwake() }
        }, linearParams(top = 22))
        content.addView(Button(this).apply {
            text = NativeStrings.text(this@WakeCheckActivity, "Close for now")
            isAllCaps = false
            textSize = 14f
            setTextColor(appearance.accent)
            background = appearance.ripple(this@WakeCheckActivity, appearance.accentSurface, 20)
            minHeight = dp(48)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            setOnClickListener { finish() }
        }, linearParams(top = 8))

        val frame = FrameLayout(this).apply {
            setBackgroundColor(appearance.background)
            addView(
                content,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER,
                ).apply {
                    marginStart = dp(20)
                    marginEnd = dp(20)
                },
            )
        }
        return ScrollView(this).apply {
            isFillViewport = true
            setBackgroundColor(appearance.background)
            setPadding(0, dp(28), 0, dp(28))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setOnApplyWindowInsetsListener { view, insets ->
                    val safe = insets.getInsetsIgnoringVisibility(
                        WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                    view.setPadding(safe.left, safe.top + dp(20), safe.right, safe.bottom + dp(20))
                    insets
                }
            }
            addView(frame, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT))
        }
    }

    private fun linearParams(
        width: Int = LinearLayout.LayoutParams.MATCH_PARENT,
        height: Int = LinearLayout.LayoutParams.WRAP_CONTENT,
        top: Int = 0,
    ) = LinearLayout.LayoutParams(width, height).apply { topMargin = dp(top) }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val extraAlarmId = "alarm_id"
        private const val extraCheckNumber = "check_number"
        private const val extraDeadline = "deadline"
        private const val extraAlarmLabel = "alarm_label"

        fun createIntent(
            context: Context,
            alarm: AlarmData,
            checkNumber: Int,
            deadline: Long,
        ) = Intent(context, WakeCheckActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            data = Uri.Builder()
                .scheme("alarmxv")
                .authority("wake-screen")
                .appendPath(alarm.id)
                .appendPath(checkNumber.toString())
                .build()
            putExtra(extraAlarmId, alarm.id)
            putExtra(extraCheckNumber, checkNumber)
            putExtra(extraDeadline, deadline)
            putExtra(extraAlarmLabel, alarm.label)
        }
    }
}
