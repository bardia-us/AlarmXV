package com.alarmxv.alarm_xv

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
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
import android.widget.LinearLayout
import android.widget.TextClock
import android.widget.TextView

class WakeCheckActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var alarmId: String
    private var checkNumber = 1
    private var deadline = 0L
    private lateinit var countdown: TextView

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
        alarmId = intent.getStringExtra(extraAlarmId) ?: run {
            finish()
            return
        }
        checkNumber = intent.getIntExtra(extraCheckNumber, 1)
        deadline = intent.getLongExtra(extraDeadline, 0L)
        configureWindow()
        setContentView(buildScreen(intent.getStringExtra(extraAlarmLabel).orEmpty()))
        handler.post(ticker)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        recreate()
    }

    override fun onResume() {
        super.onResume()
        hideSystemBars()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun confirmAwake() {
        WakeCheckScheduler.confirm(this, alarmId, checkNumber)
        finishAndRemoveTask()
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
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        }
    }

    private fun buildScreen(label: String): View {
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(28), dp(24), dp(28))
            background = rounded(Color.rgb(26, 29, 37), 28)
        }
        content.addView(TextClock(this).apply {
            format12Hour = "h:mm"
            format24Hour = "HH:mm"
            textSize = 62f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(246, 243, 252))
            typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
        }, linearParams())
        content.addView(TextView(this).apply {
            text = "هنوز بیداری؟"
            textSize = 28f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setTypeface(typeface, Typeface.BOLD)
        }, linearParams(top = 14))
        if (label.isNotBlank()) {
            content.addView(TextView(this).apply {
                text = label
                textSize = 15f
                gravity = Gravity.CENTER
                setTextColor(Color.rgb(179, 178, 190))
            }, linearParams(top = 8))
        }
        content.addView(TextView(this).apply {
            text = "برای جلوگیری از زنگ دوباره، بیدار بودنت را تأیید کن."
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(196, 188, 255))
        }, linearParams(top = 18))
        countdown = TextView(this).apply {
            text = "01:00"
            textSize = 38f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setTypeface(typeface, Typeface.BOLD)
        }
        content.addView(countdown, linearParams(top = 18))
        content.addView(Button(this).apply {
            text = "بیدارم"
            isAllCaps = false
            textSize = 18f
            setTextColor(Color.WHITE)
            background = rounded(Color.rgb(139, 128, 249), 18)
            setOnClickListener { confirmAwake() }
        }, linearParams(height = dp(60), top = 22))
        content.addView(Button(this).apply {
            text = "فعلاً ببند"
            isAllCaps = false
            textSize = 14f
            setTextColor(Color.rgb(196, 188, 255))
            background = rounded(Color.TRANSPARENT, 18)
            setOnClickListener { finishAndRemoveTask() }
        }, linearParams(height = dp(48), top = 8))

        return FrameLayout(this).apply {
            setBackgroundColor(Color.rgb(10, 12, 17))
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
    }

    private fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radius).toFloat()
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
