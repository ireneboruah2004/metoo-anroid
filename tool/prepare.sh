#!/usr/bin/env bash
# Builds a full Flutter project in ./build_app from this folder's code. Used by GitHub Actions.
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/build_app"
rm -rf "$OUT"
flutter create --org app --project-name metoo --platforms=android "$OUT"
rm -rf "$OUT/lib" "$OUT/test"
cp -r "$HERE/lib" "$HERE/assets" "$OUT/"
cp "$HERE/pubspec.yaml" "$OUT/pubspec.yaml"
# replace generated MainActivity
find "$OUT/android/app/src/main/kotlin" -name MainActivity.kt -delete
mkdir -p "$OUT/android/app/src/main/kotlin/app/metoo"
cp "$HERE/tool/MainActivity.kt" "$OUT/android/app/src/main/kotlin/app/metoo/MainActivity.kt"
# home-screen SOS widget: native code + resources
KOT="$OUT/android/app/src/main/kotlin/app/metoo"
for f in SosService SosWidgetProvider StopSirenActivity; do
  cp "$HERE/tool/$f.kt" "$KOT/$f.kt"
done
RES="$OUT/android/app/src/main/res"
mkdir -p "$RES/layout" "$RES/xml" "$RES/drawable" "$RES/raw"
cp "$HERE/tool/res/layout/widget_sos.xml" "$RES/layout/widget_sos.xml"
cp "$HERE/tool/res/xml/sos_widget_info.xml" "$RES/xml/sos_widget_info.xml"
cp "$HERE/tool/res/drawable/widget_bg.xml" "$RES/drawable/widget_bg.xml"
cp "$HERE/assets/siren.wav" "$RES/raw/siren.wav"
python3 - "$OUT" <<'PY'
import sys,re,glob
out=sys.argv[1]
mf=out+"/android/app/src/main/AndroidManifest.xml"
s=open(mf).read()
perms='''
    <uses-permission android:name="android.permission.SEND_SMS"/>
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <queries>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
    </queries>
'''
s=s.replace("<application",perms+"    <application",1)
link='''<intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="metoo"/>
            </intent-filter>
            '''
s=s.replace("<intent-filter>",link+"<intent-filter>",1)
# home-screen widget, tap service and the unlock-to-stop-siren screen
widget='''
        <receiver android:name="app.metoo.SosWidgetProvider" android:exported="true" android:label="MeToo SOS">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
            </intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/sos_widget_info"/>
        </receiver>
        <service android:name="app.metoo.SosService" android:exported="false" android:foregroundServiceType="specialUse">
            <property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="personal_safety_alert"/>
        </service>
        <activity android:name="app.metoo.StopSirenActivity" android:exported="false" android:excludeFromRecents="true" android:theme="@android:style/Theme.Translucent.NoTitleBar"/>
    '''
s=s.replace("</application>",widget+"</application>",1)
# To rename the home-screen icon, add here: s=s.replace('android:label="metoo"','android:label="YourName"')
open(mf,"w").write(s)
for g in glob.glob(out+"/android/app/build.gradle*"):
    t=open(g).read()
    t=re.sub(r"minSdk(Version)?\s*=?\s*(flutter\.minSdkVersion|\d+)","minSdk = 24",t)
    open(g,"w").write(t)
PY
(cd "$OUT" && flutter pub get)

python3 - <<'PY'
import os, re, glob
root = os.environ.get("PUB_CACHE") or os.path.expanduser("~/.pub-cache")
for f in glob.glob(root + "/hosted/*/*/android/build.gradle*"):
    t = open(f).read()
    n = re.sub(r"compileSdk(Version)?(\s*=\s*|\s+)\d+", "compileSdk = 36", t)
    if n != t:
        open(f, "w").write(n)
        print("patched", f)
PY
python3 - "$OUT" <<'PY'
import sys
mf = sys.argv[1] + "/android/app/src/main/AndroidManifest.xml"
s = open(mf).read()
extra = '''
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.READ_CALL_LOG"/>'''
if "READ_PHONE_STATE" not in s:
    s = s.replace('<uses-permission android:name="android.permission.CALL_PHONE"/>', '<uses-permission android:name="android.permission.CALL_PHONE"/>' + extra, 1)
    open(mf, "w").write(s)
PY