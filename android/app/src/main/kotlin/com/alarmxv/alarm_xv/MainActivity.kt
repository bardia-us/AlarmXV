package com.alarmxv.alarm_xv

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.media.RingtoneManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "alarm_xv/alarm_manager"
    private val notificationRequestCode = 1702
    private val ringtonePickerRequestCode = 1703
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var ringtonePickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        RingingService.ensureNotificationChannel(this)
        WakeCheckScheduler.ensureNotificationChannel(this)
        RingingService.restoreOrphanedVolume(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadAlarms" -> result.success(AlarmStore.loadJson(this))
                    "getAppInfo" -> {
                        @Suppress("DEPRECATION")
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val preferences = getSharedPreferences("alarm_xv_preferences", MODE_PRIVATE)
                        result.success(mapOf(
                            "versionName" to info.versionName.orEmpty(),
                            "versionCode" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                                info.longVersionCode else @Suppress("DEPRECATION") info.versionCode.toLong(),
                            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
                            "lastSeenVersion" to preferences.getString("whats_new_seen_version", ""),
                        ))
                    }
                    "markWhatsNewSeen" -> {
                        val version = call.arguments as? String
                        if (version.isNullOrBlank() || version.length > 100) {
                            result.error("INVALID_VERSION", "Expected app version.", null)
                        } else {
                            val saved = getSharedPreferences("alarm_xv_preferences", MODE_PRIVATE)
                                .edit().putString("whats_new_seen_version", version).commit()
                            if (saved) result.success(null)
                            else result.error("SAVE_FAILED", "Could not save version state.", null)
                        }
                    }
                    "openExternalUrl" -> {
                        val uri = (call.arguments as? String)?.let(Uri::parse)
                        val path = uri?.path.orEmpty()
                        if (uri == null || uri.scheme != "https" || uri.host != "github.com" ||
                            uri.userInfo != null || uri.port != -1 ||
                            uri.pathSegments.any { it == "." || it == ".." ||
                                it.contains('/') || it.contains('\\') } ||
                            (path != "/bardia-us/AlarmXV" && !path.startsWith("/bardia-us/AlarmXV/"))
                        ) {
                            result.error("INVALID_URL", "Expected the AlarmXV GitHub page.", null)
                        } else {
                            try {
                                val external = Intent(Intent.ACTION_VIEW, uri)
                                    .addCategory(Intent.CATEGORY_BROWSABLE)
                                startActivity(external)
                                result.success(null)
                            } catch (_: android.content.ActivityNotFoundException) {
                                result.error("NO_BROWSER", "No browser can open this link.", null)
                            } catch (error: Exception) {
                                result.error("OPEN_FAILED", error.message, null)
                            }
                        }
                    }
                    "loadAppSettings" -> result.success(AppSettingsStore.loadJson(this))
                    "saveAppSettings" -> {
                        try {
                            AppSettingsStore.save(this, call.arguments as? String
                                ?: error("Expected settings as JSON."))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("SETTINGS_SAVE_FAILED", error.message, null)
                        }
                    }
                    "saveAndSync" -> {
                        val encoded = call.arguments as? String
                        if (encoded == null) {
                            result.error("INVALID_DATA", "Expected alarms as JSON.", null)
                        } else {
                            try {
                                result.success(AlarmScheduler.saveAndSync(this, encoded))
                            } catch (error: Exception) {
                                result.error("SCHEDULE_FAILED", error.message, null)
                            }
                        }
                    }
                    "permissionStatus" -> result.success(AlarmScheduler.permissionStatus(this))
                    "reschedule" -> result.success(AlarmScheduler.reschedule(this))
                    "requestNotificationPermission" -> requestNotificationPermission(result)
                    "openExactAlarmSettings" -> {
                        openExactAlarmSettings()
                        result.success(null)
                    }
                    "openFullScreenSettings" -> {
                        openFullScreenSettings()
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    "openOverlaySettings" -> {
                        openOverlaySettings()
                        result.success(null)
                    }
                    "pickAlarmSound" -> openAlarmSoundPicker(
                        call.argument<String>("currentUri"),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(null)
            return
        }
        notificationPermissionResult?.success(null)
        notificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationRequestCode) {
            notificationPermissionResult?.success(null)
            notificationPermissionResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != ringtonePickerRequestCode) return
        val result = ringtonePickerResult ?: return
        ringtonePickerResult = null
        if (resultCode != RESULT_OK) {
            result.success(null)
            return
        }
        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
        if (uri == null) {
            result.success(null)
            return
        }
        val title = runCatching {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        }.getOrNull().orEmpty().ifBlank { "System alarm sound" }
        result.success(mapOf("uri" to uri.toString(), "name" to title))
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    Uri.parse("package:$packageName"),
                ),
            )
        }
    }

    private fun openFullScreenSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                    Uri.parse("package:$packageName"),
                ),
            )
        }
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            )
        }
        startActivity(intent)
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName"),
                ),
            )
        }
    }

    private fun openAlarmSoundPicker(
        currentUri: String?,
        result: MethodChannel.Result,
    ) {
        ringtonePickerResult?.success(null)
        ringtonePickerResult = result
        val selectedUri = currentUri?.takeIf { it.isNotBlank() }?.let(Uri::parse)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        startActivityForResult(
            Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_TYPE,
                    RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_RINGTONE,
                )
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, selectedUri)
                putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Choose alarm sound")
            },
            ringtonePickerRequestCode,
        )
    }
}
