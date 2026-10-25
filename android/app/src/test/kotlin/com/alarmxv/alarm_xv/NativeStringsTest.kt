package com.alarmxv.alarm_xv

import org.junit.Assert.assertEquals
import org.junit.Test

class NativeStringsTest {
    @Test fun bothLanguagesKeepMissionParametersAndUserValues() {
        assertEquals("پاسخ‌های باقی‌مونده: 3", NativeStrings.translate("fa", "Answers remaining: {p0}", 3))
        assertEquals("Answers remaining: 3", NativeStrings.translate("en", "Answers remaining: {p0}", 3))
        assertEquals("ساعت من", NativeStrings.translate("en", "{p0}", "ساعت من"))
        assertEquals("Still awake?", NativeStrings.translate("en", "Still awake?"))
        assertEquals("هنوز بیداری؟", NativeStrings.translate("fa", "Still awake?"))
    }
}
