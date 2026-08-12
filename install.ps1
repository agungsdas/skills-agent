<#
.SYNOPSIS
    Install Kiro skills and steering files to global config directory.

.DESCRIPTION
    Copies skill folders and steering files to ~/.kiro/skills and ~/.kiro/steering.
    Equivalent of `make link` for Windows users.

.PARAMETER Action
    Action to perform: link (default), unlink, or status.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Action link
    .\install.ps1 -Action unlink
    .\install.ps1 -Action status
#>

param(
    [ValidateSet("link", "unlink", "status")]
    [string]$Action = "link"
)

$ErrorActionPreference = "Stop"

$KiroHome = if ($env:KIRO_HOME) { $env:KIRO_HOME } else { Join-Path $env:USERPROFILE ".kiro" }
$SkillsDir = Join-Path $KiroHome "skills"
$SteeringDir = Join-Path $KiroHome "steering"
$CurrentDir = $PSScriptRoot

# Folders to skip (not skills)
$ExcludeFolders = @(".git", ".kiro", "steering")

function Get-SkillFolders {
    Get-ChildItem -Path $CurrentDir -Directory |
        Where-Object { $ExcludeFolders -notcontains $_.Name } |
        Select-Object -ExpandProperty Name
}

function Get-SteeringFiles {
    $steeringPath = Join-Path $CurrentDir "steering"
    if (Test-Path $steeringPath) {
        Get-ChildItem -Path $steeringPath -Filter "*.md" -File |
            Select-Object -ExpandProperty Name
    }
}

function Invoke-Link {
    $skillFolders = Get-SkillFolders
    $steeringFiles = Get-SteeringFiles

    Write-Host "`nCopying skills to $SkillsDir..." -ForegroundColor Cyan

    # Create skills dir and clean existing
    if (Test-Path $SkillsDir) {
        Remove-Item -Path (Join-Path $SkillsDir "*") -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null

    foreach ($folder in $skillFolders) {
        $source = Join-Path $CurrentDir $folder
        $dest = Join-Path $SkillsDir $folder
        Copy-Item -Path $source -Destination $dest -Recurse -Force
        Write-Host "  + $folder -> $dest" -ForegroundColor Green
    }

    # Copy README
    $readmeSrc = Join-Path $CurrentDir "README.md"
    if (Test-Path $readmeSrc) {
        Copy-Item -Path $readmeSrc -Destination (Join-Path $SkillsDir "README.md") -Force
        Write-Host "  + README.md -> $SkillsDir\README.md" -ForegroundColor Green
    }

    Write-Host "`nCopying steering to $SteeringDir..." -ForegroundColor Cyan

    # Create steering dir and clean existing .md files
    if (Test-Path $SteeringDir) {
        Get-ChildItem -Path $SteeringDir -Filter "*.md" -File | Remove-Item -Force
    }
    New-Item -ItemType Directory -Path $SteeringDir -Force | Out-Null

    foreach ($file in $steeringFiles) {
        $source = Join-Path $CurrentDir "steering" $file
        $dest = Join-Path $SteeringDir $file
        Copy-Item -Path $source -Destination $dest -Force
        Write-Host "  + $file -> $dest" -ForegroundColor Green
    }

    $skillCount = ($skillFolders | Measure-Object).Count
    $steeringCount = ($steeringFiles | Measure-Object).Count
    Write-Host "`nDone! $skillCount skills + $steeringCount steering files copied.`n" -ForegroundColor Green
}

function Invoke-Unlink {
    Write-Host "`nRemoving copied files..." -ForegroundColor Yellow

    if (Test-Path $SkillsDir) {
        Remove-Item -Path (Join-Path $SkillsDir "*") -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared $SkillsDir" -ForegroundColor Yellow
    }

    if (Test-Path $SteeringDir) {
        Get-ChildItem -Path $SteeringDir -Filter "*.md" -File | Remove-Item -Force
        Write-Host "  Cleared *.md from $SteeringDir" -ForegroundColor Yellow
    }

    Write-Host "`nDone!`n" -ForegroundColor Green
}

function Invoke-Status {
    Write-Host "`nSkills ($SkillsDir):" -ForegroundColor Cyan
    if (Test-Path $SkillsDir) {
        Get-ChildItem -Path $SkillsDir | ForEach-Object {
            $type = if ($_.PSIsContainer) { "[DIR] " } else { "[FILE]" }
            Write-Host "  $type $($_.Name)"
        }
    } else {
        Write-Host "  (empty)"
    }

    Write-Host "`nSteering ($SteeringDir):" -ForegroundColor Cyan
    if (Test-Path $SteeringDir) {
        Get-ChildItem -Path $SteeringDir -Filter "*.md" -File | ForEach-Object {
            Write-Host "  [FILE] $($_.Name)"
        }
    } else {
        Write-Host "  (empty)"
    }
    Write-Host ""
}

# Execute action
switch ($Action) {
    "link"   { Invoke-Link }
    "unlink" { Invoke-Unlink }
    "status" { Invoke-Status }
}
