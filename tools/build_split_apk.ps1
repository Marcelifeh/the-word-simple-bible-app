param(
    [switch]$VerboseBuild,
    [string]$BibleApiUrl,
    [string]$CommentaryApiUrl
)

$arguments = @(
    'build',
    'apk',
    '--release',
    '--split-per-abi'
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

& flutter @arguments
exit $LASTEXITCODE



