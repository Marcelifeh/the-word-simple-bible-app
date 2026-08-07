[CmdletBinding()]
param(
    [string]$KeystorePath = (Join-Path $HOME "upload-keystore.jks"),
    [string]$Alias = "upload",
    [string]$DistinguishedName = "CN=The Word App, O=The Word App, C=CA",
    [string]$BackupDirectory
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$keyPropertiesPath = Join-Path $projectRoot "android\key.properties"

if (Test-Path -LiteralPath $KeystorePath) {
    throw "Keystore already exists: $KeystorePath"
}
if (Test-Path -LiteralPath $keyPropertiesPath) {
    throw "Signing properties already exist: $keyPropertiesPath"
}

$keytoolCandidates = @(
    $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\keytool.exe" }),
    "C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$keytool = $keytoolCandidates | Select-Object -First 1
if (-not $keytool) {
    $keytool = (Get-Command keytool.exe -ErrorAction SilentlyContinue).Source
}
if (-not $keytool) {
    throw "keytool.exe was not found. Install Android Studio or configure JAVA_HOME."
}

function ConvertFrom-SecureValue {
    param([Security.SecureString]$Value)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

$password = $null
try {
    $first = Read-Host "Create a strong upload-key password (12+ characters)" -AsSecureString
    $second = Read-Host "Confirm the upload-key password" -AsSecureString
    $password = ConvertFrom-SecureValue $first
    $confirmation = ConvertFrom-SecureValue $second

    if ($password.Length -lt 12) {
        throw "The password must contain at least 12 characters."
    }
    if ($password -cne $confirmation) {
        throw "The passwords do not match."
    }

    if (-not $BackupDirectory) {
        $BackupDirectory = Read-Host `
            "Optional secure backup directory (leave blank to back up later)"
    }

    $env:WORD_APP_UPLOAD_KEY_PASSWORD = $password
    & $keytool -genkeypair -v `
        -keystore $KeystorePath `
        -storetype JKS `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias $Alias `
        -dname $DistinguishedName `
        -storepass:env WORD_APP_UPLOAD_KEY_PASSWORD `
        -keypass:env WORD_APP_UPLOAD_KEY_PASSWORD

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $KeystorePath)) {
        throw "keytool failed to create the upload keystore."
    }

    $escapedStorePath = $KeystorePath -replace '\\', '\\\\'
    $properties = @(
        "storePassword=$password"
        "keyPassword=$password"
        "keyAlias=$Alias"
        "storeFile=$escapedStorePath"
        ""
    ) -join [Environment]::NewLine
    [IO.File]::WriteAllText(
        $keyPropertiesPath,
        $properties,
        [Text.UTF8Encoding]::new($false)
    )

    if ($BackupDirectory) {
        $resolvedBackup = [IO.Path]::GetFullPath($BackupDirectory)
        [IO.Directory]::CreateDirectory($resolvedBackup) | Out-Null
        Copy-Item -LiteralPath $KeystorePath `
            -Destination (Join-Path $resolvedBackup "upload-keystore.jks")
        Copy-Item -LiteralPath $keyPropertiesPath `
            -Destination (Join-Path $resolvedBackup "key.properties")
        Write-Host "Backup written to: $resolvedBackup"
    }

    Write-Host ""
    Write-Host "Release signing is configured." -ForegroundColor Green
    Write-Host "Keystore: $KeystorePath"
    Write-Host "Properties: $keyPropertiesPath"
    Write-Host "Alias: $Alias"
    Write-Host "Back up the keystore and credentials in two secure locations."
}
finally {
    Remove-Item Env:\WORD_APP_UPLOAD_KEY_PASSWORD -ErrorAction SilentlyContinue
    $password = $null
    $confirmation = $null
}
