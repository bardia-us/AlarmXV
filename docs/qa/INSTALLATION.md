# Stable2.0.0 installation diagnosis

Device: Galaxy A34/Android16. APK: arm64-v8a, versionName2.0.0/code5007.

The owner reported that both updating and installing after their own uninstall failed. They explicitly authorized device installation testing. No app uninstall, data clear, alarm trigger or UI test was performed by the agent.

## Observed evidence

- No installed AlarmXV package was found before the test (primary or Dual App profile), consistent with the owner's uninstall.
- Fresh installation of the original signed stable APK using adb install --user0 -r (actual syntax --user 0) returned Success.
- The APK already in the phone's Downloads had the correct name, architecture and full18,983,469-byte length, but SHA256302e5e3302678d74aa565e00b89d4cb35481f97e2bafa02c70e3cadd3e5f0b70 instead of the published cbb13f1259edb29dab49ba10a38b5d0007aa933c48154b8d83ca94895a4bfd3d.
- apksigner rejected that phone download: APK Signature Scheme v2 integrity failure / CHUNKED_SHA256 digest mismatch. ZIP CRC also failed for lib/arm64-v8a/libapp.so. About1,888,313bytes differed. File size alone did not establish download integrity.
- A fresh independent download from the public GitHub v2.0.0 Release matched the published SHA256 and passed apksigner. Installing this freshly downloaded file over the preceding fresh install also returned Success.
- Post-install package metadata confirms2.0.0/code5007 on user0; no AlarmXV package listed for Dual App user95. The installation tests did not measure runtime alarm behavior.
- A verified copy was added to /sdcard/Download/AlarmXV-2.0.0-arm64-v8a-verified.apk and its on-device SHA256 matched the published value. The original damaged download was left untouched.

## Conclusion and limits

The reported phone download was corrupt; the fresh public GitHub APK installs on the same device. The exact point at which the phone file changed (transfer, resume/cache or later storage) was not identified. No specific browser/VPN/download manager is blamed without evidence. No app-code change or replacement Release asset was needed.

This verifies fresh install and same-version replacement through Android's ADB package installation path. It does not claim a browser/package-installer UI flow, old-data migration after the owner's uninstall, a full alarm cycle, or FPS results.
