# One-command build + install + launch for the Huddle app on the Pixel 6 emulator.
# Builds happen inside WSL2 (Ubuntu) to route around a Windows-side AF_UNIX socket bug
# in Gradle; everything else (emulator, adb) stays on the Windows side as usual.

$ErrorActionPreference = "Stop"

$AndroidHome = "C:\Users\Xulruca.Alucrux\AppData\Local\Android\Sdk"
$Adb = "$AndroidHome\platform-tools\adb.exe"
$EmulatorExe = "$AndroidHome\emulator\emulator.exe"
$ProjectRoot = "E:\Documents\VS Code\Mobile App Project\huddle"
$WslBuildScript = "/mnt/e/Documents/VS Code/Mobile App Project/huddle/wsl_build_apk.sh"
$ApkPath = "$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk"
$AppId = "com.huddle.app.huddle"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

Write-Step "Restarting adb server"
& $Adb kill-server 2>$null
Start-Sleep -Milliseconds 500
& $Adb start-server

Write-Step "Checking for a running emulator"
$devices = & $Adb devices
$hasDevice = $devices -match "emulator-\d+\s+device"

if (-not $hasDevice) {
    Write-Host "No emulator attached, launching Pixel_6..."
    Start-Process -FilePath $EmulatorExe -ArgumentList "-avd", "Pixel_6" -WindowStyle Minimized

    Write-Host "Waiting for device to attach..."
    $attached = $false
    while (-not $attached) {
        Start-Sleep -Seconds 2
        $devices = & $Adb devices
        $attached = $devices -match "emulator-\d+\s+device"
    }

    Write-Host "Waiting for boot to complete..."
    $booted = $false
    while (-not $booted) {
        Start-Sleep -Seconds 2
        $prop = & $Adb shell getprop sys.boot_completed 2>$null
        $booted = $prop -match "1"
    }
}
Write-Host "Emulator ready."

Write-Step "Building APK inside WSL2 (this can take a couple of minutes)"
wsl -d Ubuntu -- bash $WslBuildScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed. See output above." -ForegroundColor Red
    exit 1
}

Write-Step "Installing APK"
& $Adb install -r $ApkPath

Write-Step "Launching Huddle"
& $Adb shell am start -n "$AppId/$AppId.MainActivity" | Out-Null

Write-Host ""
Write-Host "Done. Huddle is running on the emulator." -ForegroundColor Green
