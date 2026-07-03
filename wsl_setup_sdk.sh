#!/bin/bash
set -e
export ANDROID_HOME=$HOME/Android/Sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:/usr/bin:/bin"

echo "ANDROID_HOME=$ANDROID_HOME"
echo "--- cmdline-tools bin ---"
ls "$ANDROID_HOME/cmdline-tools/latest/bin/"

echo "--- accepting licenses ---"
yes | sdkmanager --licenses > /tmp/licenses.log 2>&1
tail -5 /tmp/licenses.log

echo "--- installing packages ---"
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.1.0" "emulator" > /tmp/install.log 2>&1
tail -20 /tmp/install.log

echo "--- verifying adb ---"
ls "$ANDROID_HOME/platform-tools/adb"
echo DONE
