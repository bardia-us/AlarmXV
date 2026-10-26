# Preview APK evidence

## Stable2.0.0+5007

Fresh Release rebuild, not renamed preview binaries. All three APK manifests embed versionName2.0.0/versionCode5007; applicationId com.alarmxv.alarm_xv and the prior release signing certificate are unchanged. Local output dist/2.0.0 with SHA256SUMS.txt. No new stable APK installation or phone test was requested/performed.

| APK | Bytes | SHA256 |
|---|---:|---|
| arm64-v8a |18,983,469|cbb13f1259edb29dab49ba10a38b5d0007aa933c48154b8d83ca94895a4bfd3d|
| armeabi-v7a |16,501,125|6db7069bd7096ae274816cd83dbe14dc25a00f0b80afaf880f4839eb10b0d941|
| universal |54,881,623|2368c29c18d081b279c16a9959e6344cbf9ccd3e19809fe3b9d097f7c4965e52|

Publication target: [stable v2.0.0](https://github.com/bardia-us/AlarmXV/releases/tag/v2.0.0), to replace1.2.0 as Latest while retaining preview releases as history.

## Preview3 — final source checkpoint bca8b4f

Version2.0.0-preview.3+5006, Flutter3.47.8/Dart3.13.7. Final rebuild includes reviewed launcher/RTL/locale fixes. All three are Release APKs, com.alarmxv.alarm_xv, code5006, one Main launcher and the unchanged v1.2 signing certificate. Manifest inspection confirms Main singleTop, documentLaunchMode never and supportsRtl true.

| APK | Bytes | SHA256 |
|---|---:|---|
| arm64-v8a |18,983,481|4816762e687cfb39f507eb8fdaabd8da00b68377c7f594933c35cbc79f4ebd8e|
| armeabi-v7a |16,501,137|d517e14097656ee23b30cd81ebe6b1b3dc4bb3b2110797289d75fd9185615150|
| universal |54,881,635|755e0dd94ba0254b3d8b8bb8cf979c178c56a8e5f0f8263d68ee61b76e839214|

Location: local dist/2.0.0-preview.3, with SHA256SUMS.txt; public pre-release publication later authorized for [v2.0.0-preview.3](https://github.com/bardia-us/AlarmXV/releases/tag/v2.0.0-preview.3). On2026-10-26 the owner explicitly requested installation only and reserved phone testing for themselves. ARM64 installed successfully with adb install --user 0 -r; read-only package metadata confirms preview3/code5006 and the same CE/DE data inode values. No Dual App installation, uninstall or data clearing. No post-install UI/alarm/FPS test.

## Historical preview2

Version2.0.0-preview.2+5005, compiled with Flutter3.47.8 stable/Dart3.13.7. Not publicly released or installed on the phone.

| APK | Bytes | SHA256 |
|---|---:|---|
| arm64-v8a |18,524,225|30517be586576c3459bd40f7db49e9c952cd64745deca5161cab3316df9cca03|
| armeabi-v7a |15,943,577|67a78b95136936d07f1be9ffa27b1961cd6fb2b03b1131696784739192a9a584|
| universal |53,406,571|a6caba8962094a63774dda401ee912c7565d493b1ac76b35033d9fbd5605a540|

Application ID com.alarmxv.alarm_xv; all three versionCode5005 and exactly one MainActivity launcher; same release certificate as1.2.0. Universal includes ARMv7/ARM64/x86_64. No profile/debug ID suffix, new signing key or second application was generated.

Earlier preview1 testing:27Flutter tests,11JVM tests and one opt-in render capture passed. Preview2 changes were source-reviewed and compiled only, at the owner's request. The performance sample belongs to preview1's editor and is not proof of sustained120FPS or native ringing performance.

Two launcher icons reported by owner remain unverified on the now-disconnected phone. Android tasks were unified, but this is not claimed as a verified fix for separate installed packages or launcher shortcuts. No user data, app or shortcut was deleted.
