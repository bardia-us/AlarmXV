package com.alarmxv.alarm_xv

import android.content.Context
import org.json.JSONObject

/** Presentation-only localization; stored alarm labels and mission answers stay untouched. */
object NativeStrings {
    private var cachedJson: String? = null
    private var cachedPreference = "system"

    @Synchronized
    fun language(context: Context): String {
        val encoded = AppSettingsStore.loadJson(context)
        if (cachedJson != encoded) {
            cachedPreference = runCatching { JSONObject(encoded).optString("language", "system") }
                .getOrDefault("system")
            cachedJson = encoded
        }
        val selected = if (cachedPreference in setOf("en", "fa")) cachedPreference
            else context.resources.configuration.locales[0].language
        return if (selected == "fa") "fa" else "en"
    }

    fun text(context: Context, message: String, vararg values: Any?): String =
        translate(language(context), message, *values)

    internal fun translate(language: String, message: String, vararg values: Any?): String {
        val template = if (language == "fa") persian[message] ?: message else message
        return Regex("\\{p(\\d+)\\}").replace(template) { match ->
            val index = match.groupValues[1].toIntOrNull()
            if (index != null && index in values.indices) values[index]?.toString() ?: "" else match.value
        }
    }

    private val persian = mapOf(
        "Snooze" to "چرت کوتاه",
        "Snooze for {p0} min" to "چرت {p0} دقیقه‌ای",
        "Normal alarm" to "آلارم معمولی",
        "You can lower the volume or leave this screen." to "می‌تونی صدا رو کم کنی یا از این صفحه بیرون بری.",
        "Dismiss alarm" to "قطع آلارم",
        "Start missions" to "شروع مأموریت",
        "Math" to "ریاضی",
        "Memory" to "حافظه",
        "Shake" to "تکان دادن",
        "Typing" to "تایپ عبارت",
        "Number order" to "ترتیب اعداد",
        "Could not arm the challenge timeout. Exact alarm access is required." to "زمان‌سنج مأموریت تنظیم نشد. دسترسی زنگ دقیق لازمه.",
        "Time is up — the alarm is ringing again." to "وقت تموم شد؛ آلارم دوباره زنگ می‌خوره.",
        "Motion sensor unavailable · solve math instead" to "حسگر حرکت در دسترس نیست؛ به‌جاش ریاضی حل کن",
        "Try again" to "دوباره تلاش کن",
        "Confirm pattern" to "تأیید الگو",
        "{p0} / {p1} selected" to "{p0} از {p1} انتخاب شده",
        "Select the {p0} highlighted tiles\nRound {p1} / {p2}" to "{p0} خانهٔ روشن‌شده رو انتخاب کن\nدور {p1} از {p2}",
        "Remember this pattern" to "این الگو رو به خاطر بسپار",
        "Get ready" to "آماده باش",
        "Correct · next round" to "درسته؛ دور بعد",
        "New pattern — try again" to "الگوی تازه؛ دوباره تلاش کن",
        "Shake the phone" to "گوشی رو تکان بده",
        "{p0} remaining" to "{p0} باقی مونده",
        "Use deliberate shakes. Small movements are ignored." to "گوشی رو مشخص و کوتاه تکان بده؛ حرکت‌های کوچک حساب نمی‌شن.",
        "Use math instead" to "به‌جاش ریاضی حل کن",
        "Type this phrase" to "این عبارت رو تایپ کن",
        "Type here" to "اینجا بنویس",
        "Confirm phrase" to "تأیید عبارت",
        "Match the phrase exactly, including capitals" to "عبارت رو دقیقاً مطابق نمونه بنویس؛ حروف بزرگ و کوچک هم مهمه",
        "Tap numbers in ascending order" to "اعداد رو از کوچک به بزرگ انتخاب کن",
        "{p0} / {p1} complete" to "{p0} از {p1} انجام شده",
        "Number {p0}" to "عدد {p0}",
        "Next number: {p0}" to "عدد بعدی: {p0}",
        "Exact alarm access is required for snooze." to "برای تعویق زنگ، دسترسی زنگ دقیق لازمه.",
        "System alarm sound" to "صدای آلارم گوشی",
        "Choose alarm sound" to "انتخاب صدای زنگ",
        "Normal alarm · dismiss directly from the notification" to "آلارم معمولی · امکان قطع مستقیم از اعلان",
        "Challenge timer is running" to "زمان‌سنج مأموریت فعاله",
        "Alarm ringing - tap to wake up" to "آلارم زنگ می‌خوره؛ برای بیدارشدن بزن",
        "Challenge in progress — return before time runs out" to "مأموریت در حال اجراست؛ قبل از پایان وقت برگرد",
        "Alarm is ringing" to "آلارم زنگ می‌خوره",
        "Return to alarm" to "بازگشت به آلارم",
        "Ringing alarms" to "آلارم‌های در حال زنگ",
        "Full-screen notifications for active AlarmXV alarms" to "اعلان تمام‌صفحه برای آلارم‌های فعال AlarmXV",
        "Still awake?" to "هنوز بیداری؟",
        "Confirm you are awake to prevent the alarm from ringing again." to "برای جلوگیری از زنگ دوباره، بیدار بودنت را تأیید کن.",
        "I’m awake" to "بیدارم",
        "Close for now" to "فعلاً ببند",
        "Silent wake-up checks" to "بررسی بی‌صدای بیداری",
        "Silent confirmations; missed checks restart the real alarm" to "تأیید بی‌صدا؛ بررسی ازدست‌رفته آلارم رو دوباره فعال می‌کنه",
        "Confirm you are awake before the countdown ends" to "تا پایان شمارش، بیدار بودنت را تأیید کن",
        "Correct" to "درسته",
        "Answers remaining: {p0}" to "پاسخ‌های باقی‌مونده: {p0}",
    )
}
