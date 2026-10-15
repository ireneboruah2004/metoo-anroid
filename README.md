# MeToo – Android app (untested, first version)

Tap the app icon:
- opening the app = tap 1
- tap once more (anywhere on screen) within 2.5 s = 2 taps: SMS with location goes to your contacts automatically, no Send button
- tap twice more = 3 taps: loud siren, max volume, stops only after the phone's own password / fingerprint

Android only. A website or iPhone cannot send SMS silently.

## Build the APK (no installs, in GitHub)
1. Create a new GitHub repo, e.g. `metoo-android`.
2. Upload ALL files of this folder (keep the folders `.github`, `lib`, `tool`, `assets`). On github.com: Add file > Upload files, drag the contents in.
   (If the hidden `.github` folder is not dragged by Windows, create the file by hand: Add file > Create new file, name `.github/workflows/build-apk.yml`, paste its contents.)
3. Open the **Actions** tab > "Build MeToo APK" > **Run workflow**. Wait ~8 min.
4. Open the finished run > **Artifacts** > download `MeToo-apk` (zip) > unzip to get `app-release.apk`.
5. Send the APK to an Android phone (WhatsApp/USB), open it, allow "install unknown apps".
6. First launch: allow Location, then SMS. If SMS is greyed out: phone Settings > Apps > MeToo > ⋮ > **Allow restricted settings**, then Permissions > SMS > Allow.
7. Contacts tab: add 2 numbers. Test with your own numbers first.

## Notes
- Cannot go on Google Play with SMS permission (restricted). Share the APK directly.
- Siren stop: the lock screen password/fingerprint must be set on the phone.
- Change icon name: in `tool/prepare.sh`.
- Design: `lib/theme.dart` and `lib/pages/`.
- Not tested on a real phone. Expect bugs; send me the Actions error log or what you see.
