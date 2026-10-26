# AlarmXV checkpoints

## 2026-10-24 — redesign in progress

- Base: v1.2.0+3, commit c74bcd3. Existing project relocated to Desktop/ph/AlarmXV.
- Work branch: redesign/clay-v2. Never publicly release preview without owner's approval.
- User approved autonomous full redesign: Clay/soft depth, no Liquid Glass/blur; native alarm reliability remains first.
- Plan: docs/superpowers/plans/2026-10-24-clay-redesign.md.
- Data checkpoint: additive groups/mission settings/appearance; five migration/round-trip/next-occurrence tests passed.
- New request: version-specific What's New, user-initiated GitHub update checker + ABI matching, bilingual README/changelog, final ARM64/ARMv7/universal APKs only.
- Update/profile checkpoint: version parsing, trusted URL/ABI fallback and bounded frame statistics tests passed (5 tests); no new Flutter package.
- Flutter: shared with niraNG at D:/dev/flutter, currently 3.47.6 stable / Dart3.13.5; niraNG local.properties uses same path. Official release manifest check returned404; do not claim latest SDK or mutate shared SDK until verified.
- Environment: Flutter doctor Android/JDK21 ready; no physical ADB device attached; emulator inventory empty. Gradle daemon loopback issue under investigation. Offline pub get succeeds; pub.dev online returned authorization error.
- Security: active scan5db2d728-82a7-4bd2-b12c-a999b8b035f6; partial current source audit, mutation limits declared. No final clean bill claim until completed.
- SDK checkpoint: `flutter upgrade --verify-only` confirmed stable3.47.8 revision737ba8f885, versus installed3.47.6. User requested upgrade; command-scoped upgrade underway, both projects keep same SDK path.
- Gradle checkpoint: Windows Java Unix domain socket path too long; command-scoped JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Windows\Temp fixes daemon startup. Do not change user global Java settings.
- Next: finish Flutter+native UI, integrate What'sNew startup, run all analyzer/tests, native regression/build, private preview QA report and APK checksum/signature evidence.

## Checkpoint 2 — integration and regression

- Git checkpoint7283ef3 preserves additive migration, app settings and mission/update contracts (10 focused Dart tests green).
- Native final Kotlin/resources compilation and7 JUnit tests green; cache XML confirms zero failures/errors.
- Native fix preserves snooze/challenge PendingIntents on app resume. AlarmStore persists with checked commit before cancellations; disabled/deleted members cancel their sessions.
- New UI initially exposed two real mismatches: unsupported wake-check timeout choices and volume-protection switch; removed unsupported controls, preserved stored fields. Checker remains60seconds.
- Integrated UI test caught keyboard+2xtext overflow; editor title moved into scroll content, no font-size clamp.8 UI tests then passed (fresh complete suite still pending).
- App WhatsNew once-per-installed-version test passed. GitHub updater tests reject wrong repo/encoded path escapes, compare prerelease correctly and match ABI with universal fallback.
- Flutter3.47.8 upgrade could not finish: Google connection reset; official mirror transferred57MB then stalled on resumed chunks. Original working3.47.6 SDK restored from existing backup, stable branch restored, incomplete download and backups preserved. No claim upgrade succeeded.
- Source review (Codex Security) completed with partial coverage, zero validated findings in reviewed controls; original snapshot unavailable warning makes it unsuitable as final-release certification.

## Checkpoint3 — real device available

- User selected GPL-3.0. Canonical license added and bundled; app license viewer registered.
- User connected Galaxy A34 SM-A346E, Android16, display120Hz; serial used for targeted ADB only. Existing installed v1.2.0 has versionCode2003.
- New preview versionCode5004 (above all1.2 split codes); Flutter's supported force-version-code-ignoring-abi property keeps ARMv7/ARM64/universal mutually upgradeable. Profile signed with existing release key to preserve installed app data.
- Commit05b103e records integrated redesign checkpoint.
- Whole Flutter suite27passed+1opt-in visual skipped; separate visual capture passed; native11passed. Fresh reviewer Important1 postpersist sync errors and Important2 legacy memory/shake defaults fixed with RED/GREEN tests.
- Current native/UI widgets ready; Profile build network artifact403 on Google, retry via official mirror ongoing. No physical test result yet.
- Pending: Profile install, capture baseline alarms before/after, device alarm/mission/checker+FPS evidence, final Release outputs, public docs update (not GitHub Release).

## Checkpoint4 — owner ended testing

- ProfileAPK built and installed as update successfully; old/new signerSHA256 both4f15672645bdf1ca9a382ee715ff3fd4ae124ea9cd56c744a1178253c45c5cd6, IDunchanged, code5004. No uninstall/data clearing.
- Device screenshot before upgrade: one active08:50 alarm; actual pending AlarmManager record present. New What'sNew screen rendered. Full post-upgrade alarm inventory not independently checked before owner ended tests.
- One measured Profile6 scrolling window977frames UI P95/P99 3.595/4.452ms, raster6.003/7.471ms,6framesover8.33ms. Original label home-scroll-warm was wrong: screenshot shows new-alarm editor; report attribution corrected. No120FPS constant claim.
- User explicitly: 'بقیه چیزاش با من. دیگه تستی نمیخواد'. STOP all further automated/device tests and interaction; finish pending SDK/build/docs only. Removed own adb8181forward. Do not install final APK unless user later requests.
- Owner-provided local VPN supports SOCKS5 and HTTP proxy. Command scoped only; no proxy configuration committed. Google403 persists but mirror downloads now work. CanonicalSDK8 Dart3.13.7 archive and nextengine profile artifact verified.
- SDK8 sourceHEAD737ba8f885dc774b53b442759999a312c9461e4e; DartSDK3.13.7 installed. Old Flutter tool metadata still6; rebuilding tool stalled pub.dev403, use cached offline Flutter-tools pub resolution or official pub mirror. Preserve backupD:/dev/flutter/bin/cache/dart-sdk.backup-alarmxv-3.47.6.
- Final remaining: make SDK3.47.8 self-consistent, build signedRelease v7a/v8a/universal only, checksums/identity/signature; bilingual publicREADME+LICENSE+changelog; source checkpoint/reviewbranch; no GitHubRelease.

## Checkpoint5 — 2026-10-25 normal-mode and surface revision

- User returned after usage limit; reported duplicate Android windows, opaque save/footer bands, square dark group menus; requested genuinely permissive normal alarm separate from strict mission mode. Light Clay screenshot is the visual reference; dark depth must improve without blur.
- New contract: AlarmMode challenge/normal, JSON mode(defaultchallenge), volumeMode system/custom(defaultsystem), volumePercent0..100(default70). Old alarms remain strict. Normal ignores stored mission/checker configuration without deleting it.
- Native task evidence: launcher affinity empty vs package affinity for Ring/Wake, singleTop and inconsistent notification/relaunch intents. Fix coherent task identity and finish native Activity without removing shared launcher task.
- Root main now uses edgeToEdge + transparent navigation annotations with contrast scrim disabled. UI agent owns rounded shared choice sheets and fading footer overlays; native agent owns modes/audio/dismiss/affinity.
- SDK tool bootstrap COMPLETED via official pub mirror + command-only VPN: Flutter3.47.8 stable, HEAD737ba8f885dc774b53b442759999a312c9461e4e, enginecf636b1d, Dart3.13.7. No permanent proxy or app credentials saved. Project/CI SDK floor now3.47.8/3.13.7.
- Preview2.0.0-preview.2+5005; app What'sNew/changelog updated. User's stop-tests instruction retained: no new tests/ADB/device installation; final static review/compiler builds only.

## Checkpoint6 — latest navigation/theme requirements

- User requested an animated moon/sun header control instead of three theme buttons; keep system-following as default and expose a clear return to automatic.
- Native and Flutter system navigation must remain VISIBLE (Home/Recents/Back), transparent and inset-safe. This supersedes the earlier immersive/hide-navigation design, while strict mission behavior remains distinct from normal mode.
- Filter transitions must trigger on selected-group change even if IDs/content match All; keep lazy list and reduced-motion support.
- Normal alarm permission readiness needs exact alarms+notifications, not display-over-apps. Mode transition cancels obsolete strict sessions and all checker entrypoints skip normal. Explicit empty normal missions survive JSON round-trip.
- Source-only final review dispatched. No tests executed after stop request. SDK Android artifacts are being prefetched with command-scoped VPN for final release builds.

## Checkpoint7 — final static review and install concern

- Moon/sun action, system sync return and identical-content group transition complete; reduced motion includes accessibleNavigation. Existing UI test selectors maintained without execution; old baseline pass counts are not claimed for preview2.
- Fresh read-only review found no new Important/Critical issue. Known limitations: singleton active-alarm engine; OEM task/nav/volume behavior unverified on preview2.
- User reported an apparent clone and asked for official Android research. No new install performed. Original installed profile used exactly com.alarmxv.alarm_xv with release signer matching1.2 and install-r; source has no applicationIdSuffix or second launcher. Awaiting whether observed duplication is Recents cards, launcher shortcuts or actual Settings packages; do not pretend runtime cause is proved.
- Android references: https://developer.android.com/guide/components/activities/tasks-and-back-stack and https://developer.android.com/studio/publish/app-signing. Affinity/singleTask/canonical intents address task duplication; same ID+signer maintain update identity. No device query/uninstall/cleanup authorized or performed after stop request.
- Final release compiler command running for ARMv7/ARM64 split outputs then universal; no tests or install in that command.

## Checkpoint8 — APK build complete

- Source checkpoint dacabf6 pushed to GitHub branch redesign/clay-v2 (not merged). Private Release compile completed successfully: v7a/v8a splits165s, universal56.4s; no standalonex86APK in final directory.
- Final files dist/2.0.0-preview.2/*.apk, all com.alarmxv.alarm_xv /2.0.0-preview.2/code5005, same signer4f1567... as1.2.0 and singleMainActivity launcher. Verified integrity and wrote local SHA256SUMS; do not upload APKs publicly before approval.
- User clarified TWO LAUNCHER ICONS. Read-only targeted pm/query-activities attempted; phoneR... no longer connected, all queries returned device-not-found. No install/uninstall/launch/test or cleanup performed. Do not assert actual launcher/package duplication solved; source task fix and stable package identity are the available evidence.
- SDK3.47.8 fully working; oldSDK backup retained. No runtime tests after stop. Remaining known gap: singleton active-alarm engine; OEM/task/volume/nav behavior ofpreview2 awaitsowner testing.
- Last remaining administrative work: push final evidence docs, update public bilingual README/CHANGELOG/GPL and design images onmain only, open draft source review PR without merge/publicRelease.

## Checkpoint9 — source and documentation backed up

- Public main received documentation/license/images only in f10f82d; public app source remains v1.2.0. The preview application code is preserved separately on redesign/clay-v2, with main documentation merged back into that branch.
- Final signed APKs remain local in dist/2.0.0-preview.2. No public Release, tag, additional test run or device installation was performed.
- Duplicate launcher icons still require inspection of the owner's actual launcher/package state; device was disconnected during the authorized read-only query. Do not claim the task-affinity fix proves this separate report resolved.

## Checkpoint10 — owner-authorized Release installation, 2026-10-25

- Owner removed the reported clone, reconnected the phone and explicitly requested installation plus a duplicate check. This authorizes this narrow device check; broad alarm/performance testing remains stopped.
- Samsung has primary user0 and a running DUAL_APP user95. Before install, preview1/code5004 existed only for user0; user95 had installed=false and no launcher activity. Therefore the removed clone's original state cannot be reconstructed conclusively.
- Official Android ADB documentation warns that an unspecified install user can target all existing users. Earlier unscoped install-r is a plausible cause. For future installs ALWAYS inspect am get-current-user and explicitly use --user 0 on this device; do not install into DUAL_APP or use unscoped install.
- Installed the existing, unchanged ARM64 Release APK using adb install --user 0 -r; command returned Success. No uninstall or data-clear command was used.
- Post-install package version2.0.0-preview.2/code5005; user0 installed=true with the same CE/DE data inode values as before. Exactly one MAIN/LAUNCHER activity (MainActivity) for user0; user95 installed=false and no launcher activities. No duplicate installation was created by this install. Existing visual home-screen shortcut placement was not independently inspected.
- Reference: https://developer.android.com/tools/adb and https://source.android.com/docs/devices/admin/multi-user-testing . No app source, APK, public Release or additional automated tests changed.

## Checkpoint11 — frosted chrome and bilingual UI, 2026-10-25

- Owner explicitly requested scoped Light/Dark/scroll/menu checks for the new work, superseding the previous no-more-tests preference only for this development verification. No new phone installation or broad alarm/device test is implied.
- Canonical repository is Desktop/ph/AlarmXV. Desktop/AlarmXV contains only build output, not app source; do not create a second project there.
- Read niraNG app_shell.dart AppBar.flexibleSpace and glass_surface.dart FrostedSurface. Only the shader-free frosted recipe was adapted; niraNG remains unchanged.
- New reusable FrostedSurface: ClipRRect / BackdropFilter / themed ColoredBox / transparent Material, sigma8 and Light.64/Dark.45. Text-rich menus use sigma14 and Light.78/Dark.64. Independent overlapping filters; no shared key, per-list-item filter or production captures. Reduced effects/high contrast are opaque.
- Home/Settings/Groups chrome extends above actual scrolling bodies; safe initial padding and fixed footer insets preserved. Existing Clay content is retained. Menus transition their panel/entries together without opacity; Back button has a short elastic press.
- Root cause of cropped card shadow: SizeTransition keeps a rectangular clip even after the insertion finishes. Completed items now paint without that transition clip. Time-picker hour/minute/day-period shapes use the existing rounded token.
- Added system/fa/en appearance setting, Flutter SDK localizations, a named-parameter UI catalog and native presentation catalog for alarm/mission/wake-check/notification strings. Layout direction follows language. Saved labels, phrases, core timing and application identity unchanged.
- Fresh verification: analyzer clean; full Flutter suite39passed/1opt-in visual skipped; separate visual fixture passed; native Release Kotlin compiled and12JVM tests passed. Four UI regression checks were observed failing on the original behavior before fixes; language migration was also RED/GREEN.
- APK version2.0.0-preview.3+5006 with updated What's New and bilingual changelog. Build artifacts pending final compilation. No new physical-device performance claim; source-reviewed native localization is not a complete alarm-cycle test.

## Checkpoint12 — resumed review and launcher routing, 2026-10-26

- Resumed at1992621 after usage-limit interruption. Initial preview3 binaries had compiled before review; rebuild is required for the follow-ups below. Prior artifacts must not be presented as containing these fixes.
- Fresh review identified missing native supportsRtl and system-locale-list mismatch. Added Android RTL support while explicitly isolating math operands/answer/keypad, raw numeric progress and clocks as LTR. Native language now chooses first supported fa/en system locale, consistent with Flutter.
- Locale regression failed on de/fa/en before the fix; two manifest checks failed on the original singleTask/missing RTL configuration. After the fix all15Native tests passed, Kotlin compiled; source reviewer found no blocking issue in the follow-up.
- Owner again reported intermittent two Android windows. Connected device read-only snapshot: one task/user0 with Main root/top, preview2/code5005; DUAL_APP user95 not installed. No duplicate state was present and no old task was removed.
- Confirmed source issue predates preview3: Main.singleTask clears Ring/Check above Main when launcher opens, then the guard reopens Ring. Fixed Main to singleTop and normalized AlarmClockInfo showIntent to the actual launcher identity (no per-alarm data). Native Ring/Check singleTask and common affinity remain.
- Main.onCreate/onNewIntent defensively route only to the existing strict session using the same alarm/snooze/token. No onResume routing, audio restart, alarm reschedule or task deletion. Normal-mode Back remains unrestricted. Source fix is not proof of the intermittent OEM two-task symptom being eliminated.
- Reference: https://developer.android.com/guide/components/activities/tasks-and-back-stack and AOSP ActivityStarter.complyActivityFlags. No new permissions or application identity changes.

## Checkpoint13 — final Release outputs and install-only request, 2026-10-26

- Source checkpoint bca8b4f includes launcher/RTL/locale review fixes. Final ARMv7/ARM64 split compilation61.5s, universal15.2s; all passed. Signatures verified against unchanged v1.2 certificate; manifests code5006 and one launcher, Main singleTop and supportsRtl true. Sizes/hashes in docs/qa/RELEASE_APKS.md and local dist/2.0.0-preview.3/SHA256SUMS.txt.
- Auto-review rejected KEYCODE_WAKEUP because of the prior stop-device-testing instruction; the command was not executed and no workaround attempted. User then explicitly said: install only, they will test on the phone. This is the current device interaction boundary.
- Ran only adb install --user 0 -r for the final ARM64 Release; Success. Read-only package verification shows2.0.0-preview.3/code5006, user0 installed, unchanged CE/DE data inodes; no package listed for DUAL_APP user95. No uninstall/data clear, screen wake, post-install UI interaction, alarm trigger or FPS test.
- Local final artifacts retained; no public GitHub Release/tag or merge into main. Current source and documentation checkpoint is backed up on redesign/clay-v2.

## Checkpoint14 — owner authorized public GitHub pre-release, 2026-10-26

- Owner explicitly requested putting the finished work on GitHub with a clean presentation. Publish2.0.0-preview.3 as a public pre-release, keep1.2.0 as stable/latest, promote the matching source to main and attach only the three verified APKs plus SHA256SUMS. No additional tests, builds or phone interaction requested or needed; app sources/artifacts remain those already verified and installed.
- Refreshed bilingual homepage with current sample-only screenshots, direct architecture download table, features, GPL/license/privacy links and honest verification limits. Replaced stale1.2 RELEASE_NOTES.md with bilingual preview3 notes; no build instructions in the homepage.
- Removed obsolete tag-push publisher: it uploaded tracked1.2 release-assets for every tag. Publication now uses GitHub CLI with explicit verified local dist/2.0.0-preview.3 assets, staged as a draft before publication. No signing material or real device screenshots included.
- GitHub connector has no Release/asset publication capability; GitHub CLI authenticated to the same owned public repository is the fallback. Existing main=f10f82d; source backup branch=redesign/clay-v2. Final publication result is recorded after API verification.

## Checkpoint15 — public pre-release verified, 2026-10-26

- Published https://github.com/bardia-us/AlarmXV/releases/tag/v2.0.0-preview.3 (release424633388): draft=false, prerelease=true. Stable latest endpoint still returnsv1.2.0.
- Tag source=c7cf8642f99c7800bb2f1a0136137255bd888322, with no lib/android/pubspec changes relative to the built/installed bca8b4f checkpoint. Main fast-forwarded fromf10f82d to the matching source/homepage. No history rewrite or tag replacement.
- Exactly4assets uploaded: ARM64, ARMv7, universal and SHA256SUMS. GitHub server SHA256 digests and byte lengths matched all four local files before publication. Existing signing identity preserved.
- Public README now includes current Persian/English sample screenshots, architecture download table, versioned links, privacy/GPL/contribution sections and the actual test limitations. Repo description and topics refreshed. Old1.2 Release and assets unchanged; obsolete tag publisher removed to prevent stale artifact uploads.
- No additional tests/builds or phone interactions performed for publication. The user's install-only/they-test-device boundary remains in effect.

## Checkpoint16 — stable version correction requested, 2026-10-26

- Owner explicitly requested stable/latest publication with an increased app version and freshly rebuilt/uploaded APKs. Corrected pubspec from2.0.0-preview.3+5006 to2.0.0+5007 and in-app What's New fallback to2.0.0. Native package metadata is generated from this version; do not relabel the preview APKs.
- Retain existing applicationId/release signer and the three requested variants (ARM64,ARMv7,universal). Build pipeline started for a fresh Release rebuild into dist/2.0.0; earlier preview artifacts/releases remain historical.
- README/RELEASE_NOTES/CHANGELOG now target stable2.0.0, with stable download links and accurate attribution of the earlier39Flutter/15Native tests to the preview implementation. No new tests or phone interactions requested/run for this packaging correction. Final APK manifest/signature and remote-upload checks are required before publication.

- Fresh split Release build56.0s, universal45.8s, all successful. Each APK inspected: versionName2.0.0/code5007, unchanged com.alarmxv.alarm_xv and release certificate4f1567... . New stable artifact hashes/sizes recorded in docs/qa/RELEASE_APKS.md; no preview file relabeled. Draft upload and Stable/Latest promotion follow checksum validation.
