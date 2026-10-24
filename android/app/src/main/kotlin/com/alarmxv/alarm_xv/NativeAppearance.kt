package com.alarmxv.alarm_xv

import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.view.View
import org.json.JSONObject

object AppSettingsStore {
    private const val preferencesName = "alarm_xv_preferences"
    private const val settingsKey = "app_settings_json"

    fun loadJson(context: Context): String = context
        .getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        .getString(settingsKey, "{}") ?: "{}"

    fun save(context: Context, encoded: String) {
        val json = JSONObject(encoded)
        require(json.optString("themeMode", "system") in setOf("system", "light", "dark"))
        check(context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
            .putString(settingsKey, json.toString()).commit()) { "Could not save appearance settings" }
    }
}

/** Shared semantic clay surfaces for the native lock-screen and service overlay. */
class NativeAppearance(context: Context) {
    private val settings = runCatching { JSONObject(AppSettingsStore.loadJson(context)) }
        .getOrDefault(JSONObject())
    val dark = when (settings.optString("themeMode", "system")) {
        "light" -> false
        "dark" -> true
        else -> context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES
    }
    private fun color(value: String) = Color.parseColor(value)
    val background = color(if (dark) "#1B1F29" else "#ECEDF5")
    val surface = color(if (dark) "#272C39" else "#F5F6FC")
    val raised = color(if (dark) "#1F2430" else "#E6E9F3")
    val tile = color(if (dark) "#3C4659" else "#DCE3EF")
    val text = color(if (dark) "#F2F5FC" else "#222C40")
    val muted = color(if (dark) "#B8C3D5" else "#5A6881")
    val accent = color(when (settings.optString("accent", "ocean")) {
        "emerald" -> if (dark) "#75DAB0" else "#247C61"
        "sunset" -> if (dark) "#F1B56F" else "#B85D2C"
        "coral" -> if (dark) "#F5A79B" else "#BC5157"
        "lavender" -> if (dark) "#C5B2F6" else "#8063BC"
        "rose" -> if (dark) "#F0ABCD" else "#AB5181"
        "teal" -> if (dark) "#81D3D1" else "#257B86"
        "amber" -> if (dark) "#EBC774" else "#9F731D"
        else -> if (dark) "#AAC4FA" else "#4C70DA"
    })
    val onAccent = color(if (dark) "#172239" else "#FFFFFF")
    val danger = color(if (dark) "#FFB4AB" else "#AD3934")
    val success = color(if (dark) "#8DDAB5" else "#236E52")
    val accentSurface = blend(surface, accent, if (dark) .20f else .13f)
    private val edge = color(if (dark) "#3B4151" else "#FEFEFF")

    fun shape(context: Context, color: Int, radius: Int = 24, outlined: Boolean = true) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius * context.resources.displayMetrics.density
            if (outlined) setStroke((context.resources.displayMetrics.density).toInt().coerceAtLeast(1), edge)
        }

    fun ripple(context: Context, color: Int, radius: Int = 20) = RippleDrawable(
        ColorStateList.valueOf(blend(color, text, .18f)),
        shape(context, color, radius),
        shape(context, Color.WHITE, radius, false),
    )

    fun elevate(view: View, depth: Float = 4f) {
        view.elevation = depth * view.resources.displayMetrics.density
        view.clipToOutline = true
    }

    private fun blend(a: Int, b: Int, ratio: Float) = Color.rgb(
        (Color.red(a) * (1 - ratio) + Color.red(b) * ratio).toInt(),
        (Color.green(a) * (1 - ratio) + Color.green(b) * ratio).toInt(),
        (Color.blue(a) * (1 - ratio) + Color.blue(b) * ratio).toInt(),
    )
}
