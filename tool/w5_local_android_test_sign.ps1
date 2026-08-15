#Requires -Version 5.1
<#
.SYNOPSIS
  LOCAL W5 Android TEST SIGNING ONLY proof (not GitHub Actions; not production).
#>
$ErrorActionPreference = 'Stop'
Write-Host 'TEST SIGNING ONLY — local proof — not production'

function Resolve-JavaBin([string]$name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\$name.exe" } else { $null }),
    "C:\Program Files\Android\Android Studio\jbr\bin\$name.exe",
    (Join-Path $env:LOCALAPPDATA "Programs\Android\Android Studio\jbr\bin\$name.exe")
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { return (Resolve-Path $c).Path }
  }
  throw "$name not found (install JDK / Android Studio JBR)"
}

$keytool = Resolve-JavaBin 'keytool'
$jarsigner = Resolve-JavaBin 'jarsigner'
$env:JAVA_HOME = Split-Path (Split-Path $keytool -Parent) -Parent
$env:Path = "$(Join-Path $env:JAVA_HOME 'bin');$env:Path"
# Avoid Arabic-Indic digits breaking bundletool dex index names (classes٢.dex).
$env:JAVA_TOOL_OPTIONS = '-Duser.language=en -Duser.country=US'
$env:GRADLE_OPTS = '-Duser.language=en -Duser.country=US'
try {
  [System.Threading.Thread]::CurrentThread.CurrentCulture = [cultureinfo]::InvariantCulture
  [System.Threading.Thread]::CurrentThread.CurrentUICulture = [cultureinfo]::InvariantCulture
} catch {}
Write-Host "keytool=$keytool JAVA_HOME=$env:JAVA_HOME"

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

$work = Join-Path ([IO.Path]::GetTempPath()) ("w5-android-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
$keystore = Join-Path $work 'w5-test-upload.jks'

& $keytool -genkeypair `
  -keystore $keystore `
  -storetype JKS `
  -alias w5test `
  -keyalg RSA -keysize 2048 -validity 30 `
  -storepass 'test-only-store' `
  -keypass 'test-only-key' `
  -dname 'CN=W5 Test Signing Only, OU=SAEQ, O=SAEQ, L=Riyadh, C=SA'
if ($LASTEXITCODE -ne 0) { throw 'keytool failed' }

$list = & $keytool -list -v -keystore $keystore -storepass 'test-only-store' -alias w5test | Out-String
$m = [regex]::Match($list, 'SHA256:\s*([0-9A-Fa-f:]+)')
if (-not $m.Success) { throw 'could not parse keystore SHA256' }
$fp = ($m.Groups[1].Value -replace '[:\s]', '').ToUpperInvariant()
Write-Host "TEST signer cert SHA-256=$fp"

$props = @"
storePassword=test-only-store
keyPassword=test-only-key
keyAlias=w5test
storeFile=$($keystore.Replace('\','/'))
"@
Set-Content -Path (Join-Path $root 'android\key.properties') -Value $props -Encoding Ascii

try {
  & flutter build appbundle --release
  if ($LASTEXITCODE -ne 0) { throw 'appbundle failed' }
  & flutter build apk --release
  if ($LASTEXITCODE -ne 0) { throw 'apk failed' }

  $aab = Join-Path $root 'build\app\outputs\bundle\release\app-release.aab'
  $apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
  if (-not (Test-Path $aab)) { throw "missing $aab" }
  if (-not (Test-Path $apk)) { throw "missing $apk" }

  & $jarsigner -verify -verbose -certs $aab | Out-File (Join-Path $work 'jarsigner.txt')
  if ($LASTEXITCODE -ne 0) { throw 'jarsigner verify failed' }
  $js = Get-Content (Join-Path $work 'jarsigner.txt') -Raw
  if ($js -match 'CN=Android Debug') { throw 'debug cert in AAB' }

  $sdk = $env:ANDROID_HOME
  if (-not $sdk) { $sdk = 'D:\jeri\dev-cache\android\Sdk' }
  $apksigner = Get-ChildItem "$sdk\build-tools\*\apksigner.bat" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
  if (-not $apksigner) {
    throw "apksigner.bat not found under $sdk\build-tools"
  }
  $apkOut = Join-Path $work 'apksigner.txt'
  # apksigner may write JAVA_TOOL_OPTIONS notices to stderr; do not treat as terminating.
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $apkLines = & $apksigner verify --verbose --print-certs $apk 2>&1
  $apkCode = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
  $apkLines | ForEach-Object { "$_" } | Set-Content -Path $apkOut
  if ($apkCode -ne 0) {
    Get-Content $apkOut | Select-Object -Last 30 | Write-Host
    throw 'apksigner verify failed'
  }
  $apkText = Get-Content $apkOut -Raw
  if ($apkText -match 'CN=Android Debug') { throw 'debug cert in APK' }
  $am = [regex]::Match($apkText, 'Signer #1 certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)')
  if (-not $am.Success) { throw 'could not parse APK signer SHA-256' }
  $apkFp = ($am.Groups[1].Value -replace '[:\s]', '').ToUpperInvariant()
  if ($apkFp -ne $fp) { throw "APK fingerprint mismatch expected=$fp actual=$apkFp" }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::OpenRead($aab)
  $entry = $zip.Entries | Where-Object { $_.FullName -match '^META-INF/.*\.(RSA|DSA|EC)$' } | Select-Object -First 1
  if (-not $entry) { $zip.Dispose(); throw 'no signing block in AAB' }
  $certPath = Join-Path $work 'aab-signer.rsa'
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $certPath, $true)
  $zip.Dispose()
  $certPrint = & $keytool -printcert -file $certPath | Out-String
  $cm = [regex]::Match($certPrint, 'SHA256:\s*([0-9A-Fa-f:]+)')
  if (-not $cm.Success) { throw 'could not parse AAB signer SHA256' }
  $aabFp = ($cm.Groups[1].Value -replace '[:\s]', '').ToUpperInvariant()
  if ($aabFp -ne $fp) { throw "AAB fingerprint mismatch expected=$fp actual=$aabFp" }

  $aabHash = (Get-FileHash -Algorithm SHA256 $aab).Hash
  $apkHash = (Get-FileHash -Algorithm SHA256 $apk).Hash
  $provDir = Join-Path $root 'build\w5-local-proof'
  New-Item -ItemType Directory -Force -Path $provDir | Out-Null
  @(
    'signing=TEST_SIGNING_ONLY'
    'not_production=true'
    'execution=LOCAL'
    "repo_path=$root"
    "commit=$(git rev-parse HEAD)"
    "signer_cert_sha256=$fp"
    "aab_sha256=$aabHash"
    "apk_sha256=$apkHash"
    'jarsigner_verify=PASS'
    'apksigner_verify=PASS'
    'fingerprint_pin=PASS'
  ) | Set-Content (Join-Path $provDir 'android-test-signed.provenance.txt')

  Write-Host "LOCAL Android TEST SIGNING ONLY PASS"
  Write-Host "signer_cert_sha256=$fp"
  Write-Host "aab_sha256=$aabHash"
  Write-Host "apk_sha256=$apkHash"
}
finally {
  Remove-Item (Join-Path $root 'android\key.properties') -Force -ErrorAction SilentlyContinue
  Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
