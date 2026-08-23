param(
    [switch]$VerboseBuild,
    [string]$SermonApiUrl = 'https://the-word-app-api.onrender.com',
    [bool]$TranscriptionEnabled = $false,
    [string]$BibleApiUrl,
    [string]$CommentaryApiUrl
)

$ErrorActionPreference = 'Stop'

function Assert-ProductionApiUrl([string]$Name, [string]$Value, [bool]$Required) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Required) { throw "$Name is required for a production build." }
        return
    }
    $uri = $null
    if (-not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) {
        throw "$Name must be an absolute HTTPS URL."
    }
    $blocked = @('localhost', '127.0.0.1', '::1', '10.0.2.2')
    if ($uri.Scheme -ne 'https' -or $blocked -contains $uri.Host.ToLowerInvariant()) {
        throw "$Name must use HTTPS and must not use a local or loopback host."
    }
}

Assert-ProductionApiUrl 'SERMON_API_URL' $SermonApiUrl $true
Assert-ProductionApiUrl 'BIBLE_API_URL' $BibleApiUrl $false
Assert-ProductionApiUrl 'COMMENTARY_API_URL' $CommentaryApiUrl $false
if ($TranscriptionEnabled) {
    throw 'SERMON_TRANSCRIPTION_ENABLED must be false for this production release.'
}

$flutter = 'C:\flutter\bin\flutter.bat'
$arguments = @(
    'build',
    'apk',
    '--release',
    '--split-per-abi',
    "--dart-define=SERMON_API_URL=$SermonApiUrl",
    "--dart-define=SERMON_TRANSCRIPTION_ENABLED=$($TranscriptionEnabled.ToString().ToLowerInvariant())"
)

if ($VerboseBuild) {
    $arguments += '--verbose'
}

if ($BibleApiUrl) {
    $arguments += "--dart-define=BIBLE_API_URL=$BibleApiUrl"
}

if ($CommentaryApiUrl) {
    $arguments += "--dart-define=COMMENTARY_API_URL=$CommentaryApiUrl"
}

Write-Host 'Building production split APKs...'
Write-Host "API URL: $SermonApiUrl"
Write-Host "Cloud transcription enabled: $TranscriptionEnabled"

& $flutter pub get
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter pub get failed.'
}

& $flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter analyze failed.'
}

& $flutter @arguments
if ($LASTEXITCODE -ne 0) {
    throw 'Split APK build failed.'
}

Write-Host ''
Write-Host 'Build completed:'
Write-Host 'build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk'
Write-Host 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
Write-Host 'build\app\outputs\flutter-apk\app-x86_64-release.apk'
