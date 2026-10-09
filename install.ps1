<#
.SYNOPSIS
    Install skills and steering/rules for Kiro and Antigravity (Gemini).

.DESCRIPTION
    Copies skill folders and steering files to ~/.kiro (for Kiro) and/or
    ~/.gemini/config (for Antigravity/Gemini).
    Equivalent of `make link` for Windows users.

.PARAMETER Action
    Action to perform: link (default), unlink, or status.

.PARAMETER Target
    Target platform: all (default), kiro, or antigravity.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Action link -Target all
    .\install.ps1 -Action link -Target kiro
    .\install.ps1 -Action link -Target antigravity
    .\install.ps1 -Action status
    .\install.ps1 -Action unlink
#>

param(
    [ValidateSet("link", "unlink", "status")]
    [string]$Action = "link",

    [ValidateSet("all", "kiro", "antigravity")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

# Kiro paths
$KiroHome = if ($env:KIRO_HOME) { $env:KIRO_HOME } else { Join-Path $env:USERPROFILE ".kiro" }
$KiroSkillsDir = Join-Path $KiroHome "skills"
$KiroSteeringDir = Join-Path $KiroHome "steering"

# Antigravity paths
$GeminiHome = if ($env:GEMINI_HOME) { $env:GEMINI_HOME } else { Join-Path $env:USERPROFILE ".gemini" }
$GeminiConfigDir = Join-Path $GeminiHome "config"
$GeminiPluginDir = Join-Path $GeminiConfigDir "plugins\skills-agent"
$GeminiRulesDir = Join-Path $GeminiPluginDir "rules"
$GeminiPluginSkillsDir = Join-Path $GeminiPluginDir "skills"
$GeminiGlobalSkillsDir = Join-Path $GeminiConfigDir "skills"

$CurrentDir = $PSScriptRoot
$SkillsSource = Join-Path $CurrentDir "skills"
$SteeringSource = Join-Path $CurrentDir "steering"

function Get-SkillFolders {
    if (Test-Path $SkillsSource) {
        Get-ChildItem -Path $SkillsSource -Directory |
            Select-Object -ExpandProperty Name
    }
}

function Get-SteeringFiles {
    if (Test-Path $SteeringSource) {
        Get-ChildItem -Path $SteeringSource -Filter "*.md" -File |
            Select-Object -ExpandProperty Name
    }
}

# --- Kiro Functions ---

function Invoke-Link-Kiro {
    $skillFolders = Get-SkillFolders
    $steeringFiles = Get-SteeringFiles

    Write-Host "`n[Kiro] Copying skills to $KiroSkillsDir..." -ForegroundColor Cyan

    if (Test-Path $KiroSkillsDir) {
        Remove-Item -Path (Join-Path $KiroSkillsDir "*") -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $KiroSkillsDir -Force | Out-Null

    foreach ($folder in $skillFolders) {
        $source = Join-Path $SkillsSource $folder
        $dest = Join-Path $KiroSkillsDir $folder
        Copy-Item -Path $source -Destination $dest -Recurse -Force
        Write-Host "  + $folder -> $dest" -ForegroundColor Green
    }

    $readmeSrc = Join-Path $CurrentDir "README.md"
    if (Test-Path $readmeSrc) {
        Copy-Item -Path $readmeSrc -Destination (Join-Path $KiroSkillsDir "README.md") -Force
        Write-Host "  + README.md -> $KiroSkillsDir\README.md" -ForegroundColor Green
    }

    Write-Host "`n[Kiro] Copying steering to $KiroSteeringDir..." -ForegroundColor Cyan

    if (Test-Path $KiroSteeringDir) {
        Get-ChildItem -Path $KiroSteeringDir -Filter "*.md" -File | Remove-Item -Force
    }
    New-Item -ItemType Directory -Path $KiroSteeringDir -Force | Out-Null

    foreach ($file in $steeringFiles) {
        $source = Join-Path $SteeringSource $file
        $dest = Join-Path $KiroSteeringDir $file
        Copy-Item -Path $source -Destination $dest -Force
        Write-Host "  + $file -> $dest" -ForegroundColor Green
    }

    $skillCount = ($skillFolders | Measure-Object).Count
    $steeringCount = ($steeringFiles | Measure-Object).Count
    Write-Host "`n[Kiro] Done! $skillCount skills + $steeringCount steering files copied.`n" -ForegroundColor Green
}

function Invoke-Unlink-Kiro {
    Write-Host "`n[Kiro] Removing copied files..." -ForegroundColor Yellow

    if (Test-Path $KiroSkillsDir) {
        Remove-Item -Path (Join-Path $KiroSkillsDir "*") -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared $KiroSkillsDir" -ForegroundColor Yellow
    }

    if (Test-Path $KiroSteeringDir) {
        Get-ChildItem -Path $KiroSteeringDir -Filter "*.md" -File | Remove-Item -Force
        Write-Host "  Cleared *.md from $KiroSteeringDir" -ForegroundColor Yellow
    }

    Write-Host "`n[Kiro] Done!`n" -ForegroundColor Green
}

function Invoke-Status-Kiro {
    Write-Host "`n📂 === Kiro Status ===" -ForegroundColor Cyan
    Write-Host "Skills ($KiroSkillsDir):"
    if (Test-Path $KiroSkillsDir) {
        Get-ChildItem -Path $KiroSkillsDir | ForEach-Object {
            $type = if ($_.PSIsContainer) { "[DIR] " } else { "[FILE]" }
            Write-Host "  $type $($_.Name)"
        }
    } else {
        Write-Host "  (empty)"
    }

    Write-Host "`nSteering ($KiroSteeringDir):"
    if (Test-Path $KiroSteeringDir) {
        Get-ChildItem -Path $KiroSteeringDir -Filter "*.md" -File | ForEach-Object {
            Write-Host "  [FILE] $($_.Name)"
        }
    } else {
        Write-Host "  (empty)"
    }
    Write-Host ""
}

# --- Antigravity Functions ---

function Invoke-Link-Antigravity {
    $skillFolders = Get-SkillFolders
    $steeringFiles = Get-SteeringFiles

    Write-Host "`n[Antigravity] Setting up plugin & skills..." -ForegroundColor Cyan

    New-Item -ItemType Directory -Path $GeminiRulesDir -Force | Out-Null
    New-Item -ItemType Directory -Path $GeminiPluginSkillsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $GeminiGlobalSkillsDir -Force | Out-Null

    # 1. Generate plugin.json
    $pluginJsonContent = @'
{
  "name": "skills-agent",
  "description": "Clean Architecture patterns, engineering standards, and production rules for Kiro & Antigravity"
}
'@
    Set-Content -Path (Join-Path $GeminiPluginDir "plugin.json") -Value $pluginJsonContent -Encoding utf8
    Write-Host "  + plugin.json generated" -ForegroundColor Green

    # 2. Process steering files into rules/*.md
    if (Test-Path $GeminiRulesDir) {
        Get-ChildItem -Path $GeminiRulesDir -Filter "*.md" -File | Remove-Item -Force
    }

    foreach ($file in $steeringFiles) {
        $source = Join-Path $SteeringSource $file
        $raw = Get-Content -Path $source -Raw

        # Strip YAML frontmatter if present
        $clean = if ($raw -match "(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$") { $matches[1] } else { $raw }

        # Append autonomous agent execution rule if skill-router.md
        if ($file -eq "skill-router.md") {
            $extra = @'

## Autonomous Agent Execution Rule
Ketika menerima task yang relevan dengan domain di atas, AI WAJIB membaca file `SKILL.md` terkait (menggunakan tool `view_file` atau file reference) SEBELUM mulai membuat atau memodifikasi file kode. DILARANG KERAS membuat kode monolitik (satu file ratusan baris) atau membuat kode di luar pattern arsitektur yang telah ditetapkan.
'@
            $clean += $extra
        }

        $dest = Join-Path $GeminiRulesDir $file
        Set-Content -Path $dest -Value $clean -Encoding utf8
        Write-Host "  + steering\$file -> rules\$file" -ForegroundColor Green
    }

    # 3. Copy skills to plugin & global skills dir
    foreach ($folder in $skillFolders) {
        $source = Join-Path $SkillsSource $folder
        $destPlugin = Join-Path $GeminiPluginSkillsDir $folder
        $destGlobal = Join-Path $GeminiGlobalSkillsDir $folder

        Copy-Item -Path $source -Destination $destPlugin -Recurse -Force
        Copy-Item -Path $source -Destination $destGlobal -Recurse -Force
        Write-Host "  + $folder -> $destPlugin & $destGlobal" -ForegroundColor Green
    }

    $readmeSrc = Join-Path $CurrentDir "README.md"
    if (Test-Path $readmeSrc) {
        Copy-Item -Path $readmeSrc -Destination (Join-Path $GeminiPluginSkillsDir "README.md") -Force
        Copy-Item -Path $readmeSrc -Destination (Join-Path $GeminiGlobalSkillsDir "README.md") -Force
    }

    $skillCount = ($skillFolders | Measure-Object).Count
    $steeringCount = ($steeringFiles | Measure-Object).Count
    Write-Host "`n[Antigravity] Done! $skillCount skills + $steeringCount rules configured.`n" -ForegroundColor Green
}

function Invoke-Unlink-Antigravity {
    Write-Host "`n[Antigravity] Removing plugin & skills..." -ForegroundColor Yellow

    if (Test-Path $GeminiPluginDir) {
        Remove-Item -Path $GeminiPluginDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared $GeminiPluginDir" -ForegroundColor Yellow
    }

    $skillFolders = Get-SkillFolders
    foreach ($folder in $skillFolders) {
        $globalSkill = Join-Path $GeminiGlobalSkillsDir $folder
        if (Test-Path $globalSkill) {
            Remove-Item -Path $globalSkill -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "  Cleared global skills from $GeminiGlobalSkillsDir" -ForegroundColor Yellow

    Write-Host "`n[Antigravity] Done!`n" -ForegroundColor Green
}

function Invoke-Status-Antigravity {
    Write-Host "`n📂 === Antigravity Status ===" -ForegroundColor Cyan
    Write-Host "Plugin ($GeminiPluginDir):"
    if (Test-Path $GeminiPluginDir) {
        Get-ChildItem -Path $GeminiPluginDir | ForEach-Object {
            $type = if ($_.PSIsContainer) { "[DIR] " } else { "[FILE]" }
            Write-Host "  $type $($_.Name)"
        }
    } else {
        Write-Host "  (not installed)"
    }

    Write-Host "`nRules ($GeminiRulesDir):"
    if (Test-Path $GeminiRulesDir) {
        Get-ChildItem -Path $GeminiRulesDir -Filter "*.md" -File | ForEach-Object {
            Write-Host "  [FILE] $($_.Name)"
        }
    } else {
        Write-Host "  (empty)"
    }

    Write-Host "`nSkills ($GeminiGlobalSkillsDir):"
    if (Test-Path $GeminiGlobalSkillsDir) {
        Get-ChildItem -Path $GeminiGlobalSkillsDir | ForEach-Object {
            $type = if ($_.PSIsContainer) { "[DIR] " } else { "[FILE]" }
            Write-Host "  $type $($_.Name)"
        }
    } else {
        Write-Host "  (empty)"
    }
    Write-Host ""
}

# --- Router Execution ---
switch ($Action) {
    "link" {
        if ($Target -eq "all" -or $Target -eq "kiro") { Invoke-Link-Kiro }
        if ($Target -eq "all" -or $Target -eq "antigravity") { Invoke-Link-Antigravity }
    }
    "unlink" {
        if ($Target -eq "all" -or $Target -eq "kiro") { Invoke-Unlink-Kiro }
        if ($Target -eq "all" -or $Target -eq "antigravity") { Invoke-Unlink-Antigravity }
    }
    "status" {
        Invoke-Status-Kiro
        Invoke-Status-Antigravity
    }
}
