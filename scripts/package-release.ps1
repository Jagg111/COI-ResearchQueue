[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Test-Path Variable:\PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}

trap {
    Write-Host ("ERROR: {0}" -f $_.Exception.Message)
    exit 1
}

function Fail([string]$Message) {
    throw $Message
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repoRoot

$manifestPath = Join-Path $repoRoot "manifest.json"
if (-not (Test-Path $manifestPath)) {
    Fail "manifest.json was not found at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($manifest.id))      { Fail "manifest.json is missing the 'id' field." }
if ([string]::IsNullOrWhiteSpace($manifest.version)) { Fail "manifest.json is missing the 'version' field." }

$modId   = [string]$manifest.id
$version = [string]$manifest.version
$tag     = "v$version"

$releaseRoot  = Join-Path $repoRoot "bin\pkg"
$stagingRoot  = Join-Path $releaseRoot $modId
$dllPath      = Join-Path $repoRoot "bin\Release\net48\$modId.dll"
$zipPath      = Join-Path $releaseRoot ("{0}-{1}.zip" -f $modId, $tag)
$changelogSrc = Join-Path $repoRoot "changelog.txt"

if (-not (Test-Path $changelogSrc)) {
    Fail "changelog.txt not found at $changelogSrc -- make sure it was updated and committed before packaging."
}

Write-Host "Building release..."
& dotnet build .\ResearchQueue.sln -c Release /p:LangVersion=latest /p:DeployToModsFolder=false
if ($LASTEXITCODE -ne 0) {
    Fail "Release build failed."
}

if (-not (Test-Path $dllPath)) {
    Fail "Expected build output was not found at $dllPath"
}

if (Test-Path $releaseRoot) {
    Remove-Item -LiteralPath $releaseRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
Copy-Item -LiteralPath $dllPath        -Destination (Join-Path $stagingRoot "$modId.dll")
Copy-Item -LiteralPath $manifestPath   -Destination (Join-Path $stagingRoot "manifest.json")
Copy-Item -LiteralPath $changelogSrc   -Destination (Join-Path $stagingRoot "changelog.txt")

Compress-Archive -Path $stagingRoot -DestinationPath $zipPath -Force
if (-not (Test-Path $zipPath)) {
    Fail "Release zip was not created at $zipPath"
}

Write-Host ""
Write-Host "Package ready: $zipPath"
Write-Host "Upload this zip to the COI Hub at https://hub.coigame.com/Mod/17"
