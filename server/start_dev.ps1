$ErrorActionPreference = "Stop"

$serverDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $serverDir

.\.venv\Scripts\python.exe .\run_dev.py
