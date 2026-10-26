package com.alarmxv.alarm_xv

import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.Assert.assertEquals
import org.junit.Test
import org.w3c.dom.Element

/** Configuration regression guards, not a substitute for a device task-stack test. */
class ActivityManifestTest {
    private val androidNamespace = "http://schemas.android.com/apk/res/android"
    private fun manifest() = DocumentBuilderFactory.newInstance().apply {
        isNamespaceAware = true
    }.newDocumentBuilder().parse(File("src/main/AndroidManifest.xml"))

    @Test fun launcherMustNotClearTheAlarmActivityAboveIt() {
        val activities = manifest().getElementsByTagName("activity")
        val main = (0 until activities.length).map { activities.item(it) as Element }
            .single { it.getAttributeNS(androidNamespace, "name") == ".MainActivity" }
        assertEquals("singleTop", main.getAttributeNS(androidNamespace, "launchMode"))
        assertEquals("never", main.getAttributeNS(androidNamespace, "documentLaunchMode"))
    }

    @Test fun nativePersianLayoutsHaveAndroidRtlSupport() {
        val application = manifest().getElementsByTagName("application").item(0) as Element
        assertEquals("true", application.getAttributeNS(androidNamespace, "supportsRtl"))
    }
}
