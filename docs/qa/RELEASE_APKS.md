# Private preview APK evidence

Version2.0.0-preview.2+5005, compiled with Flutter3.47.8 stable/Dart3.13.7. Not publicly released or installed on the phone.

| APK | Bytes | SHA256 |
|---|---:|---|
| arm64-v8a |18,524,225|30517be586576c3459bd40f7db49e9c952cd64745deca5161cab3316df9cca03|
| armeabi-v7a |15,943,577|67a78b95136936d07f1be9ffa27b1961cd6fb2b03b1131696784739192a9a584|
| universal |53,406,571|a6caba8962094a63774dda401ee912c7565d493b1ac76b35033d9fbd5605a540|

Application ID com.alarmxv.alarm_xv; all three versionCode5005 and exactly one MainActivity launcher; same release certificate as1.2.0. Universal includes ARMv7/ARM64/x86_64. No profile/debug ID suffix, new signing key or second application was generated.

Earlier preview1 testing:27Flutter tests,11JVM tests and one opt-in render capture passed. Preview2 changes were source-reviewed and compiled only, at the owner's request. The performance sample belongs to preview1's editor and is not proof of sustained120FPS or native ringing performance.

Two launcher icons reported by owner remain unverified on the now-disconnected phone. Android tasks were unified, but this is not claimed as a verified fix for separate installed packages or launcher shortcuts. No user data, app or shortcut was deleted.
