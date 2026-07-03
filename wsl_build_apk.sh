#!/bin/bash
set -e
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH="$HOME/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:/usr/bin:/bin"

SRC="/mnt/e/Documents/VS Code/Mobile App Project/huddle"
DEST="$HOME/huddle"

echo "--- syncing project to native Linux filesystem ---"
rsync -a --delete --exclude 'build/' --exclude '.dart_tool/' "$SRC/" "$DEST/"
cd "$DEST"

echo "--- flutter pub get ---"
flutter pub get

echo "--- flutter build apk (release) ---"
flutter build apk --release

echo "--- copying apk back to Windows-side project ---"
mkdir -p "$SRC/build/app/outputs/flutter-apk"
cp build/app/outputs/flutter-apk/app-release.apk "$SRC/build/app/outputs/flutter-apk/app-release.apk"
ls -la "$SRC/build/app/outputs/flutter-apk/"
echo BUILD_SCRIPT_DONE
