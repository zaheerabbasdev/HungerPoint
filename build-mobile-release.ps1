# Builds release APKs of hpcustomer, hprider and hpwaiter pointed at the
# production API, and collects them in .\release\.
#
# Usage (from the repo root, in PowerShell):
#   .\build-mobile-release.ps1 -ApiUrl https://api.yourdomain.com/api/v1
#   .\build-mobile-release.ps1 -ApiUrl https://api.yourdomain.com/api/v1 -AppBundle   # .aab for Play Store

param(
    [Parameter(Mandatory = $true)][string]$ApiUrl,
    [switch]$AppBundle
)

$ErrorActionPreference = 'Stop'

if ($ApiUrl -notmatch '^https://.+/api/v1/?$') {
    Write-Error "ApiUrl must start with https:// and end with /api/v1 (Android blocks plain http). Got: $ApiUrl"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $env:PATH = "C:\src\flutter\bin;C:\Program Files\Java\jdk-22\bin;C:\Users\zabba\AppData\Local\Android\Sdk\platform-tools;C:\Program Files\nodejs;" + $env:PATH
}
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = "C:\Program Files\Java\jdk-22" }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "C:\Users\zabba\AppData\Local\Android\Sdk" }

$root = $PSScriptRoot
$out = Join-Path $root 'release'
New-Item -ItemType Directory -Force $out | Out-Null

$target = if ($AppBundle) { 'appbundle' } else { 'apk' }

foreach ($app in 'hpcustomer', 'hprider', 'hpwaiter') {
    Write-Host "`n=== Building $app ($target) ===" -ForegroundColor Cyan
    Push-Location (Join-Path $root $app)
    try {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed for $app" }
        flutter build $target --release "--dart-define=API_BASE_URL=$ApiUrl"
        if ($LASTEXITCODE -ne 0) { throw "flutter build failed for $app" }

        if ($AppBundle) {
            Copy-Item 'build\app\outputs\bundle\release\app-release.aab' (Join-Path $out "$app-release.aab") -Force
        } else {
            Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' (Join-Path $out "$app-release.apk") -Force
        }
    } finally {
        Pop-Location
    }
}

Write-Host "`nDone. Builds are in $out" -ForegroundColor Green
