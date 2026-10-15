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
python3 - "$OUT" <<'PY'
import sys,re,glob
out=sys.argv[1]
mf=out+"/android/app/src/main/AndroidManifest.xml"
s=open(mf).read()
perms='''
    <uses-permission android:name="android.permission.SEND_SMS"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.INTERNET"/>
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
